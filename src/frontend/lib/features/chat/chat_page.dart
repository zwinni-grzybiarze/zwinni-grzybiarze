import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onlyshrooms/app_theme.dart';
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
  final _inputFocus = FocusNode();
  final _scrollCtrl = ScrollController();
  int _lastMessageCount = 0;

  @override
  void dispose() {
    _inputCtrl.dispose();
    _inputFocus.dispose();
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

  void _keepInputFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _inputFocus.requestFocus();
    });
  }

  Future<void> _send() async {
    final ctrl = ref.read(chatControllerProvider);
    if (ctrl.sending || !ctrl.connected) return;
    final text = _inputCtrl.text;
    final ok = await ref.read(chatControllerProvider.notifier).send(text);
    if (ok) _inputCtrl.clear();
    _keepInputFocus();
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
                      final mine = _isMine(currentUserId, message.senderId);
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
                      focusNode: _inputFocus,
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

bool _isMine(String? currentUserId, String senderId) {
  if (currentUserId == null ||
      currentUserId.isEmpty ||
      currentUserId == 'pending' ||
      senderId.isEmpty) {
    return false;
  }
  return currentUserId.trim() == senderId.trim();
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, required this.mine});

  final ChatMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = mine
        ? OnlyShroomsTheme.moss.withValues(alpha: 0.88)
        : Colors.white.withValues(alpha: 0.92);
    final fg = mine ? OnlyShroomsTheme.cream : OnlyShroomsTheme.bark;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(mine ? 16 : 4),
      bottomRight: Radius.circular(mine ? 4 : 16),
    );

    final time =
        '${message.sentAt.toLocal().hour.toString().padLeft(2, '0')}:${message.sentAt.toLocal().minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Container(
          margin: EdgeInsets.only(
            top: 4,
            bottom: 4,
            left: mine ? 40 : 0,
            right: mine ? 0 : 40,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: radius,
          ),
          child: Column(
            crossAxisAlignment:
                mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!mine)
                Text(
                  message.senderName.isEmpty ? 'Nieznany' : message.senderName,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: fg.withValues(alpha: 0.85),
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
                  color: fg.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
