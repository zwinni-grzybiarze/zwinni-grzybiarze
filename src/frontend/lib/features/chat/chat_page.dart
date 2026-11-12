import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onlyshrooms/domain/chat_message.dart';
import 'package:onlyshrooms/features/auth/auth_controller.dart';
import 'package:onlyshrooms/features/chat/chat_controller.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  int _lastMessageCount = 0;

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _inputCtrl.text;
    _inputCtrl.clear();
    await ref.read(chatControllerProvider.notifier).send(text);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = ref.watch(chatControllerProvider);
    final currentUserId = ref.watch(authControllerProvider).user?.id;

    if (ctrl.messages.length != _lastMessageCount) {
      _lastMessageCount = ctrl.messages.length;
      _scrollToBottom();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Icon(
                ctrl.connected ? Icons.circle : Icons.circle_outlined,
                size: 12,
                color: ctrl.connected
                    ? Colors.green
                    : Theme.of(context).disabledColor,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (ctrl.error != null)
            MaterialBanner(
              content: Text(ctrl.error!),
              actions: [
                TextButton(
                  onPressed: () =>
                      ref.read(chatControllerProvider.notifier).start(),
                  child: const Text('Ponów'),
                ),
              ],
            ),
          Expanded(
            child: ctrl.loading && ctrl.messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: ctrl.messages.length,
                    itemBuilder: (context, index) {
                      final message = ctrl.messages[index];
                      final mine = message.senderId == currentUserId;
                      return _ChatBubble(message: message, mine: mine);
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Napisz wiadomość…',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: ctrl.sending || !ctrl.connected ? null : _send,
                    icon: ctrl.sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
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

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, required this.mine});

  final ChatMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alignment = mine ? Alignment.centerRight : Alignment.centerLeft;
    final bg = mine
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    final fg = mine
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;

    final time =
        '${message.sentAt.toLocal().hour.toString().padLeft(2, '0')}:${message.sentAt.toLocal().minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        child: Card(
          color: bg,
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment:
                  mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  message.senderName.isEmpty ? 'Nieznany' : message.senderName,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  message.body,
                  style: theme.textTheme.bodyMedium?.copyWith(color: fg),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: fg.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
