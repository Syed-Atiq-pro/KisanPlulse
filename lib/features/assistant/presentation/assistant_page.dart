import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/assistant_models.dart';
import '../data/assistant_repository.dart';

final assistantRepositoryProvider = Provider<AssistantRepository>(
  (ref) => AssistantRepository(Supabase.instance.client),
);

final conversationsProvider =
    FutureProvider.autoDispose<List<AssistantConversation>>(
  (ref) => ref.read(assistantRepositoryProvider).listConversations(),
);

class AssistantPage extends ConsumerStatefulWidget {
  const AssistantPage({super.key});

  @override
  ConsumerState<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends ConsumerState<AssistantPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  List<AssistantMessage> _messages = <AssistantMessage>[];
  String? _conversationId;
  bool _loading = false;

  static const _suggestions = <String>[
    'What should I do for my crops today?',
    'How much water does my crop need?',
    'How can I improve my soil?',
    'Check my recent disease risks',
  ];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _startConversation() async {
    try {
      final conversation = await ref
          .read(assistantRepositoryProvider)
          .createConversation(title: 'Farm advice');
      if (!mounted) return;
      setState(() {
        _conversationId = conversation.id;
        _messages = <AssistantMessage>[];
      });
      ref.invalidate(conversationsProvider);
    } catch (error) {
      if (!mounted) return;
      _showError(error);
    }
  }

  Future<void> _loadConversation(String id) async {
    if (id.isEmpty) return;
    try {
      final items = await ref
          .read(assistantRepositoryProvider)
          .listMessages(id);
      if (!mounted) return;
      setState(() {
        _conversationId = id;
        _messages = items;
      });
      _scrollDown();
    } catch (error) {
      if (!mounted) return;
      _showError(error);
    }
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty || _loading) return;

    if (_conversationId == null) {
      await _startConversation();
    }

    final conversationId = _conversationId;
    if (conversationId == null || !mounted) return;

    _input.clear();
    setState(() {
      _loading = true;
      _messages = <AssistantMessage>[
        ..._messages,
        AssistantMessage(
          id: 'local-${DateTime.now().microsecondsSinceEpoch}',
          role: 'user',
          content: text,
          createdAt: DateTime.now(),
        ),
      ];
    });
    _scrollDown();

    try {
      final answer = await ref.read(assistantRepositoryProvider).ask(
            conversationId: conversationId,
            message: text,
          );
      if (!mounted) return;
      setState(() {
        _messages = <AssistantMessage>[..._messages, answer];
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _messages = <AssistantMessage>[
          ..._messages,
          AssistantMessage(
            id: 'error-${DateTime.now().microsecondsSinceEpoch}',
            role: 'assistant',
            content:
                'I could not reach the farming assistant. Check your connection and AI configuration, then try again.',
            createdAt: DateTime.now(),
          ),
        ];
      });
    }
    _scrollDown();
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString())),
    );
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final conversations =
        ref.watch(conversationsProvider).valueOrNull ?? <AssistantConversation>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI Farming Assistant',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: _startConversation,
            tooltip: 'New chat',
            icon: const Icon(Icons.add_comment_rounded),
          ),
          PopupMenuButton<String>(
            onSelected: _loadConversation,
            itemBuilder: (context) {
              if (conversations.isEmpty) {
                return const <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    enabled: false,
                    value: '',
                    child: Text('No previous chats'),
                  ),
                ];
              }
              return conversations
                  .map(
                    (conversation) => PopupMenuItem<String>(
                      value: conversation.id,
                      child: Text(
                        conversation.title ?? 'Farm advice',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _EmptyAssistantView(onSuggestion: _send)
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_loading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_loading && index == _messages.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final message = _messages[index];
                      final isUser = message.role == 'user';
                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 620),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isUser
                                ? Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(message.content),
                        ),
                      );
                    },
                  ),
          ),
          if (_messages.isNotEmpty && !_loading)
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: _suggestions
                    .map(
                      (suggestion) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(
                            suggestion,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onPressed: () => _send(suggestion),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        hintText: 'Ask your farming question...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _loading ? null : _send,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyAssistantView extends StatelessWidget {
  const _EmptyAssistantView({required this.onSuggestion});

  final ValueChanged<String> onSuggestion;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 28,
                  child: Icon(Icons.auto_awesome_rounded),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your farm-aware AI assistant',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ask about crops, soil, irrigation, weather, disease symptoms, or your next farm task. The assistant uses your AgriSense farm data when available.',
                ),
                const SizedBox(height: 18),
                ..._AssistantPageState._suggestions.map(
                  (suggestion) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: OutlinedButton.icon(
                      onPressed: () => onSuggestion(suggestion),
                      icon: const Icon(Icons.arrow_outward_rounded, size: 18),
                      label: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(suggestion),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
