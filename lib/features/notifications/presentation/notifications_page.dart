import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/notification_models.dart';
import '../data/notification_repository.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _repo = NotificationRepository(Supabase.instance.client);
  late Stream<List<AppNotification>> _stream;
  bool _markingAll = false;

  @override
  void initState() {
    super.initState();
    _stream = _repo.watch();
  }

  Future<void> _markAllRead() async {
    if (_markingAll) return;
    setState(() => _markingAll = true);
    try {
      await _repo.markAllRead();
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  Future<void> _markRead(AppNotification item) async {
    if (item.read) return;
    try {
      await _repo.markRead(item.id);
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _delete(AppNotification item) async {
    try {
      await _repo.delete(item.id);
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Notification update failed: $error')),
    );
  }

  IconData _icon(String type) {
    switch (type) {
      case 'weather':
        return Icons.cloud_rounded;
      case 'irrigation':
        return Icons.water_drop_rounded;
      case 'disease':
        return Icons.health_and_safety_rounded;
      case 'market':
        return Icons.storefront_rounded;
      case 'harvest':
        return Icons.agriculture_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _severityColor(BuildContext context, String severity) {
    final scheme = Theme.of(context).colorScheme;
    switch (severity) {
      case 'critical':
        return scheme.error;
      case 'warning':
        return scheme.tertiary;
      case 'success':
        return scheme.primary;
      default:
        return scheme.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            onPressed: _markingAll ? null : _markAllRead,
            tooltip: 'Mark all as read',
            icon: _markingAll
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.done_all_rounded),
          ),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Could not load notifications: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? const <AppNotification>[];
          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                setState(() => _stream = _repo.watch());
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 180),
                  Icon(Icons.notifications_none_rounded, size: 64),
                  SizedBox(height: 16),
                  Center(child: Text('You are all caught up.')),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => setState(() => _stream = _repo.watch()),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index];
                final iconColor = _severityColor(context, item.severity);
                return Dismissible(
                  key: ValueKey(item.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _delete(item),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.delete_outline_rounded, color: Theme.of(context).colorScheme.onErrorContainer),
                  ),
                  child: Card(
                    elevation: item.read ? 0 : 2,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: iconColor.withValues(alpha: 0.12),
                        foregroundColor: iconColor,
                        child: Icon(_icon(item.type)),
                      ),
                      title: Row(
                        children: [
                          Expanded(child: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700))),
                          if (!item.read)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
                            ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text('${item.message}\n${DateFormat('dd MMM, hh:mm a').format(item.createdAt.toLocal())}'),
                      ),
                      isThreeLine: true,
                      onTap: () => _markRead(item),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
