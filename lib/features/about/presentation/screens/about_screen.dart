import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/widgets/responsive_container.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
        drawer: const AppDrawer(currentLocation: '/about'),
        appBar: AppBar(
          title: const Text('Help & About'),
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
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: ResponsiveContainer(
            maxWidth: 720,
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Branding Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 80,
                            height: 80,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('Tracker', style: AppTextStyles.displayMedium),
                        const SizedBox(height: 4),
                        Text(
                          'Version 1.0.0 Enterprise Edition',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Role-based request management, approval workflow, and governance platform with optimistic concurrency control and persisted activity history.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Architectural Highlights
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Architecture & Capabilities',
                          style: AppTextStyles.titleMedium,
                        ),
                        const SizedBox(height: 14),
                        _buildFeatureTile(
                          icon: Icons.layers_outlined,
                          title: 'Clean Architecture & Cubit',
                          description:
                              'Strict separation of Domain, Data, and Presentation layers using Bloc/Cubit state management.',
                          isDark: isDark,
                        ),
                        const Divider(),
                        _buildFeatureTile(
                          icon: Icons.sync_problem_outlined,
                          title: 'Optimistic Concurrency Control',
                          description:
                              'Version-checked mutations prevent lost updates and support user-guided conflict resolution.',
                          isDark: isDark,
                        ),
                        const Divider(),
                        _buildFeatureTile(
                          icon: Icons.history_edu_rounded,
                          title: 'Persisted Activity Audit',
                          description:
                              'Atomic recording of creation, edit, submission, approval, and rejection events.',
                          isDark: isDark,
                        ),
                        const Divider(),
                        _buildFeatureTile(
                          icon: Icons.devices_rounded,
                          title: 'Adaptive & Responsive UI',
                          description:
                              'Seamless adaptation across 320dp mobile, tablet navigation rails, and desktop monitors.',
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Roles Overview
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'User Role Workflows',
                          style: AppTextStyles.titleMedium,
                        ),
                        const SizedBox(height: 14),
                        _buildRoleTile(
                          role: 'Requester (User)',
                          color: AppColors.primary,
                          responsibilities:
                              'Create new draft requests, edit draft content, submit drafts for managerial review.',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 10),
                        _buildRoleTile(
                          role: 'Approver (Reviewer)',
                          color: AppColors.statusSubmitted,
                          responsibilities:
                              'Inspect submitted requests in the Review Queue, approve with audit trail, or reject with a mandatory explanation.',
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureTile({
    required IconData icon,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceVariantDark
                  : AppColors.surfaceVariantLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: AppColors.primaryLight),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleTile({
    required String role,
    required Color color,
    required String responsibilities,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            role,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            responsibilities,
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
