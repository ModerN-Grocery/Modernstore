import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

import '../main.dart';
import '../repositery/model/product/getAllProduct.dart';

/// Top-level isolate function for decoding & resizing thumbnails in background thread.
/// Keeps the Flutter UI thread 100% responsive and converts images (JPEG, PNG, WebP, etc.)
/// to standard PNG thumbnails so Excel natively renders them properly.
Uint8List? _processImageInIsolate(Uint8List rawBytes) {
  try {
    final img.Image? decoded = img.decodeImage(rawBytes);
    if (decoded != null) {
      // Resize to a sharp, lightweight thumbnail (max 140x140 with aspect ratio preserved)
      final img.Image resized = img.copyResize(
        decoded,
        width: 140,
        height: 140,
        maintainAspect: true,
      );
      // Encode as standard PNG bytes for universal Excel compatibility
      return Uint8List.fromList(img.encodePng(resized));
    }
  } catch (e) {
    debugPrint('Isolate image decode error: $e');
  }

  // Fallback: If decode fails but bytes are already valid JPEG or PNG, return rawBytes
  final bool isJpeg =
      rawBytes.length > 2 && rawBytes[0] == 0xFF && rawBytes[1] == 0xD8;
  final bool isPng = rawBytes.length > 4 &&
      rawBytes[0] == 0x89 &&
      rawBytes[1] == 0x50 &&
      rawBytes[2] == 0x4E &&
      rawBytes[3] == 0x47;

  if (isJpeg || isPng) {
    return rawBytes;
  }

  return null;
}

