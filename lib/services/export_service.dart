import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../utils/export_helper.dart';

class ExportService {
  static String _formatMoney(dynamic value) {
    if (value == null) return "0 đ";
    final num val = value is num
        ? value
        : (double.tryParse(value.toString()) ?? 0);
    final clean = val.floor().toString();
    final buffer = StringBuffer();
    final isNegative = clean.startsWith('-');
    final absClean = isNegative ? clean.substring(1) : clean;

    for (int i = 0; i < absClean.length; i++) {
      final posFromEnd = absClean.length - i;
      buffer.write(absClean[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) {
        buffer.write('.');
      }
    }
    return "${isNegative ? '-' : ''}${buffer.toString()} đ";
  }

  static String _formatPoint(dynamic value) {
    if (value == null) return "0 điểm";
    final num val = value is num
        ? value
        : (double.tryParse(value.toString()) ?? 0);
    final clean = val.floor().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < clean.length; i++) {
      final posFromEnd = clean.length - i;
      buffer.write(clean[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) {
        buffer.write('.');
      }
    }
    return "${buffer.toString()} điểm";
  }

  // --- REPORT EXPORT ---

  static Future<void> exportReportToExcel({
    required Map<String, dynamic> resultA,
    required Map<String, dynamic> resultB,
    required String date,
  }) async {
    final Excel excel = Excel.createExcel();
    excel.delete('Sheet1'); // Remove default sheet

    // Styles definitions using ExcelColor.fromHexString
    final headerStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ExcelColor.fromHexString("#FFFFFF"),
      backgroundColorHex: ExcelColor.fromHexString("#2563EB"),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
    final labelStyle = CellStyle(
      fontSize: 11,
      fontColorHex: ExcelColor.fromHexString("#1F2937"),
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );
    final valueStyle = CellStyle(
      fontSize: 11,
      fontColorHex: ExcelColor.fromHexString("#1F2937"),
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
    );
    final boldLabelStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ExcelColor.fromHexString("#1E3A8A"),
      backgroundColorHex: ExcelColor.fromHexString("#EFF6FF"),
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );
    final boldValueStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ExcelColor.fromHexString("#1E3A8A"),
      backgroundColorHex: ExcelColor.fromHexString("#EFF6FF"),
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
    );
    final sectionStyle = CellStyle(
      bold: true,
      fontSize: 12,
      fontColorHex: ExcelColor.fromHexString("#1E3A8A"),
      backgroundColorHex: ExcelColor.fromHexString("#DBEAFE"),
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );

    // Sheet 1: Overview
    final Sheet overviewSheet = excel['Tổng quan'];
    overviewSheet.setColumnWidth(0, 35.0);
    overviewSheet.setColumnWidth(1, 25.0);

    _writeExcelHeader(overviewSheet, "BÁO CÁO TÀI CHÍNH TỔNG QUAN", date, 2);

    final num revA = resultA["tongDoanhThu"] * 1000 ?? 0;
    final num revB = resultB["tongDoanhThu"] * 1000 ?? 0;
    final totalRevenue = revA + revB;

    final keptA = resultA["tongGiuLai"] * 1000 ?? 0;
    final keptB = resultB["tongGiuLai"] * 1000 ?? 0;
    final totalKept = keptA + keptB;

    final fwdA = resultA["tongChuyen"] * 1000 ?? 0;
    final fwdB = resultB["tongChuyen"] * 1000 ?? 0;
    final totalForwarded = fwdA + fwdB;

    final commA = resultA["hoa_hong"] * 1000 ?? 0;
    final commB = (resultB["hoa_hồng"] ?? resultB["hoa_hong"] ?? 0) * 1000;
    final totalCommission = commA + commB;

    final netFwdA = resultA["tongThucChuyen"] * 1000 ?? 0;
    final netFwdB = resultB["tongThucChuyen"] * 1000 ?? 0;
    final totalNetForwarded = netFwdA + netFwdB;

    final holdA = resultA["cam"] * 1000 ?? 0;
    final holdB = resultB["cam"] * 1000 ?? 0;
    final totalHold = holdA + holdB;

