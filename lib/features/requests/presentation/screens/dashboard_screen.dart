import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/constants/app_breakpoints.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/widgets/empty_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/responsive_container.dart';
import '../../../../injection/dependency_injection.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../../settings/presentation/cubit/settings_state.dart';
import '../../domain/entities/request_status.dart';
import '../../domain/repositories/request_repository.dart';
import '../cubit/dashboard_cubit.dart';
import '../cubit/dashboard_state.dart';
import '../cubit/request_list_cubit.dart';
import '../widgets/request_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DashboardCubit(sl<RequestRepository>())..loadDashboard(),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      drawer: const AppDrawer(currentLocation: '/dashboard'),
      appBar: AppBar(
        title: Text(
          'Tracker',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          // Dashboard Theme Toggle directly in AppBar
          BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, state) {
              final isDark = state.themeMode == ThemeMode.dark;
              return IconButton(
                key: const ValueKey('dashboard_theme_toggle'),
                icon: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: isDark ? AppColors.warning : theme.colorScheme.primary,
                ),
                tooltip: isDark
                    ? 'Switch to Light Theme'
                    : 'Switch to Dark Theme',
                onPressed: () {
                  context.read<SettingsCubit>().setThemeMode(
                    isDark ? ThemeMode.light : ThemeMode.dark,
                  );
                },
              );
            },
          ),
          // Notifications moved to top AppBar
          IconButton(
            key: const ValueKey('dashboard_notifications_button'),
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
            onPressed: () => context.go('/notifications'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading) {
            return const LoadingWidget(message: 'Loading dashboard metrics...');
          }

          if (state is DashboardError) {
            return CustomErrorWidget(
              message: state.message,
              onRetry: () => context.read<DashboardCubit>().loadDashboard(),
            );
          }

          if (state is DashboardLoaded) {
            return RefreshIndicator(
              onRefresh: () => context.read<DashboardCubit>().loadDashboard(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ResponsiveContainer(
                  maxWidth: AppBreakpoints.maxContentWidthWide,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Greeting Card with Total Requests Summary
                      _buildGreetingCard(context, state),
                      const SizedBox(height: 20),

                      // Section Header
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            'Request Overview',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Tap a card to filter',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Metrics Grid
                      _buildMetricsGrid(context, state),
                      const SizedBox(height: 24),

                      // Reviewer Queue Section
                      BlocBuilder<SettingsCubit, SettingsState>(
                        builder: (context, settingsState) {
                          if (settingsState.role.isReviewer &&
                              state.pendingReviewRequests.isNotEmpty) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.pending_actions_rounded,
                                      color: AppColors.statusSubmitted,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Awaiting Your Review (${state.pendingReviewRequests.length})',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.statusSubmitted,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                for (final req
                                    in state.pendingReviewRequests) ...[
                                  RequestCard(
                                    request: req,
                                    onTap: () async {
                                      await context.push('/requests/${req.id}');
                                      if (context.mounted) {
                                        context
                                            .read<DashboardCubit>()
                                            .loadDashboard();
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                ],
                                const SizedBox(height: 24),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),

                      // Recent Requests Header
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            'Recent Activity',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                            onPressed: () => context.go('/requests'),
                            icon: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                            ),
                            label: const Text('View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Recent Requests List
                      if (state.recentRequests.isEmpty)
                        EmptyWidget(
                          title: 'No requests yet',
                          subtitle: 'Create a new request to get started.',
                          action: ElevatedButton.icon(
                            onPressed: () => context.push('/requests/create'),
                            icon: const Icon(Icons.add),
                            label: const Text('New Request'),
                          ),
                        )
                      else
                        for (final req in state.recentRequests) ...[
                          RequestCard(
                            request: req,
                            onTap: () async {
                              await context.push('/requests/${req.id}');
                              if (context.mounted) {
                                context.read<DashboardCubit>().loadDashboard();
                              }
                            },
                          ),
                          const SizedBox(height: 10),
                        ],
                    ],
                  ),
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildGreetingCard(BuildContext context, DashboardLoaded state) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settingsState) {
        final isUser = settingsState.role.isUser;

        return Card(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isUltraNarrow = constraints.maxWidth < 360;

                final totalBadge = InkWell(
                  key: const ValueKey('dashboard_total_card'),
                  onTap: () {
                    context.read<RequestListCubit>().filterByStatus(null);
                    context.go('/requests');
                  },
                  customBorder: const CircleBorder(),
                  child: Tooltip(
                    message: 'View all requests (${state.totalCount})',
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? AppColors.surfaceVariantDark
                                : theme.colorScheme.surface,
                            border: Border.all(
                              color: isDark
                                  ? AppColors.primaryLight.withValues(
                                      alpha: 0.5,
                                    )
                                  : theme.colorScheme.primary.withValues(
                                      alpha: 0.4,
                                    ),
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: 0.12,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${state.totalCount}',
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: isDark
                                            ? AppColors.primaryLight
                                            : AppColors.primary,
                                        height: 1.0,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'TOTAL',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Total Requests',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                );

                if (isUltraNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isUser ? 'Hello, Requester!' : 'Welcome, Reviewer!',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isUser
                            ? 'Create, manage, and track your department requests.'
                            : 'Review, approve, and resolve pending team submissions.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Center(child: totalBadge),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isUser ? 'Hello, Requester!' : 'Welcome, Reviewer!',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isUser
                                ? 'Create, manage, and track your department requests.'
                                : 'Review, approve, and resolve pending team submissions.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    totalBadge,
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricsGrid(BuildContext context, DashboardLoaded state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        if (availableWidth <= 0) {
          return const SizedBox.shrink();
        }

        final int columns;
        if (availableWidth >= 720) {
          columns = 4;
        } else if (availableWidth >= 160) {
          columns = 2;
        } else {
          columns = 1;
        }

        const spacing = 12.0;
        final totalSpacing = (columns - 1) * spacing;
        final calculatedWidth = (availableWidth - totalSpacing) / columns;
        final cardWidth = calculatedWidth > 0
            ? calculatedWidth
            : availableWidth;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            _buildStatCard(
              context,
              width: cardWidth,
              title: 'Draft',
              count: state.draftCount,
              icon: Icons.edit_note_outlined,
              color: AppColors.statusDraft,
              statusFilter: RequestStatus.draft,
            ),
            _buildStatCard(
              context,
              width: cardWidth,
              title: 'Submitted',
              count: state.submittedCount,
              icon: Icons.send_outlined,
              color: AppColors.statusSubmitted,
              statusFilter: RequestStatus.submitted,
            ),
            _buildStatCard(
              context,
              width: cardWidth,
              title: 'Approved',
              count: state.approvedCount,
              icon: Icons.check_circle_outline,
              color: AppColors.statusApproved,
              statusFilter: RequestStatus.approved,
            ),
            _buildStatCard(
              context,
              width: cardWidth,
              title: 'Rejected',
              count: state.rejectedCount,
              icon: Icons.cancel_outlined,
              color: AppColors.statusRejected,
              statusFilter: RequestStatus.rejected,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required double width,
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required RequestStatus? statusFilter,
  }) {
    if (width <= 0) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);

    return SizedBox(
      width: width,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            context.read<RequestListCubit>().filterByStatus(statusFilter);
            context.go('/requests');
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 14.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, size: 18, color: color),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '$count',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Requests',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