class ProductExcelExportService {
  /// Exports all products into an Excel (.xlsx) file with guaranteed image embedding.
  /// [onProgress] gives real-time updates: (current, total, statusText)
  static Future<File?> exportProductsToExcel({
    required List<Data> products,
    void Function(int current, int total, String message)? onProgress,
  }) async {
    if (products.isEmpty) {
      return null;
    }

    // 1. Create a new Excel workbook & worksheet
    final xlsio.Workbook workbook = xlsio.Workbook();
    final xlsio.Worksheet sheet = workbook.worksheets[0];
    sheet.name = 'Products List';

    // 2. Define Styles
    // Header Style
    final xlsio.Style headerStyle = workbook.styles.add('HeaderStyle');
    headerStyle.backColor = '#1B5E20'; // Modern deep green
    headerStyle.fontColor = '#FFFFFF';
    headerStyle.bold = true;
    headerStyle.fontSize = 11;
    headerStyle.fontName = 'Calibri';
    headerStyle.hAlign = xlsio.HAlignType.center;
    headerStyle.vAlign = xlsio.VAlignType.center;
    headerStyle.wrapText = true;
    headerStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    headerStyle.borders.all.color = '#0E3A13';

    // Cell Left-aligned Style
    final xlsio.Style cellLeftStyle = workbook.styles.add('CellLeftStyle');
    cellLeftStyle.fontSize = 10;
    cellLeftStyle.fontName = 'Calibri';
    cellLeftStyle.vAlign = xlsio.VAlignType.center;
    cellLeftStyle.hAlign = xlsio.HAlignType.left;
    cellLeftStyle.wrapText = true;
    cellLeftStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    cellLeftStyle.borders.all.color = '#CCCCCC';

    // Cell Center-aligned Style
    final xlsio.Style cellCenterStyle = workbook.styles.add('CellCenterStyle');
    cellCenterStyle.fontSize = 10;
    cellCenterStyle.fontName = 'Calibri';
    cellCenterStyle.vAlign = xlsio.VAlignType.center;
    cellCenterStyle.hAlign = xlsio.HAlignType.center;
    cellCenterStyle.wrapText = true;
    cellCenterStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    cellCenterStyle.borders.all.color = '#CCCCCC';

    // Cell Right-aligned (Numbers / Price) Style
    final xlsio.Style cellRightStyle = workbook.styles.add('CellRightStyle');
    cellRightStyle.fontSize = 10;
    cellRightStyle.fontName = 'Calibri';
    cellRightStyle.vAlign = xlsio.VAlignType.center;
    cellRightStyle.hAlign = xlsio.HAlignType.right;
    cellRightStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    cellRightStyle.borders.all.color = '#CCCCCC';

    // 3. Setup Headers
    final List<String> headers = [
      'Sl No',
      'Image',
      'Product Name',
      'Sub Name',
      'Category',
      'Base Price (₹)',
      'Discount (%)',
      'Selling Price (₹)',
      'Unit',
      'SKU',
      'Selectable Quantities',
      'Description',
      'Created Date',
    ];

    sheet.setRowHeightInPixels(1, 36);

    for (int col = 0; col < headers.length; col++) {
      final xlsio.Range range = sheet.getRangeByIndex(1, col + 1);
      range.setText(headers[col]);
      range.cellStyle = headerStyle;
    }

    // Set custom column widths (in pixels)
    sheet.setColumnWidthInPixels(1, 55); // Sl No
    sheet.setColumnWidthInPixels(2, 75); // Image
    sheet.setColumnWidthInPixels(3, 170); // Product Name
    sheet.setColumnWidthInPixels(4, 130); // Sub Name
    sheet.setColumnWidthInPixels(5, 130); // Category
    sheet.setColumnWidthInPixels(6, 100); // Base Price
    sheet.setColumnWidthInPixels(7, 90); // Discount
    sheet.setColumnWidthInPixels(8, 110); // Selling Price
    sheet.setColumnWidthInPixels(9, 70); // Unit
    sheet.setColumnWidthInPixels(10, 110); // SKU
    sheet.setColumnWidthInPixels(11, 150); // Quantities
    sheet.setColumnWidthInPixels(12, 220); // Description
    sheet.setColumnWidthInPixels(13, 110); // Created Date

    // 4. Download & process images in parallel batches (Concurrency: 4)
    final int total = products.length;
    final Map<int, Uint8List?> imageBytesMap = {};
    final http.Client client = http.Client();

    // Prepare auth headers if available
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final Map<String, String> headersMap = {
      'Accept': 'image/*,*/*',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    try {
      const int batchSize = 4;
      for (int i = 0; i < total; i += batchSize) {
        final int end = (i + batchSize < total) ? i + batchSize : total;
        final List<int> batch = List.generate(end - i, (index) => i + index);

        onProgress?.call(
          i,
          total,
          'Processing images: ${i + 1} - $end of $total...',
        );

        await Future.wait(batch.map((index) async {
          final product = products[index];
          final String? imageUrl =
              (product.images != null && product.images!.isNotEmpty)
                  ? product.images!.first
                  : null;

          if (imageUrl != null && imageUrl.trim().isNotEmpty) {
            imageBytesMap[index] = await _downloadAndPrepareImage(
              client: client,
              rawUrl: imageUrl,
              headers: headersMap,
            );
          }
        }));
      }
    } finally {
      client.close();
    }

    onProgress?.call(
      total,
      total,
      'Building Excel spreadsheet...',
    );

    // 5. Fill Data Rows in Excel Sheet
    for (int i = 0; i < total; i++) {
      final int rowIndex = i + 2;
      final Data product = products[i];

      // Set row height generous enough for thumbnail
      sheet.setRowHeightInPixels(rowIndex, 62);

      // Sl No
      final xlsio.Range slRange = sheet.getRangeByIndex(rowIndex, 1);
      slRange.setNumber(i + 1);
      slRange.cellStyle = cellCenterStyle;

      // Image Handling
      final Uint8List? imageBytes = imageBytesMap[i];
      final xlsio.Range imageCell = sheet.getRangeByIndex(rowIndex, 2);
      imageCell.cellStyle = cellCenterStyle;

      if (imageBytes != null && imageBytes.isNotEmpty) {
        try {
          final xlsio.Picture picture =
              sheet.pictures.addStream(rowIndex, 2, imageBytes);
          picture.height = 54;
          picture.width = 54;
        } catch (e) {
          debugPrint('Error attaching picture to excel at row $rowIndex: $e');
          imageCell.setText('Image Error');
        }
      } else {
        imageCell.setText('No Image');
      }

      // Product Name
      final xlsio.Range nameRange = sheet.getRangeByIndex(rowIndex, 3);
      nameRange.setText(product.name ?? '-');
      nameRange.cellStyle = cellLeftStyle;

      // Sub Name
      final xlsio.Range subNameRange = sheet.getRangeByIndex(rowIndex, 4);
      subNameRange.setText(product.subName?.toString() ?? '-');
      subNameRange.cellStyle = cellLeftStyle;

      // Category
      final xlsio.Range catRange = sheet.getRangeByIndex(rowIndex, 5);
      catRange.setText(product.category?.name ?? '-');
      catRange.cellStyle = cellLeftStyle;

      // Base Price
      final double basePrice = (product.basePrice ?? 0).toDouble();
      final xlsio.Range basePriceRange = sheet.getRangeByIndex(rowIndex, 6);
      basePriceRange.setNumber(basePrice);
      basePriceRange.cellStyle = cellRightStyle;
      basePriceRange.numberFormat = '#,##0.00';

      // Discount Percentage
      final int discount = product.discountPercentage ?? 0;
      final xlsio.Range discountRange = sheet.getRangeByIndex(rowIndex, 7);
      discountRange.setNumber(discount.toDouble());
      discountRange.cellStyle = cellCenterStyle;
      discountRange.numberFormat = '0%';

      // Selling Price Calculation
      final double sellingPrice =
          basePrice > 0 ? (basePrice - (basePrice * discount / 100)) : 0.0;
      final xlsio.Range sellingPriceRange = sheet.getRangeByIndex(rowIndex, 8);
      sellingPriceRange.setNumber(sellingPrice);
      sellingPriceRange.cellStyle = cellRightStyle;
      sellingPriceRange.numberFormat = '#,##0.00';

      // Unit
      final xlsio.Range unitRange = sheet.getRangeByIndex(rowIndex, 9);
      unitRange.setText(product.unit ?? '-');
      unitRange.cellStyle = cellCenterStyle;

      // SKU
      final xlsio.Range skuRange = sheet.getRangeByIndex(rowIndex, 10);
      skuRange.setText(product.sku ?? '-');
      skuRange.cellStyle = cellCenterStyle;

      // Selectable Quantities
      final xlsio.Range qtyRange = sheet.getRangeByIndex(rowIndex, 11);
      final String qtyString = (product.selectableQuantities != null &&
              product.selectableQuantities!.isNotEmpty)
          ? product.selectableQuantities!.map((e) => e.toString()).join(', ')
          : '-';
      qtyRange.setText(qtyString);
      qtyRange.cellStyle = cellLeftStyle;

      // Description
      final xlsio.Range descRange = sheet.getRangeByIndex(rowIndex, 12);
      descRange.setText(product.description ?? '-');
      descRange.cellStyle = cellLeftStyle;

      // Created Date
      final xlsio.Range dateRange = sheet.getRangeByIndex(rowIndex, 13);
      String dateFormatted = '-';
      if (product.createdAt != null && product.createdAt!.isNotEmpty) {
        try {
          final DateTime dt = DateTime.parse(product.createdAt!);
          dateFormatted =
              '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
        } catch (_) {
          dateFormatted = product.createdAt!;
        }
      }
      dateRange.setText(dateFormatted);
      dateRange.cellStyle = cellCenterStyle;
    }

    onProgress?.call(total, total, 'Saving Excel spreadsheet...');

    // 6. Save workbook to bytes
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    // 7. Write file to local storage
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final String filePath = '${appDir.path}/ModernStore_Products_$timestamp.xlsx';
    final File file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);

    return file;
  }

