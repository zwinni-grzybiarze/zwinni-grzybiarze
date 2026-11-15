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

final mockChatStoreProvider = Provider<MockChatStore>((ref) => MockChatStore());

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  if (AppConfig.useMockData) {
    return MockChatRepository(ref.watch(mockChatStoreProvider));
  }
  return HttpChatRepository(createApiClient());
});

final chatHubClientProvider = Provider<ChatHubClient>((ref) {
  if (AppConfig.useMockData) {
    return MockChatHubClient(ref.watch(mockChatStoreProvider));
  }
  return SignalRChatHubClient();
});

final chatControllerProvider =
    ChangeNotifierProvider.autoDispose<ChatController>((ref) {
  final controller = ChatController(
    repository: ref.watch(chatRepositoryProvider),
    hub: ref.watch(chatHubClientProvider),
    // read: avoid rebuilding/disconnecting the hub on every auth notify
    auth: ref.read(authControllerProvider),
    roomId: kGlobalChatRoomId,
  );
  unawaited(controller.start());
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

  Future<void> start() async {
    final user = _auth.user;
    if (user == null) {
      error = 'Brak zalogowanego użytkownika.';
      notifyListeners();
      return;
    }

    loading = true;
    error = null;
    notifyListeners();

    try {
      await _sub?.cancel();
      await _connSub?.cancel();

      _sub = _hub.messages.listen(_onLiveMessage);
      await _hub.connect(senderId: user.id, senderName: user.displayName);
      await _hub.joinRoom(roomId);
      connected = true;
      notifyListeners();

      await _mergeLatestHistory();

      // Listen after initial join so the first `true` from connect does not
      // trigger a duplicate catch-up merge before the room is joined.
      _connSub = _hub.connectionStates.listen(_onConnectionState);
    } catch (e) {
      error = 'Nie udało się połączyć z czatem: $e';
      connected = false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _onConnectionState(bool isUp) async {
    final cameBack = isUp && !connected;
    connected = isUp;
    if (cameBack) {
      try {
        await _mergeLatestHistory();
      } catch (e) {
        error = 'Nie udało się odświeżyć historii: $e';
      }
    }
    notifyListeners();
  }

  Future<void> _mergeLatestHistory() async {
    final history = await _repository.getHistory(roomId: roomId);
    final live = List<ChatMessage>.from(messages);
    messages
      ..clear()
      ..addAll(history);
    for (final m in live) {
      if (m.roomId == roomId && !messages.any((x) => x.id == m.id)) {
        messages.add(m);
      }
    }
  }

  void _onLiveMessage(ChatMessage message) {
    if (message.roomId != roomId) return;
    if (messages.any((m) => m.id == message.id)) return;
    messages.add(message);
    notifyListeners();
  }

  Future<bool> send(String body) async {
    final text = body.trim();
    if (text.isEmpty || sending || !connected) return false;

    sending = true;
    error = null;
    notifyListeners();
    try {
      await _hub.sendMessage(roomId, text);
      return true;
    } catch (e) {
      error = 'Nie udało się wysłać: $e';
      return false;
    } finally {
      sending = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _connSub?.cancel();
    unawaited(_hub.disconnect());
    super.dispose();
  }
}
