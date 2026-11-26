import '../../../settings/domain/entities/user_role.dart';
import '../../domain/entities/request_activity.dart';

class RequestActivityModel extends RequestActivity {
  const RequestActivityModel({
    required super.id,
    required super.requestId,
    required super.eventType,
    required super.description,
    required super.timestamp,
    required super.actorRole,
  });

  factory RequestActivityModel.fromJson(Map<String, dynamic> json) {
    return RequestActivityModel(
      id: json['id'] as String,
      requestId: json['requestId'] as String,
      eventType: RequestActivityType.values.firstWhere(
        (e) => e.name == json['eventType'],
        orElse: () => RequestActivityType.created,
      ),
      description: json['description'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      actorRole: UserRole.values.firstWhere(
        (r) => r.name == json['actorRole'],
        orElse: () => UserRole.user,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requestId': requestId,
      'eventType': eventType.name,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'actorRole': actorRole.name,
    };
  }

  factory RequestActivityModel.fromEntity(RequestActivity entity) {
    return RequestActivityModel(
      id: entity.id,
      requestId: entity.requestId,
      eventType: entity.eventType,
      description: entity.description,
      timestamp: entity.timestamp,
      actorRole: entity.actorRole,
    );
  }

  RequestActivity toEntity() {
    return RequestActivity(
      id: id,
      requestId: requestId,
      eventType: eventType,
      description: description,
      timestamp: timestamp,
      actorRole: actorRole,
    );
  }
}
