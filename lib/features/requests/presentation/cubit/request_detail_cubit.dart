import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/conflict_exception.dart';
import '../../domain/repositories/request_repository.dart';
import 'request_detail_state.dart';

class RequestDetailCubit extends Cubit<RequestDetailState> {
  final RequestRepository _repository;

  RequestDetailCubit(this._repository) : super(const RequestDetailInitial());

  Future<void> loadRequest(String id) async {
    emit(const RequestDetailLoading());
    try {
      final request = await _repository.getRequestById(id);
      final activities = await _repository.getRequestActivities(id);
      emit(RequestDetailLoaded(request, activities: activities));
    } catch (e) {
      emit(RequestDetailError(e.toString()));
    }
  }

  Future<void> refresh(String id) async {
    try {
      final request = await _repository.getRequestById(id);
      final activities = await _repository.getRequestActivities(id);
      emit(RequestDetailLoaded(request, activities: activities));
    } catch (e) {
      emit(RequestDetailError(e.toString()));
    }
  }

  Future<void> submitRequest(String id, int expectedVersion) async {
    final currentState = state;
    if (currentState is RequestDetailLoaded) {
      emit(currentState.copyWith(isActionInProgress: true, clearSuccess: true));
    }

    try {
      final updated = await _repository.submitRequest(
        id: id,
        expectedVersion: expectedVersion,
      );
      final activities = await _repository.getRequestActivities(id);
      emit(
        RequestDetailLoaded(
          updated,
          activities: activities,
          successMessage: 'Request submitted for review successfully.',
        ),
      );
    } on ConflictException catch (e) {
      await _handleConflict(id, e.message);
    } catch (e) {
      emit(RequestDetailError(e.toString()));
    }
  }

  Future<void> approveRequest(String id, int expectedVersion) async {
    final currentState = state;
    if (currentState is RequestDetailLoaded) {
      emit(currentState.copyWith(isActionInProgress: true, clearSuccess: true));
    }

    try {
      final updated = await _repository.approveRequest(
        id: id,
        expectedVersion: expectedVersion,
      );
      final activities = await _repository.getRequestActivities(id);
      emit(
        RequestDetailLoaded(
          updated,
          activities: activities,
          successMessage: 'Request has been approved successfully.',
        ),
      );
    } on ConflictException catch (e) {
      await _handleConflict(id, e.message);
    } catch (e) {
      emit(RequestDetailError(e.toString()));
    }
  }

  Future<void> rejectRequest(
    String id,
    String rejectionReason,
    int expectedVersion,
  ) async {
    final currentState = state;
    if (currentState is RequestDetailLoaded) {
      emit(currentState.copyWith(isActionInProgress: true, clearSuccess: true));
    }

    try {
      final updated = await _repository.rejectRequest(
        id: id,
        rejectionReason: rejectionReason,
        expectedVersion: expectedVersion,
      );
      final activities = await _repository.getRequestActivities(id);
      emit(
        RequestDetailLoaded(
          updated,
          activities: activities,
          successMessage: 'Request has been rejected.',
        ),
      );
    } on ConflictException catch (e) {
      await _handleConflict(id, e.message);
    } catch (e) {
      emit(RequestDetailError(e.toString()));
    }
  }

  Future<void> _handleConflict(String id, String conflictMessage) async {
    try {
      final latest = await _repository.getRequestById(id);
      emit(
        RequestDetailError(
          'Optimistic concurrency conflict: The request was updated by another user or operation. Showing latest data.',
          isConflict: true,
          latestRequest: latest,
        ),
      );
    } catch (_) {
      emit(RequestDetailError(conflictMessage, isConflict: true));
    }
  }
}
