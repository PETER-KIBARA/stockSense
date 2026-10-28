import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_management_system/models/inventory_item.dart';
import 'package:inventory_management_system/models/stock_movement.dart';
import 'package:inventory_management_system/utils/csv_export.dart';

InventoryItem _item({
  String name = 'Maize Flour (Unga) 2kg',
  int quantity = 145,
  double price = 185,
  int reorder = 40,
}) =>
    InventoryItem(
      id: '1',
      name: name,
      description: 'Sifted maize meal, 2kg',
      category: 'Food & Beverages',
      quantity: quantity,
      unitPrice: price,
      supplier: 'Nakuru Grain & Cereals Ltd',
      createdAt: DateTime(2026, 10, 1),
      updatedAt: DateTime(2026, 10, 2),
      reorderLevel: reorder,
    );

StockMovement _movement(DateTime at, MovementType type, int qty) =>
    StockMovement(
      id: 'm',
      itemId: '1',
      itemName: 'Maize Flour (Unga) 2kg',
      type: type,
      quantity: qty,
      reason: 'Counter sale (cash)',
      timestamp: at,
      userId: 'u',
      userName: 'Trial User',
    );

void main() {
  test('inventory CSV has a header, one row per item and CRLF line endings',
      () {
    final csv = CsvExport.inventoryCsv([_item()]);
    final lines = csv.split('\r\n');
    expect(lines.length, 3); // header, row, trailing empty
    expect(
        lines[0],
        startsWith(
            'Name,Category,Description,Supplier,Quantity,Unit price (KES)'));
    expect(lines[1], startsWith('Maize Flour (Unga) 2kg,Food & Beverages,'));
    expect(lines[1],
        contains(',145,185,26825,40,In stock,No,,2026-10-01,2026-10-02'));
  });

  test('commas, quotes and new lines are quoted', () {
    expect(CsvExport.cell('Soap, "premium"'), '"Soap, ""premium"""');
    expect(CsvExport.cell('two\nlines'), '"two\nlines"');
  });

  test('text that could run as a spreadsheet formula is neutralised', () {
    expect(CsvExport.cell('=SUM(A1:A9)'), "'=SUM(A1:A9)");
    expect(CsvExport.cell('@cmd'), "'@cmd");
    expect(CsvExport.cell('+254712345678'), "'+254712345678");
  });

  test('numbers are written plainly and are never altered', () {
    expect(CsvExport.cell(3), '3');
    expect(CsvExport.cell(-5), '-5');
    expect(CsvExport.cell(1450.5), '1450.50');
    expect(CsvExport.cell(null), '');
  });

  test('stock status follows quantity and reorder level', () {
    expect(CsvExport.stockStatus(_item(quantity: 0)), 'Out of stock');
    expect(
        CsvExport.stockStatus(_item(quantity: 10, reorder: 40)), 'Low stock');
    expect(
        CsvExport.stockStatus(_item(quantity: 40, reorder: 40)), 'Low stock');
    expect(CsvExport.stockStatus(_item(quantity: 145)), 'In stock');
  });

  test('movements are listed newest first with readable types', () {
    final csv = CsvExport.movementsCsv([
      _movement(DateTime(2026, 10, 1, 8, 30), MovementType.stockIn, 50),
      _movement(DateTime(2026, 10, 3, 9, 15), MovementType.stockOut, 6),
    ]);
    final lines = csv.split('\r\n');
    expect(lines[0], 'Date and time,Item,Type,Quantity,Reason,Recorded by');
    expect(lines[1], startsWith('2026-10-03 09:15,'));
    expect(lines[1], contains(',Stock out,6,'));
    expect(lines[2], contains(',Stock in,50,'));
  });

  test('the file starts with a UTF-8 byte-order mark for Excel', () {
    final bytes = CsvExport.encode('a,b\r\n');
    expect(bytes.take(3).toList(), [0xEF, 0xBB, 0xBF]);
  });
}
