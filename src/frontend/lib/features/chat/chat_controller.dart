import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onlyshrooms/core/api_client.dart';
import 'package:onlyshrooms/core/config.dart';
import 'package:onlyshrooms/data/chat/chat_hub_client.dart';
import 'package:onlyshrooms/data/chat/chat_repository.dart';
import 'package:onlyshrooms/data/chat/http_chat_repository.dart';
import 'package:onlyshrooms/data/chat/mock_chat_repository.dart';
import 'package:onlyshrooms/domain/chat_message.dart';
import 'package:onlyshrooms/features/auth/auth_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

final mockChatStoreProvider = Provider<MockChatStore>((ref) => MockChatStore());

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  if (AppConfig.useMockData) {
    return MockChatRepository(ref.watch(mockChatStoreProvider));
  }
  return HttpChatRepository(createApiClient());
});

final chatHubClientProvider = Provider.autoDispose<ChatHubClient>((ref) {
  if (AppConfig.useMockData) {
    return MockChatHubClient(ref.watch(mockChatStoreProvider));
  }
  final hub = SignalRChatHubClient();
  ref.onDispose(() => unawaited(hub.disconnect()));
  return hub;
});

/// Kept alive while [MainShell] watches it so the hub can flag unread
/// outside the Chat tab; auto-disposes after logout / leaving the shell.
///
/// Rebuilds when the signed-in user id changes so logout → login as another
/// person reconnects the hub with the correct senderId.
final chatControllerProvider =
    ChangeNotifierProvider.autoDispose<ChatController>((ref) {
  final userId = ref.watch(authControllerProvider.select((a) => a.user?.id));
  final controller = ChatController(
    repository: ref.watch(chatRepositoryProvider),
    hub: ref.watch(chatHubClientProvider),
    auth: ref.read(authControllerProvider),
    roomId: kGlobalChatRoomId,
  );
  if (userId != null && userId != 'pending') {
    unawaited(controller.start());
  }
  ref.onDispose(controller.dispose);
  return controller;
});

class ChatController extends ChangeNotifier {
  ChatController({
    required ChatRepository repository,
    required ChatHubClient hub,
    required AuthController auth,
    required this.roomId,
  })  : _repository = repository,
        _hub = hub,
        _auth = auth;

  final ChatRepository _repository;
  final ChatHubClient _hub;
  final AuthController _auth;
  final String roomId;

  final List<ChatMessage> messages = [];
  bool loading = false;
  bool connected = false;
  bool sending = false;
  String? error;
  StreamSubscription<ChatMessage>? _sub;
  StreamSubscription<bool>? _connSub;
  String? _connectedAs;
  bool _starting = false;
  bool _disposed = false;

  /// True while the Chat tab is visible — live messages are auto-marked read.
  bool _viewingChat = false;
  DateTime? _lastReadAt;

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  static String _prefsKey(String roomId, String userId) =>
      'chat_last_read_at_${roomId}_$userId';

  bool get hasUnread {
    final uid = _auth.user?.id;
    final cutoff = _lastReadAt;
    if (cutoff == null || messages.isEmpty) return false;
    return messages.any(
      (m) =>
          m.sentAt.isAfter(cutoff) &&
          (uid == null || m.senderId != uid),
    );
  }

