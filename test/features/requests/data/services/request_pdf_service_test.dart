import 'package:flutter_test/flutter_test.dart';
import 'package:request_flow/features/requests/data/services/request_pdf_service.dart';
import 'package:request_flow/features/requests/domain/entities/request.dart';
import 'package:request_flow/features/requests/domain/entities/request_status.dart';

void main() {
  group('RequestPdfService Tests', () {
    test(
      'generateRequestPdf returns non-empty byte buffer for valid request',
      () async {
        final request = Request(
          id: 'req-pdf-test-1',
          title: 'Workstation Setup',
          description: 'Dual monitor and mechanical keyboard request',
          status: RequestStatus.approved,
          createdAt: DateTime(2026, 11, 20, 10, 0),
          updatedAt: DateTime(2026, 11, 22, 14, 30),
          version: 3,
        );

        final pdfBytes = await RequestPdfService.generateRequestPdf(request);
        expect(pdfBytes, isNotEmpty);
        expect(pdfBytes.length, greaterThan(500));
      },
    );

    test(
      'generateRequestPdf handles rejected request with rejection reason',
      () async {
        final request = Request(
          id: 'req-pdf-test-2',
          title: 'External Training Budget',
          description: 'Advanced Cloud Architecture course',
          status: RequestStatus.rejected,
          createdAt: DateTime(2026, 11, 15, 9, 0),
          updatedAt: DateTime(2026, 11, 16, 11, 0),
          version: 3,
          rejectionReason:
              'Course not aligned with quarterly team training goals.',
        );

        final pdfBytes = await RequestPdfService.generateRequestPdf(request);
        expect(pdfBytes, isNotEmpty);
        expect(pdfBytes.length, greaterThan(500));
      },
    );
  });
}
