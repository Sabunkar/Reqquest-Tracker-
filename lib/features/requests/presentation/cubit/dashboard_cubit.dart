import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/request.dart';
import '../../domain/entities/request_status.dart';
import '../../domain/repositories/request_repository.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final RequestRepository _repository;

  DashboardCubit(this._repository) : super(const DashboardInitial());

  Future<void> loadDashboard() async {
    emit(const DashboardLoading());
    try {
      final requests = await _repository.getRequests();

      final totalCount = requests.length;
      final draftCount = requests
          .where((r) => r.status == RequestStatus.draft)
          .length;
      final submittedCount = requests
          .where((r) => r.status == RequestStatus.submitted)
          .length;
      final approvedCount = requests
          .where((r) => r.status == RequestStatus.approved)
          .length;
      final rejectedCount = requests
          .where((r) => r.status == RequestStatus.rejected)
          .length;

      // Sort by updatedAt descending
      final sorted = List<Request>.of(requests)
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      final recentRequests = sorted.take(5).toList();
      final pendingReviewRequests = sorted
          .where((r) => r.status == RequestStatus.submitted)
          .toList();

      emit(
        DashboardLoaded(
          totalCount: totalCount,
          draftCount: draftCount,
          submittedCount: submittedCount,
          approvedCount: approvedCount,
          rejectedCount: rejectedCount,
          recentRequests: recentRequests,
          pendingReviewRequests: pendingReviewRequests,
        ),
      );
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
}
