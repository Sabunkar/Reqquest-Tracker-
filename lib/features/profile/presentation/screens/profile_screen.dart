import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/widgets/responsive_container.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../settings/domain/entities/user_role.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../../settings/presentation/cubit/settings_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        return BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, settingsState) {
            final role = settingsState.role;
            final isUser = role.isUser;
            final user = authState.user;

            final name =
                user?.name ?? (isUser ? 'Alex Johnson' : 'Sarah Miller');
            final email =
                user?.email ??
                (isUser
                    ? 'requester@requestflow.internal'
                    : 'reviewer@requestflow.internal');
            final department =
                user?.department ??
                (isUser ? 'Engineering Operations' : 'Compliance & Approvals');
            final initials = user?.initials ?? (isUser ? 'AJ' : 'SM');

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
                drawer: const AppDrawer(currentLocation: '/profile'),
                appBar: AppBar(
                  title: const Text('My Profile'),
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
                      icon: const Icon(Icons.settings_outlined),
                      tooltip: 'Settings',
                      onPressed: () => context.go('/settings'),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                body: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child: ResponsiveContainer(
                    maxWidth: 720,
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Profile Card
                        Card(
                          child: Padding(
                            padding: EdgeInsets.all(
                              MediaQuery.of(context).size.width < 360
                                  ? 16.0
                                  : 24.0,
                            ),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  child: Text(
                                    initials,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(name, style: AppTextStyles.titleLarge),
                                const SizedBox(height: 4),
                                Text(
                                  email,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isUser
                                        ? AppColors.primary.withValues(
                                            alpha: 0.12,
                                          )
                                        : AppColors.statusSubmitted.withValues(
                                            alpha: 0.12,
                                          ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isUser
                                          ? AppColors.primary.withValues(
                                              alpha: 0.3,
                                            )
                                          : AppColors.statusSubmitted
                                                .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isUser
                                            ? Icons.person_outline
                                            : Icons.fact_check_outlined,
                                        size: 16,
                                        color: isUser
                                            ? (isDark
                                                  ? AppColors.primaryLight
                                                  : AppColors.primary)
                                            : (isDark
                                                  ? AppColors
                                                        .statusSubmittedDark
                                                  : AppColors.statusSubmitted),
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          isUser
                                              ? 'Requester (User)'
                                              : 'Approver (Reviewer)',
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: isUser
                                                ? (isDark
                                                      ? AppColors.primaryLight
                                                      : AppColors.primary)
                                                : (isDark
                                                      ? AppColors
                                                            .statusSubmittedDark
                                                      : AppColors
                                                            .statusSubmitted),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  department,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: isDark
                                        ? AppColors.textMutedDark
                                        : AppColors.textMutedLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Permissions Matrix
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.shield_outlined,
                                      size: 20,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Active Role Permissions',
                                        style: AppTextStyles.titleMedium,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                _buildPermissionTile(
                                  'Create Draft Requests',
                                  enabled: isUser,
                                  isDark: isDark,
                                ),
                                _buildPermissionTile(
                                  'Edit Draft Requests',
                                  enabled: isUser,
                                  isDark: isDark,
                                ),
                                _buildPermissionTile(
                                  'Submit Requests for Review',
                                  enabled: isUser,
                                  isDark: isDark,
                                ),
                                _buildPermissionTile(
                                  'Approve Submitted Requests',
                                  enabled: !isUser,
                                  isDark: isDark,
                                ),
                                _buildPermissionTile(
                                  'Reject Submitted Requests with Reason',
                                  enabled: !isUser,
                                  isDark: isDark,
                                ),
                                _buildPermissionTile(
                                  'Audit & Timeline Inspection',
                                  enabled: true,
                                  isDark: isDark,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Quick Actions
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Quick Actions',
                                  style: AppTextStyles.titleMedium,
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      final newRole = isUser
                                          ? UserRole.reviewer
                                          : UserRole.user;
                                      context.read<SettingsCubit>().setUserRole(
                                        newRole,
                                      );
                                      context
                                          .read<AuthCubit>()
                                          .onRoleChangedInSettings(newRole);
                                    },
                                    icon: const Icon(Icons.swap_horiz_rounded),
                                    label: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        isUser
                                            ? 'Switch to Reviewer (Approver)'
                                            : 'Switch to Requester (User)',
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.settings_outlined),
                                  title: const Text('Application Settings'),
                                  subtitle: const Text(
                                    'Manage theme, network failure simulation, and preferences',
                                  ),
                                  trailing: const Icon(
                                    Icons.chevron_right_rounded,
                                  ),
                                  onTap: () => context.go('/settings'),
                                ),
                                const Divider(),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(
                                    Icons.logout_rounded,
                                    color: AppColors.error,
                                  ),
                                  title: const Text(
                                    'Sign Out',
                                    style: TextStyle(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: const Text(
                                    'End your current session and return to login',
                                  ),
                                  onTap: () async {
                                    await context.read<AuthCubit>().logout();
                                    if (context.mounted) {
                                      context.go('/login');
                                    }
                                  },
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
          },
        );
      },
    );
  }

  Widget _buildPermissionTile(
    String permission, {
    required bool enabled,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 18,
            color: enabled ? AppColors.success : AppColors.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              permission,
              style: TextStyle(
                fontSize: 13,
                fontWeight: enabled ? FontWeight.w500 : FontWeight.w400,
                color: enabled
                    ? (isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight)
                    : (isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight),
                decoration: enabled ? null : TextDecoration.lineThrough,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
