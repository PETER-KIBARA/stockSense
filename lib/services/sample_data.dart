import 'dart:math' as math;
import '../models/inventory_item.dart';
import '../models/stock_movement.dart';
import '../models/stock_prediction.dart';

/// Sample workspace given to every new trial visitor. Pure Dart (no Firebase calls),
/// deterministic, and dated relative to [build]'s `now`, so it never looks stale.
class SampleWorkspace {
  final List<InventoryItem> items;
  final List<StockMovement> movements;
  final List<StockPrediction> predictions;
  const SampleWorkspace({
    required this.items,
    required this.movements,
    required this.predictions,
  });
}

class SampleData {
  static const int historyDays = 45;
  static const String itemIdPrefix = 'sample_item_';
  static const String movementIdPrefix = 'sample_mv_';
  static const String predictionIdPrefix = 'sample_pred_';

  static String predictionIdFor(String itemId) =>
      itemId.replaceFirst(itemIdPrefix, predictionIdPrefix);

  static SampleWorkspace build({
    required DateTime now,
    required String userId,
    required String userName,
  }) {
    final items = <InventoryItem>[];
    final movements = <StockMovement>[];
    final predictions = <StockPrediction>[];

    for (var i = 0; i < _catalog.length; i++) {
      final spec = _catalog[i];
      final itemId = '$itemIdPrefix${_pad(i + 1, 2)}';
      final events = _history(spec, i, now);

      final itemMovements = <StockMovement>[];
      for (var n = 0; n < events.length; n++) {
        final e = events[n];
        itemMovements.add(StockMovement(
          id: '$movementIdPrefix${_pad(i + 1, 2)}_${_pad(n + 1, 3)}',
          itemId: itemId,
          itemName: spec.name,
          type: e.isIn ? MovementType.stockIn : MovementType.stockOut,
          quantity: e.quantity,
          reason: e.reason,
          timestamp: e.at,
          userId: userId,
          userName: userName,
        ));
      }

      final item = InventoryItem(
        id: itemId,
        name: spec.name,
        description: spec.description,
        category: spec.category,
        quantity: spec.finalQty,
        unitPrice: spec.price,
        supplier: spec.supplier,
        createdAt: events.first.at,
        updatedAt: events.last.at,
        reorderLevel: spec.reorder,
        expiryDate: spec.expiresInDays == null
            ? null
            : DateTime(now.year, now.month, now.day + spec.expiresInDays!),
        isPerishable: spec.expiresInDays != null,
      );

      items.add(item);
      movements.addAll(itemMovements);
      predictions.add(_predict(item, itemMovements, now));
    }

    movements.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return SampleWorkspace(
        items: items, movements: movements, predictions: predictions);
  }

  /// Builds one item's history by walking BACKWARDS from today's stock level.
  /// Every step keeps `balance` equal to the stock right after that moment, so
  /// replaying the events forwards can never go negative and always ends at
  /// [_Spec.finalQty].
  static List<_Event> _history(_Spec spec, int index, DateTime now) {
    final rng = _Rng(7919 * (index + 1));
    final phase = index % spec.gap;
    final firstRestockBack = 3 + (index * 5) % 12; // stagger deliveries
    final peak = math.max(spec.reorder * 3, (spec.finalQty * 0.6).round() + 1);
    final events = <_Event>[];
    var balance = spec.finalQty;

    for (var back = 1; back < historyDays; back++) {
      if ((back + phase) % spec.gap == 0) {
        final qty = math.max(
            1, (spec.perEntry * (0.6 + 0.8 * rng.nextDouble())).round());
        events.add(_Event(
          _at(now, back, 9 + rng.nextInt(0, 8), rng.nextInt(0, 59)),
          false,
          qty,
          _saleReason(rng),
        ));
        balance += qty;
      }
      // A delivery arrives when stock was down at/below the reorder level.
      if (back >= firstRestockBack && balance >= peak) {
        final low = rng.nextInt(1, spec.reorder);
        final delivered = ((balance - low) ~/ 6) * 6;
        if (delivered >= 6) {
          events.add(_Event(
            _at(now, back, 7, rng.nextInt(0, 59)),
            true,
            delivered,
            _restockReason(rng),
          ));
          balance -= delivered;
        }
      }
    }

    if (balance > 0) {
      events.add(_Event(_at(now, historyDays, 7, 0), true, balance, 'Initial stock'));
    }
    return events.reversed.toList(); // oldest first
  }

