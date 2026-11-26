import '../entities/request.dart';
import '../entities/request_activity.dart';
import '../entities/request_status.dart';

abstract class RequestRepository {
  Future<List<Request>> getRequests();

  Future<Request> getRequestById(String id);

  Future<Request> createRequest({
    required String title,
    required String description,
    required RequestStatus status,
  });

  Future<Request> updateRequest({
    required String id,
    required String title,
    required String description,
    required int expectedVersion,
  });

  Future<Request> submitRequest({
    required String id,
    required int expectedVersion,
  });

  Future<Request> approveRequest({
    required String id,
    required int expectedVersion,
  });

  Future<Request> rejectRequest({
    required String id,
    required String rejectionReason,
    required int expectedVersion,
  });

  Future<List<RequestActivity>> getRequestActivities(String requestId);
}
