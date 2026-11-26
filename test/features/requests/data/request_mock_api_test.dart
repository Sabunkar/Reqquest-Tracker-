import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:request_flow/core/errors/app_exception.dart';
import 'package:request_flow/core/errors/conflict_exception.dart';
import 'package:request_flow/features/requests/data/datasources/request_mock_api.dart';
import 'package:request_flow/features/requests/data/datasources/shared_preferences_request_datasource.dart';
import 'package:request_flow/features/requests/domain/entities/request_activity.dart';
import 'package:request_flow/features/requests/domain/entities/request_status.dart';
import 'package:request_flow/features/settings/domain/entities/user_role.dart';

void main() {
  group('RequestMockApi Tests', () {
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

    // ---------------------------------------------------------
    // A. Persistence & Seeding
    // ---------------------------------------------------------
    group('A. Persistence and Seeding', () {
      test(
        'Seed data initializes exactly 5 requests on first launch',
        () async {
          final requests = await mockApi.getRequests();
          expect(requests.length, 5);

          // Verify the 5 seed requests
          expect(
            requests.any(
              (r) =>
                  r.title.contains('REQ-1001') &&
                  r.status == RequestStatus.draft,
            ),
            isTrue,
          );
          expect(
            requests.any(
              (r) =>
                  r.title.contains('REQ-1002') &&
                  r.status == RequestStatus.submitted,
            ),
            isTrue,
          );
          expect(
            requests.any(
              (r) =>
                  r.title.contains('REQ-1003') &&
                  r.status == RequestStatus.approved,
            ),
            isTrue,
          );
          expect(
            requests.any(
              (r) =>
                  r.title.contains('REQ-1004') &&
                  r.status == RequestStatus.rejected,
            ),
            isTrue,
          );
          expect(
            requests.any(
              (r) =>
                  r.title.contains('REQ-1005') &&
                  r.status == RequestStatus.submitted,
            ),
            isTrue,
          );

          final rejectedReq = requests.firstWhere(
            (r) => r.status == RequestStatus.rejected,
          );
          expect(rejectedReq.rejectionReason, isNotNull);
          expect(rejectedReq.rejectionReason!.isNotEmpty, isTrue);
        },
      );

      test(
        'Seed data does not overwrite existing data on restart/reinitialization',
        () async {
          // First initialization
          await mockApi.getRequests();

          // Add a new user request
          final created = await mockApi.createRequest(
            title: 'Custom Brand New Request',
            description: 'Custom description',
            status: RequestStatus.draft,
          );

          // Simulate app restart with a fresh MockApi instance on the same SharedPreferences
          final restartedApi = RequestMockApi(
            localDataSource: SharedPreferencesRequestDataSource(prefs),
            artificialDelay: Duration.zero,
            currentRoleOverride: UserRole.user,
          );

          final afterRestart = await restartedApi.getRequests();
          expect(afterRestart.length, 6);
          expect(afterRestart.any((r) => r.id == created.id), isTrue);
        },
      );

      test(
        'Updated status and rejection reason persist across reinitialization',
        () async {
          await mockApi.getRequests();

          // Submit REQ-1001 (draft)
          const draftId = 'f1a00001-0000-4000-8000-000000000001';
          final submitted = await mockApi.submitRequest(
            id: draftId,
            expectedVersion: 1,
          );
          expect(submitted.status, RequestStatus.submitted);
          expect(submitted.version, 2);

          // Reviewer rejects submitted request with reason
          mockApi.currentRoleOverride = UserRole.reviewer;
          final rejected = await mockApi.rejectRequest(
            id: draftId,
            rejectionReason: 'Not eligible at this time',
            expectedVersion: 2,
          );
          expect(rejected.status, RequestStatus.rejected);
          expect(rejected.rejectionReason, 'Not eligible at this time');
          expect(rejected.version, 3);

          // Create fresh instance to verify persistence in SharedPreferences
          final freshApi = RequestMockApi(
            localDataSource: SharedPreferencesRequestDataSource(prefs),
            artificialDelay: Duration.zero,
            currentRoleOverride: UserRole.reviewer,
          );

          final persistedReq = await freshApi.getRequestById(draftId);
          expect(persistedReq.status, RequestStatus.rejected);
          expect(persistedReq.rejectionReason, 'Not eligible at this time');
          expect(persistedReq.version, 3);
        },
      );

      test(
        'Corrupted storage produces meaningful recoverable AppException',
        () async {
          await prefs.setString(
            'rf_requests_data',
            'INVALID_JSON_CORRUPTED{{{',
          );

          await expectLater(
            () => mockApi.getRequests(),
            throwsA(
              predicate(
                (e) => e is AppException && e.code == 'CORRUPTED_STORAGE',
              ),
            ),
          );
        },
      );
    });

    // ---------------------------------------------------------
    // B. Workflow and Role Authorization
    // ---------------------------------------------------------
    group('B. Workflow and Role Authorization', () {
      test('User can create, update, and submit Draft requests', () async {
        mockApi.currentRoleOverride = UserRole.user;

        // Create Draft
        final created = await mockApi.createRequest(
          title: 'New Conference Budget',
          description: 'Flight and hotel expenses',
          status: RequestStatus.draft,
        );
        expect(created.status, RequestStatus.draft);
        expect(created.version, 1);

        // Update Draft
        final updated = await mockApi.updateRequest(
          id: created.id,
          title: 'New Conference Budget (Updated)',
          description: 'Updated hotel expenses',
          expectedVersion: 1,
        );
        expect(updated.title, 'New Conference Budget (Updated)');
        expect(updated.version, 2);

        // Submit Draft
        final submitted = await mockApi.submitRequest(
          id: created.id,
          expectedVersion: 2,
        );
        expect(submitted.status, RequestStatus.submitted);
        expect(submitted.version, 3);
      });

      test(
        'Reviewer can approve and reject Submitted requests with valid reason',
        () async {
          mockApi.currentRoleOverride = UserRole.user;
          final created = await mockApi.createRequest(
            title: 'Software Tool',
            description: 'IDE License',
            status: RequestStatus.draft,
          );
          await mockApi.submitRequest(id: created.id, expectedVersion: 1);

          // Switch to Reviewer
          mockApi.currentRoleOverride = UserRole.reviewer;

          // Approve
          final approved = await mockApi.approveRequest(
            id: created.id,
            expectedVersion: 2,
          );
          expect(approved.status, RequestStatus.approved);
          expect(approved.version, 3);

          // Test Reject on another submitted request (REQ-1002)
          const req1002Id = 'f1a00002-0000-4000-8000-000000000002';
          final rejected = await mockApi.rejectRequest(
            id: req1002Id,
            rejectionReason: 'Security approval denied',
            expectedVersion: 2,
          );
          expect(rejected.status, RequestStatus.rejected);
          expect(rejected.rejectionReason, 'Security approval denied');
          expect(rejected.version, 3);
        },
      );

      test(
        'Reviewer rejecting with empty or whitespace-only reason is rejected',
        () async {
          mockApi.currentRoleOverride = UserRole.reviewer;
          const req1002Id = 'f1a00002-0000-4000-8000-000000000002';

          await expectLater(
            () => mockApi.rejectRequest(
              id: req1002Id,
              rejectionReason: '   ',
              expectedVersion: 2,
            ),
            throwsA(
              predicate(
                (e) => e is AppException && e.code == 'VALIDATION_ERROR',
              ),
            ),
          );
        },
      );

      test('User role cannot approve or reject requests', () async {
        mockApi.currentRoleOverride = UserRole.user;
        const req1002Id = 'f1a00002-0000-4000-8000-000000000002';

        await expectLater(
          () => mockApi.approveRequest(id: req1002Id, expectedVersion: 2),
          throwsA(
            predicate(
              (e) => e is AppException && e.code == 'UNAUTHORIZED_ROLE',
            ),
          ),
        );

        await expectLater(
          () => mockApi.rejectRequest(
            id: req1002Id,
            rejectionReason: 'Denied by user',
            expectedVersion: 2,
          ),
          throwsA(
            predicate(
              (e) => e is AppException && e.code == 'UNAUTHORIZED_ROLE',
            ),
          ),
        );
      });

      test('Reviewer role cannot create, edit, or submit requests', () async {
        mockApi.currentRoleOverride = UserRole.reviewer;
        const req1001Id = 'f1a00001-0000-4000-8000-000000000001';

        await expectLater(
          () => mockApi.createRequest(
            title: 'Reviewer Created',
            description: 'Not allowed',
            status: RequestStatus.draft,
          ),
          throwsA(
            predicate(
              (e) => e is AppException && e.code == 'UNAUTHORIZED_ROLE',
            ),
          ),
        );

        await expectLater(
          () => mockApi.updateRequest(
            id: req1001Id,
            title: 'Reviewer Modified',
            description: 'Not allowed',
            expectedVersion: 1,
          ),
          throwsA(
            predicate(
              (e) => e is AppException && e.code == 'UNAUTHORIZED_ROLE',
            ),
          ),
        );

        await expectLater(
          () => mockApi.submitRequest(id: req1001Id, expectedVersion: 1),
          throwsA(
            predicate(
              (e) => e is AppException && e.code == 'UNAUTHORIZED_ROLE',
            ),
          ),
        );
      });

      test(
        'Final requests (Approved and Rejected) cannot be modified or re-transitioned',
        () async {
          const approvedId = 'f1a00003-0000-4000-8000-000000000003';
          const rejectedId = 'f1a00004-0000-4000-8000-000000000004';

          // User cannot edit approved
          mockApi.currentRoleOverride = UserRole.user;
          await expectLater(
            () => mockApi.updateRequest(
              id: approvedId,
              title: 'Edit Approved',
              description: 'Desc',
              expectedVersion: 3,
            ),
            throwsA(
              predicate((e) => e is AppException && e.code == 'INVALID_STATUS'),
            ),
          );

          // Reviewer cannot re-approve rejected
          mockApi.currentRoleOverride = UserRole.reviewer;
          await expectLater(
            () => mockApi.approveRequest(id: rejectedId, expectedVersion: 3),
            throwsA(
              predicate((e) => e is AppException && e.code == 'INVALID_STATUS'),
            ),
          );

          // Reviewer cannot reject approved
          await expectLater(
            () => mockApi.rejectRequest(
              id: approvedId,
              rejectionReason: 'Try reject approved',
              expectedVersion: 3,
            ),
            throwsA(
              predicate((e) => e is AppException && e.code == 'INVALID_STATUS'),
            ),
          );
        },
      );
    });

    // ---------------------------------------------------------
    // C. Optimistic Concurrency Control (Version Checking)
    // ---------------------------------------------------------
    group('C. Optimistic Concurrency Control', () {
      test('Successful update increments version by exactly 1', () async {
        mockApi.currentRoleOverride = UserRole.user;
        const draftId = 'f1a00001-0000-4000-8000-000000000001';

        final updated = await mockApi.updateRequest(
          id: draftId,
          title: 'REQ-1001: Leave Request (Edited)',
          description: 'Updated vacation dates',
          expectedVersion: 1,
        );
        expect(updated.version, 2);

        final submitted = await mockApi.submitRequest(
          id: draftId,
          expectedVersion: 2,
        );
        expect(submitted.version, 3);
      });

      test(
        'Stale expectedVersion is rejected with ConflictException',
        () async {
          mockApi.currentRoleOverride = UserRole.user;
          const draftId = 'f1a00001-0000-4000-8000-000000000001';

          // Provide stale version 99 instead of 1
          await expectLater(
            () => mockApi.updateRequest(
              id: draftId,
              title: 'Stale update',
              description: 'Desc',
              expectedVersion: 99,
            ),
            throwsA(isA<ConflictException>()),
          );

          // Verify version was NOT incremented in storage
          final current = await mockApi.getRequestById(draftId);
          expect(current.version, 1);
        },
      );

      test(
        'Failed update does not increment version or modify storage',
        () async {
          mockApi.currentRoleOverride = UserRole.user;
          const draftId = 'f1a00001-0000-4000-8000-000000000001';

          // Validation failure (title too short)
          await expectLater(
            () => mockApi.updateRequest(
              id: draftId,
              title: 'AB',
              description: 'Desc',
              expectedVersion: 1,
            ),
            throwsA(isA<AppException>()),
          );

          final unchanged = await mockApi.getRequestById(draftId);
          expect(unchanged.version, 1);
          expect(unchanged.title, 'REQ-1001: Leave Request');
        },
      );

      test(
        'Concurrent updates using the same expectedVersion cannot both succeed',
        () async {
          mockApi.currentRoleOverride = UserRole.user;
          const draftId = 'f1a00001-0000-4000-8000-000000000001';

          var successCount = 0;
          var conflictCount = 0;

          Future<void> attemptUpdate(String title) async {
            try {
              await mockApi.updateRequest(
                id: draftId,
                title: title,
                description: 'Concurrent description',
                expectedVersion: 1,
              );
              successCount++;
            } on ConflictException {
              conflictCount++;
            }
          }

          await Future.wait([
            attemptUpdate('Update from Client A'),
            attemptUpdate('Update from Client B'),
          ]);

          expect(
            successCount,
            1,
            reason: 'Exactly one concurrent update must succeed',
          );
          expect(
            conflictCount,
            1,
            reason: 'The other concurrent update must throw ConflictException',
          );

          // Storage version should be 2
          final current = await mockApi.getRequestById(draftId);
          expect(current.version, 2);
        },
      );
    });

    // ---------------------------------------------------------
    // D. Failure Handling & Recovery
    // ---------------------------------------------------------
    group('D. Failure Handling and Recovery', () {
      test(
        'Simulated API failure throws SIMULATED_NETWORK_FAILURE exception',
        () async {
          mockApi.failureSimulationOverride = true;

          await expectLater(
            () => mockApi.getRequests(),
            throwsA(
              predicate(
                (e) =>
                    e is AppException && e.code == 'SIMULATED_NETWORK_FAILURE',
              ),
            ),
          );
        },
      );

      test(
        'Failed operations do not persist partial changes or increment version',
        () async {
          mockApi.currentRoleOverride = UserRole.user;
          const draftId = 'f1a00001-0000-4000-8000-000000000001';

          // Enable failure simulation
          mockApi.failureSimulationOverride = true;

          await expectLater(
            () => mockApi.submitRequest(id: draftId, expectedVersion: 1),
            throwsA(
              predicate(
                (e) =>
                    e is AppException && e.code == 'SIMULATED_NETWORK_FAILURE',
              ),
            ),
          );

          // Disable failure simulation and check request is untouched
          mockApi.failureSimulationOverride = false;
          final current = await mockApi.getRequestById(draftId);
          expect(current.status, RequestStatus.draft);
          expect(current.version, 1);
        },
      );

      test('Retrying after disabling failure simulation succeeds', () async {
        mockApi.currentRoleOverride = UserRole.user;
        const draftId = 'f1a00001-0000-4000-8000-000000000001';

        // 1. First attempt fails due to simulated failure
        mockApi.failureSimulationOverride = true;
        await expectLater(
          () => mockApi.submitRequest(id: draftId, expectedVersion: 1),
          throwsA(
            predicate(
              (e) => e is AppException && e.code == 'SIMULATED_NETWORK_FAILURE',
            ),
          ),
        );

        // 2. Retry with failure simulation disabled
        mockApi.failureSimulationOverride = false;
        final submitted = await mockApi.submitRequest(
          id: draftId,
          expectedVersion: 1,
        );
        expect(submitted.status, RequestStatus.submitted);
        expect(submitted.version, 2);
      });
    });

    // ---------------------------------------------------------
    // H. Genuine Persisted Activity History
    // ---------------------------------------------------------
    group('H. Genuine Persisted Activity History', () {
      test('Seed requests have no fabricated activity history', () async {
        const seedId = 'f1a00001-0000-4000-8000-000000000001';
        final activities = await mockApi.getRequestActivities(seedId);
        expect(activities, isEmpty);
      });

      test('createRequest logs genuine created activity', () async {
        mockApi.currentRoleOverride = UserRole.user;
        final req = await mockApi.createRequest(
          title: 'Activity Test',
          description: 'Testing activity persistence',
          status: RequestStatus.draft,
        );

        final activities = await mockApi.getRequestActivities(req.id);
        expect(activities.length, 1);
        expect(activities.first.eventType, RequestActivityType.created);
        expect(activities.first.actorRole, UserRole.user);
        expect(activities.first.requestId, req.id);
      });

      test('Full lifecycle logs chronological activities with roles', () async {
        mockApi.currentRoleOverride = UserRole.user;
        final req = await mockApi.createRequest(
          title: 'Full Lifecycle',
          description: 'Testing full activity log',
          status: RequestStatus.draft,
        );

        final edited = await mockApi.updateRequest(
          id: req.id,
          title: 'Full Lifecycle Edited',
          description: 'Updated description',
          expectedVersion: req.version,
        );

        final submitted = await mockApi.submitRequest(
          id: req.id,
          expectedVersion: edited.version,
        );

        mockApi.currentRoleOverride = UserRole.reviewer;
        await mockApi.approveRequest(
          id: req.id,
          expectedVersion: submitted.version,
        );

        final activities = await mockApi.getRequestActivities(req.id);
        expect(activities.length, 4);
        expect(activities[0].eventType, RequestActivityType.created);
        expect(activities[0].actorRole, UserRole.user);
        expect(activities[1].eventType, RequestActivityType.edited);
        expect(activities[1].actorRole, UserRole.user);
        expect(activities[2].eventType, RequestActivityType.submitted);
        expect(activities[2].actorRole, UserRole.user);
        expect(activities[3].eventType, RequestActivityType.approved);
        expect(activities[3].actorRole, UserRole.reviewer);
      });

      test(
        'Failed or stale operations do NOT create activity records',
        () async {
          mockApi.currentRoleOverride = UserRole.user;
          final req = await mockApi.createRequest(
            title: 'Conflict Activity Test',
            description: 'Testing conflict does not create activity',
            status: RequestStatus.draft,
          );

          // Attempt update with wrong version
          await expectLater(
            () => mockApi.updateRequest(
              id: req.id,
              title: 'Stale Edit',
              description: 'Stale description',
              expectedVersion: 999,
            ),
            throwsA(isA<ConflictException>()),
          );

          // Only the initial create activity should exist
          final activities = await mockApi.getRequestActivities(req.id);
          expect(activities.length, 1);
          expect(activities.first.eventType, RequestActivityType.created);
        },
      );
    });
  });
}
