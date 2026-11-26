import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:request_flow/core/errors/app_exception.dart';
import 'package:request_flow/features/requests/data/datasources/request_local_datasource.dart';
import 'package:request_flow/features/requests/data/datasources/request_mock_api.dart';
import 'package:request_flow/features/requests/data/datasources/shared_preferences_request_datasource.dart';
import 'package:request_flow/features/requests/data/repositories/request_repository_impl.dart';
import 'package:request_flow/features/requests/domain/entities/request_activity.dart';
import 'package:request_flow/features/requests/domain/entities/request_status.dart';
import 'package:request_flow/features/requests/domain/repositories/request_repository.dart';
import 'package:request_flow/features/requests/presentation/cubit/request_form_cubit.dart';
import 'package:request_flow/features/requests/presentation/cubit/request_form_state.dart';
import 'package:request_flow/features/requests/presentation/cubit/request_list_cubit.dart';
import 'package:request_flow/features/requests/presentation/screens/create_request_screen.dart';
import 'package:request_flow/features/requests/presentation/utils/unsaved_draft_store.dart';
import 'package:request_flow/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:request_flow/features/settings/domain/entities/user_role.dart';
import 'package:request_flow/features/settings/domain/repositories/settings_repository.dart';
import 'package:request_flow/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:request_flow/injection/dependency_injection.dart';

