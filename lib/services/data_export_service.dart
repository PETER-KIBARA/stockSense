import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/inventory_item.dart';
import '../models/stock_movement.dart';
import '../utils/csv_export.dart';
import '../utils/file_download.dart';
import '../utils/friendly_error.dart';
import 'inventory_service.dart';

class DataExportService {
  /// Every item, not just the first page the list screens load.
  static Future<List<InventoryItem>> fetchAllItems() async {
    final all = <InventoryItem>[];
    DocumentSnapshot? last;
    const batch = 100;
    while (true) {
      final page =
          await InventoryService.getInventoryItems(limit: batch, lastDoc: last);
      if (page.isEmpty) break;
      all.addAll(page);
      last = page.last.snapshot;
      if (page.length < batch || last == null) break;
    }
    return all;
  }

  static Future<List<StockMovement>> fetchMovements({int limit = 1000}) =>
      InventoryService.getStockMovements(limit: limit);

  static String _stamp() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  static Future<void> exportInventory(BuildContext context,
          {List<InventoryItem>? items}) =>
      _run(context, () async {
        final data = items ?? await fetchAllItems();
        if (data.isEmpty) return 'There are no items to export yet.';
        await FileDownload.save(
          baseName: 'stocksense-inventory-${_stamp()}',
          bytes: CsvExport.encode(CsvExport.inventoryCsv(data)),
          kind: DownloadKind.csv,
        );
        return 'Inventory exported (${data.length} items).';
      });

  static Future<void> exportMovements(BuildContext context,
          {List<StockMovement>? movements}) =>
      _run(context, () async {
        final data = movements ?? await fetchMovements();
        if (data.isEmpty) return 'There are no stock movements to export yet.';
        await FileDownload.save(
          baseName: 'stocksense-stock-movements-${_stamp()}',
          bytes: CsvExport.encode(CsvExport.movementsCsv(data)),
          kind: DownloadKind.csv,
        );
        return 'Stock movements exported (${data.length} records).';
      });

  /// Items and stock history as two CSV files.
  static Future<void> exportAll(BuildContext context) =>
      _run(context, () async {
        final items = await fetchAllItems();
        final movements = await fetchMovements();
        if (items.isEmpty && movements.isEmpty) {
          return 'There is no data to export yet.';
        }
        if (items.isNotEmpty) {
          await FileDownload.save(
            baseName: 'stocksense-inventory-${_stamp()}',
            bytes: CsvExport.encode(CsvExport.inventoryCsv(items)),
            kind: DownloadKind.csv,
          );
        }
        if (movements.isNotEmpty) {
          await FileDownload.save(
            baseName: 'stocksense-stock-movements-${_stamp()}',
            bytes: CsvExport.encode(CsvExport.movementsCsv(movements)),
            kind: DownloadKind.csv,
          );
        }
        return 'Your data was exported as CSV files.';
      });

  static Future<void> _run(
      BuildContext context, Future<String> Function() job) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(const SnackBar(
      content: Text('Preparing your export…'),
      duration: Duration(seconds: 2),
    ));
    try {
      final message = await job();
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(friendlyError(e,
              fallback: 'Could not export your data. Please try again.')),
        ));
    }
  }
}
