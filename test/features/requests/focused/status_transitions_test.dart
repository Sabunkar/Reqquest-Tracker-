import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:request_flow/core/errors/app_exception.dart';
import 'package:request_flow/features/requests/data/datasources/request_mock_api.dart';
import 'package:request_flow/features/requests/data/datasources/shared_preferences_request_datasource.dart';
import 'package:request_flow/features/requests/domain/entities/request_activity.dart';
import 'package:request_flow/features/requests/domain/entities/request_status.dart';
import 'package:request_flow/features/settings/domain/entities/user_role.dart';

void main() {
  group('2. Status Transitions - Workflow State Machine Tests', () {
    late SharedPreferences prefs;
    late SharedPreferencesRequestDataSource localDataSource;
    late RequestMockApi mockApi;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      localDataSource = SharedPreferencesRequestDataSource(prefs);
      mockApi = RequestMockApi(
        localDataSource: localDataSource,
        artificialDelay: Duration.zero,
        currentRoleOverride: UserRole.user,
      );
    });

    test(
      'Draft -> Submitted succeeds, updates status, and increments version exactly once',
      () async {
        final created = await mockApi.createRequest(
          title: 'Draft to Submit Request',
          description: 'Testing transition from Draft to Submitted',
          status: RequestStatus.draft,
        );
        expect(created.status, RequestStatus.draft);
        expect(created.version, 1);

        final submitted = await mockApi.submitRequest(
          id: created.id,
          expectedVersion: 1,
        );

        expect(submitted.status, RequestStatus.submitted);
        expect(submitted.version, 2);

        // Verify in storage
        final stored = await localDataSource.getRequestById(created.id);
        expect(stored, isNotNull);
        expect(stored!.status, RequestStatus.submitted);
        expect(stored.version, 2);

        // Verify activity history logged
        final activities = await localDataSource.getActivities(created.id);
        expect(
          activities.any((a) => a.eventType == RequestActivityType.submitted),
          isTrue,
        );
      },
    );

    test(
      'Submitted -> Approved succeeds for Reviewer, increments version exactly once',
      () async {
        final created = await mockApi.createRequest(
          title: 'Draft to Approve Request',
          description: 'Testing approve workflow',
          status: RequestStatus.draft,
        );
        await mockApi.submitRequest(id: created.id, expectedVersion: 1);

        // Switch to Reviewer
        mockApi.currentRoleOverride = UserRole.reviewer;

        final approved = await mockApi.approveRequest(
          id: created.id,
          expectedVersion: 2,
        );

        expect(approved.status, RequestStatus.approved);
        expect(approved.version, 3);

        final stored = await localDataSource.getRequestById(created.id);
        expect(stored!.status, RequestStatus.approved);
        expect(stored.version, 3);

        final activities = await localDataSource.getActivities(created.id);
        expect(
          activities.any((a) => a.eventType == RequestActivityType.approved),
          isTrue,
        );
      },
    );

    test(
      'Submitted -> Rejected succeeds for Reviewer with valid reason, increments version exactly once',
      () async {
        final created = await mockApi.createRequest(
          title: 'Draft to Reject Request',
          description: 'Testing reject workflow',
          status: RequestStatus.draft,
        );
        await mockApi.submitRequest(id: created.id, expectedVersion: 1);

        mockApi.currentRoleOverride = UserRole.reviewer;

        final rejected = await mockApi.rejectRequest(
          id: created.id,
          rejectionReason: 'Exceeds budget limit for current fiscal quarter',
          expectedVersion: 2,
        );

        expect(rejected.status, RequestStatus.rejected);
        expect(
          rejected.rejectionReason,
          'Exceeds budget limit for current fiscal quarter',
        );
        expect(rejected.version, 3);

        final stored = await localDataSource.getRequestById(created.id);
        expect(stored!.status, RequestStatus.rejected);
        expect(
          stored.rejectionReason,
          'Exceeds budget limit for current fiscal quarter',
        );
        expect(stored.version, 3);

        final activities = await localDataSource.getActivities(created.id);
        expect(
          activities.any((a) => a.eventType == RequestActivityType.rejected),
          isTrue,
        );
      },
    );

    test(
      'Invalid transitions are rejected (cannot approve or reject Draft directly)',
      () async {
        final draft = await mockApi.createRequest(
          title: 'Direct Approval Attempt',
          description: 'Should not allow approving draft directly',
          status: RequestStatus.draft,
        );

        mockApi.currentRoleOverride = UserRole.reviewer;

        // Attempt Approve on Draft
        await expectLater(
          () => mockApi.approveRequest(id: draft.id, expectedVersion: 1),
          throwsA(
            predicate(
              (e) =>
                  e is AppException &&
                  e.code == 'INVALID_STATUS' &&
                  e.message.contains('Only submitted requests can be approved'),
            ),
          ),
        );

        // Attempt Reject on Draft
        await expectLater(
          () => mockApi.rejectRequest(
            id: draft.id,
            rejectionReason: 'Premature rejection',
            expectedVersion: 1,
          ),
          throwsA(
            predicate(
              (e) =>
                  e is AppException &&
                  e.code == 'INVALID_STATUS' &&
                  e.message.contains('Only submitted requests can be rejected'),
            ),
          ),
        );

        // Storage remains unchanged
        final stored = await localDataSource.getRequestById(draft.id);
        expect(stored!.status, RequestStatus.draft);
        expect(stored.version, 1);
      },
    );

    test(
      'Requester cannot approve or reject requests (Unauthorized Role)',
      () async {
        final draft = await mockApi.createRequest(
          title: 'Reviewer Action Privilege Test',
          description: 'Requester role restriction test',
          status: RequestStatus.draft,
        );
        await mockApi.submitRequest(id: draft.id, expectedVersion: 1);

        // Remain UserRole.user
        mockApi.currentRoleOverride = UserRole.user;

        await expectLater(
          () => mockApi.approveRequest(id: draft.id, expectedVersion: 2),
          throwsA(
            predicate(
              (e) =>
                  e is AppException &&
                  e.code == 'UNAUTHORIZED_ROLE' &&
                  e.message.contains('Users cannot approve requests'),
            ),
          ),
        );

        await expectLater(
          () => mockApi.rejectRequest(
            id: draft.id,
            rejectionReason: 'Self rejection attempt',
            expectedVersion: 2,
          ),
          throwsA(
            predicate(
              (e) =>
                  e is AppException &&
                  e.code == 'UNAUTHORIZED_ROLE' &&
                  e.message.contains('Users cannot reject requests'),
            ),
          ),
        );
      },
    );

    test(
      'Approved requests cannot be modified or resubmitted (Immutable Final State)',
      () async {
        final draft = await mockApi.createRequest(
          title: 'Approved Finality Test',
          description: 'Approved requests are immutable',
          status: RequestStatus.draft,
        );
        await mockApi.submitRequest(id: draft.id, expectedVersion: 1);
        mockApi.currentRoleOverride = UserRole.reviewer;
        await mockApi.approveRequest(id: draft.id, expectedVersion: 2);

        // Switch back to User
        mockApi.currentRoleOverride = UserRole.user;

        // Update attempt on Approved
        await expectLater(
          () => mockApi.updateRequest(
            id: draft.id,
            title: 'Modified Approved Title',
            description: 'Updated desc',
            expectedVersion: 3,
          ),
          throwsA(
            predicate(
              (e) =>
                  e is AppException &&
                  e.code == 'INVALID_STATUS' &&
                  e.message.contains('final and read-only'),
            ),
          ),
        );

        // Submit attempt on Approved
        await expectLater(
          () => mockApi.submitRequest(id: draft.id, expectedVersion: 3),
          throwsA(
            predicate(
              (e) =>
                  e is AppException &&
                  e.code == 'INVALID_STATUS' &&
                  e.message.contains('final and read-only'),
            ),
          ),
        );
      },
    );

    test(
      'Rejected requests cannot be modified or resubmitted (Immutable Final State)',
      () async {
        final draft = await mockApi.createRequest(
          title: 'Rejected Finality Test',
          description: 'Rejected requests are immutable',
          status: RequestStatus.draft,
        );
        await mockApi.submitRequest(id: draft.id, expectedVersion: 1);
        mockApi.currentRoleOverride = UserRole.reviewer;
        await mockApi.rejectRequest(
          id: draft.id,
          rejectionReason: 'Final rejection reason',
          expectedVersion: 2,
        );

        // Switch back to User
        mockApi.currentRoleOverride = UserRole.user;

        // Update attempt on Rejected
        await expectLater(
          () => mockApi.updateRequest(
            id: draft.id,
            title: 'Modified Rejected Title',
            description: 'Updated desc',
            expectedVersion: 3,
          ),
          throwsA(
            predicate(
              (e) =>
                  e is AppException &&
                  e.code == 'INVALID_STATUS' &&
                  e.message.contains('final and read-only'),
            ),
          ),
        );

        // Submit attempt on Rejected
        await expectLater(
          () => mockApi.submitRequest(id: draft.id, expectedVersion: 3),
          throwsA(
            predicate(
              (e) =>
                  e is AppException &&
                  e.code == 'INVALID_STATUS' &&
                  e.message.contains('final and read-only'),
            ),
          ),
        );
      },
    );
  });
}
