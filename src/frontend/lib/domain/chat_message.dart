/// Global room id for v1. Later: `grzybobranie:{id}`.
const kGlobalChatRoomId = 'global';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderName,
    required this.body,
    required this.sentAt,
  });

  final String id;
  final String roomId;
  final String senderId;
  final String senderName;
  final String body;
  final DateTime sentAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final id = (json['chatMessageId'] ??
            json['ChatMessageId'] ??
            json['id'] ??
            json['Id'])
        .toString();
    final sentAtRaw = json['sentAt'] ?? json['SentAt'];
    final sentAt = sentAtRaw is DateTime
        ? sentAtRaw.toUtc()
        : DateTime.parse(sentAtRaw.toString()).toUtc();

    return ChatMessage(
      id: id,
      roomId: (json['roomId'] ?? json['RoomId'])?.toString() ??
          kGlobalChatRoomId,
      senderId: (json['senderId'] ?? json['SenderId'])?.toString() ?? '',
      senderName: (json['senderName'] ?? json['SenderName'])?.toString() ?? '',
      body: (json['body'] ?? json['Body'])?.toString() ?? '',
      sentAt: sentAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'chatMessageId': id,
        'roomId': roomId,
        'senderId': senderId,
        'senderName': senderName,
        'body': body,
        'sentAt': sentAt.toUtc().toIso8601String(),
      };
}
