import 'package:flutter_test/flutter_test.dart';
import 'package:request_flow/features/requests/data/models/request_model.dart';
import 'package:request_flow/features/requests/domain/entities/request.dart';
import 'package:request_flow/features/requests/domain/entities/request_status.dart';

void main() {
  group('RequestModel', () {
    final now = DateTime(2026, 11, 23, 10, 0, 0);
    final model = RequestModel(
      id: 'req-1',
      title: 'New Laptop',
      description: 'MacBook Pro for development',
      status: RequestStatus.draft,
      createdAt: now,
      updatedAt: now,
      version: 1,
      rejectionReason: null,
    );

    test('serializes to and from JSON', () {
      final json = model.toJson();
      expect(json['id'], 'req-1');
      expect(json['status'], 'draft');
      expect(json['createdAt'], now.toIso8601String());

      final fromJson = RequestModel.fromJson(json);
      expect(fromJson.id, model.id);
      expect(fromJson.title, model.title);
      expect(fromJson.status, model.status);
      expect(fromJson.version, 1);
    });

    test('converts to and from domain entity', () {
      final entity = model.toEntity();
      expect(entity, isA<Request>());
      expect(entity.id, model.id);

      final fromEntity = RequestModel.fromEntity(entity);
      expect(fromEntity, equals(model));
    });

    test('handles optional rejectionReason', () {
      final rejected = model.copyWith(
        status: RequestStatus.rejected,
        rejectionReason: 'Exceeds budget allowance',
      );
      final json = rejected.toJson();
      expect(json['rejectionReason'], 'Exceeds budget allowance');

      final fromJson = RequestModel.fromJson(json);
      expect(fromJson.rejectionReason, 'Exceeds budget allowance');
    });
  });
}