  /// Resolves relative image URLs and downloads image bytes with retry and fallback.
  /// Runs decoding and thumbnail conversion in an isolate via [compute] so the UI never freezes.
  static Future<Uint8List?> _downloadAndPrepareImage({
    required http.Client client,
    required String rawUrl,
    required Map<String, String> headers,
  }) async {
    // 1. Resolve full URL if relative
    String url = rawUrl.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      final String base = basePath.replaceAll('/api', '');
      if (url.startsWith('/')) {
        url = '$base$url';
      } else {
        url = '$base/$url';
      }
    }

    // 2. Download with retry and 12-second timeout
    Uint8List? downloadedBytes;
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await client
            .get(Uri.parse(url), headers: headers)
            .timeout(const Duration(seconds: 12));

        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          downloadedBytes = response.bodyBytes;
          break;
        } else if (response.statusCode == 401 || response.statusCode == 403) {
          // If auth rejected, try request without headers
          final unauthResponse = await client
              .get(Uri.parse(url))
              .timeout(const Duration(seconds: 12));
          if (unauthResponse.statusCode == 200 &&
              unauthResponse.bodyBytes.isNotEmpty) {
            downloadedBytes = unauthResponse.bodyBytes;
            break;
          }
        }
      } catch (e) {
        if (attempt == 1) {
          debugPrint('Failed to download image for excel ($url): $e');
        }
      }
    }

    if (downloadedBytes == null || downloadedBytes.isEmpty) {
      return null;
    }

    // 3. Process into clean thumbnail in background isolate
    try {
      final Uint8List? processed =
          await compute(_processImageInIsolate, downloadedBytes);
      return processed ?? downloadedBytes;
    } catch (e) {
      debugPrint('Error in compute thumbnail: $e');
      return downloadedBytes;
    }
  }

  /// Opens the exported Excel file with the device's default application.
  static Future<OpenResult> openExcelFile(String filePath) async {
    return await OpenFilex.open(filePath);
  }

  /// Shares the Excel file via the native share sheet.
  static Future<void> shareExcelFile(String filePath) async {
    final File file = File(filePath);
    if (await file.exists()) {
      final String fileName = filePath.split(Platform.pathSeparator).last;
      await Printing.sharePdf(
        bytes: await file.readAsBytes(),
        filename: fileName,
      );
    }
  }
}
