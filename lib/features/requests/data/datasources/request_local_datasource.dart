import '../models/request_activity_model.dart';
import '../models/request_model.dart';

abstract class RequestLocalDataSource {
  Future<List<RequestModel>> getRequests();

  Future<RequestModel?> getRequestById(String id);

  Future<void> saveRequests(List<RequestModel> requests);

  Future<RequestModel> saveRequest(RequestModel request);

  Future<RequestModel> saveRequestWithActivity({
    required RequestModel request,
    required RequestActivityModel activity,
  });

  Future<RequestModel> updateRequest(
    RequestModel request, {
    required int expectedVersion,
  });

  Future<void> deleteRequest(String id);

  Future<List<RequestActivityModel>> getActivities(String requestId);

  Future<void> saveActivity(RequestActivityModel activity);

  Future<void> saveActivities(List<RequestActivityModel> activities);

  Future<bool> isInitialized();

  Future<void> setInitialized();

  Future<void> clear();
}
