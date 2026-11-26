import 'package:equatable/equatable.dart';
import '../../domain/entities/request.dart';
import '../../domain/entities/request_status.dart';

abstract class RequestListState extends Equatable {
  const RequestListState();

  @override
  List<Object?> get props => [];
}

class RequestListInitial extends RequestListState {
  const RequestListInitial();
}

class RequestListLoading extends RequestListState {
  const RequestListLoading();
}

class RequestListLoaded extends RequestListState {
  final List<Request> allRequests;
  final List<Request> filteredRequests;
  final String searchQuery;
  final RequestStatus? selectedFilter;
  final bool isRefreshing;

  const RequestListLoaded({
    required this.allRequests,
    required this.filteredRequests,
    this.searchQuery = '',
    this.selectedFilter,
    this.isRefreshing = false,
  });

  // For backward compatibility with existing tests
  List<Request> get requests => filteredRequests;

  RequestListLoaded copyWith({
    List<Request>? allRequests,
    List<Request>? filteredRequests,
    String? searchQuery,
    RequestStatus? selectedFilter,
    bool clearFilter = false,
    bool? isRefreshing,
  }) {
    return RequestListLoaded(
      allRequests: allRequests ?? this.allRequests,
      filteredRequests: filteredRequests ?? this.filteredRequests,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedFilter: clearFilter
          ? null
          : (selectedFilter ?? this.selectedFilter),
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [
    allRequests,
    filteredRequests,
    searchQuery,
    selectedFilter,
    isRefreshing,
  ];
}

class RequestListError extends RequestListState {
  final String message;

  const RequestListError(this.message);

  @override
  List<Object?> get props => [message];
}
