import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../../../app/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/conflict_exception.dart';
import '../../../settings/domain/entities/user_role.dart';
import '../../domain/entities/request_activity.dart';
import '../../domain/entities/request_status.dart';
import '../../domain/validators/request_validator.dart';
import '../models/request_activity_model.dart';
import '../models/request_model.dart';
import 'request_local_datasource.dart';

class RequestMockApi {
  final RequestLocalDataSource localDataSource;
  final Duration artificialDelay;
  final UserRole Function()? currentRoleProvider;
  final bool Function()? failureSimulationProvider;
  final Uuid _uuid;

  UserRole? currentRoleOverride;
  bool? failureSimulationOverride;

  Future<void> _lock = Future.value();

  RequestMockApi({
    required this.localDataSource,
    this.artificialDelay = const Duration(milliseconds: 600),
    this.currentRoleProvider,
    this.failureSimulationProvider,
    this.currentRoleOverride,
    this.failureSimulationOverride,
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  UserRole get currentRole =>
      currentRoleOverride ?? currentRoleProvider?.call() ?? UserRole.user;

  bool get isFailureSimulated =>
      failureSimulationOverride ?? failureSimulationProvider?.call() ?? false;

  Future<T> _synchronized<T>(Future<T> Function() computation) async {
    final previous = _lock;
    final completer = Completer<void>();
    _lock = completer.future;
    try {
      await previous;
      return await computation();
    } finally {
      completer.complete();
    }
  }

  Future<void> _applyNetworkSimulation() async {
    if (isFailureSimulated) {
      throw const AppException(
        'Simulated API network error. Request failed.',
        code: 'SIMULATED_NETWORK_FAILURE',
      );
    }
    if (artificialDelay > Duration.zero) {
      await Future.delayed(artificialDelay);
    }
  }

  /// Seeds initial data once if storage has not been initialized.
  /// Never overwrites existing requests when the application restarts.
  Future<void> seedInitialDataIfNeeded() async {
    final isInitialized = await localDataSource.isInitialized();
    if (isInitialized) {
      return;
    }

    final existing = await localDataSource.getRequests();
    if (existing.isNotEmpty) {
      await localDataSource.setInitialized();
      return;
    }

    final now = DateTime.now();
    final seeds = [
      RequestModel(
        id: 'f1a00001-0000-4000-8000-000000000001',
        title: 'REQ-1001: Leave Request',
        description: 'Annual leave request for 5 days of vacation with family.',
        status: RequestStatus.draft,
        createdAt: now.subtract(const Duration(days: 4)),
        updatedAt: now.subtract(const Duration(days: 4)),
        version: 1,
      ),
      RequestModel(
        id: 'f1a00002-0000-4000-8000-000000000002',
        title: 'REQ-1002: Software Access Request',
        description:
            'Access request for Figma Enterprise license and GitHub organization developer seat.',
        status: RequestStatus.submitted,
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 2)),
        version: 2,
      ),
      RequestModel(
        id: 'f1a00003-0000-4000-8000-000000000003',
        title: 'REQ-1003: Hardware Request',
        description:
            'Workstation upgrade: 32GB RAM module, 4K monitor, and ergonomic mechanical keyboard.',
        status: RequestStatus.approved,
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 1)),
        version: 3,
      ),
      RequestModel(
        id: 'f1a00004-0000-4000-8000-000000000004',
        title: 'REQ-1004: Travel Approval',
        description:
            'Travel authorization to attend international technology summit as a keynote speaker.',
        status: RequestStatus.rejected,
        createdAt: now.subtract(const Duration(days: 6)),
        updatedAt: now.subtract(const Duration(days: 2)),
        version: 3,
        rejectionReason:
            'Department travel budget has reached full allocation for Q4. Please resubmit in Q1.',
      ),
      RequestModel(
        id: 'f1a00005-0000-4000-8000-000000000005',
        title: 'REQ-1005: Project Access Request',
        description:
            'Read-only access to staging cloud infrastructure for monitoring database performance.',
        status: RequestStatus.submitted,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(hours: 12)),
        version: 2,
      ),
    ];

    await localDataSource.saveRequests(seeds);
    await localDataSource.setInitialized();
  }

  Future<List<RequestModel>> getRequests() async {
    await _applyNetworkSimulation();
    await seedInitialDataIfNeeded();
    return localDataSource.getRequests();
  }

  Future<RequestModel> getRequestById(String id) async {
    await _applyNetworkSimulation();
    await seedInitialDataIfNeeded();
    final request = await localDataSource.getRequestById(id);
    if (request == null) {
      throw AppException(
        'Request with ID "$id" was not found',
        code: 'NOT_FOUND',
      );
    }
    return request;
  }

  Future<RequestModel> createRequest({
    required String title,
    required String description,
    required RequestStatus status,
  }) async {
    await _applyNetworkSimulation();

    final titleError = RequestValidator.validateTitle(title);
    if (titleError != null) {
      throw AppException(titleError, code: 'VALIDATION_ERROR');
    }
    final descError = RequestValidator.validateDescription(description);
    if (descError != null) {
      throw AppException(descError, code: 'VALIDATION_ERROR');
    }

    final now = DateTime.now();
    final newRequest = RequestModel(
      id: _uuid.v4(),
      title: title.trim(),
      description: description.trim(),
      status: RequestStatus.draft,
      createdAt: now,
      updatedAt: now,
      version: 1,
    );

    return _synchronized(() async {
      final actingRole = currentRole;
      if (actingRole != UserRole.user) {
        throw const AppException(
          'Reviewers cannot create requests. Only users are authorized.',
          code: 'UNAUTHORIZED_ROLE',
        );
      }

      await seedInitialDataIfNeeded();
      final activity = RequestActivityModel(
        id: _uuid.v4(),
        requestId: newRequest.id,
        eventType: RequestActivityType.created,
        description: 'Request created as Draft',
        timestamp: newRequest.createdAt,
        actorRole: actingRole,
      );

      return localDataSource.saveRequestWithActivity(
        request: newRequest,
        activity: activity,
      );
    });
  }

  Future<RequestModel> updateRequest({
    required String id,
    required String title,
    required String description,
    required int expectedVersion,
  }) async {
    await _applyNetworkSimulation();

    final titleError = RequestValidator.validateTitle(title);
    if (titleError != null) {
      throw AppException(titleError, code: 'VALIDATION_ERROR');
    }
    final descError = RequestValidator.validateDescription(description);
    if (descError != null) {
      throw AppException(descError, code: 'VALIDATION_ERROR');
    }

    return _synchronized(() async {
      final actingRole = currentRole;
      if (actingRole != UserRole.user) {
        throw const AppException(
          'Reviewers cannot edit requests. Only users are authorized to edit draft requests.',
          code: 'UNAUTHORIZED_ROLE',
        );
      }

      await seedInitialDataIfNeeded();
      final existing = await localDataSource.getRequestById(id);
      if (existing == null) {
        throw AppException(
          'Request with ID "$id" not found',
          code: 'NOT_FOUND',
        );
      }

      if (existing.status.isFinal) {
        throw const AppException(
          'Approved or rejected requests are final and read-only.',
          code: 'INVALID_STATUS',
        );
      }

      if (!existing.status.canEdit) {
        throw AppException(
          'Cannot edit request in "${existing.status.displayName}" status. Only draft requests can be edited.',
          code: 'INVALID_STATUS',
        );
      }

      if (existing.version != expectedVersion) {
        throw ConflictException(
          expectedVersion: expectedVersion,
          actualVersion: existing.version,
          message:
              'Optimistic concurrency conflict: Expected version $expectedVersion, but current version is ${existing.version}.',
        );
      }

      final updated = existing.copyWith(
        title: title.trim(),
        description: description.trim(),
        version: existing.version + 1,
        updatedAt: DateTime.now(),
      );

      final activity = RequestActivityModel(
        id: _uuid.v4(),
        requestId: updated.id,
        eventType: RequestActivityType.edited,
        description: 'Draft request details updated (v${updated.version})',
        timestamp: updated.updatedAt,
        actorRole: actingRole,
      );

      return localDataSource.saveRequestWithActivity(
        request: updated,
        activity: activity,
      );
    });
  }

  Future<RequestModel> submitRequest({
    required String id,
    required int expectedVersion,
  }) async {
    await _applyNetworkSimulation();

    return _synchronized(() async {
      final actingRole = currentRole;
      if (actingRole != UserRole.user) {
        throw const AppException(
          'Reviewers cannot submit requests. Only users are authorized to submit draft requests.',
          code: 'UNAUTHORIZED_ROLE',
        );
      }

      await seedInitialDataIfNeeded();
      final existing = await localDataSource.getRequestById(id);
      if (existing == null) {
        throw AppException(
          'Request with ID "$id" not found',
          code: 'NOT_FOUND',
        );
      }

      if (existing.status.isFinal) {
        throw const AppException(
          'Approved or rejected requests are final and read-only.',
          code: 'INVALID_STATUS',
        );
      }

      if (!existing.status.canSubmit) {
        throw AppException(
          'Cannot submit request in "${existing.status.displayName}" status. Only draft requests can be submitted.',
          code: 'INVALID_STATUS',
        );
      }

      if (existing.version != expectedVersion) {
        throw ConflictException(
          expectedVersion: expectedVersion,
          actualVersion: existing.version,
          message:
              'Optimistic concurrency conflict: Expected version $expectedVersion, but current version is ${existing.version}.',
        );
      }

      final updated = existing.copyWith(
        status: RequestStatus.submitted,
        version: existing.version + 1,
        updatedAt: DateTime.now(),
      );

      final activity = RequestActivityModel(
        id: _uuid.v4(),
        requestId: updated.id,
        eventType: RequestActivityType.submitted,
        description: 'Request submitted for review',
        timestamp: updated.updatedAt,
        actorRole: actingRole,
      );

      return localDataSource.saveRequestWithActivity(
        request: updated,
        activity: activity,
      );
    });
  }

  Future<RequestModel> approveRequest({
    required String id,
    required int expectedVersion,
  }) async {
    await _applyNetworkSimulation();

    return _synchronized(() async {
      final actingRole = currentRole;
      if (actingRole != UserRole.reviewer) {
        throw const AppException(
          'Users cannot approve requests. Only reviewers are authorized to approve submitted requests.',
          code: 'UNAUTHORIZED_ROLE',
        );
      }

      await seedInitialDataIfNeeded();
      final existing = await localDataSource.getRequestById(id);
      if (existing == null) {
        throw AppException(
          'Request with ID "$id" not found',
          code: 'NOT_FOUND',
        );
      }

      if (existing.status.isFinal) {
        throw const AppException(
          'Approved or rejected requests are final and read-only.',
          code: 'INVALID_STATUS',
        );
      }

      if (!existing.status.canReview) {
        throw AppException(
          'Cannot approve request in "${existing.status.displayName}" status. Only submitted requests can be approved.',
          code: 'INVALID_STATUS',
        );
      }

      if (existing.version != expectedVersion) {
        throw ConflictException(
          expectedVersion: expectedVersion,
          actualVersion: existing.version,
          message:
              'Optimistic concurrency conflict: Expected version $expectedVersion, but current version is ${existing.version}.',
        );
      }

      final updated = existing.copyWith(
        status: RequestStatus.approved,
        version: existing.version + 1,
        updatedAt: DateTime.now(),
      );

      final activity = RequestActivityModel(
        id: _uuid.v4(),
        requestId: updated.id,
        eventType: RequestActivityType.approved,
        description: 'Request approved by Reviewer',
        timestamp: updated.updatedAt,
        actorRole: actingRole,
      );

      return localDataSource.saveRequestWithActivity(
        request: updated,
        activity: activity,
      );
    });
  }

  Future<RequestModel> rejectRequest({
    required String id,
    required String rejectionReason,
    required int expectedVersion,
  }) async {
    await _applyNetworkSimulation();

    final reason = rejectionReason.trim();
    if (reason.isEmpty) {
      throw const AppException(
        'A non-empty rejection reason is required when rejecting a request.',
        code: 'VALIDATION_ERROR',
      );
    }
    if (reason.length > AppConstants.rejectionReasonMaxLength) {
      throw const AppException(
        'Rejection reason cannot exceed 500 characters.',
        code: 'VALIDATION_ERROR',
      );
    }

    return _synchronized(() async {
      final actingRole = currentRole;
      if (actingRole != UserRole.reviewer) {
        throw const AppException(
          'Users cannot reject requests. Only reviewers are authorized to reject submitted requests.',
          code: 'UNAUTHORIZED_ROLE',
        );
      }

      await seedInitialDataIfNeeded();
      final existing = await localDataSource.getRequestById(id);
      if (existing == null) {
        throw AppException(
          'Request with ID "$id" not found',
          code: 'NOT_FOUND',
        );
      }

      if (existing.status.isFinal) {
        throw const AppException(
          'Approved or rejected requests are final and read-only.',
          code: 'INVALID_STATUS',
        );
      }

      if (!existing.status.canReview) {
        throw AppException(
          'Cannot reject request in "${existing.status.displayName}" status. Only submitted requests can be rejected.',
          code: 'INVALID_STATUS',
        );
      }

      if (existing.version != expectedVersion) {
        throw ConflictException(
          expectedVersion: expectedVersion,
          actualVersion: existing.version,
          message:
              'Optimistic concurrency conflict: Expected version $expectedVersion, but current version is ${existing.version}.',
        );
      }

      final updated = existing.copyWith(
        status: RequestStatus.rejected,
        rejectionReason: reason,
        version: existing.version + 1,
        updatedAt: DateTime.now(),
      );

      final activity = RequestActivityModel(
        id: _uuid.v4(),
        requestId: updated.id,
        eventType: RequestActivityType.rejected,
        description: 'Request rejected by Reviewer. Reason: $reason',
        timestamp: updated.updatedAt,
        actorRole: actingRole,
      );

      return localDataSource.saveRequestWithActivity(
        request: updated,
        activity: activity,
      );
    });
  }

  Future<List<RequestActivityModel>> getRequestActivities(
    String requestId,
  ) async {
    await _applyNetworkSimulation();
    return localDataSource.getActivities(requestId);
  }
}
