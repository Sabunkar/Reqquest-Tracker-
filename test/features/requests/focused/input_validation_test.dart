import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:request_flow/core/errors/app_exception.dart';
import 'package:request_flow/features/requests/data/datasources/request_mock_api.dart';
import 'package:request_flow/features/requests/data/datasources/shared_preferences_request_datasource.dart';
import 'package:request_flow/features/requests/domain/entities/request_status.dart';
import 'package:request_flow/features/requests/domain/repositories/request_repository.dart';
import 'package:request_flow/features/requests/domain/validators/request_validator.dart';
import 'package:request_flow/features/requests/presentation/cubit/request_form_cubit.dart';
import 'package:request_flow/features/requests/presentation/cubit/request_form_state.dart';
import 'package:request_flow/features/settings/domain/entities/user_role.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockRequestRepository extends Mock implements RequestRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(RequestStatus.draft);
  });

  group('1. Input Validation - Pure Domain Validator Tests', () {
    test('Empty or whitespace-only title is rejected', () {
      expect(RequestValidator.validateTitle(''), 'Title is required');
      expect(RequestValidator.validateTitle('   '), 'Title is required');
      expect(RequestValidator.validateTitle('\t\n'), 'Title is required');
      expect(RequestValidator.validateTitle(null), 'Title is required');
    });

    test('Title shorter than 3 characters is rejected', () {
      expect(
        RequestValidator.validateTitle('a'),
        'Title must be at least 3 characters',
      );
      expect(
        RequestValidator.validateTitle('ab'),
        'Title must be at least 3 characters',
      );
      expect(
        RequestValidator.validateTitle('  x  '),
        'Title must be at least 3 characters',
      );
    });

    test('Title longer than 120 characters is rejected', () {
      final longTitle121 = 'A' * 121;
      final longTitle200 = 'B' * 200;
      expect(
        RequestValidator.validateTitle(longTitle121),
        'Title must not exceed 120 characters',
      );
      expect(
        RequestValidator.validateTitle(longTitle200),
        'Title must not exceed 120 characters',
      );
    });

    test('Valid title within 3–120 characters is accepted', () {
      expect(RequestValidator.validateTitle('ABC'), isNull);
      expect(RequestValidator.validateTitle('New Equipment Request'), isNull);
      expect(RequestValidator.validateTitle('A' * 120), isNull);
      expect(RequestValidator.validateTitle('  Valid with padding  '), isNull);
    });

    test('Description exceeding 2,000 characters is rejected', () {
      final desc2001 = 'D' * 2001;
      final desc3000 = 'D' * 3000;
      expect(
        RequestValidator.validateDescription(desc2001),
        'Description must not exceed 2000 characters',
      );
      expect(
        RequestValidator.validateDescription(desc3000),
        'Description must not exceed 2000 characters',
      );
    });

    test('Valid description is accepted', () {
      expect(RequestValidator.validateDescription(''), isNull);
      expect(RequestValidator.validateDescription('   '), isNull);
      expect(RequestValidator.validateDescription(null), isNull);
      expect(RequestValidator.validateDescription('Short description'), isNull);
      expect(RequestValidator.validateDescription('D' * 2000), isNull);
    });
  });

  group('1. Input Validation - API & Repository Layer Enforcement', () {
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
      'mockApi.createRequest rejects invalid title with AppException VALIDATION_ERROR',
      () async {
        await expectLater(
          () => mockApi.createRequest(
            title: 'ab',
            description: 'Valid description',
            status: RequestStatus.draft,
          ),
          throwsA(
            predicate(
              (e) =>
                  e is AppException &&
                  e.code == 'VALIDATION_ERROR' &&
                  e.message == 'Title must be at least 3 characters',
            ),
          ),
        );
      },
    );

    test(
      'mockApi.createRequest rejects description over 2000 characters',
      () async {
        await expectLater(
          () => mockApi.createRequest(
            title: 'Valid Request Title',
            description: 'X' * 2001,
            status: RequestStatus.draft,
          ),
          throwsA(
            predicate(
              (e) =>
                  e is AppException &&
                  e.code == 'VALIDATION_ERROR' &&
                  e.message.contains('2000 characters'),
            ),
          ),
        );
      },
    );

    test(
      'mockApi.updateRequest rejects invalid title and excessive description',
      () async {
        final created = await mockApi.createRequest(
          title: 'Initial Valid Title',
          description: 'Initial Description',
          status: RequestStatus.draft,
        );

        // Invalid title
        await expectLater(
          () => mockApi.updateRequest(
            id: created.id,
            title: '  ',
            description: 'Valid description',
            expectedVersion: 1,
          ),
          throwsA(
            predicate((e) => e is AppException && e.code == 'VALIDATION_ERROR'),
          ),
        );

        // Excessive description
        await expectLater(
          () => mockApi.updateRequest(
            id: created.id,
            title: 'Valid Title',
            description: 'Z' * 2001,
            expectedVersion: 1,
          ),
          throwsA(
            predicate((e) => e is AppException && e.code == 'VALIDATION_ERROR'),
          ),
        );
      },
    );
  });

  group('1. Input Validation - Cubit & UI State Exposure Tests', () {
    late MockRequestRepository mockRepo;
    late RequestFormCubit cubit;

    setUp(() {
      mockRepo = MockRequestRepository();
      cubit = RequestFormCubit(mockRepo);
    });

    tearDown(() {
      cubit.close();
    });

    blocTest<RequestFormCubit, RequestFormState>(
      'createDraft exposes title validation error in fieldErrors map to UI',
      build: () => cubit,
      act: (cubit) => cubit.createDraft(title: 'NO', description: 'Valid desc'),
      expect: () => [
        isA<RequestFormError>()
            .having(
              (s) => s.message,
              'message',
              'Please correct validation errors',
            )
            .having(
              (s) => s.fieldErrors?['title'],
              'title field error',
              'Title must be at least 3 characters',
            ),
      ],
      verify: (_) {
        verifyNever(
          () => mockRepo.createRequest(
            title: any(named: 'title'),
            description: any(named: 'description'),
            status: any(named: 'status'),
          ),
        );
      },
    );

    blocTest<RequestFormCubit, RequestFormState>(
      'createDraft exposes description validation error in fieldErrors map to UI',
      build: () => cubit,
      act: (cubit) =>
          cubit.createDraft(title: 'Valid Title Here', description: 'T' * 2001),
      expect: () => [
        isA<RequestFormError>()
            .having(
              (s) => s.message,
              'message',
              'Please correct validation errors',
            )
            .having(
              (s) => s.fieldErrors?['description'],
              'description field error',
              'Description must not exceed 2000 characters',
            ),
      ],
    );

    blocTest<RequestFormCubit, RequestFormState>(
      'updateDraft exposes multiple validation errors simultaneously to UI',
      build: () => cubit,
      act: (cubit) => cubit.updateDraft(
        id: 'draft-99',
        title: 'X',
        description: 'Y' * 2005,
        expectedVersion: 1,
      ),
      expect: () => [
        isA<RequestFormError>()
            .having(
              (s) => s.fieldErrors?['title'],
              'title error',
              'Title must be at least 3 characters',
            )
            .having(
              (s) => s.fieldErrors?['description'],
              'description error',
              'Description must not exceed 2000 characters',
            ),
      ],
    );
  });
}
