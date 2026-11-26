import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../app/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/conflict_exception.dart';
import '../models/request_activity_model.dart';
import '../models/request_model.dart';
import 'request_local_datasource.dart';

class _StoragePayload {
  final List<RequestModel> requests;
  final List<RequestActivityModel> activities;

  const _StoragePayload({required this.requests, required this.activities});
}

class SharedPreferencesRequestDataSource implements RequestLocalDataSource {
  final SharedPreferences _sharedPreferences;

  SharedPreferencesRequestDataSource(this._sharedPreferences);

  Future<_StoragePayload> _loadPayload() async {
    final jsonString = _sharedPreferences.getString(AppConstants.keyRequests);
    if (jsonString == null || jsonString.isEmpty) {
      final legacyActivities = _loadLegacyActivities();
      return _StoragePayload(requests: [], activities: legacyActivities);
    }

    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is Map<String, dynamic>) {
        final requestsRaw = decoded['requests'];
        final activitiesRaw = decoded['activities'];

        final requests = requestsRaw is List
            ? requestsRaw
                  .map(
                    (item) =>
                        RequestModel.fromJson(item as Map<String, dynamic>),
                  )
                  .toList()
            : <RequestModel>[];

        final activities = activitiesRaw is List
            ? activitiesRaw
                  .map(
                    (item) => RequestActivityModel.fromJson(
                      item as Map<String, dynamic>,
                    ),
                  )
                  .toList()
            : <RequestActivityModel>[];

        return _StoragePayload(requests: requests, activities: activities);
      } else if (decoded is List) {
        // Legacy format: raw JSON list of requests
        final requests = decoded
            .map((item) => RequestModel.fromJson(item as Map<String, dynamic>))
            .toList();
        final legacyActivities = _loadLegacyActivities();
        return _StoragePayload(
          requests: requests,
          activities: legacyActivities,
        );
      } else {
        throw const AppException(
          'Corrupted storage: Root element is neither a JSON map nor list',
          code: 'CORRUPTED_STORAGE',
        );
      }
    } on FormatException catch (e) {
      throw AppException(
        'Failed to parse requests from local storage due to invalid JSON: ${e.message}',
        code: 'CORRUPTED_STORAGE',
        details: e,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        'Unexpected error accessing local storage: $e',
        code: 'STORAGE_ERROR',
        details: e,
      );
    }
  }

  List<RequestActivityModel> _loadLegacyActivities() {
    final actString = _sharedPreferences.getString(
      AppConstants.keyRequestActivities,
    );
    if (actString == null || actString.isEmpty) return [];
    try {
      final decoded = jsonDecode(actString);
      if (decoded is List) {
        return decoded
            .map(
              (item) =>
                  RequestActivityModel.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> _persistPayload(_StoragePayload payload) async {
    try {
      final jsonMap = {
        'requests': payload.requests.map((r) => r.toJson()).toList(),
        'activities': payload.activities.map((a) => a.toJson()).toList(),
      };
      final jsonString = jsonEncode(jsonMap);
      await _sharedPreferences.setString(AppConstants.keyRequests, jsonString);
    } catch (e) {
      throw AppException('Failed to persist storage payload: $e');
    }
  }

  @override
  Future<List<RequestModel>> getRequests() async {
    final payload = await _loadPayload();
    return payload.requests;
  }

  @override
  Future<RequestModel?> getRequestById(String id) async {
    final requests = await getRequests();
    final index = requests.indexWhere((r) => r.id == id);
    if (index == -1) {
      return null;
    }
    return requests[index];
  }

  @override
  Future<void> saveRequests(List<RequestModel> requests) async {
    final payload = await _loadPayload();
    await _persistPayload(
      _StoragePayload(requests: requests, activities: payload.activities),
    );
  }

  @override
  Future<RequestModel> saveRequest(RequestModel request) async {
    final payload = await _loadPayload();
    final index = payload.requests.indexWhere((r) => r.id == request.id);

    List<RequestModel> updatedList;
    if (index >= 0) {
      updatedList = List.of(payload.requests)..[index] = request;
    } else {
      updatedList = [request, ...payload.requests];
    }

    await _persistPayload(
      _StoragePayload(requests: updatedList, activities: payload.activities),
    );
    return request;
  }

  @override
  Future<RequestModel> saveRequestWithActivity({
    required RequestModel request,
    required RequestActivityModel activity,
  }) async {
    final payload = await _loadPayload();
    final index = payload.requests.indexWhere((r) => r.id == request.id);

    List<RequestModel> updatedRequests;
    if (index >= 0) {
      updatedRequests = List.of(payload.requests)..[index] = request;
    } else {
      updatedRequests = [request, ...payload.requests];
    }

    final updatedActivities = List<RequestActivityModel>.from(
      payload.activities,
    )..add(activity);

    await _persistPayload(
      _StoragePayload(requests: updatedRequests, activities: updatedActivities),
    );
    return request;
  }

  @override
  Future<RequestModel> updateRequest(
    RequestModel request, {
    required int expectedVersion,
  }) async {
    final payload = await _loadPayload();
    final index = payload.requests.indexWhere((r) => r.id == request.id);

    if (index == -1) {
      throw const AppException(
        'Request not found in local storage',
        code: 'NOT_FOUND',
      );
    }

    final existing = payload.requests[index];
    if (existing.version != expectedVersion) {
      throw ConflictException(
        expectedVersion: expectedVersion,
        actualVersion: existing.version,
      );
    }

    final updated = request.copyWith(
      version: existing.version + 1,
      updatedAt: DateTime.now(),
    );

    final updatedList = List.of(payload.requests)..[index] = updated;
    await _persistPayload(
      _StoragePayload(requests: updatedList, activities: payload.activities),
    );
    return updated;
  }

  @override
  Future<void> deleteRequest(String id) async {
    final payload = await _loadPayload();
    final updatedList = payload.requests.where((r) => r.id != id).toList();
    await _persistPayload(
      _StoragePayload(requests: updatedList, activities: payload.activities),
    );
  }

  @override
  Future<List<RequestActivityModel>> getActivities(String requestId) async {
    final payload = await _loadPayload();
    final filtered = payload.activities
        .where((a) => a.requestId == requestId)
        .toList();
    filtered.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return filtered;
  }

  @override
  Future<void> saveActivity(RequestActivityModel activity) async {
    final payload = await _loadPayload();
    final updatedActivities = List<RequestActivityModel>.from(
      payload.activities,
    )..add(activity);
    await _persistPayload(
      _StoragePayload(
        requests: payload.requests,
        activities: updatedActivities,
      ),
    );
  }

  @override
  Future<void> saveActivities(List<RequestActivityModel> activities) async {
    final payload = await _loadPayload();
    final updatedActivities = List<RequestActivityModel>.from(
      payload.activities,
    )..addAll(activities);
    await _persistPayload(
      _StoragePayload(
        requests: payload.requests,
        activities: updatedActivities,
      ),
    );
  }

  @override
  Future<bool> isInitialized() async {
    return _sharedPreferences.getBool(AppConstants.keyStorageInitialized) ??
        false;
  }

  @override
  Future<void> setInitialized() async {
    await _sharedPreferences.setBool(AppConstants.keyStorageInitialized, true);
  }

  @override
  Future<void> clear() async {
    await _sharedPreferences.remove(AppConstants.keyRequests);
    await _sharedPreferences.remove(AppConstants.keyRequestActivities);
    await _sharedPreferences.remove(AppConstants.keyStorageInitialized);
  }
}
