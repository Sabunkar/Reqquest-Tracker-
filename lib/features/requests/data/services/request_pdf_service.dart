import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/request.dart';
import '../../domain/entities/request_status.dart';

/// Domain-specific service responsible for generating formatted, printable PDF documents for [Request] entities.
///
/// Located in `features/requests/data/services/` because its layout, metadata fields,
/// status styling, and confidentiality headers are strictly bound to the Request domain.
class RequestPdfService {
  const RequestPdfService._();

  static Future<Uint8List> generateRequestPdf(Request request) async {
    final pdf = pw.Document();

    final statusColor = _getPdfStatusColor(request.status);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Tracker',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.Text(
                        'Enterprise Request Management System',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: pw.BoxDecoration(
                      color: statusColor,
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(4),
                      ),
                    ),
                    child: pw.Text(
                      request.status.displayName.toUpperCase(),
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(color: PdfColors.grey400, thickness: 1),
              pw.SizedBox(height: 16),

              // Request Title and Key Details
              pw.Text(
                request.title,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey900,
                ),
              ),
              pw.SizedBox(height: 12),

              // Metadata Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  _buildTableRow('Request Identifier', request.id),
                  _buildTableRow('Current Status', request.status.displayName),
                  _buildTableRow('Entity Version', 'v${request.version}'),
                  _buildTableRow(
                    'Created Date',
                    DateFormatter.formatDateTime(request.createdAt),
                  ),
                  _buildTableRow(
                    'Last Updated',
                    DateFormatter.formatDateTime(request.updatedAt),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Description Section
              pw.Text(
                'Description',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey800,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(4),
                  ),
                ),
                child: pw.Text(
                  request.description.isEmpty
                      ? 'No description provided.'
                      : request.description,
                  style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.4),
                ),
              ),

              // Rejection Reason (if applicable)
              if (request.status == RequestStatus.rejected &&
                  request.rejectionReason != null &&
                  request.rejectionReason!.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                pw.Text(
                  'Rejection Reason',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.red800,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.red50,
                    border: pw.Border.all(color: PdfColors.red300),
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(4),
                    ),
                  ),
                  child: pw.Text(
                    request.rejectionReason!,
                    style: pw.TextStyle(
                      fontSize: 11,
                      color: PdfColors.red900,
                      lineSpacing: 1.4,
                    ),
                  ),
                ),
              ],

              pw.Spacer(),

              // Footer
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Generated on ${DateFormatter.formatDateTime(DateTime.now())}',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.Text(
                    'Confidential | Internal Use Only',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> printOrSharePdf(Request request) async {
    final pdfBytes = await generateRequestPdf(request);
    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name: 'Tracker_${request.id}.pdf',
    );
  }

  static pw.TableRow _buildTableRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey900),
          ),
        ),
      ],
    );
  }

  static PdfColor _getPdfStatusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.draft:
        return PdfColors.grey700;
      case RequestStatus.submitted:
        return PdfColors.blue700;
      case RequestStatus.approved:
        return PdfColors.green700;
      case RequestStatus.rejected:
        return PdfColors.red700;
    }
  }
}
