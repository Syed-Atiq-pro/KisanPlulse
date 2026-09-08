import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/assistant_models.dart';
import '../data/assistant_repository.dart';

final assistantRepositoryProvider = Provider((ref) => AssistantRepository(Supabase.instance.client));
final conversationsProvider = FutureProvider.autoDispose<List<AssistantConversation>>((ref) => ref.read(assistantRepositoryProvider).listConversations());

class AssistantPage extends ConsumerStatefulWidget {
  const AssistantPage({super.key});
  @override ConsumerState<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends ConsumerState<AssistantPage> {
  final input = TextEditingController();
  final scroll = ScrollController();
  List<AssistantMessage> messages = [];
  String? conversationId;
  bool loading = false;

  @override
  void dispose() { input.dispose(); scroll.dispose(); super.dispose(); }

  Future<void> _startConversation() async {
    final conversation = await ref.read(assistantRepositoryProvider).createConversation(title: 'Farm advice');
    setState(() { conversationId = conversation.id; messages = []; });
    ref.invalidate(conversationsProvider);
  }

  Future<void> _loadConversation(String id) async {
    final items = await ref.read(assistantRepositoryProvider).listMessages(id);
    if (!mounted) return;
    setState(() { conversationId = id; messages = items; });
    _scrollDown();
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? input.text).trim();
    if (text.isEmpty || loading) return;
    if (conversationId == null) await _startConversation();
    final id = conversationId!;
    input.clear();
    setState(() { loading = true; messages = [...messages, AssistantMessage(id: 'local-${DateTime.now().microsecondsSinceEpoch}', role: 'user', content: text, createdAt: DateTime.now())]; });
    _scrollDown();
    try {
      final answer = await ref.read(assistantRepositoryProvider).ask(conversationId: id, message: text);
      if (!mounted) return;
      setState(() { messages = [...messages, answer]; loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { loading = false; messages = [...messages, AssistantMessage(id: 'error-${DateTime.now().microsecondsSinceEpoch}', role: 'assistant', content: 'I could not reach the farming assistant. Check your connection and AI configuration, then try again.', createdAt: DateTime.now())]; });
    }
    _scrollDown();
  }

  void _scrollDown() { WidgetsBinding.instance.addPostFrameCallback((_) { if (scroll.hasClients) scroll.animateTo(scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut); }); }

  @override
  Widget build(BuildContext context) {
    final suggestions = ['What should I do for my crops today?', 'How much water does my crop need?', 'How can I improve my soil?', 'Check my recent disease risks'];
    return Scaffold(
      appBar: AppBar(title: const Text('AI Farming Assistant', style: TextStyle(fontWeight: FontWeight.w800)), actions: [IconButton(onPressed: _startConversation, tooltip: 'New chat', icon: const Icon(Icons.add_comment_rounded)), PopupMenuButton<String>(onSelected: _loadConversation, itemBuilder: (context) { final conversations = ref.read(conversationsProvider).valueOrNull ?? []; return [if (conversations.isEmpty) const PopupMenuItem(enabled: false, value: '', child: Text('No previous chats')), ...conversations.map((c) => PopupMenuItem(value: c.id, child: Text(c.title ?? 'Farm advice', overflow: TextOverflow.ellipsis)))]; })]),
      body: Column(children: [
        Expanded(child: messages.isEmpty ? ListView(padding: const EdgeInsets.fromLTRB(20, 30, 20, 20), children: [Card(child: Padding(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [CircleAvatar(radius: 28, child: const Icon(Icons.auto_awesome_rounded)), const SizedBox(height: 16), Text('Your farm-aware AI assistant', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 8), const Text('Ask about crops, soil, irrigation, weather, disease symptoms, or your next farm task. The assistant uses your AgriSense farm data when available.'), const SizedBox(height: 18), ...suggestions.map((s) => Padding(padding: const EdgeInsets.only(bottom: 8), child: OutlinedButton.icon(onPressed: () => _send(s), icon: const Icon(Icons.arrow_outward_rounded, size: 18), label: Align(alignment: Alignment.centerLeft, child: Text(s))))) ]))]) : ListView.builder(controller: scroll, padding: const EdgeInsets.all(16), itemCount: messages.length + (loading ? 1 : 0), itemBuilder: (context, index) { if (loading && index == messages.length) return const Padding(padding: EdgeInsets.all(16), child: Align(alignment: Alignment.centerLeft, child: CircularProgressIndicator())); final m = messages[index]; final user = m.role == 'user'; return Align(alignment: user ? Alignment.centerRight : Alignment.centerLeft, child: Container(constraints: const BoxConstraints(maxWidth: 620), margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: user ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(18)), child: Text(m.content))); }),
        if (messages.isNotEmpty && !loading) SizedBox(height: 42, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), children: suggestions.map((s) => Padding(padding: const EdgeInsets.only(right: 8), child: ActionChip(label: Text(s, maxLines: 1, overflow: TextOverflow.ellipsis), onPressed: () => _send(s)))).toList())),
        SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(12, 8, 12, 12), child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Expanded(child: TextField(controller: input, minLines: 1, maxLines: 4, textInputAction: TextInputAction.newline, decoration: const InputDecoration(hintText: 'Ask your farming question...', border: OutlineInputBorder()))), const SizedBox(width: 8), IconButton.filled(onPressed: loading ? null : () => _send(), icon: const Icon(Icons.send_rounded))])))
      ]),
    );
  }
}
