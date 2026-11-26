import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/constants/app_breakpoints.dart';
import '../../../../app/constants/app_constants.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/responsive_container.dart';
import '../../../../injection/dependency_injection.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../../settings/presentation/cubit/settings_state.dart';
import '../../data/services/request_pdf_service.dart';
import '../../domain/entities/request.dart';
import '../../domain/entities/request_activity.dart';
import '../../domain/entities/request_status.dart';
import '../../domain/repositories/request_repository.dart';
import '../../domain/validators/request_validator.dart';
import '../cubit/request_detail_cubit.dart';
import '../cubit/request_detail_state.dart';
import '../cubit/request_list_cubit.dart';
import '../widgets/request_timeline.dart';
import '../widgets/status_chip.dart';

class RequestDetailScreen extends StatelessWidget {
  final String requestId;

  const RequestDetailScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          RequestDetailCubit(sl<RequestRepository>())..loadRequest(requestId),
      child: _RequestDetailView(requestId: requestId),
    );
  }
}

class _RequestDetailView extends StatelessWidget {
  final String requestId;

  const _RequestDetailView({required this.requestId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/requests');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text('Request Details'),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Back',
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/requests');
              }
            },
          ),
          actions: [
            BlocBuilder<RequestDetailCubit, RequestDetailState>(
              builder: (context, state) {
                if (state is RequestDetailLoaded) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 4.0,
                    ),
                    child: FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 32),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                      label: const Text(
                        'Export PDF',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () => _exportPdf(context, state.request),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh',
              onPressed: () =>
                  context.read<RequestDetailCubit>().refresh(requestId),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: BlocConsumer<RequestDetailCubit, RequestDetailState>(
          listener: (context, state) {
            if (state is RequestDetailLoaded && state.successMessage != null) {
              context.read<RequestListCubit>().loadRequests();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.successMessage!),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state is RequestDetailError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: state.isConflict
                      ? Colors.orange
                      : theme.colorScheme.error,
                  action: state.isConflict
                      ? SnackBarAction(
                          label: 'Reload',
                          textColor: Colors.white,
                          onPressed: () => context
                              .read<RequestDetailCubit>()
                              .refresh(requestId),
                        )
                      : null,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is RequestDetailLoading) {
              return const LoadingWidget(message: 'Loading request details...');
            }

            if (state is RequestDetailError && state.latestRequest == null) {
              return CustomErrorWidget(
                message: state.message,
                onRetry: () =>
                    context.read<RequestDetailCubit>().loadRequest(requestId),
              );
            }

            final request = state is RequestDetailLoaded
                ? state.request
                : (state as RequestDetailError).latestRequest;

            if (request == null) {
              return const SizedBox.shrink();
            }

            final activities = state is RequestDetailLoaded
                ? state.activities
                : const <RequestActivity>[];

            final isActionInProgress =
                state is RequestDetailLoaded && state.isActionInProgress;

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width < 360
                          ? 12.0
                          : 16.0,
                      vertical: 16.0,
                    ),
                    child: ResponsiveContainer(
                      maxWidth: AppBreakpoints.maxContentWidthMedium,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Prominent Request ID Banner Card
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 16.0),
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.surfaceVariantDark
                                  : AppColors.surfaceVariantLight,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.borderDark
                                    : AppColors.borderLight,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.fingerprint_rounded,
                                    size: 20,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'REQUEST ID',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.8,
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondaryLight,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      SelectableText(
                                        request.id,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              fontFamily: 'monospace',
                                              color: isDark
                                                  ? AppColors.textPrimaryDark
                                                  : AppColors.textPrimaryLight,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.copy_rounded,
                                    size: 18,
                                  ),
                                  tooltip: 'Copy Request ID',
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(text: request.id),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Request ID copied to clipboard',
                                        ),
                                        duration: Duration(seconds: 1),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),

                          // Title & Status Chip Row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  request.title,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              StatusChip(status: request.status),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Horizontal Progress Stepper
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 12.0,
                              ),
                              child: RequestTimeline(
                                currentStatus: request.status,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Metadata Info Card
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  _buildMetaRow(
                                    context,
                                    label: 'Created At',
                                    value: DateFormatter.formatDateTime(
                                      request.createdAt,
                                    ),
                                    icon: Icons.calendar_today_outlined,
                                  ),
                                  const Divider(height: 16),
                                  _buildMetaRow(
                                    context,
                                    label: 'Last Updated',
                                    value: DateFormatter.formatDateTime(
                                      request.updatedAt,
                                    ),
                                    icon: Icons.update_rounded,
                                  ),
                                  const Divider(height: 16),
                                  _buildMetaRow(
                                    context,
                                    label: 'Version',
                                    value: 'v${request.version}',
                                    icon: Icons.tag_rounded,
                                  ),
                                  const Divider(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: const Size(0, 48),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.picture_as_pdf_rounded,
                                        size: 20,
                                      ),
                                      label: const Text(
                                        'Export PDF',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      onPressed: () =>
                                          _exportPdf(context, request),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Description Section
                          Text(
                            'Description',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: SizedBox(
                                width: double.infinity,
                                child: Text(
                                  request.description.isEmpty
                                      ? 'No description provided.'
                                      : request.description,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Rejection Reason (if rejected)
                          if (request.status == RequestStatus.rejected &&
                              request.rejectionReason != null) ...[
                            const SizedBox(height: 20),
                            Text(
                              'Rejection Reason',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.error,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Card(
                              color: theme.colorScheme.errorContainer
                                  .withValues(alpha: 0.15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: theme.colorScheme.error.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.error_outline_rounded,
                                      color: theme.colorScheme.error,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        request.rejectionReason!,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onErrorContainer,
                                              height: 1.4,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),

                          // Activity Timeline Log
                          Text(
                            'Activity History',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: RequestActivityTimeline(
                                activities: activities,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom Workflow Actions
                _buildBottomActionPanel(context, request, isActionInProgress),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMetaRow(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 260) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 24),
                child: Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        }
        return Row(
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomActionPanel(
    BuildContext context,
    Request request,
    bool isActionInProgress,
  ) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settingsState) {
        final isUser = settingsState.role.isUser;
        final isReviewer = settingsState.role.isReviewer;

        // User actions on Draft: Edit and Submit
        if (isUser && request.status.isDraft) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: const Offset(0, -2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: ResponsiveContainer(
                maxWidth: AppBreakpoints.maxContentWidthMedium,
                padding: const EdgeInsets.all(16.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow =
                        constraints.maxWidth < AppBreakpoints.compactMobile;

                    if (isNarrow) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.statusSubmitted,
                            ),
                            icon: isActionInProgress
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.send_rounded, size: 18),
                            label: const Text('Submit for Review'),
                            onPressed: isActionInProgress
                                ? null
                                : () => _confirmSubmit(context, request),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Edit Draft'),
                            onPressed: isActionInProgress
                                ? null
                                : () async {
                                    final changed = await context.push<bool>(
                                      '/requests/${request.id}/edit',
                                    );
                                    if (changed == true && context.mounted) {
                                      context
                                          .read<RequestDetailCubit>()
                                          .refresh(request.id);
                                    }
                                  },
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Edit Draft'),
                            onPressed: isActionInProgress
                                ? null
                                : () async {
                                    final changed = await context.push<bool>(
                                      '/requests/${request.id}/edit',
                                    );
                                    if (changed == true && context.mounted) {
                                      context
                                          .read<RequestDetailCubit>()
                                          .refresh(request.id);
                                    }
                                  },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.statusSubmitted,
                            ),
                            icon: isActionInProgress
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.send_rounded, size: 18),
                            label: const Text('Submit for Review'),
                            onPressed: isActionInProgress
                                ? null
                                : () => _confirmSubmit(context, request),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        }

        // Reviewer actions on Submitted: Approve and Reject
        if (isReviewer && request.status.isSubmitted) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: const Offset(0, -2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: ResponsiveContainer(
                maxWidth: AppBreakpoints.maxContentWidthMedium,
                padding: const EdgeInsets.all(16.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow =
                        constraints.maxWidth < AppBreakpoints.compactMobile;

                    if (isNarrow) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.statusApproved,
                            ),
                            icon: isActionInProgress
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.check_rounded, size: 18),
                            label: const Text('Approve Request'),
                            onPressed: isActionInProgress
                                ? null
                                : () => _confirmApprove(context, request),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.statusRejected,
                              side: const BorderSide(
                                color: AppColors.statusRejected,
                              ),
                            ),
                            icon: const Icon(Icons.close_rounded, size: 18),
                            label: const Text('Reject'),
                            onPressed: isActionInProgress
                                ? null
                                : () => _showRejectDialog(context, request),
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.statusRejected,
                              side: const BorderSide(
                                color: AppColors.statusRejected,
                              ),
                            ),
                            icon: const Icon(Icons.close_rounded, size: 18),
                            label: const Text('Reject'),
                            onPressed: isActionInProgress
                                ? null
                                : () => _showRejectDialog(context, request),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.statusApproved,
                            ),
                            icon: isActionInProgress
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.check_rounded, size: 18),
                            label: const Text('Approve Request'),
                            onPressed: isActionInProgress
                                ? null
                                : () => _confirmApprove(context, request),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        }

        // Final or Read-Only state banner
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    request.status.isFinal
                        ? Icons.lock_outline_rounded
                        : Icons.visibility_outlined,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      request.status.isFinal
                          ? 'Final Request • Read Only'
                          : isUser
                          ? 'Submitted for Review • Awaiting Approval'
                          : 'Draft Request • Cannot Review until Submitted',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _confirmSubmit(BuildContext context, Request request) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          actionsOverflowButtonSpacing: 8,
          actionsOverflowDirection: VerticalDirection.down,
          title: const Text('Submit Request for Review?'),
          content: SingleChildScrollView(
            child: Text(
              'Are you sure you want to submit "${request.title}"?\n\n'
              'Once submitted, the request will be placed in the reviewer queue and you will no longer be able to edit its contents.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.statusSubmitted,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<RequestDetailCubit>().submitRequest(
                  request.id,
                  request.version,
                );
              },
              child: const Text('Confirm Submit'),
            ),
          ],
        );
      },
    );
  }

  void _confirmApprove(BuildContext context, Request request) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          actionsOverflowButtonSpacing: 8,
          actionsOverflowDirection: VerticalDirection.down,
          title: const Text('Approve Request?'),
          content: SingleChildScrollView(
            child: Text(
              'Are you sure you want to approve "${request.title}"?\n\n'
              'This action is final and will resolve the request.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.statusApproved,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<RequestDetailCubit>().approveRequest(
                  request.id,
                  request.version,
                );
              },
              child: const Text('Approve'),
            ),
          ],
        );
      },
    );
  }

  void _showRejectDialog(BuildContext context, Request request) {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            final reasonLength = reasonController.text.length;

            return AlertDialog(
              actionsOverflowButtonSpacing: 8,
              actionsOverflowDirection: VerticalDirection.down,
              title: const Text('Reject Request'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Please provide a specific rejection reason for the requester:',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: reasonController,
                        decoration: InputDecoration(
                          labelText: 'Rejection Reason *',
                          hintText: 'e.g. Budget allocation exhausted for Q4',
                          alignLabelWithHint: true,
                          counterText:
                              '$reasonLength / ${AppConstants.rejectionReasonMaxLength}',
                        ),
                        maxLines: 4,
                        maxLength: AppConstants.rejectionReasonMaxLength,
                        validator: RequestValidator.validateRejectionReason,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 14,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'This action is final and will permanently reject the request.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline,
                                    fontSize: 11,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.statusRejected,
                  ),
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      final reason = reasonController.text.trim();
                      Navigator.of(dialogContext).pop();
                      context.read<RequestDetailCubit>().rejectRequest(
                        request.id,
                        reason,
                        request.version,
                      );
                    }
                  },
                  child: const Text('Confirm Reject'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _exportPdf(BuildContext context, Request request) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generating PDF document...'),
          duration: Duration(seconds: 1),
        ),
      );
      await RequestPdfService.printOrSharePdf(request);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export PDF: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
