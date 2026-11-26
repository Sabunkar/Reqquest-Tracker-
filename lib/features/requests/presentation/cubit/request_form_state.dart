import 'package:equatable/equatable.dart';
import '../../domain/entities/request.dart';

abstract class RequestFormState extends Equatable {
  const RequestFormState();

  @override
  List<Object?> get props => [];
}

class RequestFormInitial extends RequestFormState {
  const RequestFormInitial();
}

class RequestFormLoadingEdit extends RequestFormState {
  const RequestFormLoadingEdit();
}

class RequestFormLoadedForEdit extends RequestFormState {
  final Request request;

  const RequestFormLoadedForEdit(this.request);

  @override
  List<Object?> get props => [request];
}

class RequestFormSubmitting extends RequestFormState {
  const RequestFormSubmitting();
}

class RequestFormSuccess extends RequestFormState {
  final Request request;
  final bool isEdit;

  const RequestFormSuccess(this.request, {this.isEdit = false});

  @override
  List<Object?> get props => [request, isEdit];
}

class RequestFormError extends RequestFormState {
  final String message;
  final Map<String, String>? fieldErrors;
  final bool isConflict;
  final Request? latestRequest;

  const RequestFormError(
    this.message, {
    this.fieldErrors,
    this.isConflict = false,
    this.latestRequest,
  });

  @override
  List<Object?> get props => [message, fieldErrors, isConflict, latestRequest];
}