  /// Mirrors InventoryService's prediction logic so the saved predictions match
  /// what the app itself would calculate (it refreshes them after 24 hours).
  static StockPrediction _predict(
      InventoryItem item, List<StockMovement> history, DateTime now) {
    final cutoff = now.subtract(const Duration(days: 30));
    final recent = history.where((m) => m.timestamp.isAfter(cutoff)).toList();

    final usageByDay = <String, int>{};
    for (final m in recent) {
      if (m.type == MovementType.stockOut) {
        final key = m.timestamp.toIso8601String().substring(0, 10);
        usageByDay[key] = (usageByDay[key] ?? 0) + m.quantity;
      }
    }

    final isLow = item.quantity <= item.reorderLevel;
    final isOut = item.quantity == 0;

    var averageDailyUsage = 0.0;
    int daysLeft;
    if (usageByDay.isNotEmpty) {
      final total = usageByDay.values.reduce((a, b) => a + b);
      averageDailyUsage = total / usageByDay.length;
      daysLeft = averageDailyUsage > 0
          ? (item.quantity / averageDailyUsage).ceil()
          : 999;
    } else {
      daysLeft = isOut ? 0 : 999;
    }

    if (item.isPerishable && item.expiryDate != null) {
      final daysUntilExpiry = item.expiryDate!.difference(now).inDays;
      if (daysUntilExpiry < daysLeft) {
        daysLeft = daysUntilExpiry.clamp(0, daysLeft);
      }
    }

    final hasHistory = recent.isNotEmpty;
    PredictionConfidence confidence;
    if (item.isPerishable && item.expiryDate != null) {
      confidence =
          hasHistory ? PredictionConfidence.high : PredictionConfidence.medium;
    } else if (hasHistory) {
      confidence = recent.length >= 14
          ? PredictionConfidence.high
          : (recent.length >= 7
              ? PredictionConfidence.medium
              : PredictionConfidence.low);
    } else {
      confidence = PredictionConfidence.low;
    }

    return StockPrediction(
      itemId: item.id,
      itemName: item.name,
      currentQuantity: item.quantity,
      averageDailyUsage: averageDailyUsage,
      daysLeft: daysLeft,
      predictedDepletionDate: now.add(Duration(days: daysLeft)),
      needsRestock: isLow || isOut || daysLeft <= 7,
      confidence: confidence,
      calculatedAt: now,
    );
  }

  static DateTime _at(DateTime now, int daysBack, int hour, int minute) =>
      DateTime(now.year, now.month, now.day - daysBack, hour, minute);

  static String _pad(int n, int width) => n.toString().padLeft(width, '0');

  static String _saleReason(_Rng rng) {
    const reasons = [
      'Customer sales',
      'Customer sales',
      'Customer sales',
      'Bulk order',
      'Online order',
    ];
    return reasons[rng.nextInt(0, reasons.length - 1)];
  }

  static String _restockReason(_Rng rng) {
    const reasons = ['Supplier delivery', 'Restock - purchase order'];
    return reasons[rng.nextInt(0, reasons.length - 1)];
  }

