import 'dart:convert';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import '../models/inventory_item.dart';
import '../models/stock_movement.dart';

/// Pure CSV builders (unit-tested). Output opens cleanly in Excel and Google Sheets.
class CsvExport {
  static const String eol = '\r\n';

  static String number(num value) {
    final d = value.toDouble();
    return d == d.roundToDouble() ? d.toInt().toString() : d.toStringAsFixed(2);
  }

  /// One CSV cell. Text starting with = + - @ is prefixed so a spreadsheet
  /// never runs it as a formula (item names are typed by users).
  static String cell(Object? value) {
    if (value == null) return '';
    if (value is num) return number(value);
    var text = value.toString();
    if (text.isNotEmpty && '=+-@\t\r'.contains(text[0])) {
      text = "'$text";
    }
    final needsQuotes = text.contains(',') ||
        text.contains('"') ||
        text.contains('\n') ||
        text.contains('\r');
    return needsQuotes ? '"${text.replaceAll('"', '""')}"' : text;
  }

  static String _row(List<Object?> values) => values.map(cell).join(',');

  static String _date(DateTime? d) =>
      d == null ? '' : DateFormat('yyyy-MM-dd').format(d);

  static String stockStatus(InventoryItem item) {
    if (item.quantity == 0) return 'Out of stock';
    if (item.quantity <= item.reorderLevel) return 'Low stock';
    return 'In stock';
  }

  static String inventoryCsv(List<InventoryItem> items) {
    final rows = <String>[
      _row([
        'Name',
        'Category',
        'Description',
        'Supplier',
        'Quantity',
        'Unit price (KES)',
        'Stock value (KES)',
        'Reorder level',
        'Status',
        'Perishable',
        'Expiry date',
        'Created',
        'Last updated',
      ]),
    ];
    for (final i in items) {
      rows.add(_row([
        i.name,
        i.category,
        i.description,
        i.supplier,
        i.quantity,
        i.unitPrice,
        i.quantity * i.unitPrice,
        i.reorderLevel,
        stockStatus(i),
        i.isPerishable ? 'Yes' : 'No',
        _date(i.expiryDate),
        _date(i.createdAt),
        _date(i.updatedAt),
      ]));
    }
    return rows.join(eol) + eol;
  }

  static String movementType(MovementType type) {
    switch (type) {
      case MovementType.stockIn:
        return 'Stock in';
      case MovementType.stockOut:
        return 'Stock out';
      case MovementType.adjustment:
        return 'Adjustment';
    }
  }

  static String movementsCsv(List<StockMovement> movements) {
    final sorted = [...movements]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final rows = <String>[
      _row([
        'Date and time',
        'Item',
        'Type',
        'Quantity',
        'Reason',
        'Recorded by'
      ]),
    ];
    for (final m in sorted) {
      rows.add(_row([
        DateFormat('yyyy-MM-dd HH:mm').format(m.timestamp),
        m.itemName,
        movementType(m.type),
        m.quantity,
        m.reason,
        m.userName,
      ]));
    }
    return rows.join(eol) + eol;
  }

  /// UTF-8 with a byte-order mark so Excel reads the file correctly.
  static Uint8List encode(String csv) =>
      Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(csv)]);
}
