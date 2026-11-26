import 'package:flutter_test/flutter_test.dart';
import 'package:request_flow/features/requests/domain/validators/request_validator.dart';

void main() {
  group('RequestValidator', () {
    test('validates title correctly', () {
      expect(RequestValidator.validateTitle(null), 'Title is required');
      expect(RequestValidator.validateTitle(''), 'Title is required');
      expect(RequestValidator.validateTitle('  '), 'Title is required');
      expect(
        RequestValidator.validateTitle('ab'),
        'Title must be at least 3 characters',
      );
      expect(RequestValidator.validateTitle('Valid Title'), isNull);
      expect(
        RequestValidator.validateTitle('A' * 121),
        'Title must not exceed 120 characters',
      );
      expect(RequestValidator.validateTitle('A' * 120), isNull);
    });

    test('validates description correctly', () {
      expect(RequestValidator.validateDescription(null), isNull);
      expect(RequestValidator.validateDescription(''), isNull);
      expect(RequestValidator.validateDescription('   '), isNull);
      expect(RequestValidator.validateDescription('Valid description'), isNull);
      expect(
        RequestValidator.validateDescription('A' * 2001),
        'Description must not exceed 2000 characters',
      );
      expect(RequestValidator.validateDescription('A' * 2000), isNull);
    });

    test('validates rejection reason correctly', () {
      expect(
        RequestValidator.validateRejectionReason(null),
        'Rejection reason is required',
      );
      expect(
        RequestValidator.validateRejectionReason(''),
        'Rejection reason is required',
      );
      expect(
        RequestValidator.validateRejectionReason('ab'),
        'Rejection reason must be at least 3 characters',
      );
      expect(
        RequestValidator.validateRejectionReason('Budget exceeded'),
        isNull,
      );
    });
  });
}
