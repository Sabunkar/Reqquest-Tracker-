import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:request_flow/core/errors/app_exception.dart';
import 'package:request_flow/features/requests/domain/entities/request.dart';
import 'package:request_flow/features/requests/domain/entities/request_status.dart';
import 'package:request_flow/features/requests/domain/repositories/request_repository.dart';
import 'package:request_flow/features/requests/presentation/cubit/request_list_cubit.dart';
import 'package:request_flow/features/requests/presentation/cubit/request_list_state.dart';

class MockRequestRepository extends Mock implements RequestRepository {}

void main() {
  group('RequestListCubit', () {
    late MockRequestRepository mockRepository;
    late RequestListCubit cubit;

    setUp(() {
      mockRepository = MockRequestRepository();
      cubit = RequestListCubit(mockRepository);
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is RequestListInitial', () {
      expect(cubit.state, const RequestListInitial());
    });

    final testRequests = [
      Request(
        id: '1',
        title: 'Project Tools',
        description: 'Software licenses',
        status: RequestStatus.submitted,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        version: 1,
      ),
      Request(
        id: '2',
        title: 'Laptop Upgrade',
        description: 'Need extra RAM for development',
        status: RequestStatus.draft,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        version: 1,
      ),
    ];

    blocTest<RequestListCubit, RequestListState>(
      'emits [RequestListLoading, RequestListLoaded] when loadRequests succeeds',
      build: () {
        when(
          () => mockRepository.getRequests(),
        ).thenAnswer((_) async => testRequests);
        return cubit;
      },
      act: (cubit) => cubit.loadRequests(),
      expect: () => [
        const RequestListLoading(),
        RequestListLoaded(
          allRequests: testRequests,
          filteredRequests: testRequests,
          searchQuery: '',
          selectedFilter: null,
          isRefreshing: false,
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.getRequests()).called(1);
      },
    );

    blocTest<RequestListCubit, RequestListState>(
      'filters requests by search query case-insensitively',
      build: () {
        when(
          () => mockRepository.getRequests(),
        ).thenAnswer((_) async => testRequests);
        return cubit;
      },
      seed: () => RequestListLoaded(
        allRequests: testRequests,
        filteredRequests: testRequests,
      ),
      act: (cubit) => cubit.search('laptop'),
      expect: () => [
        isA<RequestListLoaded>().having(
          (s) => s.filteredRequests.length,
          'filteredRequests length',
          1,
        ),
      ],
    );

    blocTest<RequestListCubit, RequestListState>(
      'filters requests by status correctly',
      build: () {
        when(
          () => mockRepository.getRequests(),
        ).thenAnswer((_) async => testRequests);
        return cubit;
      },
      seed: () => RequestListLoaded(
        allRequests: testRequests,
        filteredRequests: testRequests,
      ),
      act: (cubit) => cubit.filterByStatus(RequestStatus.draft),
      expect: () => [
        isA<RequestListLoaded>()
            .having(
              (s) => s.selectedFilter,
              'selectedFilter',
              RequestStatus.draft,
            )
            .having((s) => s.filteredRequests.length, 'filtered length', 1),
      ],
    );

    blocTest<RequestListCubit, RequestListState>(
      'emits [RequestListLoading, RequestListError] when loadRequests fails',
      build: () {
        when(
          () => mockRepository.getRequests(),
        ).thenThrow(const AppException('Storage error', code: 'STORAGE_ERR'));
        return cubit;
      },
      act: (cubit) => cubit.loadRequests(),
      expect: () => [const RequestListLoading(), isA<RequestListError>()],
    );
  });
}
