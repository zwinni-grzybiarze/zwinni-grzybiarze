import 'dart:async';
import 'dart:convert';

import 'package:onlyshrooms/core/config.dart';
import 'package:onlyshrooms/data/chat/mock_chat_repository.dart';
import 'package:onlyshrooms/domain/chat_message.dart';
import 'package:signalr_netcore/signalr_client.dart';

typedef ChatMessageHandler = void Function(ChatMessage message);

abstract class ChatHubClient {
  Stream<ChatMessage> get messages;
  Future<void> connect({
    required String senderId,
    required String senderName,
  });
  Future<void> joinRoom(String roomId);
  Future<void> leaveRoom(String roomId);
  Future<void> sendMessage(String roomId, String body);
  Future<void> disconnect();
}

class SignalRChatHubClient implements ChatHubClient {
  SignalRChatHubClient({String? hubUrl})
      : _hubUrl = hubUrl ?? '${AppConfig.apiBase}/hubs/chat';

  final String _hubUrl;
  final _controller = StreamController<ChatMessage>.broadcast();
  HubConnection? _connection;
  String? _joinedRoom;

  @override
  Stream<ChatMessage> get messages => _controller.stream;

  @override
  Future<void> connect({
    required String senderId,
    required String senderName,
  }) async {
    await disconnect();

    final uri = Uri.parse(_hubUrl).replace(
      queryParameters: {
        'senderId': senderId,
        'senderName': senderName,
      },
    );

    final connection = HubConnectionBuilder()
        .withUrl(uri.toString())
        .withAutomaticReconnect()
        .build();

    connection.on('ReceiveMessage', _onReceiveMessage);
    connection.onreconnected(({connectionId}) async {
      final room = _joinedRoom;
      if (room != null) {
        await connection.invoke('JoinRoom', args: <Object>[room]);
      }
    });

    await connection.start();
    _connection = connection;
  }

  void _onReceiveMessage(List<Object?>? args) {
    if (args == null || args.isEmpty) return;
    final raw = args.first;
    final map = _asStringKeyedMap(raw);
    if (map == null) return;
    _controller.add(ChatMessage.fromJson(map));
  }

  static Map<String, dynamic>? _asStringKeyedMap(Object? raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    if (raw is String) {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    }
    return null;
  }

  HubConnection get _requireConnection {
    final connection = _connection;
    if (connection == null) {
      throw StateError('Chat hub is not connected.');
    }
    return connection;
  }

  @override
  Future<void> joinRoom(String roomId) async {
    await _requireConnection.invoke('JoinRoom', args: <Object>[roomId]);
    _joinedRoom = roomId;
  }

  @override
  Future<void> leaveRoom(String roomId) async {
    await _requireConnection.invoke('LeaveRoom', args: <Object>[roomId]);
    if (_joinedRoom == roomId) _joinedRoom = null;
  }

  @override
  Future<void> sendMessage(String roomId, String body) async {
    await _requireConnection.invoke(
      'SendMessage',
      args: <Object>[roomId, body],
    );
  }

  @override
  Future<void> disconnect() async {
    final connection = _connection;
    _connection = null;
    _joinedRoom = null;
    if (connection == null) return;
    connection.off('ReceiveMessage');
    try {
      await connection.stop();
    } catch (_) {
      // Best-effort teardown.
    }
  }
}

class MockChatHubClient implements ChatHubClient {
  MockChatHubClient(this._store);

  final MockChatStore _store;
  final _controller = StreamController<ChatMessage>.broadcast();
  String? _senderId;
  String? _senderName;
  String? _joinedRoom;

  void _listener(ChatMessage message) {
    if (message.roomId == _joinedRoom) {
      _controller.add(message);
    }
  }

  @override
  Stream<ChatMessage> get messages => _controller.stream;

  @override
  Future<void> connect({
    required String senderId,
    required String senderName,
  }) async {
    _senderId = senderId;
    _senderName = senderName;
    _store.addListener(_listener);
  }

  @override
  Future<void> joinRoom(String roomId) async {
    _joinedRoom = roomId;
  }

  @override
  Future<void> leaveRoom(String roomId) async {
    if (_joinedRoom == roomId) _joinedRoom = null;
  }

  @override
  Future<void> sendMessage(String roomId, String body) async {
    final senderId = _senderId;
    final senderName = _senderName;
    if (senderId == null || senderName == null) {
      throw StateError('Chat hub is not connected.');
    }
    _store.append(
      roomId: roomId,
      senderId: senderId,
      senderName: senderName,
      body: body,
    );
  }

  @override
  Future<void> disconnect() async {
    _store.removeListener(_listener);
    _joinedRoom = null;
    _senderId = null;
    _senderName = null;
  }
}
