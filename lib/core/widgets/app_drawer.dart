import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';
import '../../features/settings/domain/entities/user_role.dart';
import '../../features/settings/presentation/cubit/settings_cubit.dart';
import '../../features/settings/presentation/cubit/settings_state.dart';

class AppDrawer extends StatelessWidget {
  final String currentLocation;

  const AppDrawer({super.key, this.currentLocation = ''});

  void _navigate(BuildContext context, String path) {
    Navigator.of(context).pop(); // Close drawer
    if (path.isEmpty || currentLocation == path) return;

    context.go(path);
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.error, size: 22),
            SizedBox(width: 10),
            Text('Confirm Logout'),
          ],
        ),
        content: const Text(
          'Are you sure you want to end your current session? You will be redirected to the sign-in screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop(true);
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true && context.mounted) {
        Navigator.of(context).pop(); // Close drawer if still open
        await context.read<AuthCubit>().logout();
        if (context.mounted) {
          context.go('/login');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        return BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, settingsState) {
            final role = settingsState.role;
            final user = authState.user;
            final isUser = role.isUser;

            final userName =
                user?.name ?? (isUser ? 'Alex Johnson' : 'Sarah Miller');
            final userEmail =
                user?.email ??
                (isUser
                    ? 'requester@requestflow.internal'
                    : 'reviewer@requestflow.internal');
            final initials = user?.initials ?? (isUser ? 'AJ' : 'SM');
            final department =
                user?.department ??
                (isUser ? 'Engineering Operations' : 'Compliance & Approvals');

            return Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Drawer Header with User Profile
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 20,
                      bottom: 20,
                      left: 20,
                      right: 20,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceVariantDark
                          : theme.colorScheme.primaryContainer.withValues(
                              alpha: 0.5,
                            ),
                      border: Border(
                        bottom: BorderSide(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isUser
                                    ? AppColors.primary.withValues(alpha: 0.12)
                                    : AppColors.statusSubmitted.withValues(
                                        alpha: 0.12,
                                      ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isUser
                                      ? AppColors.primary.withValues(alpha: 0.3)
                                      : AppColors.statusSubmitted.withValues(
                                          alpha: 0.3,
                                        ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isUser
                                        ? Icons.person_outline
                                        : Icons.fact_check_outlined,
                                    size: 14,
                                    color: isUser
                                        ? (isDark
                                              ? AppColors.primaryLight
                                              : AppColors.primary)
                                        : (isDark
                                              ? AppColors.statusSubmittedDark
                                              : AppColors.statusSubmitted),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isUser ? 'Requester' : 'Approver',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isUser
                                          ? (isDark
                                                ? AppColors.primaryLight
                                                : AppColors.primary)
                                          : (isDark
                                                ? AppColors.statusSubmittedDark
                                                : AppColors.statusSubmitted),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          userName,
                          style: AppTextStyles.titleMedium.copyWith(
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          userEmail,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          department,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Role Switcher Card in Drawer
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceVariantDark
                          : AppColors.surfaceVariantLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ACTIVE ROLE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                key: const ValueKey('drawer_role_requester'),
                                onTap: () async {
                                  await context
                                      .read<SettingsCubit>()
                                      .setUserRole(UserRole.user);
                                  if (context.mounted) {
                                    context
                                        .read<AuthCubit>()
                                        .onRoleChangedInSettings(UserRole.user);
                                  }
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isUser
                                        ? theme.colorScheme.primary
                                        : (isDark
                                              ? AppColors.surfaceDark
                                              : AppColors.surfaceLight),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isUser
                                          ? theme.colorScheme.primary
                                          : (isDark
                                                ? AppColors.borderDark
                                                : AppColors.borderLight),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.person_outline_rounded,
                                        size: 16,
                                        color: isUser
                                            ? Colors.white
                                            : (isDark
                                                  ? AppColors.textSecondaryDark
                                                  : AppColors
                                                        .textSecondaryLight),
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          'Requester',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: isUser
                                                ? Colors.white
                                                : (isDark
                                                      ? AppColors
                                                            .textSecondaryDark
                                                      : AppColors
                                                            .textSecondaryLight),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: InkWell(
                                key: const ValueKey('drawer_role_reviewer'),
                                onTap: () async {
                                  await context
                                      .read<SettingsCubit>()
                                      .setUserRole(UserRole.reviewer);
                                  if (context.mounted) {
                                    context
                                        .read<AuthCubit>()
                                        .onRoleChangedInSettings(
                                          UserRole.reviewer,
                                        );
                                  }
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: !isUser
                                        ? AppColors.statusSubmitted
                                        : (isDark
                                              ? AppColors.surfaceDark
                                              : AppColors.surfaceLight),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: !isUser
                                          ? AppColors.statusSubmitted
                                          : (isDark
                                                ? AppColors.borderDark
                                                : AppColors.borderLight),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.verified_user_outlined,
                                        size: 16,
                                        color: !isUser
                                            ? Colors.white
                                            : (isDark
                                                  ? AppColors.textSecondaryDark
                                                  : AppColors
                                                        .textSecondaryLight),
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          'Reviewer',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: !isUser
                                                ? Colors.white
                                                : (isDark
                                                      ? AppColors
                                                            .textSecondaryDark
                                                      : AppColors
                                                            .textSecondaryLight),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Navigation Items
                  _buildSectionHeader('WORKFLOW'),
                  _buildDrawerTile(
                    context,
                    icon: Icons.dashboard_outlined,
                    selectedIcon: Icons.dashboard_rounded,
                    title: 'Dashboard',
                    path: '/dashboard',
                  ),
                  _buildDrawerTile(
                    context,
                    icon: Icons.list_alt_outlined,
                    selectedIcon: Icons.list_alt_rounded,
                    title: 'My Requests',
                    path: '/requests',
                  ),
                  _buildDrawerTile(
                    context,
                    icon: Icons.add_circle_outline_rounded,
                    selectedIcon: Icons.add_circle_rounded,
                    title: 'Create Request',
                    path: '/requests/create',
                    disabled: !isUser,
                    disabledTooltip: 'Only Requesters can create requests',
                    onTapOverride: !isUser
                        ? () {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Reviewers cannot create requests. Switch to Requester role in Settings to create requests.',
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        : null,
                  ),
                  _buildDrawerTile(
                    context,
                    icon: Icons.fact_check_outlined,
                    selectedIcon: Icons.fact_check_rounded,
                    title: 'Review Queue',
                    path: '/review-queue',
                    badgeCount: isUser ? null : 'Pending',
                  ),

                  const Divider(indent: 16, endIndent: 16, height: 16),
                  _buildSectionHeader('GOVERNANCE & ACTIVITY'),
                  _buildDrawerTile(
                    context,
                    icon: Icons.history_rounded,
                    selectedIcon: Icons.history_edu_rounded,
                    title: 'Activity History',
                    path: '/activity-history',
                  ),

                  const Divider(indent: 16, endIndent: 16, height: 16),
                  _buildSectionHeader('SYSTEM & ACCOUNT'),
                  _buildDrawerTile(
                    context,
                    icon: Icons.person_outline_rounded,
                    selectedIcon: Icons.person_rounded,
                    title: 'My Profile',
                    path: '/profile',
                  ),
                  _buildDrawerTile(
                    context,
                    icon: Icons.settings_outlined,
                    selectedIcon: Icons.settings_rounded,
                    title: 'Settings',
                    path: '/settings',
                  ),
                  _buildDrawerTile(
                    context,
                    icon: Icons.info_outline_rounded,
                    selectedIcon: Icons.info_rounded,
                    title: 'Help & About',
                    path: '/about',
                  ),

                  // Drawer Footer: Logout & Version
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          leading: const Icon(
                            Icons.logout_rounded,
                            color: AppColors.error,
                            size: 22,
                          ),
                          title: const Text(
                            'Logout',
                            style: TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          onTap: () => _showLogoutConfirmation(context),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tracker Enterprise v1.0.0',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: AppColors.textSecondaryLight,
        ),
      ),
    );
  }

  Widget _buildDrawerTile(
    BuildContext context, {
    required IconData icon,
    required IconData selectedIcon,
    required String title,
    required String path,
    String? badgeCount,
    bool disabled = false,
    String? disabledTooltip,
    VoidCallback? onTapOverride,
  }) {
    final isSelected = currentLocation == path;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget tile = ListTile(
      selected: isSelected,
      enabled: !disabled || onTapOverride != null,
      selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      leading: Icon(
        isSelected ? selectedIcon : icon,
        color: isSelected
            ? theme.colorScheme.primary
            : (disabled
                  ? (isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight)
                  : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight)),
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected
              ? theme.colorScheme.primary
              : (disabled
                    ? (isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight)
                    : (isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight)),
        ),
      ),
      trailing: badgeCount != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badgeCount,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            )
          : null,
      onTap:
          onTapOverride ?? (disabled ? null : () => _navigate(context, path)),
    );

    if (disabled && disabledTooltip != null) {
      tile = Tooltip(message: disabledTooltip, child: tile);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: tile,
    );
  }
}
