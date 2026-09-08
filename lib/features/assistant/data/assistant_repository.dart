import 'package:supabase_flutter/supabase_flutter.dart';
import 'assistant_models.dart';

class AssistantRepository {
  AssistantRepository(this.client);
  final SupabaseClient client;

  Future<List<AssistantConversation>> listConversations() async {
    final rows = await client.from('ai_conversations').select('id,title,updated_at').order('updated_at', ascending: false).limit(20);
    return (rows as List).map((r) => AssistantConversation.fromMap(Map<String, dynamic>.from(r))).toList();
  }

  Future<AssistantConversation> createConversation({String? title}) async {
    final userId = client.auth.currentUser!.id;
    final row = await client.from('ai_conversations').insert({'user_id': userId, 'title': title}).select('id,title,updated_at').single();
    return AssistantConversation.fromMap(Map<String, dynamic>.from(row));
  }

  Future<List<AssistantMessage>> listMessages(String conversationId) async {
    final rows = await client.from('ai_messages').select('id,role,content,created_at').eq('conversation_id', conversationId).order('created_at');
    return (rows as List).map((r) => AssistantMessage.fromMap(Map<String, dynamic>.from(r))).toList();
  }

  Future<AssistantMessage> ask({required String conversationId, required String message}) async {
    final response = await client.functions.invoke('agri-assistant', body: {'conversation_id': conversationId, 'message': message.trim()});
    if (response.data is! Map) throw Exception('Assistant returned an invalid response.');
    final data = Map<String, dynamic>.from(response.data as Map);
    return AssistantMessage.fromMap(Map<String, dynamic>.from(data['message'] as Map));
  }
}
