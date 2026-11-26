import 'package:equatable/equatable.dart';
import '../../domain/entities/request.dart';
import '../../domain/entities/request_activity.dart';

abstract class RequestDetailState extends Equatable {
  const RequestDetailState();

  @override
  List<Object?> get props => [];
}

class RequestDetailInitial extends RequestDetailState {
  const RequestDetailInitial();
}

class RequestDetailLoading extends RequestDetailState {
  const RequestDetailLoading();
}

class RequestDetailLoaded extends RequestDetailState {
  final Request request;
  final List<RequestActivity> activities;
  final bool isActionInProgress;
  final String? successMessage;

  const RequestDetailLoaded(
    this.request, {
    this.activities = const [],
    this.isActionInProgress = false,
    this.successMessage,
  });

  RequestDetailLoaded copyWith({
    Request? request,
    List<RequestActivity>? activities,
    bool? isActionInProgress,
    String? successMessage,
    bool clearSuccess = false,
  }) {
    return RequestDetailLoaded(
      request ?? this.request,
      activities: activities ?? this.activities,
      isActionInProgress: isActionInProgress ?? this.isActionInProgress,
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
    request,
    activities,
    isActionInProgress,
    successMessage,
  ];
}

class RequestDetailError extends RequestDetailState {
  final String message;
  final bool isConflict;
  final Request? latestRequest;

  const RequestDetailError(
    this.message, {
    this.isConflict = false,
    this.latestRequest,
  });

  @override
  List<Object?> get props => [message, isConflict, latestRequest];
}
