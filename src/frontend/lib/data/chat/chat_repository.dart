import 'package:onlyshrooms/domain/chat_message.dart';

abstract class ChatRepository {
  Future<List<ChatMessage>> getHistory({
    required String roomId,
    DateTime? before,
    String? beforeId,
    int limit = 50,
  });
}