void main() {
  group('3. Failure and Retry Lifecycle Tests', () {
    late SharedPreferences prefs;
    late SharedPreferencesRequestDataSource localDataSource;
    late RequestMockApi mockApi;
    late RequestRepositoryImpl repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      localDataSource = SharedPreferencesRequestDataSource(prefs);
      await localDataSource.setInitialized();
      mockApi = RequestMockApi(
        localDataSource: localDataSource,
        artificialDelay: Duration.zero,
        currentRoleOverride: UserRole.user,
      );
      repository = RequestRepositoryImpl(mockApi: mockApi);
    });

    test(
      'Simulated API failure is thrown as an AppException and leaves storage clean',
      () async {
        mockApi.failureSimulationOverride = true;

        expect(
          () => mockApi.getRequests(),
          throwsA(
            isA<AppException>().having(
              (e) => e.code,
              'code',
              'SIMULATED_NETWORK_FAILURE',
            ),
          ),
        );

        final storedRequests = await localDataSource.getRequests();
        expect(storedRequests, isEmpty);
      },
    );

    group('Operation 1: Create Request / Create Draft failure and retry', () {
      test(
        'Failure returns error, leaves storage clean, and retry succeeds with 1 request and 1 activity',
        () async {
          mockApi.failureSimulationOverride = true;

          // Attempt creation while failure simulation is enabled
          await expectLater(
            () => repository.createRequest(
              title: 'Equipment Request',
              description: 'Request for keyboard and monitor',
              status: RequestStatus.draft,
            ),
            throwsA(
              isA<AppException>().having(
                (e) => e.code,
                'code',
                'SIMULATED_NETWORK_FAILURE',
              ),
            ),
          );

          // Verify storage unchanged
          final requestsAfterFail = await localDataSource.getRequests();
          expect(requestsAfterFail, isEmpty);

          // Clear failure simulation and retry
          mockApi.failureSimulationOverride = false;
          final created = await repository.createRequest(
            title: 'Equipment Request',
            description: 'Request for keyboard and monitor',
            status: RequestStatus.draft,
          );

          expect(created.title, 'Equipment Request');
          expect(created.version, 1);

          // Verify exactly 1 request in storage
          final requestsAfterRetry = await localDataSource.getRequests();
          expect(requestsAfterRetry.length, 1);
          expect(requestsAfterRetry.first.id, created.id);

          // Verify exactly 1 activity logged
          final activities = await localDataSource.getActivities(created.id);
          expect(activities.length, 1);
          expect(activities.first.eventType, RequestActivityType.created);
        },
      );

      test(
        'RequestFormCubit preserves form input values across submission failure and emits RequestFormError',
        () async {
          final formCubit = RequestFormCubit(repository);
          mockApi.failureSimulationOverride = true;

          const inputTitle = 'Preserved Form Title';
          const inputDesc =
              'Preserved description text across network failure.';

          await formCubit.createDraft(
            title: inputTitle,
            description: inputDesc,
          );

          expect(formCubit.state, isA<RequestFormError>());
          final errorState = formCubit.state as RequestFormError;
          expect(errorState.message, contains('Simulated API network error'));
          expect(errorState.isConflict, isFalse);

          // Form state emits error without clearing user controller values; retry with same input
          mockApi.failureSimulationOverride = false;
          await formCubit.createDraft(
            title: inputTitle,
            description: inputDesc,
          );

          expect(formCubit.state, isA<RequestFormSuccess>());
          final successState = formCubit.state as RequestFormSuccess;
          expect(successState.request.title, inputTitle);
          expect(successState.request.description, inputDesc);

          await formCubit.close();
        },
      );
    });

    group('Operation 2: Update Request / Update Draft failure and retry', () {
      test(
        'Failure leaves original request and activity log unchanged; retry increments version once',
        () async {
          // Initial setup: valid draft
          final created = await repository.createRequest(
            title: 'Initial Title',
            description: 'Initial Description',
            status: RequestStatus.draft,
          );
          expect(created.version, 1);

          final initialActivities = await localDataSource.getActivities(
            created.id,
          );
          expect(initialActivities.length, 1);

          // Enable failure simulation
          mockApi.failureSimulationOverride = true;

          await expectLater(
            () => repository.updateRequest(
              id: created.id,
              title: 'Updated Title Attempt 1',
              description: 'Updated Description Attempt 1',
              expectedVersion: 1,
            ),
            throwsA(
              isA<AppException>().having(
                (e) => e.code,
                'code',
                'SIMULATED_NETWORK_FAILURE',
              ),
            ),
          );

          // Verify request not modified
          final storedAfterFail = await localDataSource.getRequestById(
            created.id,
          );
          expect(storedAfterFail!.title, 'Initial Title');
          expect(storedAfterFail.version, 1);

          // Verify no false activity entry created
          final activitiesAfterFail = await localDataSource.getActivities(
            created.id,
          );
          expect(activitiesAfterFail.length, 1);

          // Clear failure and retry update
          mockApi.failureSimulationOverride = false;
          final updated = await repository.updateRequest(
            id: created.id,
            title: 'Updated Title Success',
            description: 'Updated Description Success',
            expectedVersion: 1,
          );

          expect(updated.title, 'Updated Title Success');
          expect(updated.version, 2);

          // Verify storage and activities
          final storedFinal = await localDataSource.getRequestById(created.id);
          expect(storedFinal!.version, 2);
          expect(storedFinal.title, 'Updated Title Success');

          final finalActivities = await localDataSource.getActivities(
            created.id,
          );
          expect(finalActivities.length, 2); // 1 created + 1 edited
          expect(finalActivities.last.eventType, RequestActivityType.edited);
        },
      );
    });

    group('Operation 3: Submit Request failure and retry', () {
      test(
        'Failure does not change status to submitted; retry succeeds with status=submitted and v2',
        () async {
          final created = await repository.createRequest(
            title: 'Draft to Submit',
            description: 'Ready to submit',
            status: RequestStatus.draft,
          );
          expect(created.status, RequestStatus.draft);
          expect(created.version, 1);

          // Enable failure
          mockApi.failureSimulationOverride = true;

          await expectLater(
            () => repository.submitRequest(id: created.id, expectedVersion: 1),
            throwsA(
              isA<AppException>().having(
                (e) => e.code,
                'code',
                'SIMULATED_NETWORK_FAILURE',
              ),
            ),
          );

          // Verify status remains draft
          final storedAfterFail = await localDataSource.getRequestById(
            created.id,
          );
          expect(storedAfterFail!.status, RequestStatus.draft);
          expect(storedAfterFail.version, 1);

          final activitiesAfterFail = await localDataSource.getActivities(
            created.id,
          );
          expect(activitiesAfterFail.length, 1);

          // Clear failure and retry submit
          mockApi.failureSimulationOverride = false;
          final submitted = await repository.submitRequest(
            id: created.id,
            expectedVersion: 1,
          );

          expect(submitted.status, RequestStatus.submitted);
          expect(submitted.version, 2);

          final storedFinal = await localDataSource.getRequestById(created.id);
          expect(storedFinal!.status, RequestStatus.submitted);
          expect(storedFinal.version, 2);

          final finalActivities = await localDataSource.getActivities(
            created.id,
          );
          expect(finalActivities.length, 2); // 1 created + 1 submitted
          expect(finalActivities.last.eventType, RequestActivityType.submitted);
        },
      );
    });

    group('Operation 4: Approve Request failure and retry', () {
      test(
        'Failure does not approve request; retry as Reviewer succeeds with status=approved and v3',
        () async {
          // User creates and submits request
          final created = await repository.createRequest(
            title: 'Purchase Order',
            description: 'Server hardware purchase',
            status: RequestStatus.draft,
          );
          final submitted = await repository.submitRequest(
            id: created.id,
            expectedVersion: 1,
          );
          expect(submitted.status, RequestStatus.submitted);
          expect(submitted.version, 2);

          // Switch to Reviewer role
          mockApi.currentRoleOverride = UserRole.reviewer;

          // Simulate failure on approval
          mockApi.failureSimulationOverride = true;

          await expectLater(
            () =>
                repository.approveRequest(id: submitted.id, expectedVersion: 2),
            throwsA(
              isA<AppException>().having(
                (e) => e.code,
                'code',
                'SIMULATED_NETWORK_FAILURE',
              ),
            ),
          );

          // Verify request still submitted and version unchanged
          final storedAfterFail = await localDataSource.getRequestById(
            submitted.id,
          );
          expect(storedAfterFail!.status, RequestStatus.submitted);
          expect(storedAfterFail.version, 2);

          final activitiesAfterFail = await localDataSource.getActivities(
            submitted.id,
          );
          expect(activitiesAfterFail.length, 2); // created + submitted only

          // Disable failure and retry approve
          mockApi.failureSimulationOverride = false;
          final approved = await repository.approveRequest(
            id: submitted.id,
            expectedVersion: 2,
          );

          expect(approved.status, RequestStatus.approved);
          expect(approved.version, 3);

          final storedFinal = await localDataSource.getRequestById(
            submitted.id,
          );
          expect(storedFinal!.status, RequestStatus.approved);
          expect(storedFinal.version, 3);

          final finalActivities = await localDataSource.getActivities(
            submitted.id,
          );
          expect(finalActivities.length, 3); // created + submitted + approved
          expect(finalActivities.last.eventType, RequestActivityType.approved);
        },
      );
    });

    group('Operation 5: Reject Request failure and retry', () {
      test(
        'Failure does not reject request or store reason; retry populates reason and sets status=rejected',
        () async {
          // User creates and submits request
          final created = await repository.createRequest(
            title: 'Budget Extension',
            description: 'Requesting supplementary project funds',
            status: RequestStatus.draft,
          );
          final submitted = await repository.submitRequest(
            id: created.id,
            expectedVersion: 1,
          );
          expect(submitted.status, RequestStatus.submitted);
          expect(submitted.version, 2);

          // Switch to Reviewer role
          mockApi.currentRoleOverride = UserRole.reviewer;

          // Simulate failure
          mockApi.failureSimulationOverride = true;

          await expectLater(
            () => repository.rejectRequest(
              id: submitted.id,
              rejectionReason: 'Exceeds budget cap for current quarter',
              expectedVersion: 2,
            ),
            throwsA(
              isA<AppException>().having(
                (e) => e.code,
                'code',
                'SIMULATED_NETWORK_FAILURE',
              ),
            ),
          );

          // Verify request still submitted, no rejection reason, version 2
          final storedAfterFail = await localDataSource.getRequestById(
            submitted.id,
          );
          expect(storedAfterFail!.status, RequestStatus.submitted);
          expect(storedAfterFail.rejectionReason, isNull);
          expect(storedAfterFail.version, 2);

          final activitiesAfterFail = await localDataSource.getActivities(
            submitted.id,
          );
          expect(activitiesAfterFail.length, 2);

          // Clear failure and retry reject
          mockApi.failureSimulationOverride = false;
          final rejected = await repository.rejectRequest(
            id: submitted.id,
            rejectionReason: 'Exceeds budget cap for current quarter',
            expectedVersion: 2,
          );

          expect(rejected.status, RequestStatus.rejected);
          expect(rejected.version, 3);
          expect(
            rejected.rejectionReason,
            'Exceeds budget cap for current quarter',
          );

          final storedFinal = await localDataSource.getRequestById(
            submitted.id,
          );
          expect(storedFinal!.status, RequestStatus.rejected);
          expect(
            storedFinal.rejectionReason,
            'Exceeds budget cap for current quarter',
          );
          expect(storedFinal.version, 3);

          final finalActivities = await localDataSource.getActivities(
            submitted.id,
          );
          expect(finalActivities.length, 3); // created + submitted + rejected
          expect(finalActivities.last.eventType, RequestActivityType.rejected);
          expect(
            finalActivities.last.description,
            contains('Exceeds budget cap for current quarter'),
          );
        },
      );
    });

    group(
      'Operation 6: Complete UI Failure -> Navigation to Settings -> Recovery and Retry Workflow',
      () {
        test(
          'UnsavedDraftStore saves input, preserves across re-entry, and clears upon success',
          () async {
            UnsavedDraftStore.clearDraft();
            expect(UnsavedDraftStore.getSavedTitle(), isEmpty);
            expect(UnsavedDraftStore.getSavedDescription(), isEmpty);

            UnsavedDraftStore.saveDraft(
              'Preserved Title',
              'Preserved Description',
            );
            expect(UnsavedDraftStore.getSavedTitle(), 'Preserved Title');
            expect(
              UnsavedDraftStore.getSavedDescription(),
              'Preserved Description',
            );

            UnsavedDraftStore.clearDraft();
            expect(UnsavedDraftStore.getSavedTitle(), isEmpty);
            expect(UnsavedDraftStore.getSavedDescription(), isEmpty);
          },
        );

        testWidgets(
          'CreateRequestScreen preserves input after failure, retains data when navigating to settings and back, and succeeds on retry',
          (tester) async {
            UnsavedDraftStore.clearDraft();
            await initDependencies(mockApiDelay: Duration.zero);
            final settingsLocalDataSource = sl<SettingsLocalDataSource>();
            await settingsLocalDataSource.setSimulateApiFailure(true);

            final requestRepo = sl<RequestRepository>();
            final requestListCubit = RequestListCubit(requestRepo);
            final settingsCubit = SettingsCubit(sl<SettingsRepository>());

            final router = GoRouter(
              initialLocation: '/requests/create',
              routes: [
                GoRoute(
                  path: '/requests/create',
                  builder: (context, state) => const CreateRequestScreen(),
                ),
                GoRoute(
                  path: '/settings',
                  builder: (context, state) => Scaffold(
                    body: Center(
                      child: ElevatedButton(
                        onPressed: () async {
                          await settingsCubit.setSimulateApiFailure(false);
                          await settingsLocalDataSource.setSimulateApiFailure(
                            false,
                          );
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/requests/create');
                          }
                        },
                        child: const Text('Disable Failure and Return'),
                      ),
                    ),
                  ),
                ),
                GoRoute(
                  path: '/requests/:id',
                  builder: (context, state) =>
                      const Scaffold(body: Text('Request Details Destination')),
                ),
                GoRoute(
                  path: '/requests',
                  builder: (context, state) =>
                      const Scaffold(body: Text('Requests List')),
                ),
              ],
            );

            await tester.pumpWidget(
              MultiBlocProvider(
                providers: [
                  BlocProvider<RequestListCubit>.value(value: requestListCubit),
                  BlocProvider<SettingsCubit>.value(value: settingsCubit),
                ],
                child: MaterialApp.router(routerConfig: router),
              ),
            );
            await tester.pumpAndSettle();

            // 1. Enter title and description
            final titleField = find.byType(TextFormField).first;
            final descField = find.byType(TextFormField).last;
            await tester.enterText(titleField, 'New Purchase Request');
            await tester.enterText(
              descField,
              'Urgent equipment needed for deployment',
            );
            await tester.pumpAndSettle();

            // 2. Click Save as Draft while Failure Simulation is ON
            final saveButton = find.widgetWithText(
              ElevatedButton,
              'Save as Draft',
            );
            await tester.tap(saveButton);
            await tester.pumpAndSettle();

            // 3. Verify Mock API failed: recovery guide shown, storage clean, 0 requests, 0 activities
            expect(find.text('API Failure Simulation is ON'), findsWidgets);
            expect(
              find.textContaining(
                'Your request could not be saved. Follow these steps to retry:',
              ),
              findsWidgets,
            );
            expect(
              find.text('Open Settings using the button provided.'),
              findsWidgets,
            );
            expect(find.text('Turn OFF API Failure Simulation.'), findsWidgets);
            expect(
              find.text('Return to the Create Request screen.'),
              findsWidgets,
            );
            expect(
              find.text(
                'Click Save as Draft again to submit your request successfully.',
              ),
              findsWidgets,
            );
            expect(
              find.byKey(const ValueKey('dialog_go_to_settings_button')),
              findsOneWidget,
            );

            final localDs = sl<RequestLocalDataSource>();
            final storedRequestsAfterFail = await localDs.getRequests();
            expect(storedRequestsAfterFail, isEmpty);

            // 4. Verify form inputs are preserved on screen
            expect(find.text('New Purchase Request'), findsOneWidget);
            expect(
              find.text('Urgent equipment needed for deployment'),
              findsOneWidget,
            );

            // 5. Navigate to Settings using the dialog's 'Go to Settings' button
            await tester.tap(
              find.byKey(const ValueKey('dialog_go_to_settings_button')),
            );
            await tester.pumpAndSettle();

            expect(find.text('Disable Failure and Return'), findsOneWidget);

            // 6. Disable failure and return to CreateRequestScreen
            await tester.tap(find.text('Disable Failure and Return'));
            await tester.pumpAndSettle();

            // 7. Verify returning to CreateRequestScreen still has the title and description
            expect(find.text('New Purchase Request'), findsOneWidget);
            expect(
              find.text('Urgent equipment needed for deployment'),
              findsOneWidget,
            );

            // 8. Dismiss any lingering snackbars and Click Save as Draft again
            ScaffoldMessenger.of(
              tester.element(find.byType(CreateRequestScreen)),
            ).clearSnackBars();
            await tester.pumpAndSettle();

            await tester.tap(
              find.widgetWithText(ElevatedButton, 'Save as Draft'),
            );
            await tester.pumpAndSettle();

            // 9. Verify success: navigated to request details, exactly 1 request created, 1 activity, version 1
            expect(find.text('Request Details Destination'), findsOneWidget);

            final storedRequestsFinal = await localDs.getRequests();
            expect(storedRequestsFinal.length, 1);
            expect(storedRequestsFinal.first.title, 'New Purchase Request');
            expect(storedRequestsFinal.first.version, 1);

            final activitiesFinal = await localDs.getActivities(
              storedRequestsFinal.first.id,
            );
            expect(activitiesFinal.length, 1);
            expect(
              activitiesFinal.first.eventType,
              RequestActivityType.created,
            );

            // 10. Verify unsaved draft is cleared
            expect(UnsavedDraftStore.getSavedTitle(), isEmpty);
            expect(UnsavedDraftStore.getSavedDescription(), isEmpty);
          },
        );
      },
    );
  });
}
