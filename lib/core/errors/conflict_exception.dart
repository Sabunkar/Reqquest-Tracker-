import 'app_exception.dart';

class ConflictException extends AppException {
  final int expectedVersion;
  final int actualVersion;

  ConflictException({
    required this.expectedVersion,
    required this.actualVersion,
    String message =
        'The request was modified by another process. Please refresh and try again.',
  }) : super(
         message,
         code: 'CONFLICT_ERROR',
         details: {
           'expectedVersion': expectedVersion,
           'actualVersion': actualVersion,
         },
       );

  @override
  String toString() =>
      'ConflictException: $message (expected: $expectedVersion, actual: $actualVersion)';
}
