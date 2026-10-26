import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_management_system/models/stock_movement.dart';
import 'package:inventory_management_system/services/sample_data.dart';

const _categories = [
  'Electronics',
  'Office Supplies',
  'Food & Beverages',
  'Clothing & Apparel',
  'Tools & Equipment',
  'Medical Supplies',
  'Automotive',
  'Books & Media',
  'Furniture',
  'Cleaning Supplies',
  'Sports & Recreation',
  'Beauty & Personal Care',
];

void main() {
  final now = DateTime(2026, 10, 7, 9, 0);
  final data =
      SampleData.build(now: now, userId: 'uid-123', userName: 'Trial User');

  final byItem = <String, List<StockMovement>>{};
  for (final m in data.movements) {
    byItem.putIfAbsent(m.itemId, () => []).add(m);
  }
  for (final list in byItem.values) {
    list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  bool isInitial(StockMovement m) => m.reason == 'Initial stock';
  bool isDelivery(StockMovement m) => m.reason.startsWith('Supplier delivery');

  group('catalogue', () {
    test('has a realistic number of unique, well-formed items', () {
      expect(data.items.length, inInclusiveRange(20, 35));
      expect(data.items.map((i) => i.id).toSet().length, data.items.length);
      expect(data.items.map((i) => i.name).toSet().length, data.items.length);
      for (final item in data.items) {
        expect(_categories, contains(item.category), reason: item.name);
        expect(item.unitPrice, greaterThan(0), reason: item.name);
        expect(item.reorderLevel, greaterThan(0), reason: item.name);
        expect(item.quantity, greaterThanOrEqualTo(0), reason: item.name);
        expect(item.supplier, isNotEmpty);
        expect(item.description, isNotEmpty);
      }
    });

    test('stock levels include healthy, low and out-of-stock items', () {
      final low = data.items.where((i) => i.quantity <= i.reorderLevel);
      final out = data.items.where((i) => i.quantity == 0);
      expect(low.length, inInclusiveRange(4, 10));
      expect(out, isNotEmpty);
      expect(data.items.length - low.length, greaterThanOrEqualTo(12));
    });

    test('the seed stays small so many trials fit in the daily write quota',
        () {
      final writes =
          data.items.length + data.movements.length + data.predictions.length;
      expect(writes, lessThan(450));
    });

    test('perishables carry expiry dates, some expired and some expiring soon',
        () {
      final perishable = data.items.where((i) => i.isPerishable).toList();
      for (final i in perishable) {
        expect(i.expiryDate, isNotNull, reason: i.name);
      }
      for (final i in data.items.where((i) => !i.isPerishable)) {
        expect(i.expiryDate, isNull, reason: i.name);
      }
      expect(perishable.where((i) => i.expiryDate!.isBefore(now)).length,
          greaterThanOrEqualTo(1));
      final soon = perishable.where((i) {
        final d = i.expiryDate!.difference(now).inDays;
        return d >= 0 && d <= 30;
      });
      expect(soon.length, greaterThanOrEqualTo(3));
    });
  });

  group('Kenyan retail realism', () {
    test('prices are whole Kenyan shillings in a plausible retail range', () {
      for (final item in data.items) {
        expect(item.unitPrice, item.unitPrice.roundToDouble(),
            reason: '${item.name} should be a whole-shilling price');
        expect(item.unitPrice, inInclusiveRange(20, 5000), reason: item.name);
      }
    });

    test('is sourced from many different suppliers', () {
      expect(data.items.map((i) => i.supplier).toSet().length,
          greaterThanOrEqualTo(8));
    });

    test('deliveries arrive before opening and sales happen 8am to 9pm', () {
      for (final m in data.movements) {
        if (m.type == MovementType.stockIn) {
          expect(m.timestamp.hour, inInclusiveRange(6, 7));
        } else {
          expect(m.timestamp.hour, inInclusiveRange(8, 20));
        }
      }
    });

    test('there are no supplier deliveries on Sundays', () {
      for (final m in data.movements.where(isDelivery)) {
        expect(m.timestamp.weekday, isNot(DateTime.sunday));
      }
    });

    test('sales are cash, M-Pesa, wholesale and WhatsApp orders', () {
      final reasons = data.movements
          .where((m) => m.type == MovementType.stockOut)
          .map((m) => m.reason)
          .toSet();
      expect(
          reasons,
          containsAll([
            'Counter sale (cash)',
            'Counter sale (M-Pesa)',
            'Wholesale order',
            'Online order (WhatsApp)',
          ]));
    });

    test('every delivery names the item\'s own supplier', () {
      for (final m in data.movements.where(isDelivery)) {
        final item = data.items.firstWhere((i) => i.id == m.itemId);
        expect(m.reason, 'Supplier delivery - ${item.supplier}');
      }
    });
  });

  group('stock movements', () {
    test('every item starts with its initial stock', () {
      expect(byItem.keys.toSet(), data.items.map((i) => i.id).toSet());
      for (final entry in byItem.entries) {
        expect(entry.value.first.type, MovementType.stockIn);
        expect(isInitial(entry.value.first), isTrue);
      }
    });

    test(
        'replaying movements never goes negative and ends at the item quantity',
        () {
      for (final item in data.items) {
        var balance = 0;
        for (final m in byItem[item.id]!) {
          balance += m.type == MovementType.stockIn ? m.quantity : -m.quantity;
          expect(balance, greaterThanOrEqualTo(0),
              reason: '${item.name} went negative');
        }
        expect(balance, item.quantity, reason: item.name);
      }
    });

    test('all movements sit inside the 45-day window and are well-formed', () {
      final earliest = now.subtract(Duration(days: SampleData.historyDays + 1));
      for (final m in data.movements) {
        expect(m.timestamp.isAfter(earliest), isTrue);
        expect(m.timestamp.isBefore(now), isTrue);
        expect(m.quantity, greaterThan(0));
        expect(m.type, isNot(MovementType.adjustment));
        expect(m.userId, 'uid-123');
        expect(m.userName, 'Trial User');
      }
    });

    test(
        'has plenty of recent activity spread over at least two calendar months',
        () {
      final recentSales = data.movements.where((m) =>
          m.type == MovementType.stockOut &&
          m.timestamp.isAfter(now.subtract(const Duration(days: 30))));
      expect(recentSales.length, greaterThan(100));
      final months = data.movements
          .map((m) => '${m.timestamp.year}-${m.timestamp.month}')
          .toSet();
      expect(months.length, greaterThanOrEqualTo(2));
    });
  });

  group('predictions', () {
    test('one per item, and every low or out-of-stock item needs restocking',
        () {
      expect(data.predictions.length, data.items.length);
      for (var i = 0; i < data.items.length; i++) {
        final item = data.items[i];
        final p = data.predictions[i];
        expect(p.itemId, item.id);
        expect(p.currentQuantity, item.quantity);
        expect(p.daysLeft, greaterThanOrEqualTo(0));
        if (item.quantity <= item.reorderLevel) {
          expect(p.needsRestock, isTrue, reason: item.name);
        }
      }
      expect(data.predictions.where((p) => p.needsRestock).length,
          inInclusiveRange(5, 14));
    });
  });

  test('building twice gives identical data', () {
    final again =
        SampleData.build(now: now, userId: 'uid-123', userName: 'Trial User');
    expect(again.items.map((i) => '${i.id}:${i.quantity}').toList(),
        data.items.map((i) => '${i.id}:${i.quantity}').toList());
    expect(
        again.movements
            .map((m) => '${m.id}:${m.quantity}:${m.timestamp}')
            .toList(),
        data.movements
            .map((m) => '${m.id}:${m.quantity}:${m.timestamp}')
            .toList());
  });
}
