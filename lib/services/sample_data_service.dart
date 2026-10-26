import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'sample_data.dart';

typedef _Write
    = MapEntry<DocumentReference<Map<String, dynamic>>, Map<String, dynamic>>;

class SampleDataService {
  static const int _batchLimit = 400; // Firestore allows 500 writes per batch

  /// Gives a new trial account its own sample workspace, once.
  /// Never throws: if anything fails the trial simply opens with an empty workspace.
  static Future<void> seedIfNeeded({
    required String uid,
    required String userName,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final userRef = firestore.collection('users').doc(uid);

      final userSnap = await userRef.get();
      if (userSnap.data()?['trialSeeded'] == true) return;

      // Never touch a workspace that already holds data.
      final existing =
          await userRef.collection('inventory_items').limit(1).get();

      if (existing.docs.isEmpty) {
        final data = SampleData.build(
            now: DateTime.now(), userId: uid, userName: userName);

        final writes = <_Write>[];
        for (final item in data.items) {
          writes.add(MapEntry(
            userRef.collection('inventory_items').doc(item.id),
            {...item.toMap(), 'sample': true},
          ));
        }
        for (final m in data.movements) {
          writes.add(MapEntry(
            userRef.collection('stock_movements').doc(m.id),
            {...m.toMap(), 'sample': true},
          ));
        }
        for (var i = 0; i < data.predictions.length; i++) {
          writes.add(MapEntry(
            userRef
                .collection('stock_predictions')
                .doc(SampleData.predictionIdFor(data.items[i].id)),
            {...data.predictions[i].toMap(), 'sample': true},
          ));
        }

        for (var i = 0; i < writes.length; i += _batchLimit) {
          final batch = firestore.batch();
          for (final w in writes.skip(i).take(_batchLimit)) {
            batch.set(w.key, w.value);
          }
          await batch.commit();
        }
      }

      await userRef.set({
        'trialSeeded': true,
        'trialSeededAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Sample data seeding skipped: $e');
    }
  }

  /// True while this account still has the seeded sample workspace.
  static Future<bool> hasSampleData(String uid) async {
    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final data = (await userRef.get()).data();
      if (data?['trialSeeded'] != true || data?['sampleCleared'] == true) {
        return false;
      }
      final probe = await userRef
          .collection('inventory_items')
          .where('sample', isEqualTo: true)
          .limit(1)
          .get();
      return probe.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Deletes the sample items plus every movement and prediction linked to them.
  /// Items the visitor created themselves are kept. Returns the number of
  /// documents removed.
  static Future<int> clearSampleData(String uid) async {
    final firestore = FirebaseFirestore.instance;
    final userRef = firestore.collection('users').doc(uid);
    final refs = <DocumentReference<Map<String, dynamic>>>[];

    final items = await userRef
        .collection('inventory_items')
        .where('sample', isEqualTo: true)
        .get();
    refs.addAll(items.docs.map((d) => d.reference));

    for (final collection in ['stock_movements', 'stock_predictions']) {
      final snapshot = await userRef
          .collection(collection)
          .where('itemId', isGreaterThanOrEqualTo: SampleData.itemIdPrefix)
          .where('itemId', isLessThan: '${SampleData.itemIdPrefix}\uf8ff')
          .get();
      refs.addAll(snapshot.docs.map((d) => d.reference));
    }

    for (var i = 0; i < refs.length; i += _batchLimit) {
      final batch = firestore.batch();
      for (final ref in refs.skip(i).take(_batchLimit)) {
        batch.delete(ref);
      }
      await batch.commit();
    }

    // The seeding flag stays true, so the sample is never recreated.
    await userRef.set({
      'sampleCleared': true,
      'sampleClearedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return refs.length;
  }
}
