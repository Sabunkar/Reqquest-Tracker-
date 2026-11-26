import 'package:equatable/equatable.dart';
import '../../../settings/domain/entities/user_role.dart';

enum RequestActivityType {
  created,
  edited,
  submitted,
  approved,
  rejected;

  String get displayName {
    switch (this) {
      case RequestActivityType.created:
        return 'Request Created';
      case RequestActivityType.edited:
        return 'Request Edited';
      case RequestActivityType.submitted:
        return 'Request Submitted';
      case RequestActivityType.approved:
        return 'Request Approved';
      case RequestActivityType.rejected:
        return 'Request Rejected';
    }
  }
}

class RequestActivity extends Equatable {
  final String id;
  final String requestId;
  final RequestActivityType eventType;
  final String description;
  final DateTime timestamp;
  final UserRole actorRole;

  const RequestActivity({
    required this.id,
    required this.requestId,
    required this.eventType,
    required this.description,
    required this.timestamp,
    required this.actorRole,
  });

  @override
  List<Object?> get props => [
    id,
    requestId,
    eventType,
    description,
    timestamp,
    actorRole,
  ];
}
