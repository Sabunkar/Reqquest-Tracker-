import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/constants/app_breakpoints.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/widgets/responsive_container.dart';
import '../../domain/entities/user_role.dart';
import '../cubit/settings_cubit.dart';
import '../cubit/settings_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
        drawer: const AppDrawer(currentLocation: '/settings'),
        appBar: AppBar(
          title: const Text('Settings'),
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
        body: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: ResponsiveContainer(
                maxWidth: AppBreakpoints.maxContentWidthCompact,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Profile & Role Group
                    _buildSectionHeader(
                      context,
                      title: 'User Profile & Role',
                      icon: Icons.person_pin_circle_outlined,
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: RadioGroup<UserRole>(
                        groupValue: state.role,
                        onChanged: (role) {
                          if (role != null) {
                            context.read<SettingsCubit>().setUserRole(role);
                          }
                        },
                        child: Column(
                          children: [
                            RadioListTile<UserRole>(
                              value: UserRole.user,
                              secondary: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.create_new_folder_outlined,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              title: const Text(
                                'Requester (User)',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: const Text(
                                'Create draft requests, edit drafts, and submit for review.',
                              ),
                            ),
                            const Divider(),
                            RadioListTile<UserRole>(
                              value: UserRole.reviewer,
                              secondary: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.statusSubmitted.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.fact_check_outlined,
                                  color: AppColors.statusSubmitted,
                                  size: 20,
                                ),
                              ),
                              title: const Text(
                                'Approver (Reviewer)',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: const Text(
                                'View submitted requests, approve, or reject with a reason.',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Appearance Theme Group
                    _buildSectionHeader(
                      context,
                      title: 'Appearance',
                      icon: Icons.palette_outlined,
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: RadioGroup<ThemeMode>(
                        groupValue: state.themeMode,
                        onChanged: (mode) {
                          if (mode != null) {
                            context.read<SettingsCubit>().setThemeMode(mode);
                          }
                        },
                        child: const Column(
                          children: [
                            RadioListTile<ThemeMode>(
                              value: ThemeMode.system,
                              secondary: Icon(Icons.brightness_auto_outlined),
                              title: Text('System Default'),
                              subtitle: Text('Match device light or dark mode'),
                            ),
                            Divider(),
                            RadioListTile<ThemeMode>(
                              value: ThemeMode.light,
                              secondary: Icon(Icons.light_mode_outlined),
                              title: Text('Light Mode'),
                              subtitle: Text(
                                'Crisp light surfaces and slate borders',
                              ),
                            ),
                            Divider(),
                            RadioListTile<ThemeMode>(
                              value: ThemeMode.dark,
                              secondary: Icon(Icons.dark_mode_outlined),
                              title: Text('Dark Mode'),
                              subtitle: Text(
                                'Deep navy surfaces with subtle contrast',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Developer Resilience Options
                    _buildSectionHeader(
                      context,
                      title: 'Developer Options',
                      icon: Icons.bug_report_outlined,
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: SwitchListTile(
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: state.simulateApiFailure
                                ? Colors.red.withValues(alpha: 0.1)
                                : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.wifi_off_rounded,
                            color: state.simulateApiFailure
                                ? Colors.red
                                : theme.colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                        ),
                        title: const Text(
                          'Simulate API Failure',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text(
                          'Causes all API operations to fail with a simulated network error to verify retry and error handling resilience.',
                        ),
                        value: state.simulateApiFailure,
                        onChanged: (value) {
                          context.read<SettingsCubit>().setSimulateApiFailure(
                            value,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
