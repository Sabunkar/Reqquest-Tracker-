import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/widgets/empty_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/responsive_container.dart';
import '../../../../injection/dependency_injection.dart';
import '../../domain/entities/request_activity.dart';
import '../../domain/repositories/request_repository.dart';

class ActivityHistoryScreen extends StatefulWidget {
  const ActivityHistoryScreen({super.key});

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen> {
  bool _isLoading = true;
  List<RequestActivity> _activities = [];
  Map<String, String> _requestTitles = {};

  @override
  void initState() {
    super.initState();
    _loadAllActivities();
  }

  Future<void> _loadAllActivities() async {
    setState(() => _isLoading = true);
    try {
      final repo = sl<RequestRepository>();
      final requests = await repo.getRequests();
      final titles = <String, String>{};
      final allActivities = <RequestActivity>[];

      for (final req in requests) {
        titles[req.id] = req.title;
        final acts = await repo.getRequestActivities(req.id);
        allActivities.addAll(acts);
      }

      // Sort chronological descending
      allActivities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (mounted) {
        setState(() {
          _activities = allActivities;
          _requestTitles = titles;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

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
          context.go('/dashboard');
        }
      },
      child: Scaffold(
        drawer: const AppDrawer(currentLocation: '/activity-history'),
        appBar: AppBar(
          title: const Text('Activity History'),
          leading: Builder(
            builder: (ctx) {
              if (context.canPop()) {
                return IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'Back',
                  onPressed: () => context.pop(),
                );
              }
              return IconButton(
                icon: const Icon(Icons.menu_rounded),
                tooltip: 'Open navigation drawer',
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              );
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh Timeline',
              onPressed: _loadAllActivities,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: _isLoading
            ? const LoadingWidget(message: 'Loading activity history...')
            : _activities.isEmpty
            ? const EmptyWidget(
                title: 'No Activity Recorded Yet',
                subtitle:
                    'Activity history is automatically recorded when requests are created, edited, submitted, approved, or rejected.',
                icon: Icons.history_rounded,
              )
            : ResponsiveContainer(
                maxWidth: 960,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: ListView.separated(
                  itemCount: _activities.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final act = _activities[index];
                    final title = _requestTitles[act.requestId] ?? 'Request';

                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: _buildActivityIcon(act.eventType, isDark),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: AppTextStyles.titleSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildActorBadge(act.actorRole.displayName, isDark),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              act.description,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormatter.formatRelative(act.timestamp),
                              style: AppTextStyles.labelSmall.copyWith(
                                color: isDark
                                    ? AppColors.textMutedDark
                                    : AppColors.textMutedLight,
                              ),
                            ),
                          ],
                        ),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                        ),
                        onTap: () => context.push('/requests/${act.requestId}'),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildActivityIcon(RequestActivityType type, bool isDark) {
    IconData icon;
    Color color;

    switch (type) {
      case RequestActivityType.created:
        icon = Icons.add_circle_outline_rounded;
        color = AppColors.primary;
        break;
      case RequestActivityType.edited:
        icon = Icons.edit_note_rounded;
        color = AppColors.warning;
        break;
      case RequestActivityType.submitted:
        icon = Icons.send_rounded;
        color = AppColors.statusSubmitted;
        break;
      case RequestActivityType.approved:
        icon = Icons.check_circle_outline_rounded;
        color = AppColors.statusApproved;
        break;
      case RequestActivityType.rejected:
        icon = Icons.cancel_outlined;
        color = AppColors.statusRejected;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildActorBadge(String actor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceVariantDark
            : AppColors.surfaceVariantLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Text(
        actor,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
      ),
    );
  }
}
