import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/widgets/common.dart';
import '../../models/crm_notification.dart';
import '../../services/notification_repository.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _repo = NotificationRepository();
  late Future<List<CrmNotification>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.fetchMyNotifications();
  }

  void _reload() => setState(() {
    _future = _repo.fetchMyNotifications();
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              await _repo.markAllRead();
              _reload();
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: FutureBuilder<List<CrmNotification>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const LoadingView();
          }
          if (snap.hasError) {
            return ErrorRetryView(
              message: 'Failed to load notifications.\n${snap.error}',
              onRetry: _reload,
            );
          }
          final items = snap.data!;
          if (items.isEmpty) {
            return const EmptyState(
              message: 'No notifications',
              icon: Icons.notifications_none,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final n = items[i];
                return ListTile(
                  tileColor: n.isRead
                      ? AppColors.transparent
                      : AppColors.primary.withValues(alpha: 0.05),
                  leading: Icon(
                    _iconFor(n.notificationType),
                    color: n.isRead ? AppColors.iconMuted : AppColors.primary,
                  ),
                  title: Text(
                    n.title,
                    style: TextStyle(
                      fontWeight: n.isRead
                          ? FontWeight.normal
                          : FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(n.message),
                  trailing: Text(
                    DateFormat.MMMd().add_jm().format(n.createdAt),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  onTap: () async {
                    if (!n.isRead) {
                      await _repo.markRead(n.id);
                      _reload();
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'lead_assigned':
        return Icons.person_add_alt;
      case 'follow_up_due_today':
        return Icons.today_outlined;
      case 'follow_up_overdue':
        return Icons.warning_amber_outlined;
      case 'deal_closing_soon':
        return Icons.hourglass_bottom;
      case 'opportunity_won':
        return Icons.emoji_events_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }
}
