import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:request_flow/features/requests/domain/entities/request.dart';
import 'package:request_flow/features/requests/domain/entities/request_status.dart';
import 'package:request_flow/features/requests/domain/repositories/request_repository.dart';
import 'package:request_flow/features/requests/presentation/cubit/request_form_cubit.dart';
import 'package:request_flow/features/requests/presentation/cubit/request_form_state.dart';

class MockRequestRepository extends Mock implements RequestRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(RequestStatus.draft);
  });

  group('RequestFormCubit Tests', () {
    late MockRequestRepository mockRepo;
    late RequestFormCubit cubit;

    setUp(() {
      mockRepo = MockRequestRepository();
      cubit = RequestFormCubit(mockRepo);
    });

    tearDown(() {
      cubit.close();
    });

    final now = DateTime.now();
    final draftRequest = Request(
      id: 'draft-101',
      title: 'Valid Draft Title',
      description: 'Valid description for draft',
      status: RequestStatus.draft,
      createdAt: now,
      updatedAt: now,
      version: 1,
    );

    test('initial state is RequestFormInitial', () {
      expect(cubit.state, const RequestFormInitial());
    });

    blocTest<RequestFormCubit, RequestFormState>(
      'emits RequestFormError on invalid title',
      build: () => cubit,
      act: (cubit) => cubit.createDraft(title: 'AB', description: 'Desc'),
      expect: () => [
        isA<RequestFormError>().having(
          (s) => s.fieldErrors?['title'],
          'title error',
          'Title must be at least 3 characters',
        ),
      ],
    );

    blocTest<RequestFormCubit, RequestFormState>(
      'emits [RequestFormSubmitting, RequestFormSuccess] on valid createDraft',
      build: () {
        when(
          () => mockRepo.createRequest(
            title: any(named: 'title'),
            description: any(named: 'description'),
            status: any(named: 'status'),
          ),
        ).thenAnswer((_) async => draftRequest);
        return cubit;
      },
      act: (cubit) => cubit.createDraft(
        title: 'Valid Draft Title',
        description: 'Valid description',
      ),
      expect: () => [
        const RequestFormSubmitting(),
        RequestFormSuccess(draftRequest, isEdit: false),
      ],
    );

    blocTest<RequestFormCubit, RequestFormState>(
      'loads request for edit successfully when status is draft',
      build: () {
        when(
          () => mockRepo.getRequestById('draft-101'),
        ).thenAnswer((_) async => draftRequest);
        return cubit;
      },
      act: (cubit) => cubit.loadRequestForEdit('draft-101'),
      expect: () => [
        const RequestFormLoadingEdit(),
        RequestFormLoadedForEdit(draftRequest),
      ],
    );

    blocTest<RequestFormCubit, RequestFormState>(
      'emits RequestFormError when attempting to load non-draft request for edit',
      build: () {
        final submitted = draftRequest.copyWith(
          status: RequestStatus.submitted,
        );
        when(
          () => mockRepo.getRequestById('draft-101'),
        ).thenAnswer((_) async => submitted);
        return cubit;
      },
      act: (cubit) => cubit.loadRequestForEdit('draft-101'),
      expect: () => [const RequestFormLoadingEdit(), isA<RequestFormError>()],
    );
  });
}
