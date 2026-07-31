//import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';


class RevenueReceiptService {
  static Future<void> generateAndPrint({
    required String receiptNumber,
    required String adminName,
    required String adminEmail,
    required String period,
    required double grandTotal,
    required double totalLiters,
    required int totalDispenses,
    required List<Map<String, dynamic>> vendoBreakdown,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final formattedDate = DateFormat('MMMM dd, yyyy').format(now);
    final formattedTime = DateFormat('hh:mm a').format(now);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [

              // --- HEADER ---
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      "H2O HUB",
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      "PSU Lubao Campus",
                      style: const pw.TextStyle(fontSize: 14),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      "COLLECTION RECEIPT",
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 10),

              // --- RECEIPT INFO ---
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow("Receipt No:", receiptNumber),
                      _buildInfoRow("Date:", formattedDate),
                      _buildInfoRow("Time:", formattedTime),
                      _buildInfoRow("Period:", period),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow("Collected by:", adminName),
                      _buildInfoRow("Email:", adminEmail),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 16),
              pw.Divider(),
              pw.SizedBox(height: 10),

              // --- VENDO BREAKDOWN TABLE ---
              pw.Text(
                "VENDO BREAKDOWN",
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),

              // Table Header
              pw.Container(
                color: PdfColors.blueGrey100,
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text(
                        "Vendo Unit",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        "Dispenses",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        "Volume",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        "Revenue",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),

              // Table Rows
              ...vendoBreakdown.asMap().entries.map((entry) {
                int idx = entry.key;
                Map<String, dynamic> vendo = entry.value;
                bool isEven = idx % 2 == 0;

                return pw.Container(
                  color: isEven ? PdfColors.grey100 : PdfColors.white,
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 3,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              vendo['name'] ?? vendo['id'],
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                            pw.Text(
                              "ID: ${vendo['id']}  |  Php1:${vendo['mlPerPeso'].toInt()}ml",
                              style: const pw.TextStyle(
                                fontSize: 9,
                                color: PdfColors.grey600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          "${vendo['dispenses']}x",
                          style: const pw.TextStyle(fontSize: 11),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          "${(vendo['liters'] as double).toStringAsFixed(2)} L",
                          style: const pw.TextStyle(fontSize: 11),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          "Php${(vendo['revenue'] as double).toStringAsFixed(2)}",
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 11,
                          ),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1.5),

              // --- TOTALS ---
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          "Total Dispenses: $totalDispenses times",
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                        pw.Text(
                          "Total Volume: ${totalLiters.toStringAsFixed(2)} L",
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          "TOTAL COLLECTED",
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          "Php${grandTotal.toStringAsFixed(2)}",
                          style: pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),
              pw.Divider(),
              pw.SizedBox(height: 40),

              // --- SIGNATURE SECTION ---
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        width: 180,
                        child: pw.Divider(thickness: 1),
                      ),
                      pw.Text(
                        adminName,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      pw.Text(
                        "Admin - Collected by",
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        width: 180,
                        child: pw.Divider(thickness: 1),
                      ),
                      pw.Text(
                        "Authorized Signatory",
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      pw.Text(
                        "PSU Lubao Campus",
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 30),
              pw.Divider(),
              pw.SizedBox(height: 8),

              // --- FOOTER ---
              pw.Center(
                child: pw.Text(
                  "This is a system-generated receipt from H2O Hub Admin System.",
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey500,
                  ),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  "Generated on $formattedDate at $formattedTime",
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey500,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Print or Download the PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: "H2O_Receipt_$receiptNumber.pdf",
    );
  }

  // Helper widget for info rows
  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 11,
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }
}