import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/conflict_exception.dart';
import '../../domain/entities/request_status.dart';
import '../../domain/repositories/request_repository.dart';
import '../../domain/validators/request_validator.dart';
import 'request_form_state.dart';

class RequestFormCubit extends Cubit<RequestFormState> {
  final RequestRepository _repository;

  RequestFormCubit(this._repository) : super(const RequestFormInitial());

  Future<void> loadRequestForEdit(String id) async {
    emit(const RequestFormLoadingEdit());
    try {
      final request = await _repository.getRequestById(id);
      if (!request.status.canEdit) {
        emit(
          RequestFormError(
            'Only Draft requests can be edited. Current status is ${request.status.displayName}.',
          ),
        );
        return;
      }
      emit(RequestFormLoadedForEdit(request));
    } catch (e) {
      emit(RequestFormError(e.toString()));
    }
  }

  Future<void> createDraft({
    required String title,
    required String description,
  }) async {
    final titleError = RequestValidator.validateTitle(title);
    final descError = RequestValidator.validateDescription(description);

    if (titleError != null || descError != null) {
      final errors = <String, String>{};
      if (titleError != null) errors['title'] = titleError;
      if (descError != null) errors['description'] = descError;

      emit(
        RequestFormError(
          'Please correct validation errors',
          fieldErrors: errors,
        ),
      );
      return;
    }

    emit(const RequestFormSubmitting());
    try {
      final created = await _repository.createRequest(
        title: title,
        description: description,
        status: RequestStatus.draft,
      );
      emit(RequestFormSuccess(created, isEdit: false));
    } catch (e) {
      emit(RequestFormError(e.toString()));
    }
  }

  Future<void> updateDraft({
    required String id,
    required String title,
    required String description,
    required int expectedVersion,
  }) async {
    final titleError = RequestValidator.validateTitle(title);
    final descError = RequestValidator.validateDescription(description);

    if (titleError != null || descError != null) {
      final errors = <String, String>{};
      if (titleError != null) errors['title'] = titleError;
      if (descError != null) errors['description'] = descError;

      emit(
        RequestFormError(
          'Please correct validation errors',
          fieldErrors: errors,
        ),
      );
      return;
    }

    emit(const RequestFormSubmitting());
    try {
      final updated = await _repository.updateRequest(
        id: id,
        title: title,
        description: description,
        expectedVersion: expectedVersion,
      );
      emit(RequestFormSuccess(updated, isEdit: true));
    } on ConflictException catch (e) {
      try {
        final latest = await _repository.getRequestById(id);
        emit(
          RequestFormError(
            'Optimistic concurrency conflict: This request was modified by another operation. Please refresh the latest data.',
            isConflict: true,
            latestRequest: latest,
          ),
        );
      } catch (_) {
        emit(RequestFormError(e.message, isConflict: true));
      }
    } catch (e) {
      emit(RequestFormError(e.toString()));
    }
  }
}
