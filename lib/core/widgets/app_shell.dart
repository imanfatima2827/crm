import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';
import '../../state/auth_provider.dart';
import '../../state/lookup_provider.dart';
import '../../services/notification_repository.dart';
import '../../services/realtime_service.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/leads/leads_list_screen.dart';
import '../../features/customers/customers_list_screen.dart';
import '../../features/pipeline/pipeline_screen.dart';
import '../../features/activities/activities_screen.dart';
import '../../features/products/products_screen.dart';
import '../../features/reports/reports_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/users/users_screen.dart';
import '../../features/search/global_search_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/audit/audit_log_screen.dart';
import '../../features/settings/app_settings_screen.dart';

class NavItem {
  final String label;
  final IconData icon;
  final Widget Function() builder;
  final bool adminOnly;
  const NavItem(this.label, this.icon, this.builder, {this.adminOnly = false});
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  int _unread = 0;
  RealtimeChannel? _notificationsChannel;
  String? _subscribedUserId;

  final List<NavItem> _items = [
    NavItem(
      'Dashboard',
      Icons.dashboard_outlined,
      () => const DashboardScreen(),
    ),
    NavItem(
      'Leads',
      Icons.person_add_alt_outlined,
      () => const LeadsListScreen(),
    ),
    NavItem(
      'Customers',
      Icons.groups_outlined,
      () => const CustomersListScreen(),
    ),
    NavItem(
      'Pipeline',
      Icons.view_kanban_outlined,
      () => const PipelineScreen(),
    ),
    NavItem(
      'Activities',
      Icons.event_note_outlined,
      () => const ActivitiesScreen(),
    ),
    NavItem(
      'Products',
      Icons.inventory_2_outlined,
      () => const ProductsScreen(),
    ),
    NavItem('Reports', Icons.bar_chart_outlined, () => const ReportsScreen()),
    NavItem(
      'Users',
      Icons.admin_panel_settings_outlined,
      () => const UsersScreen(),
      adminOnly: true,
    ),
    NavItem(
      'Audit Log',
      Icons.history_outlined,
      () => const AuditLogScreen(),
      adminOnly: true,
    ),
    NavItem(
      'Settings',
      Icons.settings_outlined,
      () => const AppSettingsScreen(),
      adminOnly: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LookupProvider>().loadAll();
      _loadUnread();
      _subscribeToNotifications();
    });
  }

  void _subscribeToNotifications() {
    final userId = context.read<AuthProvider>().profile?.id;
    if (userId == null || userId == _subscribedUserId) return;
    RealtimeService.stop(_notificationsChannel);
    _subscribedUserId = userId;
    _notificationsChannel = RealtimeService.watchNotifications(
      userId,
      _loadUnread,
    );
  }

  @override
  void dispose() {
    RealtimeService.stop(_notificationsChannel);
    super.dispose();
  }

  Future<void> _loadUnread() async {
    final count = await NotificationRepository().fetchUnreadCount();
    if (mounted) setState(() => _unread = count);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.profile != null && auth.profile!.id != _subscribedUserId) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _subscribeToNotifications(),
      );
    }
    final isAdmin = auth.isAdmin;
    final items = _items.where((i) => !i.adminOnly || isAdmin).toList();
    final safeIndex = _index >= items.length ? 0 : _index;
    final wide = MediaQuery.of(context).size.width >= 900;

    final content = items[safeIndex].builder();

    return Scaffold(
      appBar: AppBar(
        title: wide
            ? Text(items[safeIndex].label)
            : Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      'assets/logo.png',
                      width: 28,
                      height: 28,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      items[safeIndex].label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
        actions: [
          IconButton(
            tooltip: 'Search',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GlobalSearchScreen()),
            ),
            icon: const Icon(Icons.search),
          ),
          IconButton(
            tooltip: 'Notifications',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
              _loadUnread();
            },
            icon: Badge(
              label: Text('$_unread'),
              isLabelVisible: _unread > 0,
              backgroundColor: AppColors.danger,
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
          PopupMenuButton<String>(
            offset: const Offset(0, 46),
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              child: Text(
                (auth.profile?.fullName.isNotEmpty == true
                        ? auth.profile!.fullName[0]
                        : '?')
                    .toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onSelected: (v) {
              if (v == 'signout') auth.signOut();
              if (v == 'profile') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Text(
                  '${auth.profile?.fullName ?? ''}\n${auth.profile?.roleName ?? ''}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 18),
                    SizedBox(width: 10),
                    Text('My Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'signout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: AppColors.danger),
                    SizedBox(width: 10),
                    Text('Sign out', style: TextStyle(color: AppColors.danger)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      drawer: wide
          ? null
          : Drawer(
              child: SafeArea(
                child: ListView(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryDark,
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.asset(
                              'assets/logo.png',
                              width: 32,
                              height: 32,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Sales CRM',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(color: AppColors.textOnPrimary),
                          ),
                        ],
                      ),
                    ),
                    for (int i = 0; i < items.length; i++)
                      ListTile(
                        leading: Icon(items[i].icon, color: AppColors.primary),
                        title: Text(
                          items[i].label,
                          style: TextStyle(
                            color: i == safeIndex
                                ? AppColors.primary
                                : AppColors.textPrimary,
                            fontWeight: i == safeIndex ? FontWeight.w700 : null,
                          ),
                        ),
                        selected: i == safeIndex,
                        selectedTileColor: AppColors.primary.withValues(
                          alpha: 0.06,
                        ),
                        onTap: () {
                          setState(() => _index = i);
                          Navigator.pop(context);
                        },
                      ),
                  ],
                ),
              ),
            ),
      body: wide
          ? Row(
              children: [
                Container(
                  width: 220,
                  color: AppColors.surfaceCard,
                  child: Column(
                    children: [
                      Container(
                        height: 64,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.asset(
                                'assets/logo.png',
                                width: 30,
                                height: 30,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Sales CRM',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          children: [
                            for (int i = 0; i < items.length; i++)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 2,
                                ),
                                child: Material(
                                  color: i == safeIndex
                                      ? AppColors.primary.withValues(
                                          alpha: 0.08,
                                        )
                                      : AppColors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  child: ListTile(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    leading: Icon(
                                      items[i].icon,
                                      size: 20,
                                      color: AppColors.primary,
                                    ),
                                    title: Text(
                                      items[i].label,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: i == safeIndex
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: i == safeIndex
                                            ? AppColors.primary
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                    onTap: () => setState(() => _index = i),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ],
            )
          : content,
    );
  }
}
