class Chat {
  final String id;
  final String title;
  final String? avatarColor;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool isGroup;
  final DateTime createdAt;

  const Chat({
    required this.id,
    required this.title,
    this.avatarColor,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.isGroup = false,
    required this.createdAt,
  });

  Chat copyWith({
    String? title,
    String? avatarColor,
    String? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
    bool? isGroup,
  }) {
    return Chat(
      id: id,
      title: title ?? this.title,
      avatarColor: avatarColor ?? this.avatarColor,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      isGroup: isGroup ?? this.isGroup,
      createdAt: createdAt,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'avatar_color': avatarColor,
        'last_message': lastMessage,
        'last_message_at': lastMessageAt?.millisecondsSinceEpoch,
        'unread_count': unreadCount,
        'is_group': isGroup ? 1 : 0,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory Chat.fromMap(Map<String, Object?> map) => Chat(
        id: map['id'] as String,
        title: map['title'] as String,
        avatarColor: map['avatar_color'] as String?,
        lastMessage: map['last_message'] as String?,
        lastMessageAt: map['last_message_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['last_message_at'] as int)
            : null,
        unreadCount: (map['unread_count'] as int?) ?? 0,
        isGroup: (map['is_group'] as int?) == 1,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      );
}
