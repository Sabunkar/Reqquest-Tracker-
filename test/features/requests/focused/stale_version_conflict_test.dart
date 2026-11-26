import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:request_flow/core/errors/conflict_exception.dart';
import 'package:request_flow/features/requests/data/datasources/request_mock_api.dart';
import 'package:request_flow/features/requests/data/datasources/shared_preferences_request_datasource.dart';
import 'package:request_flow/features/requests/data/repositories/request_repository_impl.dart';
import 'package:request_flow/features/requests/domain/entities/request_status.dart';
import 'package:request_flow/features/requests/presentation/cubit/request_detail_cubit.dart';
import 'package:request_flow/features/requests/presentation/cubit/request_detail_state.dart';
import 'package:request_flow/features/requests/presentation/cubit/request_form_cubit.dart';
import 'package:request_flow/features/requests/presentation/cubit/request_form_state.dart';
import 'package:request_flow/features/settings/domain/entities/user_role.dart';

void main() {
  group('4. Stale-Version Conflict and Optimistic Concurrency Tests', () {
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
      'Updating with current expected version succeeds and increments version exactly once',
      () async {
        final created = await repository.createRequest(
          title: 'Concurrent Request Alpha',
          description: 'Testing expected version match',
          status: RequestStatus.draft,
        );
        expect(created.version, 1);

        final updated = await repository.updateRequest(
          id: created.id,
          title: 'Concurrent Request Alpha (v2)',
          description: 'Testing expected version match updated',
          expectedVersion: 1, // matches current version
        );

        expect(updated.version, 2);
        expect(updated.title, 'Concurrent Request Alpha (v2)');

        final stored = await localDataSource.getRequestById(created.id);
        expect(stored!.version, 2);
      },
    );

    test(
      'Updating with outdated expected version throws ConflictException and does NOT overwrite stored request',
      () async {
        // 1. Initial draft at version 1
        final created = await repository.createRequest(
          title: 'Original Title',
          description: 'Original Description',
          status: RequestStatus.draft,
        );
        expect(created.version, 1);

        // 2. Client A updates request to version 2
        final updatedByA = await repository.updateRequest(
          id: created.id,
          title: 'Updated by Client A',
          description: 'Client A Description',
          expectedVersion: 1,
        );
        expect(updatedByA.version, 2);

        // 3. Client B attempts update using stale version 1
        expect(
          () => repository.updateRequest(
            id: created.id,
            title: 'Stale Update by Client B',
            description: 'Client B Description',
            expectedVersion: 1, // Stale! Current is 2
          ),
          throwsA(
            isA<ConflictException>()
                .having((e) => e.expectedVersion, 'expectedVersion', 1)
                .having((e) => e.actualVersion, 'actualVersion', 2),
          ),
        );

        // 4. Verify that stored request retains Client A changes and version 2
        final storedAfterConflict = await localDataSource.getRequestById(
          created.id,
        );
        expect(storedAfterConflict!.version, 2);
        expect(storedAfterConflict.title, 'Updated by Client A');
        expect(storedAfterConflict.description, 'Client A Description');
      },
    );

    test(
      'submitRequest with outdated expected version throws ConflictException without changing status',
      () async {
        final created = await repository.createRequest(
          title: 'Draft Request',
          description: 'Ready to submit',
          status: RequestStatus.draft,
        );

        // Draft updated to version 2 first
        await repository.updateRequest(
          id: created.id,
          title: 'Draft Request (Edited)',
          description: 'Ready to submit (Edited)',
          expectedVersion: 1,
        );

        // Submit attempted with stale version 1
        expect(
          () => repository.submitRequest(
            id: created.id,
            expectedVersion: 1, // Stale! Current is 2
          ),
          throwsA(
            isA<ConflictException>()
                .having((e) => e.expectedVersion, 'expectedVersion', 1)
                .having((e) => e.actualVersion, 'actualVersion', 2),
          ),
        );

        // Verify request is still in draft status at version 2
        final stored = await localDataSource.getRequestById(created.id);
        expect(stored!.status, RequestStatus.draft);
        expect(stored.version, 2);
      },
    );

    test(
      'approveRequest with outdated expected version throws ConflictException without approving',
      () async {
        final created = await repository.createRequest(
          title: 'Draft for Review',
          description: 'Review description',
          status: RequestStatus.draft,
        );
        final submitted = await repository.submitRequest(
          id: created.id,
          expectedVersion: 1,
        );
        expect(submitted.version, 2);

        // Switch to Reviewer
        mockApi.currentRoleOverride = UserRole.reviewer;

        // Reviewer attempts approval with stale version 1
        expect(
          () => repository.approveRequest(
            id: submitted.id,
            expectedVersion: 1, // Stale! Current is 2
          ),
          throwsA(
            isA<ConflictException>()
                .having((e) => e.expectedVersion, 'expectedVersion', 1)
                .having((e) => e.actualVersion, 'actualVersion', 2),
          ),
        );

        // Status remains submitted
        final stored = await localDataSource.getRequestById(submitted.id);
        expect(stored!.status, RequestStatus.submitted);
        expect(stored.version, 2);
      },
    );

    test(
      'rejectRequest with outdated expected version throws ConflictException without rejecting',
      () async {
        final created = await repository.createRequest(
          title: 'Draft for Rejection Review',
          description: 'Review description',
          status: RequestStatus.draft,
        );
        final submitted = await repository.submitRequest(
          id: created.id,
          expectedVersion: 1,
        );
        expect(submitted.version, 2);

        // Switch to Reviewer
        mockApi.currentRoleOverride = UserRole.reviewer;

        // Reviewer attempts rejection with stale version 1
        expect(
          () => repository.rejectRequest(
            id: submitted.id,
            rejectionReason: 'Invalid reason',
            expectedVersion: 1, // Stale! Current is 2
          ),
          throwsA(
            isA<ConflictException>()
                .having((e) => e.expectedVersion, 'expectedVersion', 1)
                .having((e) => e.actualVersion, 'actualVersion', 2),
          ),
        );

        // Status remains submitted
        final stored = await localDataSource.getRequestById(submitted.id);
        expect(stored!.status, RequestStatus.submitted);
        expect(stored.version, 2);
        expect(stored.rejectionReason, isNull);
      },
    );

    test(
      'RequestFormCubit handles ConflictException: exposes latest server data, preserves unsaved user input, and supports Reload vs Reapply',
      () async {
        final formCubit = RequestFormCubit(repository);

        // 1. Initial draft created
        final initialDraft = await repository.createRequest(
          title: 'Original Form Title',
          description: 'Original Form Description',
          status: RequestStatus.draft,
        );
        expect(initialDraft.version, 1);

        // 2. Out-of-band update occurs on the server/other client
        final concurrentUpdate = await repository.updateRequest(
          id: initialDraft.id,
          title: 'Updated on Server by Team Member',
          description: 'Updated server description',
          expectedVersion: 1,
        );
        expect(concurrentUpdate.version, 2);

        // 3. User tries to submit their changes with outdated version 1
        const unsavedUserTitle = 'My Custom Local Title Edit';
        const unsavedUserDesc = 'My Custom Local Description Edit';

        await formCubit.updateDraft(
          id: initialDraft.id,
          title: unsavedUserTitle,
          description: unsavedUserDesc,
          expectedVersion: 1, // Outdated version
        );

        // 4. Verify cubit emits RequestFormError with isConflict=true and latestRequest attached
        expect(formCubit.state, isA<RequestFormError>());
        final conflictState = formCubit.state as RequestFormError;
        expect(conflictState.isConflict, isTrue);
        expect(conflictState.latestRequest, isNotNull);
        expect(conflictState.latestRequest!.version, 2);
        expect(
          conflictState.latestRequest!.title,
          'Updated on Server by Team Member',
        );

        // 5. Test "Reload Latest Data" workflow:
        // Invoking loadRequestForEdit loads the latest server request (v2) into form state
        await formCubit.loadRequestForEdit(initialDraft.id);
        expect(formCubit.state, isA<RequestFormLoadedForEdit>());
        final loadedState = formCubit.state as RequestFormLoadedForEdit;
        expect(loadedState.request.version, 2);
        expect(loadedState.request.title, 'Updated on Server by Team Member');

        // 6. Test "Reapply My Changes" workflow:
        // User reapplies their unsaved input using the latest version (v2)
        await formCubit.updateDraft(
          id: initialDraft.id,
          title: unsavedUserTitle,
          description: unsavedUserDesc,
          expectedVersion: loadedState.request.version, // Now uses 2
        );

        expect(formCubit.state, isA<RequestFormSuccess>());
        final reapplySuccess = formCubit.state as RequestFormSuccess;
        expect(reapplySuccess.request.version, 3);
        expect(reapplySuccess.request.title, unsavedUserTitle);
        expect(reapplySuccess.request.description, unsavedUserDesc);

        // Verify in storage
        final finalStored = await localDataSource.getRequestById(
          initialDraft.id,
        );
        expect(finalStored!.version, 3);
        expect(finalStored.title, unsavedUserTitle);

        await formCubit.close();
      },
    );

    test(
      'RequestDetailCubit handles ConflictException: emits isConflict=true and provides latest server state',
      () async {
        final detailCubit = RequestDetailCubit(repository);

        // Create draft and load it into detail cubit
        final draft = await repository.createRequest(
          title: 'Detail Review Item',
          description: 'Detail description',
          status: RequestStatus.draft,
        );
        await detailCubit.loadRequest(draft.id);
        expect(detailCubit.state, isA<RequestDetailLoaded>());

        // Concurrently update draft to version 2
        await repository.updateRequest(
          id: draft.id,
          title: 'Concurrent Item v2',
          description: 'Concurrent description v2',
          expectedVersion: 1,
        );

        // Attempt to submit via detail cubit with stale version 1
        await detailCubit.submitRequest(draft.id, 1);

        expect(detailCubit.state, isA<RequestDetailError>());
        final errorState = detailCubit.state as RequestDetailError;
        expect(errorState.isConflict, isTrue);
        expect(errorState.latestRequest, isNotNull);
        expect(errorState.latestRequest!.version, 2);
        expect(errorState.latestRequest!.title, 'Concurrent Item v2');

        await detailCubit.close();
      },
    );
  });
}
