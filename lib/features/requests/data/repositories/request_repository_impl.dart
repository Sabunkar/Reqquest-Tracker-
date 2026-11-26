import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/request.dart';
import '../../domain/entities/request_activity.dart';
import '../../domain/entities/request_status.dart';
import '../../domain/repositories/request_repository.dart';
import '../datasources/request_mock_api.dart';

class RequestRepositoryImpl implements RequestRepository {
  final RequestMockApi mockApi;

  RequestRepositoryImpl({required this.mockApi});

  @override
  Future<List<Request>> getRequests() async {
    try {
      final models = await mockApi.getRequests();
      return models.map((m) => m.toEntity()).toList();
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(
        'Failed to fetch requests: $e',
        code: 'REPOSITORY_ERROR',
        details: e,
      );
    }
  }

  @override
  Future<Request> getRequestById(String id) async {
    try {
      final model = await mockApi.getRequestById(id);
      return model.toEntity();
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(
        'Failed to retrieve request with ID "$id": $e',
        code: 'REPOSITORY_ERROR',
        details: e,
      );
    }
  }

  @override
  Future<Request> createRequest({
    required String title,
    required String description,
    required RequestStatus status,
  }) async {
    try {
      final model = await mockApi.createRequest(
        title: title,
        description: description,
        status: status,
      );
      return model.toEntity();
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(
        'Failed to create request: $e',
        code: 'REPOSITORY_ERROR',
        details: e,
      );
    }
  }

  @override
  Future<Request> updateRequest({
    required String id,
    required String title,
    required String description,
    required int expectedVersion,
  }) async {
    try {
      final model = await mockApi.updateRequest(
        id: id,
        title: title,
        description: description,
        expectedVersion: expectedVersion,
      );
      return model.toEntity();
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(
        'Failed to update request "$id": $e',
        code: 'REPOSITORY_ERROR',
        details: e,
      );
    }
  }

  @override
  Future<Request> submitRequest({
    required String id,
    required int expectedVersion,
  }) async {
    try {
      final model = await mockApi.submitRequest(
        id: id,
        expectedVersion: expectedVersion,
      );
      return model.toEntity();
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(
        'Failed to submit request "$id": $e',
        code: 'REPOSITORY_ERROR',
        details: e,
      );
    }
  }

  @override
  Future<Request> approveRequest({
    required String id,
    required int expectedVersion,
  }) async {
    try {
      final model = await mockApi.approveRequest(
        id: id,
        expectedVersion: expectedVersion,
      );
      return model.toEntity();
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(
        'Failed to approve request "$id": $e',
        code: 'REPOSITORY_ERROR',
        details: e,
      );
    }
  }

  @override
  Future<Request> rejectRequest({
    required String id,
    required String rejectionReason,
    required int expectedVersion,
  }) async {
    try {
      final model = await mockApi.rejectRequest(
        id: id,
        rejectionReason: rejectionReason,
        expectedVersion: expectedVersion,
      );
      return model.toEntity();
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(
        'Failed to reject request "$id": $e',
        code: 'REPOSITORY_ERROR',
        details: e,
      );
    }
  }

  @override
  Future<List<RequestActivity>> getRequestActivities(String requestId) async {
    try {
      final models = await mockApi.getRequestActivities(requestId);
      return models.map((m) => m.toEntity()).toList();
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(
        'Failed to retrieve activities for request "$requestId": $e',
        code: 'REPOSITORY_ERROR',
        details: e,
      );
    }
  }
}
