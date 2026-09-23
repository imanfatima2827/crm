import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/widgets/common.dart';
import '../../models/activity.dart';
import '../../services/activity_repository.dart';
import 'activity_form_screen.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});
  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen>
    with SingleTickerProviderStateMixin {
  final _repo = ActivityRepository();
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const ActivityFormScreen()),
          );
          if (created == true) setState(() {});
        },
        icon: const Icon(Icons.add),
        label: const Text('Log Activity'),
      ),
      body: Column(
        children: [
          Material(
            color: AppColors.surfaceCard,
            child: TabBar(
              controller: _tab,
              labelColor: AppColors.primary,
              tabs: const [
                Tab(text: 'Pending'),
                Tab(text: 'Upcoming'),
                Tab(text: 'Overdue'),
                Tab(text: 'Completed'),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _ActivityList(future: _repo.fetchActivities(status: 'pending')),
                _ActivityList(future: _repo.fetchUpcoming(limit: 100)),
                _ActivityList(
                  future: _repo.fetchOverdue(limit: 100),
                  overdue: true,
                ),
                _ActivityList(
                  future: _repo.fetchActivities(status: 'completed'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityList extends StatefulWidget {
  final Future<List<Activity>> future;
  final bool overdue;
  const _ActivityList({required this.future, this.overdue = false});
  @override
  State<_ActivityList> createState() => _ActivityListState();
}

class _ActivityListState extends State<_ActivityList> {
  final _repo = ActivityRepository();
  late Future<List<Activity>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.future;
  }

  Future<void> _complete(Activity a) async {
    await _repo.markCompleted(a.id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Activity>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const LoadingView();
        }
        if (snap.hasError) {
          return ErrorRetryView(
            message: 'Failed to load activities.\n${snap.error}',
            onRetry: () => setState(() {}),
          );
        }
        final list = snap.data!;
        if (list.isEmpty) return const EmptyState(message: 'Nothing here');
        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 90, top: 8),
          itemCount: list.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final a = list[i];
            return ListTile(
              leading: Icon(
                _iconFor(a.activityType),
                color: widget.overdue ? AppColors.danger : AppColors.primary,
              ),
              title: Text(
                a.subject,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${a.leadName ?? a.customerName ?? a.opportunityTitle ?? ''} \u00b7 ${DateFormat.yMMMd().add_jm().format(a.scheduledAt)}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              trailing: a.status == 'pending'
                  ? IconButton(
                      tooltip: 'Mark completed',
                      icon: const Icon(Icons.check_circle_outline),
                      onPressed: () => _complete(a),
                    )
                  : StatusBadge(status: a.status),
            );
          },
        );
      },
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'call':
        return Icons.call_outlined;
      case 'meeting':
        return Icons.groups_2_outlined;
      case 'email':
        return Icons.email_outlined;
      case 'follow_up':
        return Icons.replay_outlined;
      default:
        return Icons.notes_outlined;
    }
  }
}
