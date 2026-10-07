import 'dart:io';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

import '../repositery/model/Inventory/getAllnventory.dart';

class StockExcelService {
  /// Exports all inventory stocks to an Excel (.xlsx) file with professional formatting.
  static Future<File?> exportStockToExcel({
    required List<Data> stockItems,
    void Function(int current, int total, String message)? onProgress,
  }) async {
    if (stockItems.isEmpty) return null;

    final xlsio.Workbook workbook = xlsio.Workbook();

    // ── Sheet 1: Stock Update Sheet ──────────────────────────
    final xlsio.Worksheet sheet = workbook.worksheets[0];
    sheet.name = 'Stock Update Sheet';

    // Header Style
    final xlsio.Style headerStyle = workbook.styles.add('HeaderStyle');
    headerStyle.backColor = '#1B5E20';
    headerStyle.fontColor = '#FFFFFF';
    headerStyle.bold = true;
    headerStyle.fontSize = 11;
    headerStyle.fontName = 'Calibri';
    headerStyle.hAlign = xlsio.HAlignType.center;
    headerStyle.vAlign = xlsio.VAlignType.center;
    headerStyle.wrapText = true;
    headerStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    headerStyle.borders.all.color = '#0E3A13';

    // Accent Header for "Stock To Add" column
    final xlsio.Style addHeaderStyle = workbook.styles.add('AddHeaderStyle');
    addHeaderStyle.backColor = '#E65100'; // Deep Orange
    addHeaderStyle.fontColor = '#FFFFFF';
    addHeaderStyle.bold = true;
    addHeaderStyle.fontSize = 11;
    addHeaderStyle.fontName = 'Calibri';
    addHeaderStyle.hAlign = xlsio.HAlignType.center;
    addHeaderStyle.vAlign = xlsio.VAlignType.center;
    addHeaderStyle.wrapText = true;
    addHeaderStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    addHeaderStyle.borders.all.color = '#BF360C';

    // Standard Styles
    final xlsio.Style cellLeftStyle = workbook.styles.add('CellLeftStyle');
    cellLeftStyle.fontSize = 10;
    cellLeftStyle.fontName = 'Calibri';
    cellLeftStyle.vAlign = xlsio.VAlignType.center;
    cellLeftStyle.hAlign = xlsio.HAlignType.left;
    cellLeftStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    cellLeftStyle.borders.all.color = '#CCCCCC';

    final xlsio.Style cellCenterStyle = workbook.styles.add('CellCenterStyle');
    cellCenterStyle.fontSize = 10;
    cellCenterStyle.fontName = 'Calibri';
    cellCenterStyle.vAlign = xlsio.VAlignType.center;
    cellCenterStyle.hAlign = xlsio.HAlignType.center;
    cellCenterStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    cellCenterStyle.borders.all.color = '#CCCCCC';

    final xlsio.Style cellRightStyle = workbook.styles.add('CellRightStyle');
    cellRightStyle.fontSize = 10;
    cellRightStyle.fontName = 'Calibri';
    cellRightStyle.vAlign = xlsio.VAlignType.center;
    cellRightStyle.hAlign = xlsio.HAlignType.right;
    cellRightStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    cellRightStyle.borders.all.color = '#CCCCCC';

    final xlsio.Style addInputStyle = workbook.styles.add('AddInputStyle');
    addInputStyle.backColor = '#FFF9C4'; // Soft yellow highlight
    addInputStyle.fontColor = '#B71C1C'; // Red bold text
    addInputStyle.bold = true;
    addInputStyle.fontSize = 11;
    addInputStyle.fontName = 'Calibri';
    addInputStyle.vAlign = xlsio.VAlignType.center;
    addInputStyle.hAlign = xlsio.HAlignType.right;
    addInputStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    addInputStyle.borders.all.color = '#CCCCCC';

    // Headers
    final List<String> headers = [
      'Product ID (Do Not Change)',
      'Sl No',
      'Product Name',
      'SKU Code',
      'Unit',
      'Current Stock',
      'Sold Qty',
      'Stock To Add (Enter Qty)',
      'Projected Total Stock',
      'Stock Status',
      'Remarks',
    ];

    sheet.setRowHeightInPixels(1, 40);
    for (int col = 0; col < headers.length; col++) {
      final xlsio.Range range = sheet.getRangeByIndex(1, col + 1);
      range.setText(headers[col]);
      range.cellStyle = (col == 7) ? addHeaderStyle : headerStyle;
    }

    final int total = stockItems.length;
    for (int i = 0; i < total; i++) {
      final item = stockItems[i];
      final int row = i + 2;

      sheet.setRowHeightInPixels(row, 24);

      final String prodId = item.productId?.id ?? item.id ?? '';
      final String prodName = item.productId?.name ?? 'N/A';
      final String sku = item.sku ?? '';
      final String unit = item.unit ?? '';
      final double currentStock = (item.quantityInStock ?? 0).toDouble();
      final double soldQty = (item.soldQuantity ?? 0).toDouble();

      // Col 1: Product ID
      final r1 = sheet.getRangeByIndex(row, 1);
      r1.setText(prodId);
      r1.cellStyle = cellCenterStyle;

      // Col 2: Sl No
      final r2 = sheet.getRangeByIndex(row, 2);
      r2.setNumber(i + 1);
      r2.cellStyle = cellCenterStyle;

      // Col 3: Product Name
      final r3 = sheet.getRangeByIndex(row, 3);
      r3.setText(prodName);
      r3.cellStyle = cellLeftStyle;

      // Col 4: SKU
      final r4 = sheet.getRangeByIndex(row, 4);
      r4.setText(sku);
      r4.cellStyle = cellCenterStyle;

      // Col 5: Unit
      final r5 = sheet.getRangeByIndex(row, 5);
      r5.setText(unit);
      r5.cellStyle = cellCenterStyle;

      // Col 6: Current Stock
      final r6 = sheet.getRangeByIndex(row, 6);
      r6.setNumber(currentStock);
      r6.cellStyle = cellRightStyle;

      // Col 7: Sold Qty
      final r7 = sheet.getRangeByIndex(row, 7);
      r7.setNumber(soldQty);
      r7.cellStyle = cellRightStyle;

      // Col 8: Stock To Add (Blank / 0 for input)
      final r8 = sheet.getRangeByIndex(row, 8);
      r8.setNumber(0);
      r8.cellStyle = addInputStyle;

      // Col 9: Projected Total Stock (Formula = Col6 + Col8)
      final r9 = sheet.getRangeByIndex(row, 9);
      r9.setFormula('=F$row+H$row');
      r9.cellStyle = cellRightStyle;

      // Col 10: Status
      final r10 = sheet.getRangeByIndex(row, 10);
      r10.setText(currentStock <= 0 ? 'Out of Stock' : (currentStock < 10 ? 'Low Stock' : 'In Stock'));
      r10.cellStyle = cellCenterStyle;

      // Col 11: Remarks
      final r11 = sheet.getRangeByIndex(row, 11);
      r11.setText('');
      r11.cellStyle = cellLeftStyle;

      if (i % 25 == 0) {
        onProgress?.call(i + 1, total, 'Preparing ${i + 1} of $total products...');
      }
    }

    // Set Column Widths
    sheet.getRangeByIndex(1, 1).columnWidth = 28; // Product ID
    sheet.getRangeByIndex(1, 2).columnWidth = 8;  // Sl No
    sheet.getRangeByIndex(1, 3).columnWidth = 32; // Name
    sheet.getRangeByIndex(1, 4).columnWidth = 16; // SKU
    sheet.getRangeByIndex(1, 5).columnWidth = 12; // Unit
    sheet.getRangeByIndex(1, 6).columnWidth = 16; // Current Stock
    sheet.getRangeByIndex(1, 7).columnWidth = 14; // Sold Qty
    sheet.getRangeByIndex(1, 8).columnWidth = 26; // Stock to Add
    sheet.getRangeByIndex(1, 9).columnWidth = 22; // Projected Total
    sheet.getRangeByIndex(1, 10).columnWidth = 16;// Status
    sheet.getRangeByIndex(1, 11).columnWidth = 20;// Remarks

    // ── Sheet 2: Guidelines ──────────────────────────────────
    final xlsio.Worksheet guideSheet = workbook.worksheets.addWithName('Instructions & Guide');
    guideSheet.getRangeByIndex(1, 1).setText('MODERN STORE - STOCK BULK UPDATE INSTRUCTIONS');
    guideSheet.getRangeByIndex(1, 1).cellStyle.fontSize = 14;
    guideSheet.getRangeByIndex(1, 1).cellStyle.bold = true;
    guideSheet.getRangeByIndex(1, 1).cellStyle.fontColor = '#1B5E20';

    final guideHeaders = ['Column Name', 'Description', 'Mandatory?', 'Notes'];
    for (int c = 0; c < guideHeaders.length; c++) {
      final cell = guideSheet.getRangeByIndex(3, c + 1);
      cell.setText(guideHeaders[c]);
      cell.cellStyle = headerStyle;
    }

    final guideData = [
      ['Product ID', 'Unique database ID of product. Do NOT edit or remove.', 'YES (Key)', 'System Identifier'],
      ['Product Name', 'Name of product for easy reference.', 'Read Only', 'e.g. Apple Shimla'],
      ['Current Stock', 'Stock currently present in system.', 'Read Only', 'Auto-filled'],
      ['Stock To Add', 'Enter the NEW quantity you want to add to this product.', 'YES (Fill This)', 'Type positive number'],
      ['Projected Total', 'Formula calculating (Current Stock + Stock To Add).', 'Formula', 'Auto-calculated'],
    ];

    for (int r = 0; r < guideData.length; r++) {
      for (int c = 0; c < 4; c++) {
        final cell = guideSheet.getRangeByIndex(r + 4, c + 1);
        cell.setText(guideData[r][c]);
        cell.cellStyle = (c == 0 || c == 2) ? cellCenterStyle : cellLeftStyle;
      }
    }

    guideSheet.getRangeByIndex(1, 1).columnWidth = 20;
    guideSheet.getRangeByIndex(1, 2).columnWidth = 45;
    guideSheet.getRangeByIndex(1, 3).columnWidth = 18;
    guideSheet.getRangeByIndex(1, 4).columnWidth = 25;

    // Save Workbook
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    final Directory appDir = await getApplicationDocumentsDirectory();
    final String timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final String filePath = '${appDir.path}/ModernStore_Stock_Update_$timestamp.xlsx';
    final File file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);

    return file;
  }

  /// Opens the exported Excel file
  static Future<OpenResult> openExcelFile(String filePath) async {
    return await OpenFilex.open(filePath);
  }
}
