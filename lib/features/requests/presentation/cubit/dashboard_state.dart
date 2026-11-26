import 'package:equatable/equatable.dart';
import '../../domain/entities/request.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  final int totalCount;
  final int draftCount;
  final int submittedCount;
  final int approvedCount;
  final int rejectedCount;
  final List<Request> recentRequests;
  final List<Request> pendingReviewRequests;

  const DashboardLoaded({
    required this.totalCount,
    required this.draftCount,
    required this.submittedCount,
    required this.approvedCount,
    required this.rejectedCount,
    required this.recentRequests,
    required this.pendingReviewRequests,
  });

  @override
  List<Object?> get props => [
    totalCount,
    draftCount,
    submittedCount,
    approvedCount,
    rejectedCount,
    recentRequests,
    pendingReviewRequests,
  ];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
