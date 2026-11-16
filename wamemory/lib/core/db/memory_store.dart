import '../models/chat.dart';
import '../models/message.dart';

/// In-memory store for web / demo when SQLite is unavailable.
class MemoryStore {
  final Map<String, Chat> chats = {};
  final Map<String, Message> messages = {};

  List<Chat> getChats() {
    final list = chats.values.toList()
      ..sort((a, b) {
        final at = a.lastMessageAt?.millisecondsSinceEpoch ?? 0;
        final bt = b.lastMessageAt?.millisecondsSinceEpoch ?? 0;
        return bt.compareTo(at);
      });
    return list;
  }

  Chat? getChat(String id) => chats[id];

  void upsertChat(Chat chat) => chats[chat.id] = chat;

  List<Message> getMessages(String chatId) {
    return messages.values.where((m) => m.chatId == chatId).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  List<Message> getDeletedMessages() {
    return messages.values.where((m) => m.isDeleted).toList()
      ..sort((a, b) {
        final at = a.deletedAt?.millisecondsSinceEpoch ?? 0;
        final bt = b.deletedAt?.millisecondsSinceEpoch ?? 0;
        return bt.compareTo(at);
      });
  }

  void insertMessage(Message message) {
    if (message.notificationKey != null) {
      final exists = messages.values.any(
        (m) => m.notificationKey == message.notificationKey,
      );
      if (exists) return;
    }
    messages[message.id] = message;
  }

  void markDeletedById(String messageId) {
    final m = messages[messageId];
    if (m == null) return;
    messages[messageId] = m.copyWith(
      isDeleted: true,
      deletedAt: DateTime.now(),
    );
  }

  void markDeleted({required String chatId, required String bodyHint}) {
    final candidates = messages.values
        .where((m) => m.chatId == chatId && !m.isDeleted)
        .where((m) => bodyHint.isEmpty || m.body.contains(bodyHint))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (candidates.isEmpty) return;
    markDeletedById(candidates.first.id);
  }

  List<Message> search(String query) {
    final q = query.toLowerCase();
    return messages.values
        .where((m) => m.body.toLowerCase().contains(q))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  void clearAll() {
    chats.clear();
    messages.clear();
  }
}
