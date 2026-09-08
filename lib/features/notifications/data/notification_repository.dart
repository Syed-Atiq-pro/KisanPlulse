import 'package:supabase_flutter/supabase_flutter.dart';

import 'notification_models.dart';

class NotificationRepository {
  NotificationRepository(this.client);

  final SupabaseClient client;

  String get _userId => client.auth.currentUser!.id;

  Future<List<AppNotification>> list({bool unreadOnly = false}) async {
    var query = client
        .from('notifications')
        .select('id,type,severity,title,message,read,created_at')
        .eq('user_id', _userId);
    if (unreadOnly) query = query.eq('read', false);
    final rows = await query.order('created_at', ascending: false).limit(100);
    return (rows as List)
        .map((row) => AppNotification.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Stream<List<AppNotification>> watch() {
    return client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', _userId)
        .order('created_at', ascending: false)
        .limit(100)
        .map(
          (rows) => rows
              .map((row) => AppNotification.fromMap(Map<String, dynamic>.from(row)))
              .toList(),
        );
  }

  Future<void> markRead(String id) async {
    await client.from('notifications').update({'read': true}).eq('id', id).eq('user_id', _userId);
  }

  Future<void> markAllRead() async {
    await client.from('notifications').update({'read': true}).eq('user_id', _userId).eq('read', false);
  }

  Future<void> delete(String id) async {
    await client.from('notifications').delete().eq('id', id).eq('user_id', _userId);
  }
}
