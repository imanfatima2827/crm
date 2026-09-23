import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/widgets/common.dart';
import '../../models/profile.dart';
import '../../services/user_repository.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});
  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _repo = UserRepository();
  late Future<List<Profile>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.fetchAllUsers();
  }

  void _reload() => setState(() {
    _future = _repo.fetchAllUsers();
  });

  Future<void> _editAccess(Profile user, List<Profile> allUsers) async {
    String role = user.roleSlug ?? 'sales_rep';
    String? managerId = user.managerId;
    bool active = user.isActive;
    final managers = allUsers
        .where((u) => u.id != user.id && (u.isAdmin || u.isManager))
        .toList();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setD) {
          return AlertDialog(
            title: Text(user.fullName),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(
                      value: 'sales_manager',
                      child: Text('Sales Manager'),
                    ),
                    DropdownMenuItem(
                      value: 'sales_rep',
                      child: Text('Sales Representative'),
                    ),
                  ],
                  onChanged: (v) => setD(() => role = v!),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String?>(
                  initialValue: managerId,
                  decoration: const InputDecoration(labelText: 'Reports to'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('None')),
                    for (final m in managers)
                      DropdownMenuItem(value: m.id, child: Text(m.fullName)),
                  ],
                  onChanged: (v) => setD(() => managerId = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  value: active,
                  onChanged: (v) => setD(() => active = v),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed != true) return;
    try {
      await _repo.setUserAccess(
        userId: user.id,
        roleSlug: role,
        managerId: managerId,
        isActive: active,
      );
      _reload();
    } catch (e) {
      if (!mounted) return;
      showError(context, e, prefix: 'Update failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Profile>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const LoadingView();
          }
          if (snap.hasError) {
            return ErrorRetryView(
              message: 'Failed to load users.\n${snap.error}',
              onRetry: _reload,
            );
          }
          final users = snap.data!;
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: users.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final u = users[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Text(
                    u.fullName.isNotEmpty ? u.fullName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                title: Text(
                  u.fullName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${u.email ?? ''} \u00b7 ${u.roleName ?? u.roleSlug ?? ''}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!u.isActive) const StatusBadge(status: 'inactive'),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _editAccess(u, users),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