  Future<void> start() async {
    if (_starting || _disposed) return;

    final user = _auth.user;
    if (user == null || user.id == 'pending') {
      error = 'Brak zalogowanego użytkownika.';
      _notify();
      return;
    }

    // Already connected as this user — just refresh history.
    if (_connectedAs == user.id && connected) {
      try {
        await _mergeLatestHistory();
      } catch (e) {
        error = 'Nie udało się odświeżyć historii: $e';
        _notify();
      }
      return;
    }

    _starting = true;
    await _loadLastRead();
    if (_disposed) {
      _starting = false;
      return;
    }

    loading = true;
    error = null;
    _notify();

    try {
      await _sub?.cancel();
      await _connSub?.cancel();

      messages.clear();
      _sub = _hub.messages.listen(_onLiveMessage);
      await _hub.connect(senderId: user.id, senderName: user.displayName);
      if (_disposed) return;
      await _hub.joinRoom(roomId);
      if (_disposed) return;
      _connectedAs = user.id;
      connected = true;
      _notify();

      await _mergeLatestHistory();
      if (_disposed) return;

      // Listen after initial join so the first `true` from connect does not
      // trigger a duplicate catch-up merge before the room is joined.
      _connSub = _hub.connectionStates.listen(_onConnectionState);
    } catch (e) {
      error = 'Nie udało się połączyć z czatem: $e';
      connected = false;
      _connectedAs = null;
    } finally {
      loading = false;
      _starting = false;
      _notify();
    }
  }

  Future<void> _loadLastRead() async {
    final userId = _auth.user?.id;
    if (userId == null || userId == 'pending') return;
    final prefs = await SharedPreferences.getInstance();
    if (_disposed) return;
    final raw = prefs.getString(_prefsKey(roomId, userId));
    if (raw == null) {
      _lastReadAt = null;
      return;
    }
    _lastReadAt = DateTime.tryParse(raw)?.toUtc();
  }

  /// Call when entering / leaving the Chat tab.
  Future<void> setViewingChat(bool viewing) async {
    if (_disposed) return;
    final changed = _viewingChat != viewing;
    _viewingChat = viewing;
    // Entering clears the badge; leaving stamps "last seen" for later unread.
    if (changed || viewing) {
      await markRead();
    }
  }

  Future<void> markRead() async {
    if (_disposed) return;
    final latest = messages.isEmpty
        ? DateTime.now().toUtc()
        : messages.map((m) => m.sentAt).reduce(
              (a, b) => a.isAfter(b) ? a : b,
            );
    if (_lastReadAt != null && !latest.isAfter(_lastReadAt!)) {
      _notify();
      return;
    }
    _lastReadAt = latest;
    final userId = _auth.user?.id;
    if (userId != null && userId != 'pending') {
      final prefs = await SharedPreferences.getInstance();
      if (_disposed) return;
      await prefs.setString(
        _prefsKey(roomId, userId),
        latest.toIso8601String(),
      );
    }
    _notify();
  }

  Future<void> _onConnectionState(bool isUp) async {
    if (_disposed) return;
    final cameBack = isUp && !connected;
    connected = isUp;
    if (cameBack) {
      try {
        await _mergeLatestHistory();
      } catch (e) {
        error = 'Nie udało się odświeżyć historii: $e';
      }
    }
    _notify();
  }

  Future<void> _mergeLatestHistory() async {
    final history = await _repository.getHistory(roomId: roomId);
    if (_disposed) return;
    final live = List<ChatMessage>.from(messages);
    messages
      ..clear()
      ..addAll(history);
    for (final m in live) {
      if (m.roomId == roomId && !messages.any((x) => x.id == m.id)) {
        messages.add(m);
      }
    }
    if (_viewingChat) {
      await markRead();
    }
  }

  void _onLiveMessage(ChatMessage message) {
    if (_disposed) return;
    if (message.roomId != roomId) return;
    if (messages.any((m) => m.id == message.id)) return;
    messages.add(message);
    if (_viewingChat) {
      unawaited(markRead());
    } else {
      _notify();
    }
  }

  Future<bool> send(String body) async {
    final text = body.trim();
    if (text.isEmpty || sending || !connected || _disposed) return false;

    sending = true;
    error = null;
    _notify();
    try {
      await _hub.sendMessage(roomId, text);
      return true;
    } catch (e) {
      error = 'Nie udało się wysłać: $e';
      return false;
    } finally {
      sending = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    _connSub?.cancel();
    unawaited(_hub.disconnect());
    super.dispose();
  }
}