    _writeRow(overviewSheet, 3, ["Chỉ số", "Giá trị"], style: headerStyle, rowHeight: 28.0);
    _writeRowWithStyles(overviewSheet, 4, ["TỔNG THU NHẬP ĐẠI LÝ (CẦM)", _formatMoney(totalHold)], [boldLabelStyle, boldValueStyle], rowHeight: 26.0);
    _writeRowWithStyles(overviewSheet, 5, ["Doanh thu A + B", _formatMoney(totalRevenue)], [labelStyle, valueStyle]);
    _writeRowWithStyles(overviewSheet, 6, ["Thực chuyển chủ", _formatMoney(totalNetForwarded)], [labelStyle, valueStyle]);
    _writeRowWithStyles(overviewSheet, 7, ["Hoa hồng nhận", _formatMoney(totalCommission)], [labelStyle, valueStyle]);
    _writeRowWithStyles(overviewSheet, 8, ["Tổng giữ lại", _formatMoney(totalKept)], [labelStyle, valueStyle]);
    _writeRowWithStyles(overviewSheet, 9, ["Tổng chuyển đi", _formatMoney(totalForwarded)], [labelStyle, valueStyle]);
    _writeRowWithStyles(overviewSheet, 10, ["Doanh thu loại A", _formatMoney(revA)], [labelStyle, valueStyle]);
    _writeRowWithStyles(overviewSheet, 11, ["Doanh thu loại B", _formatMoney(revB)], [labelStyle, valueStyle]);

    // Sheet 2: Mã Loại A
    final Sheet aSheet = excel['Mã Loại A'];
    aSheet.setColumnWidth(0, 25.0);
    aSheet.setColumnWidth(1, 25.0);
    aSheet.setColumnWidth(2, 25.0);

