import 'package:flutter_test/flutter_test.dart';
import 'package:onlyshrooms/domain/chat_message.dart';

void main() {
  test('ChatMessage.fromJson reads chatMessageId and UTC sentAt', () {
    final message = ChatMessage.fromJson({
      'chatMessageId': '11111111-1111-1111-1111-111111111111',
      'roomId': 'global',
      'senderId': 'stub-google-1',
      'senderName': 'Jan Kowalski',
      'body': 'cześć',
      'sentAt': '2026-11-12T09:15:00Z',
    });

    expect(message.id, '11111111-1111-1111-1111-111111111111');
    expect(message.roomId, kGlobalChatRoomId);
    expect(message.senderId, 'stub-google-1');
    expect(message.senderName, 'Jan Kowalski');
    expect(message.body, 'cześć');
    expect(message.sentAt.isUtc, isTrue);
    expect(message.sentAt, DateTime.utc(2026, 11, 12, 9, 15));
  });

  test('ChatMessage.toJson round-trips room-scoped fields', () {
    final original = ChatMessage(
      id: 'abc',
      roomId: 'grzybobranie:12',
      senderId: 'u1',
      senderName: 'Ala',
      body: 'hi',
      sentAt: DateTime.utc(2026, 11, 12, 10),
    );

    final restored = ChatMessage.fromJson(original.toJson());
    expect(restored.id, original.id);
    expect(restored.roomId, 'grzybobranie:12');
    expect(restored.body, 'hi');
  });
}
