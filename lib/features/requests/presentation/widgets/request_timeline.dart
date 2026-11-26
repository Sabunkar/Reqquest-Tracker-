import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/request_activity.dart';
import '../../domain/entities/request_status.dart';

class RequestTimeline extends StatelessWidget {
  final RequestStatus currentStatus;

  const RequestTimeline({super.key, required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    final isDraft = currentStatus == RequestStatus.draft;
    final isSubmitted = currentStatus == RequestStatus.submitted;
    final isApproved = currentStatus == RequestStatus.approved;
    final isRejected = currentStatus == RequestStatus.rejected;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          _buildStep(
            context,
            title: 'Draft',
            isCompleted: !isDraft,
            isActive: isDraft,
            color: AppColors.statusDraft,
          ),
          _buildConnector(
            context,
            isCompleted: isSubmitted || isApproved || isRejected,
          ),
          _buildStep(
            context,
            title: 'Submitted',
            isCompleted: isApproved || isRejected,
            isActive: isSubmitted,
            color: AppColors.statusSubmitted,
          ),
          _buildConnector(context, isCompleted: isApproved || isRejected),
          _buildStep(
            context,
            title: isRejected ? 'Rejected' : 'Approved',
            isCompleted: isApproved || isRejected,
            isActive: isApproved || isRejected,
            color: isRejected
                ? AppColors.statusRejected
                : AppColors.statusApproved,
          ),
        ],
      ),
    );
  }

  Widget _buildStep(
    BuildContext context, {
    required String title,
    required bool isCompleted,
    required bool isActive,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final indicatorColor = isCompleted || isActive
        ? color
        : theme.colorScheme.outline;

    return Expanded(
      flex: 3,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? indicatorColor
                  : isActive
                  ? indicatorColor.withValues(alpha: 0.15)
                  : Colors.transparent,
              border: Border.all(color: indicatorColor, width: 2),
            ),
            child: isCompleted
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : isActive
                ? Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: indicatorColor,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: isActive || isCompleted
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: isActive || isCompleted
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnector(BuildContext context, {required bool isCompleted}) {
    final theme = Theme.of(context);
    return Expanded(
      flex: 2,
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        color: isCompleted
            ? AppColors.primary
            : theme.colorScheme.outline.withValues(alpha: 0.3),
      ),
    );
  }
}

class RequestActivityTimeline extends StatelessWidget {
  final List<RequestActivity> activities;

  const RequestActivityTimeline({super.key, required this.activities});

  IconData _iconForType(RequestActivityType type) {
    switch (type) {
      case RequestActivityType.created:
        return Icons.add_circle_outline_rounded;
      case RequestActivityType.edited:
        return Icons.edit_note_rounded;
      case RequestActivityType.submitted:
        return Icons.send_rounded;
      case RequestActivityType.approved:
        return Icons.check_circle_rounded;
      case RequestActivityType.rejected:
        return Icons.cancel_rounded;
    }
  }

  Color _colorForType(RequestActivityType type) {
    switch (type) {
      case RequestActivityType.created:
        return AppColors.statusDraft;
      case RequestActivityType.edited:
        return AppColors.primary;
      case RequestActivityType.submitted:
        return AppColors.statusSubmitted;
      case RequestActivityType.approved:
        return AppColors.statusApproved;
      case RequestActivityType.rejected:
        return AppColors.statusRejected;
    }
  }

  String _titleForType(RequestActivityType type) {
    switch (type) {
      case RequestActivityType.created:
        return 'Request Created';
      case RequestActivityType.edited:
        return 'Draft Updated';
      case RequestActivityType.submitted:
        return 'Submitted for Review';
      case RequestActivityType.approved:
        return 'Request Approved';
      case RequestActivityType.rejected:
        return 'Request Rejected';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (activities.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(
              Icons.history_toggle_off_rounded,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'No activity records logged yet.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < activities.length; i++) ...[
          _buildTimelineRow(
            context,
            activity: activities[i],
            isLast: i == activities.length - 1,
            theme: theme,
          ),
        ],
      ],
    );
  }

  Widget _buildTimelineRow(
    BuildContext context, {
    required RequestActivity activity,
    required bool isLast,
    required ThemeData theme,
  }) {
    final icon = _iconForType(activity.eventType);
    final color = _colorForType(activity.eventType);
    final title = _titleForType(activity.eventType);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.15),
                  border: Border.all(color: color, width: 2),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              activity.actorRole.displayName,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        DateFormatter.formatDate(activity.timestamp),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activity.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormatter.formatTime(activity.timestamp),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
