import 'package:equatable/equatable.dart';
import 'request_status.dart';

class Request extends Equatable {
  final String id;
  final String title;
  final String description;
  final RequestStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;
  final String? rejectionReason;

  const Request({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.version = 1,
    this.rejectionReason,
  });

  Request copyWith({
    String? id,
    String? title,
    String? description,
    RequestStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? version,
    String? rejectionReason,
  }) {
    return Request(
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

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    status,
    createdAt,
    updatedAt,
    version,
    rejectionReason,
  ];
}
