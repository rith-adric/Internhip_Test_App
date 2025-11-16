import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:csv/csv.dart';
import '../models/product.dart';

class ExportService {
  // Get the best directory for saving files
  static Future<Directory> _getSaveDirectory() async {
    if (Platform.isAndroid) {
      // For Android, try to use external storage Downloads folder
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        final downloadsPath =
            '${externalDir.path.split('/Android')[0]}/Download';
        final downloadsDir = Directory(downloadsPath);
        if (await downloadsDir.exists()) {
          return downloadsDir;
        }
      }
      // Fallback to app documents directory
      return await getApplicationDocumentsDirectory();
    } else if (Platform.isIOS) {
      // iOS: Use app documents directory (can be accessed via Files app)
      return await getApplicationDocumentsDirectory();
    } else {
      final homeDir =
          Platform.environment['HOME'] ??
          Platform.environment['USERPROFILE'] ??
          '';
      if (homeDir.isNotEmpty) {
        final downloadsPath = Platform.isWindows
            ? '$homeDir\\Downloads'
            : '$homeDir/Downloads';
        final downloadsDir = Directory(downloadsPath);
        if (await downloadsDir.exists()) {
          return downloadsDir;
        }
      }
      return await getApplicationDocumentsDirectory();
    }
  }

  // Export to PDF
  static Future<File> exportToPdf(List<Product> products) async {
    final PdfDocument document = PdfDocument();
    final PdfPage page = document.pages.add();
    final PdfGraphics graphics = page.graphics;

    // Add title
    final PdfFont titleFont = PdfStandardFont(PdfFontFamily.helvetica, 20);
    graphics.drawString(
      'Product List',
      titleFont,
      brush: PdfSolidBrush(PdfColor(30, 58, 95)),
      bounds: const Rect.fromLTWH(0, 0, 500, 30),
    );

    final PdfGrid grid = PdfGrid();
    grid.columns.add(count: 4);
    grid.headers.add(1);

    // Header row
    final PdfGridRow headerRow = grid.headers[0];
    headerRow.cells[0].value = 'ID';
    headerRow.cells[1].value = 'Name';
    headerRow.cells[2].value = 'Price';
    headerRow.cells[3].value = 'Stock';
    headerRow.style.font = PdfStandardFont(
      PdfFontFamily.helvetica,
      12,
      style: PdfFontStyle.bold,
    );
    headerRow.style.backgroundBrush = PdfSolidBrush(PdfColor(255, 107, 53));

    // Data rows
    for (var product in products) {
      final PdfGridRow row = grid.rows.add();
      row.cells[0].value = product.id;
      row.cells[1].value = product.name;
      row.cells[2].value = '\$${product.price.toStringAsFixed(2)}';
      row.cells[3].value = product.stock.toString();
    }

    // Draw table
    grid.draw(page: page, bounds: const Rect.fromLTWH(0, 40, 500, 0));

    final Directory directory = await _getSaveDirectory();
    final String fileName =
        'products_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final String path = '${directory.path}/$fileName';
    final File file = File(path);
    await file.writeAsBytes(await document.save());
    document.dispose();

    return file;
  }

  // Export to CSV
  static Future<File> exportToCsv(List<Product> products) async {
    final List<List<dynamic>> rows = [
      ['ID', 'Name', 'Price', 'Stock'],
    ];

    for (var product in products) {
      rows.add([product.id, product.name, product.price, product.stock]);
    }

    final String csv = const ListToCsvConverter().convert(rows);

    final Directory directory = await _getSaveDirectory();
    final String fileName =
        'products_${DateTime.now().millisecondsSinceEpoch}.csv';
    final String path = '${directory.path}/$fileName';
    final File file = File(path);
    await file.writeAsString(csv);

    return file;
  }

  // Get user-friendly location message
  static String getLocationMessage(String filePath) {
    if (Platform.isAndroid) {
      if (filePath.contains('/Download')) {
        return 'Saved to Downloads folder';
      }
      return 'Saved to app storage. Use a file manager to access it.';
    } else if (Platform.isIOS) {
      return 'Saved to Files app > On My iPhone > ${_getAppName()}';
    } else {
      if (filePath.contains('Downloads')) {
        return 'Saved to Downloads folder';
      }
      return 'Saved to: $filePath';
    }
  }

  static String _getAppName() {
    // You can customize this or get from package info
    return 'my_app';
  }
}
