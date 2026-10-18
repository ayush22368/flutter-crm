import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/agency_model.dart';
import '../models/quotation_model.dart';

class PdfService {
  static Future<void> generateAndDownloadQuotation({
    required Agency agency,
    required Quotation quotation,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('MMM dd, yyyy');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        agency.name.isNotEmpty ? agency.name : 'ClientFlow Agency',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.indigo900,
                        ),
                      ),
                      if (agency.description.isNotEmpty) ...[
                        pw.SizedBox(height: 4),
                        pw.Text(
                          agency.description,
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                      if (agency.businessEmail.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          agency.businessEmail,
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                      if (agency.phone.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          agency.phone,
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'QUOTATION',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.indigo700,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Quote #: ${quotation.quoteNumber}',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Date: ${dateFormat.format(quotation.createdAt)}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Valid Until: ${dateFormat.format(quotation.validityDate)}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: pw.BoxDecoration(
                          color: _statusColor(quotation.status),
                          borderRadius: const pw.BorderRadius.all(
                              pw.Radius.circular(4)),
                        ),
                        child: pw.Text(
                          quotation.status.toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 24),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 12),

              // Client Info & Project Title
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'PREPARED FOR:',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey600,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        quotation.clientName,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      if (quotation.clientEmail.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          quotation.clientEmail,
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'PROJECT TITLE:',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey600,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        quotation.title,
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              if (quotation.description.isNotEmpty) ...[
                pw.SizedBox(height: 10),
                pw.Text(
                  quotation.description,
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                ),
              ],

              pw.SizedBox(height: 20),

              // Items Table
              pw.TableHelper.fromTextArray(
                context: context,
                border: pw.TableBorder.symmetric(
                  inside: const pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                  outside: const pw.BorderSide(color: PdfColors.grey300, width: 0.8),
                ),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.indigo800,
                ),
                cellStyle: const pw.TextStyle(fontSize: 10),
                cellPadding: const pw.EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                headers: ['#', 'Service / Deliverable', 'Qty', 'Unit Price', 'Total'],
                data: List.generate(
                  quotation.items.length,
                  (index) {
                    final item = quotation.items[index];
                    return [
                      '${index + 1}',
                      item.description,
                      '${item.quantity}',
                      '${agency.currencySymbol}${item.unitPrice.toStringAsFixed(2)}',
                      '${agency.currencySymbol}${item.total.toStringAsFixed(2)}',
                    ];
                  },
                ),
              ),

              pw.SizedBox(height: 16),

              // Totals
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 220,
                    child: pw.Column(
                      children: [
                        _buildTotalRow(
                          'Subtotal:',
                          '${agency.currencySymbol}${quotation.subtotal.toStringAsFixed(2)}',
                        ),
                        if (quotation.taxPercent > 0)
                          _buildTotalRow(
                            'Tax (${quotation.taxPercent.toStringAsFixed(0)}%):',
                            '${agency.currencySymbol}${quotation.taxAmount.toStringAsFixed(2)}',
                          ),
                        if (quotation.discountAmount > 0)
                          _buildTotalRow(
                            'Discount:',
                            '-${agency.currencySymbol}${quotation.discountAmount.toStringAsFixed(2)}',
                          ),
                        pw.Divider(color: PdfColors.grey400),
                        _buildTotalRow(
                          'Final Total:',
                          '${agency.currencySymbol}${quotation.finalTotal.toStringAsFixed(2)}',
                          isBold: true,
                          fontSize: 12,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.Spacer(),

              // Notes & Terms
              if (quotation.notes.isNotEmpty) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Terms & Notes:',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 9,
                          color: PdfColors.grey800,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        quotation.notes,
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),
              ],

              // Footer
              pw.Center(
                child: pw.Text(
                  'Thank you for your business! Generated by ClientFlow CRM.',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey500,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: '${quotation.quoteNumber}_Quotation.pdf',
    );
  }

  static pw.Widget _buildTotalRow(
    String title,
    String value, {
    bool isBold = false,
    double fontSize = 10,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  static PdfColor _statusColor(String status) {
    switch (status) {
      case 'Accepted':
        return PdfColors.green700;
      case 'Sent':
        return PdfColors.blue700;
      case 'Rejected':
        return PdfColors.red700;
      case 'Expired':
        return PdfColors.amber800;
      default:
        return PdfColors.grey700;
    }
  }
}
