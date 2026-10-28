import 'dart:math' as math;
import '../models/inventory_item.dart';
import '../models/stock_movement.dart';
import '../models/stock_prediction.dart';

/// Sample workspace given to every new trial visitor: a small Kenyan general shop
/// (duka / mini-supermarket). Pure Dart (no Firebase calls), deterministic, and dated
/// relative to the `now` passed to [SampleData.build], so it never looks stale.
/// Supplier names are fictional and prices are indicative Nairobi retail estimates in KES.
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
  static const int historyDays = 30;
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
  /// [_Spec.finalQty]. Deliveries (6-7am) always precede the day's sales (8am+).
  static List<_Event> _history(_Spec spec, int index, DateTime now) {
    final rng = _Rng(7919 * (index + 1));
    final phase = index % spec.gap;
    final firstRestockBack = 3 + (index * 5) % 12; // stagger deliveries
    final peak = math.max(spec.reorder * 3, (spec.finalQty * 0.6).round() + 1);
    final events = <_Event>[];
    var balance = spec.finalQty;

    for (var back = 1; back < historyDays; back++) {
      final weekday = DateTime(now.year, now.month, now.day - back).weekday;

      if ((back + phase) % spec.gap == 0) {
        final dayFactor = weekday == DateTime.saturday
            ? 1.3
            : (weekday == DateTime.sunday ? 0.8 : 1.0);
        final qty = math.max(
            1,
            (spec.perEntry * (0.6 + 0.8 * rng.nextDouble()) * dayFactor)
                .round());
        events.add(_Event(
          _at(now, back, 8 + rng.nextInt(0, 12), rng.nextInt(0, 59)),
          false,
          qty,
          _saleReason(rng),
        ));
        balance += qty;
      }

      // Supplier deliveries arrive before opening and never on Sundays,
      // when stock had been run down to/below the reorder level.
      if (back >= firstRestockBack &&
          weekday != DateTime.sunday &&
          balance >= peak) {
        final low = rng.nextInt(1, spec.reorder);
        final delivered = ((balance - low) ~/ spec.pack) * spec.pack;
        if (delivered >= spec.pack) {
          events.add(_Event(
            _at(now, back, 6 + rng.nextInt(0, 1), rng.nextInt(0, 59)),
            true,
            delivered,
            'Supplier delivery - ${spec.supplier}',
          ));
          balance -= delivered;
        }
      }
    }

    if (balance > 0) {
      events.add(
          _Event(_at(now, historyDays, 7, 0), true, balance, 'Initial stock'));
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
      'Counter sale (cash)',
      'Counter sale (cash)',
      'Counter sale (M-Pesa)',
      'Counter sale (M-Pesa)',
      'Wholesale order',
      'Online order (WhatsApp)',
    ];
    return reasons[rng.nextInt(0, reasons.length - 1)];
  }

  // Columns: name, description, category, supplier, price (KES), reorder level,
  // quantity today, typical units per sales entry, days between sales entries,
  // carton size (delivery multiple), days until expiry (null = no expiry;
  // negative = already expired).
  static const List<_Spec> _catalog = [
    // ---- Food & Beverages ----
    _Spec(
        'Maize Flour (Unga) 2kg',
        'Sifted maize meal for ugali, 2kg packet',
        'Food & Beverages',
        'Nakuru Grain & Cereals Ltd',
        185,
        40,
        145,
        6,
        3,
        12,
        270),
    _Spec(
        'Wheat Flour 2kg',
        'All-purpose wheat flour for chapati and mandazi, 2kg packet',
        'Food & Beverages',
        'Nakuru Grain & Cereals Ltd',
        190,
        30,
        84,
        4,
        4,
        12,
        240),
    _Spec('Pishori Rice 1kg', 'Aromatic long-grain pishori rice, 1kg packet',
        'Food & Beverages', 'Mwea Rice Traders', 240, 25, 78, 4, 4, 10),
    _Spec('Sugar 1kg', 'White granulated sugar, 1kg packet', 'Food & Beverages',
        'Kisumu Lakeside Foods', 190, 35, 12, 5, 3, 20),
    _Spec(
        'Cooking Oil 1L',
        'Refined vegetable cooking oil, 1 litre bottle',
        'Food & Beverages',
        'Gikomba Wholesale Traders',
        320,
        30,
        96,
        4,
        4,
        12,
        330),
    _Spec(
        'Tea Leaves 250g',
        'Kenyan black CTC tea leaves, 250g packet',
        'Food & Beverages',
        'Kericho Highlands Tea Traders',
        125,
        40,
        150,
        5,
        4,
        20,
        300),
    _Spec('Salt 1kg', 'Iodised table salt, 1kg packet', 'Food & Beverages',
        'Gikomba Wholesale Traders', 50, 40, 190, 6, 5, 20),
    _Spec(
        'UHT Milk 500ml',
        'Long-life whole milk, 500ml packet',
        'Food & Beverages',
        'Eldoret Dairy Cooperative',
        65,
        48,
        130,
        10,
        3,
        24,
        60),
    _Spec(
        'Fresh Milk 500ml',
        'Pasteurised fresh milk, 500ml packet',
        'Food & Beverages',
        'Eldoret Dairy Cooperative',
        60,
        24,
        6,
        5,
        3,
        24,
        -2),
    _Spec(
        'Mala (Fermented Milk) 500ml',
        'Traditional fermented milk (mala), 500ml packet',
        'Food & Beverages',
        'Eldoret Dairy Cooperative',
        75,
        20,
        44,
        3,
        4,
        12,
        6),
    _Spec('Eggs Tray (30)', 'Farm eggs, tray of 30', 'Food & Beverages',
        'Kiambu Poultry Farmers Co-op', 480, 10, 28, 2, 4, 10, 12),
    _Spec('White Bread 400g', 'Sliced white bread loaf, 400g',
        'Food & Beverages', 'Thika Bakers Ltd', 65, 20, 36, 6, 2, 12, 3),
    _Spec(
        'Mango Juice 1L',
        'Mango fruit juice drink, 1 litre carton',
        'Food & Beverages',
        'Mombasa Road Distributors',
        220,
        18,
        0,
        3,
        4,
        12,
        25),
    _Spec(
        'Bottled Water 500ml',
        'Still drinking water, 500ml bottle',
        'Food & Beverages',
        'Mombasa Road Distributors',
        40,
        100,
        260,
        20,
        3,
        24,
        400),
    // ---- Cleaning Supplies ----
    _Spec('Laundry Detergent 1kg', 'Multi-surface washing powder, 1kg packet',
        'Cleaning Supplies', 'Thika Home Care Ltd', 310, 20, 48, 3, 5, 12),
    _Spec('Dishwashing Liquid 750ml', 'Lemon dishwashing liquid, 750ml bottle',
        'Cleaning Supplies', 'Thika Home Care Ltd', 200, 18, 12, 2, 5, 12),
    _Spec(
        'Household Bleach 750ml',
        'Disinfectant household bleach, 750ml bottle',
        'Cleaning Supplies',
        'Thika Home Care Ltd',
        170,
        15,
        52,
        3,
        5,
        12),
    _Spec(
        'Mosquito Coils (Pack of 12)',
        'Slow-burn mosquito coils, pack of 12',
        'Cleaning Supplies',
        'Mombasa Road Distributors',
        120,
        20,
        85,
        5,
        4,
        24),
    _Spec(
        'Toilet Paper (10 Pack)',
        'Soft 2-ply toilet tissue, pack of 10 rolls',
        'Cleaning Supplies',
        'Thika Home Care Ltd',
        400,
        20,
        70,
        4,
        4,
        12),
    // ---- Beauty & Personal Care ----
    _Spec(
        'Bathing Soap Bar 200g',
        'Moisturising bathing soap, 200g bar',
        'Beauty & Personal Care',
        'Mombasa Road Distributors',
        100,
        40,
        160,
        8,
        4,
        24),
    _Spec(
        'Petroleum Jelly 250ml',
        'Soothing petroleum jelly, 250ml jar',
        'Beauty & Personal Care',
        'Mombasa Road Distributors',
        260,
        15,
        44,
        3,
        5,
        12),
    _Spec('Sanitary Pads (Pack of 10)', 'Ultra-thin sanitary pads, pack of 10',
        'Beauty & Personal Care', 'Thika Home Care Ltd', 110, 30, 9, 6, 3, 24),
    // ---- Medical Supplies ----
    _Spec('Hand Sanitizer 500ml', 'Alcohol-based hand sanitizer, 500ml bottle',
        'Medical Supplies', 'Thika Home Care Ltd', 350, 20, 55, 4, 5, 12, 400),
    // ---- Electronics ----
    _Spec(
        'Solar Lantern (Rechargeable)',
        'Rechargeable LED solar lantern with USB phone charging',
        'Electronics',
        'Industrial Area Electronics',
        1450,
        8,
        7,
        1,
        6,
        6),
    _Spec('Phone Charger USB-C 20W', 'Fast wall charger with USB-C port, 20W',
        'Electronics', 'Industrial Area Electronics', 650, 15, 46, 3, 5, 12),
    _Spec('LED Bulb 9W', 'Energy-saving LED bulb, 9W', 'Electronics',
        'Industrial Area Electronics', 180, 30, 120, 6, 5, 24),
    _Spec('Power Bank 10,000mAh', 'Portable power bank, 10,000mAh, dual USB',
        'Electronics', 'Industrial Area Electronics', 1800, 6, 3, 1, 7, 6),
    // ---- Office Supplies ----
    _Spec('A4 Printing Paper Ream', '500 sheets, 80gsm A4 copier paper',
        'Office Supplies', 'Westlands Office Hub', 650, 15, 52, 3, 6, 10),
    _Spec(
        'Exercise Books 96pg (Pack of 10)',
        'Ruled school exercise books, pack of 10',
        'Office Supplies',
        'Kariokor Stationers',
        480,
        12,
        41,
        3,
        6,
        10),
    _Spec('Ballpoint Pens (Box of 50)', 'Blue ballpoint pens, box of 50',
        'Office Supplies', 'Kariokor Stationers', 450, 10, 8, 1, 6, 6),
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
  final int pack;
  final int? expiresInDays;
  const _Spec(
      this.name,
      this.description,
      this.category,
      this.supplier,
      this.price,
      this.reorder,
      this.finalQty,
      this.perEntry,
      this.gap,
      this.pack,
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
