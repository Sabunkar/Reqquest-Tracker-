import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/request.dart';
import '../../domain/entities/request_status.dart';
import '../../domain/repositories/request_repository.dart';
import 'request_list_state.dart';

class RequestListCubit extends Cubit<RequestListState> {
  final RequestRepository _repository;

  RequestListCubit(this._repository) : super(const RequestListInitial());

  Future<void> loadRequests({bool isRefresh = false}) async {
    final currentState = state;
    if (isRefresh && currentState is RequestListLoaded) {
      emit(currentState.copyWith(isRefreshing: true));
    } else {
      emit(const RequestListLoading());
    }

    try {
      final requests = await _repository.getRequests();
      final query = currentState is RequestListLoaded
          ? currentState.searchQuery
          : '';
      final filter = currentState is RequestListLoaded
          ? currentState.selectedFilter
          : null;

      final filtered = _filterRequests(requests, query: query, filter: filter);

      emit(
        RequestListLoaded(
          allRequests: requests,
          filteredRequests: filtered,
          searchQuery: query,
          selectedFilter: filter,
          isRefreshing: false,
        ),
      );
    } catch (e) {
      emit(RequestListError(e.toString()));
    }
  }

  void search(String query) {
    final currentState = state;
    if (currentState is RequestListLoaded) {
      final filtered = _filterRequests(
        currentState.allRequests,
        query: query,
        filter: currentState.selectedFilter,
      );

      emit(
        currentState.copyWith(searchQuery: query, filteredRequests: filtered),
      );
    }
  }

  void clearSearch() {
    search('');
  }

  void filterByStatus(RequestStatus? status) {
    final currentState = state;
    if (currentState is RequestListLoaded) {
      final filtered = _filterRequests(
        currentState.allRequests,
        query: currentState.searchQuery,
        filter: status,
      );

      emit(
        currentState.copyWith(
          selectedFilter: status,
          clearFilter: status == null,
          filteredRequests: filtered,
        ),
      );
    }
  }

  List<Request> _filterRequests(
    List<Request> requests, {
    required String query,
    required RequestStatus? filter,
  }) {
    final trimmedQuery = query.trim().toLowerCase();

    return requests.where((req) {
      final matchesFilter = filter == null || req.status == filter;
      final matchesQuery =
          trimmedQuery.isEmpty ||
          req.title.toLowerCase().contains(trimmedQuery) ||
          req.description.toLowerCase().contains(trimmedQuery);

      return matchesFilter && matchesQuery;
    }).toList();
  }
}
