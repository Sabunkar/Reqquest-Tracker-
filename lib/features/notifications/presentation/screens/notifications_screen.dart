import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/widgets/empty_widget.dart';
import '../../../../core/widgets/responsive_container.dart';

class _NotificationItem {
  final String id;
  final String title;
  final String message;
  final String time;
  final IconData icon;
  final Color color;
  bool isRead;

  _NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.color,
    this.isRead = false,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<_NotificationItem> _notifications = [
    _NotificationItem(
      id: 'notif_1',
      title: 'Request Approved',
      message:
          'REQ-1002 (Software Access Request) was approved by Sarah Miller.',
      time: '10m ago',
      icon: Icons.check_circle_outline_rounded,
      color: AppColors.statusApproved,
      isRead: false,
    ),
    _NotificationItem(
      id: 'notif_2',
      title: 'New Request Submitted',
      message: 'REQ-1004 has been submitted and is awaiting reviewer action.',
      time: '1h ago',
      icon: Icons.send_rounded,
      color: AppColors.statusSubmitted,
      isRead: false,
    ),
    _NotificationItem(
      id: 'notif_3',
      title: 'Review SLA Alert',
      message: 'REQ-1001 is approaching the 48-hour compliance review window.',
      time: '3h ago',
      icon: Icons.warning_amber_rounded,
      color: AppColors.warning,
      isRead: true,
    ),
    _NotificationItem(
      id: 'notif_4',
      title: 'System Maintenance',
      message: 'Tracker platform upgrade scheduled for Saturday at 02:00 UTC.',
      time: '1d ago',
      icon: Icons.info_outline_rounded,
      color: AppColors.primary,
      isRead: true,
    ),
  ];

  void _markAllAsRead() {
    setState(() {
      for (final n in _notifications) {
        n.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _clearAll() {
    setState(() {
      _notifications.clear();
    });
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
        drawer: const AppDrawer(currentLocation: '/notifications'),
        appBar: AppBar(
          title: const Text('Notifications'),
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
            if (_notifications.isNotEmpty) ...[
              IconButton(
                icon: const Icon(Icons.done_all_rounded),
                tooltip: 'Mark all read',
                onPressed: _markAllAsRead,
              ),
              IconButton(
                icon: const Icon(Icons.clear_all_rounded),
                tooltip: 'Clear All',
                onPressed: _clearAll,
              ),
            ],
            const SizedBox(width: 8),
          ],
        ),
        body: _notifications.isEmpty
            ? const EmptyWidget(
                title: 'No Notifications',
                subtitle: 'You are all caught up! New alerts will appear here.',
                icon: Icons.notifications_none_rounded,
              )
            : ResponsiveContainer(
                maxWidth: 800,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: ListView.separated(
                  itemCount: _notifications.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final notif = _notifications[index];

                    return Card(
                      color: notif.isRead
                          ? (isDark
                                ? AppColors.surfaceDark
                                : AppColors.surfaceLight)
                          : (isDark
                                ? AppColors.surfaceVariantDark
                                : AppColors.surfaceVariantLight),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: notif.color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(notif.icon, color: notif.color, size: 22),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                notif.title,
                                style: AppTextStyles.titleSmall.copyWith(
                                  fontWeight: notif.isRead
                                      ? FontWeight.w500
                                      : FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              notif.time,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: isDark
                                    ? AppColors.textMutedDark
                                    : AppColors.textMutedLight,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            notif.message,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ),
                        trailing: notif.isRead
                            ? null
                            : Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                        onTap: () {
                          setState(() {
                            notif.isRead = true;
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
