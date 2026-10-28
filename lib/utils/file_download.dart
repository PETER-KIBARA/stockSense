import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'file_download_stub.dart'
    if (dart.library.js_interop) 'file_download_web.dart' as web_impl;

enum DownloadKind { pdf, csv }

class FileDownload {
  /// Saves a file: a normal browser download on the web, a save dialog elsewhere.
  static Future<void> save({
    required String baseName,
    required Uint8List bytes,
    required DownloadKind kind,
  }) async {
    final isPdf = kind == DownloadKind.pdf;
    final ext = isPdf ? 'pdf' : 'csv';

    if (kIsWeb) {
      web_impl.downloadBytes(
        fileName: '$baseName.$ext',
        bytes: bytes,
        mimeType: isPdf ? 'application/pdf' : 'text/csv;charset=utf-8',
      );
      return;
    }

    await FileSaver.instance.saveAs(
      name: baseName,
      bytes: bytes,
      fileExtension: ext,
      mimeType: isPdf ? MimeType.pdf : MimeType.csv,
    );
  }
}
