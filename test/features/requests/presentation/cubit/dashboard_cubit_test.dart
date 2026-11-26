import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:request_flow/features/requests/domain/entities/request.dart';
import 'package:request_flow/features/requests/domain/entities/request_status.dart';
import 'package:request_flow/features/requests/domain/repositories/request_repository.dart';
import 'package:request_flow/features/requests/presentation/cubit/dashboard_cubit.dart';
import 'package:request_flow/features/requests/presentation/cubit/dashboard_state.dart';

class MockRequestRepository extends Mock implements RequestRepository {}

void main() {
  group('DashboardCubit Tests', () {
    late MockRequestRepository mockRepo;
    late DashboardCubit cubit;

    setUp(() {
      mockRepo = MockRequestRepository();
      cubit = DashboardCubit(mockRepo);
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is DashboardInitial', () {
      expect(cubit.state, const DashboardInitial());
    });

    final now = DateTime.now();
    final sampleRequests = [
      Request(
        id: '1',
        title: 'Draft Request',
        description: 'Draft Desc',
        status: RequestStatus.draft,
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 3)),
        version: 1,
      ),
      Request(
        id: '2',
        title: 'Submitted Request',
        description: 'Submitted Desc',
        status: RequestStatus.submitted,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
        version: 2,
      ),
      Request(
        id: '3',
        title: 'Approved Request',
        description: 'Approved Desc',
        status: RequestStatus.approved,
        createdAt: now.subtract(const Duration(days: 4)),
        updatedAt: now.subtract(const Duration(days: 1)),
        version: 3,
      ),
      Request(
        id: '4',
        title: 'Rejected Request',
        description: 'Rejected Desc',
        status: RequestStatus.rejected,
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now,
        version: 3,
        rejectionReason: 'Over budget',
      ),
    ];

    blocTest<DashboardCubit, DashboardState>(
      'emits [DashboardLoading, DashboardLoaded] with correct status statistics',
      build: () {
        when(
          () => mockRepo.getRequests(),
        ).thenAnswer((_) async => sampleRequests);
        return cubit;
      },
      act: (cubit) => cubit.loadDashboard(),
      expect: () => [
        const DashboardLoading(),
        isA<DashboardLoaded>()
            .having((s) => s.totalCount, 'totalCount', 4)
            .having((s) => s.draftCount, 'draftCount', 1)
            .having((s) => s.submittedCount, 'submittedCount', 1)
            .having((s) => s.approvedCount, 'approvedCount', 1)
            .having((s) => s.rejectedCount, 'rejectedCount', 1)
            .having((s) => s.recentRequests.length, 'recentRequests length', 4)
            .having(
              (s) => s.pendingReviewRequests.length,
              'pendingReviewRequests length',
              1,
            ),
      ],
      verify: (_) {
        verify(() => mockRepo.getRequests()).called(1);
      },
    );
  });
}
