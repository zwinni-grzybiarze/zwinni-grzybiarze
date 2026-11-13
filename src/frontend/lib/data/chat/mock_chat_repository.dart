import 'package:onlyshrooms/data/chat/chat_repository.dart';
import 'package:onlyshrooms/domain/chat_message.dart';

/// In-memory history shared with [MockChatHubClient] via [MockChatStore].
class MockChatRepository implements ChatRepository {
  MockChatRepository(this._store);

  final MockChatStore _store;

  @override
  Future<List<ChatMessage>> getHistory({
    required String roomId,
    DateTime? before,
    String? beforeId,
    int limit = 50,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    var items = _store.messagesFor(roomId);
    if (before != null) {
      items = items.where((m) {
        final sent = m.sentAt.toUtc();
        final cursor = before.toUtc();
        if (sent.isBefore(cursor)) return true;
        if (beforeId != null &&
            sent.isAtSameMomentAs(cursor) &&
            m.id.compareTo(beforeId) < 0) {
          return true;
        }
        return false;
      }).toList();
    }
    if (items.length > limit) {
      items = items.sublist(items.length - limit);
    }
    return List.unmodifiable(items);
  }
}

class MockChatStore {
  final Map<String, List<ChatMessage>> _byRoom = {};
  final List<void Function(ChatMessage)> _listeners = [];

  List<ChatMessage> messagesFor(String roomId) =>
      List.unmodifiable(_byRoom[roomId] ?? const []);

  void addListener(void Function(ChatMessage) listener) {
    _listeners.add(listener);
  }

  void removeListener(void Function(ChatMessage) listener) {
    _listeners.remove(listener);
  }

  ChatMessage append({
    required String roomId,
    required String senderId,
    required String senderName,
    required String body,
  }) {
    final message = ChatMessage(
      id: 'mock-${DateTime.now().microsecondsSinceEpoch}',
      roomId: roomId,
      senderId: senderId,
      senderName: senderName,
      body: body.trim(),
      sentAt: DateTime.now().toUtc(),
    );
    final list = _byRoom.putIfAbsent(roomId, () => []);
    list.add(message);
    for (final listener in List.of(_listeners)) {
      listener(message);
    }
    return message;
  }
}
