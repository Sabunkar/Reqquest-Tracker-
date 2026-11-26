import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/constants/app_breakpoints.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../../settings/presentation/cubit/settings_state.dart';

class NavigationScaffold extends StatelessWidget {
  final Widget child;
  final String location;

  const NavigationScaffold({
    super.key,
    required this.child,
    required this.location,
  });

  Future<bool> _showExitConfirmation(BuildContext context) async {
    final theme = Theme.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        icon: Icon(
          Icons.exit_to_app_rounded,
          size: 32,
          color: theme.colorScheme.primary,
        ),
        title: const Text('Exit Application'),
        content: const Text('Are you sure you want to exit Tracker?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  int _calculateSelectedIndex(String loc) {
    if (loc.startsWith('/requests') && !loc.startsWith('/requests/create')) {
      return 1;
    }
    if (loc.startsWith('/settings')) {
      return 2;
    }
    return 0; // /dashboard or default
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/requests');
        break;
      case 2:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(location);
    final isWideScreen =
        MediaQuery.of(context).size.width >= AppBreakpoints.tablet;
    final theme = Theme.of(context);

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settingsState) {
        final isUser = settingsState.role.isUser;
        final showFab =
            isUser && (location == '/dashboard' || location == '/requests');
        final isRootDashboard = location == '/dashboard';

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;

            // 1. If child or root navigator has routes to pop, pop them
            if (context.canPop()) {
              context.pop();
              return;
            }

            // 2. If on root Dashboard, prompt exit confirmation
            if (isRootDashboard) {
              final shouldExit = await _showExitConfirmation(context);
              if (shouldExit && context.mounted) {
                SystemNavigator.pop();
              }
              return;
            }

            // 3. If on secondary shell screen (Request List, Settings, etc.),
            // navigate back to Dashboard without closing the application
            if (context.mounted) {
              context.go('/dashboard');
            }
          },
          child: Scaffold(
            drawer: AppDrawer(currentLocation: location),
            body: Row(
              children: [
                if (isWideScreen) ...[
                  NavigationRail(
                    selectedIndex: selectedIndex,
                    onDestinationSelected: (idx) => _onItemTapped(idx, context),
                    labelType: NavigationRailLabelType.all,
                    minWidth: 80,
                    backgroundColor: theme.colorScheme.surface,
                    leading: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Builder(
                        builder: (railCtx) => IconButton(
                          icon: const Icon(Icons.menu_rounded),
                          tooltip: 'Open navigation drawer',
                          onPressed: () => Scaffold.of(railCtx).openDrawer(),
                        ),
                      ),
                    ),
                    trailing: showFab
                        ? Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 24.0),
                                child: FloatingActionButton(
                                  tooltip: 'Create Request',
                                  elevation: 2,
                                  onPressed: () =>
                                      context.push('/requests/create'),
                                  child: const Icon(Icons.add_rounded),
                                ),
                              ),
                            ),
                          )
                        : null,
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.dashboard_outlined),
                        selectedIcon: Icon(Icons.dashboard_rounded),
                        label: Text('Dashboard'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.list_alt_outlined),
                        selectedIcon: Icon(Icons.list_alt_rounded),
                        label: Text('Requests'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.settings_outlined),
                        selectedIcon: Icon(Icons.settings_rounded),
                        label: Text('Settings'),
                      ),
                    ],
                  ),
                  const VerticalDivider(thickness: 1, width: 1),
                ],
                Expanded(child: child),
              ],
            ),
            bottomNavigationBar: isWideScreen
                ? null
                : NavigationBar(
                    selectedIndex: selectedIndex,
                    onDestinationSelected: (idx) => _onItemTapped(idx, context),
                    elevation: 2,
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.dashboard_outlined),
                        selectedIcon: Icon(Icons.dashboard_rounded),
                        label: 'Dashboard',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.list_alt_outlined),
                        selectedIcon: Icon(Icons.list_alt_rounded),
                        label: 'Requests',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.settings_outlined),
                        selectedIcon: Icon(Icons.settings_rounded),
                        label: 'Settings',
                      ),
                    ],
                  ),
            floatingActionButton: (!isWideScreen && showFab)
                ? FloatingActionButton.extended(
                    onPressed: () => context.push('/requests/create'),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('New Request'),
                    tooltip: 'Create a new draft request',
                  )
                : null,
          ),
        );
      },
    );
  }
}
