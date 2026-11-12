import 'package:dio/dio.dart';
import 'package:onlyshrooms/data/chat/chat_repository.dart';
import 'package:onlyshrooms/domain/chat_message.dart';

class HttpChatRepository implements ChatRepository {
  HttpChatRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<ChatMessage>> getHistory({
    required String roomId,
    DateTime? before,
    int limit = 50,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/chat/rooms/$roomId/messages',
      queryParameters: {
        if (before != null) 'before': before.toUtc().toIso8601String(),
        'limit': limit,
      },
    );

    return (response.data ?? const <dynamic>[])
        .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
