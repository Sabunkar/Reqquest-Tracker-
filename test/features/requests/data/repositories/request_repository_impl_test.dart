import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:request_flow/core/errors/conflict_exception.dart';
import 'package:request_flow/features/requests/data/datasources/request_mock_api.dart';
import 'package:request_flow/features/requests/data/datasources/shared_preferences_request_datasource.dart';
import 'package:request_flow/features/requests/data/repositories/request_repository_impl.dart';
import 'package:request_flow/features/requests/domain/entities/request_activity.dart';
import 'package:request_flow/features/requests/domain/entities/request_status.dart';
import 'package:request_flow/features/settings/domain/entities/user_role.dart';

void main() {
  group('RequestRepositoryImpl Integration Tests', () {
    late SharedPreferences prefs;
    late SharedPreferencesRequestDataSource localDataSource;
    late RequestMockApi mockApi;
    late RequestRepositoryImpl repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      localDataSource = SharedPreferencesRequestDataSource(prefs);
      mockApi = RequestMockApi(
        localDataSource: localDataSource,
        artificialDelay: Duration.zero,
        currentRoleOverride: UserRole.user,
      );
      repository = RequestRepositoryImpl(mockApi: mockApi);
    });

    test(
      'getRequests returns domain entities including initial seed data',
      () async {
        final requests = await repository.getRequests();
        expect(requests.length, 5);
        expect(requests.first.id, isNotEmpty);
      },
    );

    test(
      'createRequest saves and returns domain entity with version 1',
      () async {
        final created = await repository.createRequest(
          title: 'Project Budget',
          description: 'Q1 Marketing and engineering tools',
          status: RequestStatus.draft,
        );

        expect(created.title, 'Project Budget');
        expect(created.status, RequestStatus.draft);
        expect(created.version, 1);

        final fetched = await repository.getRequestById(created.id);
        expect(fetched.id, created.id);
        expect(fetched.title, created.title);
      },
    );

    test('updateRequest increments version on expectedVersion match', () async {
      final created = await repository.createRequest(
        title: 'Conference Pass',
        description: 'FlutterCon 2026',
        status: RequestStatus.draft,
      );

      final updated = await repository.updateRequest(
        id: created.id,
        title: 'Conference Pass (VIP)',
        description: 'VIP Admission ticket',
        expectedVersion: 1,
      );

      expect(updated.version, 2);
      expect(updated.title, 'Conference Pass (VIP)');
    });

    test(
      'updateRequest throws ConflictException on expectedVersion mismatch',
      () async {
        final created = await repository.createRequest(
          title: 'Hardware Monitor',
          description: '4K monitor',
          status: RequestStatus.draft,
        );

        expect(
          () => repository.updateRequest(
            id: created.id,
            title: 'Modified monitor',
            description: 'Modified desc',
            expectedVersion: 5,
          ),
          throwsA(isA<ConflictException>()),
        );
      },
    );

    test(
      'submitRequest, approveRequest, and rejectRequest workflow transitions',
      () async {
        final created = await repository.createRequest(
          title: 'Travel Authorization',
          description: 'Client on-site visit',
          status: RequestStatus.draft,
        );

        // User submits draft (v1 -> v2)
        final submitted = await repository.submitRequest(
          id: created.id,
          expectedVersion: 1,
        );
        expect(submitted.status, RequestStatus.submitted);
        expect(submitted.version, 2);

        // Switch to Reviewer for approval (v2 -> v3)
        mockApi.currentRoleOverride = UserRole.reviewer;
        final approved = await repository.approveRequest(
          id: created.id,
          expectedVersion: 2,
        );
        expect(approved.status, RequestStatus.approved);
        expect(approved.version, 3);
      },
    );

    test('getRequestActivities returns domain entities for request', () async {
      final created = await repository.createRequest(
        title: 'Activity Repo Test',
        description: 'Testing repository activity mapping',
        status: RequestStatus.draft,
      );

      final activities = await repository.getRequestActivities(created.id);
      expect(activities.length, 1);
      expect(activities.first.eventType, RequestActivityType.created);
      expect(activities.first.actorRole, UserRole.user);
    });
  });
}