    _writeExcelHeader(aSheet, "BÁO CÁO MÃ LOẠI A", date, 3);
    _writeRow(aSheet, 3, ["Chỉ số", "Giá trị", ""], style: headerStyle, rowHeight: 28.0);
    aSheet.merge(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 3), CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 3));
    
    _writeRowWithStyles(aSheet, 4, ["Doanh thu", _formatMoney(revA), ""], [labelStyle, valueStyle, null]);
    aSheet.merge(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 4), CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 4));
    
    _writeRowWithStyles(aSheet, 5, ["Giữ tối đa / mã", _formatMoney(resultA["giaGiuMoiCon"] * 1000 ?? 0), ""], [labelStyle, valueStyle, null]);
    aSheet.merge(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 5), CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 5));
    
    _writeRowWithStyles(aSheet, 6, ["Tổng giữ lại", _formatMoney(keptA), ""], [labelStyle, valueStyle, null]);
    aSheet.merge(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 6), CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 6));
    
    _writeRowWithStyles(aSheet, 7, ["Hoa hồng", _formatMoney(commA), ""], [labelStyle, valueStyle, null]);
    aSheet.merge(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 7), CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 7));
    
    _writeRowWithStyles(aSheet, 8, ["Thực chuyển", _formatMoney(netFwdA), ""], [labelStyle, valueStyle, null]);
    aSheet.merge(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 8), CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 8));
    
    _writeRowWithStyles(aSheet, 9, ["Thực cầm", _formatMoney(holdA), ""], [boldLabelStyle, boldValueStyle, null]);
    aSheet.merge(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 9), CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 9));

    _writeRow(aSheet, 11, ["CHI TIẾT THEO MÃ SẢN PHẨM (LOẠI A)", "", ""], style: sectionStyle, rowHeight: 26.0);
    aSheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 11), CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 11));

    _writeRow(aSheet, 12, ["Mã SP", "Giữ lại", "Chuyển đi"], style: headerStyle, rowHeight: 26.0);

    final Map<String, dynamic> retainedA = Map<String, dynamic>.from(resultA["chi_tiết_giữ_lại"] ?? {});
    final Map<String, dynamic> forwardedA = Map<String, dynamic>.from(resultA["chi_tiết_chuyển"] ?? {});
    final keysA = {...retainedA.keys, ...forwardedA.keys}.toList()..sort();
    int rowIdxA = 13;
    for (final key in keysA) {
      final rVal = (retainedA[key] ?? 0) * 1000;
      final fVal = (forwardedA[key] ?? 0) * 1000;
      _writeRowWithStyles(aSheet, rowIdxA++, [key, _formatMoney(rVal), _formatMoney(fVal)], [labelStyle, valueStyle, valueStyle]);
    }

    // Sheet 3: Mã Loại B
    final Sheet bSheet = excel['Mã Loại B'];
    bSheet.setColumnWidth(0, 25.0);
    bSheet.setColumnWidth(1, 25.0);
    bSheet.setColumnWidth(2, 25.0);

    _writeExcelHeader(bSheet, "BÁO CÁO MÃ LOẠI B", date, 3);
    _writeRow(bSheet, 3, ["Chỉ số", "Giá trị", ""], style: headerStyle, rowHeight: 28.0);
    bSheet.merge(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 3), CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 3));

    _writeRowWithStyles(bSheet, 4, ["Doanh thu", _formatMoney(revB), ""], [labelStyle, valueStyle, null]);
    bSheet.merge(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 4), CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 4));

    _writeRowWithStyles(bSheet, 5, ["Giữ tối đa / mã", _formatPoint(resultB["giaGiuMoiCon"] * 1000 ?? 0), ""], [labelStyle, valueStyle, null]);
    bSheet.merge(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 5), CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 5));

    _writeRowWithStyles(bSheet, 6, ["Tổng giữ lại (tiền)", _formatMoney(keptB), ""], [labelStyle, valueStyle, null]);
    bSheet.merge(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 6), CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 6));

    _writeRowWithStyles(bSheet, 7, ["Hoa hồng", _formatMoney(commB), ""], [labelStyle, valueStyle, null]);
    bSheet.merge(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 7), CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 7));

    _writeRowWithStyles(bSheet, 8, ["Thực chuyển", _formatMoney(netFwdB), ""], [labelStyle, valueStyle, null]);
    bSheet.merge(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 8), CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 8));

    _writeRowWithStyles(bSheet, 9, ["Thực cầm", _formatMoney(holdB), ""], [boldLabelStyle, boldValueStyle, null]);
    bSheet.merge(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 9), CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 9));

    _writeRow(bSheet, 11, ["CHI TIẾT THEO MÃ SẢN PHẨM (LOẠI B)", "", ""], style: sectionStyle, rowHeight: 26.0);
    bSheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 11), CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 11));

    _writeRow(bSheet, 12, ["Mã SP", "Giữ lại (điểm)", "Chuyển đi (điểm)"], style: headerStyle, rowHeight: 26.0);

    final Map<String, dynamic> retainedB = Map<String, dynamic>.from(resultB["chi_tiết_giữ_lại"] ?? {});
    final Map<String, dynamic> forwardedB = Map<String, dynamic>.from(resultB["chi_tiết_chuyển"] ?? {});
    final keysB = {...retainedB.keys, ...forwardedB.keys}.toList()..sort();
    int rowIdxB = 13;
    for (final key in keysB) {
      final rVal = retainedB[key] ?? 0;
      final fVal = forwardedB[key] ?? 0;
      _writeRowWithStyles(bSheet, rowIdxB++, [key, _formatPoint(rVal), _formatPoint(fVal)], [labelStyle, valueStyle, valueStyle]);
    }

    final bytes = excel.encode();
    if (bytes != null) {
      await ExportHelper.saveAndShareFile(
        bytes: bytes,
        filename: "bao_cao_tai_chinh_$date.xlsx",
        mimeType: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      );
    }
  }

  static Future<void> exportReportToPdf({
    required Map<String, dynamic> resultA,
    required Map<String, dynamic> resultB,
    required String date,
  }) async {
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: await PdfGoogleFonts.robotoRegular(),
        bold: await PdfGoogleFonts.robotoBold(),
      ),
    );

    final num revA = resultA["tongDoanhThu"] * 1000 ?? 0;
    final num revB = resultB["tongDoanhThu"] * 1000 ?? 0;
    final totalRevenue = revA + revB;
    final keptA = resultA["tongGiuLai"] * 1000 ?? 0;
    final keptB = resultB["tongGiuLai"] * 1000 ?? 0;
    final totalKept = keptA + keptB;
    final fwdA = resultA["tongChuyen"] * 1000 ?? 0;
    final fwdB = resultB["tongChuyen"] * 1000 ?? 0;
    final totalForwarded = fwdA + fwdB;
    final commA = resultA["hoa_hong"] * 1000 ?? 0;
    final commB = (resultB["hoa_hồng"] ?? resultB["hoa_hong"] ?? 0) * 1000;
    final totalCommission = commA + commB;
    final netFwdA = resultA["tongThucChuyen"] * 1000 ?? 0;
    final netFwdB = resultB["tongThucChuyen"] * 1000 ?? 0;
    final totalNetForwarded = netFwdA + netFwdB;
    final holdA = resultA["cam"] * 1000 ?? 0;
    final holdB = resultB["cam"] * 1000 ?? 0;
    final totalHold = holdA + holdB;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Center(
              child: pw.Column(
                children: [
                  pw.Text("BÁO CÁO TÀI CHÍNH TỔNG HỢP", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 5),
                  pw.Text("Ngày báo cáo: $date", style: const pw.TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
          pw.SizedBox(height: 20),

          // Overview section
          pw.Text("1. Tổng quan tình hình tài chính", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ["Chỉ số", "Giá trị"],
            data: [
              ["TỔNG THU NHẬP ĐẠI LÝ (CẦM)", _formatMoney(totalHold)],
              ["Doanh thu A + B", _formatMoney(totalRevenue)],
              ["Thực chuyển chủ", _formatMoney(totalNetForwarded)],
              ["Tổng hoa hồng nhận", _formatMoney(totalCommission)],
              ["Tổng giữ lại", _formatMoney(totalKept)],
              ["Tổng chuyển đi", _formatMoney(totalForwarded)],
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 20),

          // Type A Details
          pw.Text("2. Chi tiết mã loại A", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ["Chỉ số", "Giá trị"],
            data: [
              ["Doanh thu Loại A", _formatMoney(revA)],
              ["Giữ tối đa / mã", _formatMoney(resultA["giaGiuMoiCon"] * 1000 ?? 0)],
              ["Thực chuyển", _formatMoney(netFwdA)],
              ["Thực cầm", _formatMoney(holdA)],
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 20),

          // Type B Details
          pw.Text("3. Chi tiết mã loại B", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ["Chỉ số", "Giá trị"],
            data: [
              ["Doanh thu Loại B", _formatMoney(revB)],
              ["Giữ tối đa / mã", _formatPoint(resultB["giaGiuMoiCon"] * 1000 ?? 0)],
              ["Thực chuyển", _formatMoney(netFwdB)],
              ["Thực cầm", _formatMoney(holdB)],
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );

    // Page 2: Table of Product code details
    final Map<String, dynamic> rA = Map<String, dynamic>.from(resultA["chi_tiết_giữ_lại"] ?? {});
    final Map<String, dynamic> fA = Map<String, dynamic>.from(resultA["chi_tiết_chuyển"] ?? {});
    final keysA = {...rA.keys, ...fA.keys}.toList()..sort();

    final Map<String, dynamic> rB = Map<String, dynamic>.from(resultB["chi_tiết_giữ_lại"] ?? {});
    final Map<String, dynamic> fB = Map<String, dynamic>.from(resultB["chi_tiết_chuyển"] ?? {});
    final keysB = {...rB.keys, ...fB.keys}.toList()..sort();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text("4. Chi tiết theo mã sản phẩm (Loại A)", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          if (keysA.isEmpty)
            pw.Text("Không có dữ liệu loại A")
          else
            pw.TableHelper.fromTextArray(
              headers: ["Mã SP", "Giữ lại", "Chuyển đi"],
              data: keysA.map((key) {
                final rVal = (rA[key] ?? 0) * 1000;
                final fVal = (fA[key] ?? 0) * 1000;
                return [key, _formatMoney(rVal), _formatMoney(fVal)];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          pw.SizedBox(height: 25),

          pw.Text("5. Chi tiết theo mã sản phẩm (Loại B)", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          if (keysB.isEmpty)
            pw.Text("Không có dữ liệu loại B")
          else
            pw.TableHelper.fromTextArray(
              headers: ["Mã SP", "Giữ lại (điểm)", "Chuyển đi (điểm)"],
              data: keysB.map((key) {
                final rVal = rB[key] ?? 0;
                final fVal = fB[key] ?? 0;
                return [key, _formatPoint(rVal), _formatPoint(fVal)];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
        ],
      ),
    );

    final bytes = await pdf.save();
    await ExportHelper.saveAndShareFile(
      bytes: bytes,
      filename: "bao_cao_tai_chinh_$date.pdf",
      mimeType: "application/pdf",
    );
  }

  // --- SETTLEMENT EXPORT ---

  static Future<void> exportSettlementToExcel({
    required Map<String, dynamic> result,
    required String date,
  }) async {
    final Excel excel = Excel.createExcel();
    excel.delete('Sheet1');

    final Sheet sheet = excel['Bồi hoàn'];
    sheet.setColumnWidth(0, 35.0);
    sheet.setColumnWidth(1, 25.0);

    final isProfit = result["profit"] as bool;
    final type = result["type"] as String;

    // Styles
    final headerStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ExcelColor.fromHexString("#FFFFFF"),
      backgroundColorHex: ExcelColor.fromHexString("#F97316"), // Orange color accent for settlement
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
    final labelStyle = CellStyle(
      fontSize: 11,
      fontColorHex: ExcelColor.fromHexString("#1F2937"),
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );
    final valueStyle = CellStyle(
      fontSize: 11,
      fontColorHex: ExcelColor.fromHexString("#1F2937"),
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
    );
    final highlightLabelStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ExcelColor.fromHexString(isProfit ? "#065F46" : "#991B1B"),
      backgroundColorHex: ExcelColor.fromHexString(isProfit ? "#D1FAE5" : "#FEE2E2"),
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );
    final highlightValueStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ExcelColor.fromHexString(isProfit ? "#065F46" : "#991B1B"),
      backgroundColorHex: ExcelColor.fromHexString(isProfit ? "#D1FAE5" : "#FEE2E2"),
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
    );
    final conclusionStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ExcelColor.fromHexString(isProfit ? "#047857" : "#B91C1C"),
      backgroundColorHex: ExcelColor.fromHexString("#F3F4F6"),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    _writeExcelHeader(sheet, "BÁO CÁO THANH TOÁN BỒI HOÀN", date, 2);

    _writeRow(sheet, 3, ["Thông tin", "Giá trị"], style: headerStyle, rowHeight: 28.0);
    _writeRowWithStyles(sheet, 4, [
      isProfit ? "LỢI NHUẬN CÒN LẠI" : "SỐ TIỀN THÂM HỤT",
      _formatMoney(result["remaining"] * 1000),
    ], [highlightLabelStyle, highlightValueStyle], rowHeight: 26.0);

    _writeRowWithStyles(sheet, 5, ["Loại Mã", "Mã Loại $type"], [labelStyle, valueStyle]);
    _writeRowWithStyles(sheet, 6, ["Mã sản phẩm", result["productCode"].toString()], [labelStyle, valueStyle]);
    
    int nextRow = 7;
    if (type == "B") {
      _writeRowWithStyles(sheet, nextRow++, ["Hệ số bồi hoàn", result["multiplier"].toString()], [labelStyle, valueStyle]);
      _writeRowWithStyles(sheet, nextRow++, ["Giá bán / điểm", _formatMoney(result["ticketPrice"])], [labelStyle, valueStyle]);
    }

    _writeRowWithStyles(sheet, nextRow++, [
      type == "A" ? "Số lượng giữ lại" : "Số điểm giữ lại",
      type == "A" ? _formatMoney(result["retained"] * 1000) : "${result["retained"]} điểm",
    ], [labelStyle, valueStyle]);

    _writeRowWithStyles(sheet, nextRow++, ["Tỉ lệ bồi hoàn", result["refundRate"].toString()], [labelStyle, valueStyle]);
    _writeRowWithStyles(sheet, nextRow++, ["Tổng tiền ban đầu (giữ + hồng)", _formatMoney(result["totalRetained"] * 1000)], [labelStyle, valueStyle]);
    _writeRowWithStyles(sheet, nextRow++, ["Tiền phải bồi hoàn", _formatMoney(result["refundMoney"] * 1000)], [labelStyle, valueStyle]);
    _writeRowWithStyles(sheet, nextRow++, ["Còn lại (Sau bồi hoàn)", _formatMoney(result["remaining"] * 1000)], [highlightLabelStyle, highlightValueStyle], rowHeight: 26.0);
    
    // Add space and conclusion
    nextRow++;
    sheet.setRowHeight(nextRow, 30.0);
    final conclusionText = isProfit
        ? "Kết luận: Sau khi bồi hoàn, đại lý vẫn bảo toàn được lợi nhuận."
        : "Kết luận: Sau khi bồi hoàn, tổng thu chi bị âm (đại lý bị lỗ).";
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: nextRow)).value = TextCellValue(conclusionText);
    for (int col = 0; col < 2; col++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: nextRow)).cellStyle = conclusionStyle;
    }
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: nextRow),
      CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: nextRow),
    );

    final bytes = excel.encode();
    if (bytes != null) {
      await ExportHelper.saveAndShareFile(
        bytes: bytes,
        filename: "bao_cao_boi_hoan_${result["productCode"]}_$date.xlsx",
        mimeType: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      );
    }
  }

  static Future<void> exportSettlementToPdf({
    required Map<String, dynamic> result,
    required String date,
  }) async {
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: await PdfGoogleFonts.robotoRegular(),
        bold: await PdfGoogleFonts.robotoBold(),
      ),
    );

    final isProfit = result["profit"] as bool;
    final type = result["type"] as String;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Header(
              level: 0,
              child: pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text("BÁO CÁO THÀNH TOÁN BỒI HOÀN", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 5),
                    pw.Text("Ngày thực hiện: $date", style: const pw.TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 20),

            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: isProfit ? PdfColors.green : PdfColors.red, width: 2),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      isProfit ? "LỢI NHUẬN CÒN LẠI" : "SỐ TIỀN THÂM HỤT",
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      _formatMoney(result["remaining"] * 1000),
                      style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: isProfit ? PdfColors.green700 : PdfColors.red700),
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 20),

            pw.Text("Thông số chi tiết", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ["Thông số", "Giá trị"],
              data: [
                ["Loại Mã", "Mã Loại $type"],
                ["Mã sản phẩm", result["productCode"].toString()],
                if (type == "B") ...[
                  ["Hệ số bồi hoàn", result["multiplier"].toString()],
                  ["Giá bán / điểm", _formatMoney(result["ticketPrice"])],
                ],
                [
                  type == "A" ? "Số lượng giữ lại" : "Số điểm giữ lại",
                  type == "A" ? _formatMoney(result["retained"] * 1000) : "${result["retained"]} điểm",
                ],
                ["Tỉ lệ bồi hoàn", result["refundRate"].toString()],
                ["Tổng tiền ban đầu", _formatMoney(result["totalRetained"] * 1000)],
                ["Tiền phải bồi hoàn", _formatMoney(result["refundMoney"] * 1000)],
                ["Lợi nhuận cuối cùng", _formatMoney(result["remaining"] * 1000)],
              ],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 25),

            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              color: PdfColors.grey100,
              child: pw.Text(
                isProfit
                    ? "Kết luận: Sau khi bồi hoàn, đại lý vẫn bảo toàn được lợi nhuận."
                    : "Kết luận: Sau khi bồi hoàn, tổng thu chi bị âm (đại lý bị lỗ).",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: isProfit ? PdfColors.green800 : PdfColors.red800),
              ),
            ),
          ],
        ),
      ),
    );

    final bytes = await pdf.save();
    await ExportHelper.saveAndShareFile(
      bytes: bytes,
      filename: "bao_cao_boi_hoan_${result["productCode"]}_$date.pdf",
      mimeType: "application/pdf",
    );
  }

  // --- PRIVATE HELPERS ---

  static void _writeExcelHeader(Sheet sheet, String title, String date, int maxCols) {
    // Row 0: Title
    sheet.setRowHeight(0, 36.0);
    final titleStyle = CellStyle(
      bold: true,
      fontSize: 13,
      fontColorHex: ExcelColor.fromHexString("#FFFFFF"),
      backgroundColorHex: ExcelColor.fromHexString("#1E3B8A"), // Deep royal blue header
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
    for (int col = 0; col < maxCols; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
      cell.cellStyle = titleStyle;
      if (col == 0) {
        cell.value = TextCellValue(title);
      }
    }
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: maxCols - 1, rowIndex: 0),
    );

    // Row 1: Subtitle/Date
    sheet.setRowHeight(1, 24.0);
    final metaStyle = CellStyle(
      italic: true,
      fontSize: 10,
      fontColorHex: ExcelColor.fromHexString("#4B5563"),
      backgroundColorHex: ExcelColor.fromHexString("#F3F4F6"),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
    for (int col = 0; col < maxCols; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 1));
      cell.cellStyle = metaStyle;
      if (col == 0) {
        cell.value = TextCellValue("Ngày lập: $date");
      }
    }
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
      CellIndex.indexByColumnRow(columnIndex: maxCols - 1, rowIndex: 1),
    );
  }

  static void _writeRow(Sheet sheet, int rowIndex, List<String> values, {CellStyle? style, double rowHeight = 22.0}) {
    sheet.setRowHeight(rowIndex, rowHeight);
    for (int col = 0; col < values.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex));
      cell.value = TextCellValue(values[col]);
      if (style != null) {
        cell.cellStyle = style;
      }
    }
  }

  static void _writeRowWithStyles(Sheet sheet, int rowIndex, List<String> values, List<CellStyle?> styles, {double rowHeight = 22.0}) {
    sheet.setRowHeight(rowIndex, rowHeight);
    for (int col = 0; col < values.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex));
      cell.value = TextCellValue(values[col]);
      final style = col < styles.length ? styles[col] : null;
      if (style != null) {
        cell.cellStyle = style;
      }
    }
  }
}
