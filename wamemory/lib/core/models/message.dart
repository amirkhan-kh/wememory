enum MessageType { text, image, video, audio, voice, document, unknown }

class Message {
  final String id;
  final String chatId;
  final String? sender;
  final String body;
  final MessageType type;
  final bool isOutgoing;
  final bool isDeleted;
  final DateTime timestamp;
  final DateTime? deletedAt;
  final String? mediaPath;
  final String? notificationKey;

  const Message({
    required this.id,
    required this.chatId,
    this.sender,
    required this.body,
    this.type = MessageType.text,
    this.isOutgoing = false,
    this.isDeleted = false,
    required this.timestamp,
    this.deletedAt,
    this.mediaPath,
    this.notificationKey,
  });

  Message copyWith({
    String? body,
    MessageType? type,
    bool? isDeleted,
    DateTime? deletedAt,
    String? mediaPath,
  }) {
    return Message(
      id: id,
      chatId: chatId,
      sender: sender,
      body: body ?? this.body,
      type: type ?? this.type,
      isOutgoing: isOutgoing,
      isDeleted: isDeleted ?? this.isDeleted,
      timestamp: timestamp,
      deletedAt: deletedAt ?? this.deletedAt,
      mediaPath: mediaPath ?? this.mediaPath,
      notificationKey: notificationKey,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'chat_id': chatId,
        'sender': sender,
        'body': body,
        'type': type.name,
        'is_outgoing': isOutgoing ? 1 : 0,
        'is_deleted': isDeleted ? 1 : 0,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'deleted_at': deletedAt?.millisecondsSinceEpoch,
        'media_path': mediaPath,
        'notification_key': notificationKey,
      };

  factory Message.fromMap(Map<String, Object?> map) => Message(
        id: map['id'] as String,
        chatId: map['chat_id'] as String,
        sender: map['sender'] as String?,
        body: map['body'] as String? ?? '',
        type: MessageType.values.firstWhere(
          (e) => e.name == map['type'],
          orElse: () => MessageType.text,
        ),
        isOutgoing: (map['is_outgoing'] as int?) == 1,
        isDeleted: (map['is_deleted'] as int?) == 1,
        timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
        deletedAt: map['deleted_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['deleted_at'] as int)
            : null,
        mediaPath: map['media_path'] as String?,
        notificationKey: map['notification_key'] as String?,
      );
}