  // name, description, category, supplier, price (KES), reorder level,
  // quantity today, typical units per sales entry, days between sales entries,
  // days until expiry (null = not perishable; negative = already expired)
  static const List<_Spec> _catalog = [
    _Spec('Maize Flour 2kg', 'Sifted maize meal, 2kg pack', 'Food & Beverages', 'Nairobi Wholesale Traders', 190, 40, 145, 6, 2, 210),
    _Spec('Cooking Oil 1L', 'Refined vegetable cooking oil, 1 litre', 'Food & Beverages', 'Nairobi Wholesale Traders', 320, 30, 22, 4, 3, 300),
    _Spec('Sugar 1kg', 'White granulated sugar, 1kg pack', 'Food & Beverages', 'Kisumu Agro Supplies', 165, 35, 90, 5, 2),
    _Spec('Long Life Milk 500ml', 'UHT whole milk, 500ml carton', 'Food & Beverages', 'Eldoret Dairy Partners', 65, 48, 130, 10, 2, 45),
    _Spec('Fresh Yoghurt 500ml', 'Natural set yoghurt, 500ml cup', 'Food & Beverages', 'Eldoret Dairy Partners', 110, 20, 14, 3, 3, 4),
    _Spec('Eggs Tray (30)', 'Farm eggs, tray of 30', 'Food & Beverages', 'Nakuru Fresh Produce', 450, 10, 24, 2, 3, 12),
    _Spec('Mineral Water 500ml', 'Still mineral water, 500ml bottle', 'Food & Beverages', 'Mombasa Road Distributors', 40, 100, 260, 20, 2, 400),
    _Spec('Fresh Orange Juice 1L', 'Not-from-concentrate orange juice, 1 litre', 'Food & Beverages', 'Nakuru Fresh Produce', 230, 18, 0, 3, 3, 25),
    _Spec('Fresh Milk 500ml', 'Pasteurised fresh milk, 500ml pouch', 'Food & Beverages', 'Eldoret Dairy Partners', 60, 24, 6, 5, 2, -2),
    _Spec('Tea Leaves 500g', 'Loose black tea, 500g pack', 'Food & Beverages', 'Kisumu Agro Supplies', 280, 25, 61, 2, 3, 180),
    _Spec('Laundry Detergent 1kg', 'Multi-surface washing powder, 1kg', 'Cleaning Supplies', 'Thika Home Care Ltd', 340, 20, 48, 3, 3),
    _Spec('Dishwashing Liquid 750ml', 'Lemon dishwashing liquid, 750ml', 'Cleaning Supplies', 'Thika Home Care Ltd', 210, 18, 12, 2, 3),
    _Spec('Toilet Paper (10 Pack)', 'Soft 2-ply toilet tissue, 10 rolls', 'Cleaning Supplies', 'Thika Home Care Ltd', 420, 20, 70, 4, 3),
    _Spec('A4 Printing Paper Ream', '500 sheets, 80gsm A4 copier paper', 'Office Supplies', 'Westlands Office Hub', 650, 15, 52, 3, 4),
    _Spec('Ballpoint Pens (Box of 50)', 'Blue ballpoint pens, box of 50', 'Office Supplies', 'Westlands Office Hub', 480, 10, 8, 1, 4),
    _Spec('Exercise Books 96pg (10 Pack)', 'Ruled exercise books, pack of 10', 'Office Supplies', 'Westlands Office Hub', 520, 12, 41, 3, 4),
    _Spec('USB-C Charging Cable 1m', 'Fast-charge USB-C cable, 1 metre', 'Electronics', 'Industrial Area Electronics', 350, 20, 64, 3, 3),
    _Spec('Wireless Earbuds', 'Bluetooth 5.0 earbuds with charging case', 'Electronics', 'Industrial Area Electronics', 2800, 6, 9, 1, 4),
    _Spec('LED Bulb 9W', 'Energy-saving LED bulb, E27, 9W', 'Electronics', 'Industrial Area Electronics', 180, 30, 120, 6, 3),
    _Spec('Power Extension Cord 4-Way', '4-socket surge-protected extension, 3m', 'Electronics', 'Industrial Area Electronics', 950, 8, 3, 1, 4),
    _Spec('Bathing Soap Bar 200g', 'Moisturising bathing soap, 200g', 'Beauty & Personal Care', 'Mombasa Road Distributors', 95, 40, 160, 8, 2),
    _Spec('Body Lotion 400ml', 'Nourishing body lotion, 400ml', 'Beauty & Personal Care', 'Mombasa Road Distributors', 420, 15, 38, 2, 4, 420),
    _Spec('Toothpaste 100ml', 'Fluoride toothpaste, 100ml tube', 'Beauty & Personal Care', 'Mombasa Road Distributors', 160, 30, 44, 4, 3, 365),
    _Spec('Hand Sanitizer 500ml', 'Alcohol-based hand sanitizer, 500ml', 'Medical Supplies', 'Thika Home Care Ltd', 350, 20, 55, 4, 3, 26),
  ];
}

class _Spec {
  final String name;
  final String description;
  final String category;
  final String supplier;
  final double price;
  final int reorder;
  final int finalQty;
  final int perEntry;
  final int gap;
  final int? expiresInDays;
  const _Spec(this.name, this.description, this.category, this.supplier,
      this.price, this.reorder, this.finalQty, this.perEntry, this.gap,
      [this.expiresInDays]);
}

class _Event {
  final DateTime at;
  final bool isIn;
  final int quantity;
  final String reason;
  const _Event(this.at, this.isIn, this.quantity, this.reason);
}

/// Small deterministic generator (Park-Miller). Plain integer maths that stays
/// exact in both the Dart VM and the browser, so every visitor gets the same shape.
class _Rng {
  int _s;
  _Rng(int seed) : _s = (seed % 2147483646) + 1;

  double nextDouble() {
    _s = (_s * 48271) % 2147483647;
    return (_s - 1) / 2147483646;
  }

  /// Inclusive range.
  int nextInt(int min, int max) =>
      min + (nextDouble() * (max - min + 1)).floor();
}