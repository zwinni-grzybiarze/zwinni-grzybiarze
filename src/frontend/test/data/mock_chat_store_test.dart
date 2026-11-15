import 'package:flutter_test/flutter_test.dart';
import 'package:onlyshrooms/data/chat/mock_chat_repository.dart';
import 'package:onlyshrooms/domain/chat_message.dart';

void main() {
  test('MockChatStore append notifies listeners for the room', () async {
    final store = MockChatStore();
    final repo = MockChatRepository(store);
    ChatMessage? seen;
    store.addListener((m) => seen = m);

    final sent = store.append(
      roomId: kGlobalChatRoomId,
      senderId: 'u1',
      senderName: 'Jan',
      body: '  hej  ',
    );

    expect(sent.body, 'hej');
    expect(seen?.id, sent.id);

    final history = await repo.getHistory(roomId: kGlobalChatRoomId);
    expect(history, hasLength(1));
    expect(history.single.body, 'hej');

    final other = await repo.getHistory(roomId: 'other');
    expect(other, isEmpty);
  });
}
