import '../../domain/entities/request.dart';
import '../../domain/entities/request_status.dart';

class RequestModel extends Request {
  const RequestModel({
    required super.id,
    required super.title,
    required super.description,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
    super.version = 1,
    super.rejectionReason,
  });

  factory RequestModel.fromJson(Map<String, dynamic> json) {
    return RequestModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      status: RequestStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => RequestStatus.draft,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      version: json['version'] as int? ?? 1,
      rejectionReason: json['rejectionReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'version': version,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
    };
  }

  factory RequestModel.fromEntity(Request entity) {
    return RequestModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      status: entity.status,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      version: entity.version,
      rejectionReason: entity.rejectionReason,
    );
  }

  Request toEntity() {
    return Request(
      id: id,
      title: title,
      description: description,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      version: version,
      rejectionReason: rejectionReason,
    );
  }

  @override
  RequestModel copyWith({
    String? id,
    String? title,
    String? description,
    RequestStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? version,
    String? rejectionReason,
  }) {
    return RequestModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}
