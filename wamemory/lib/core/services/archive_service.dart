import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../db/memory_store.dart';
import '../models/chat.dart';
import '../models/message.dart';

/// Bridges Android NotificationListener → SQLite (mobile) or memory (web demo).
class ArchiveService extends ChangeNotifier {
  ArchiveService({AppDatabase? db, MemoryStore? memory, bool? useMemory})
      : _db = db ?? AppDatabase.instance,
        _memory = memory ?? MemoryStore(),
        _useMemory = useMemory ?? kIsWeb;

  final AppDatabase _db;
  final MemoryStore _memory;
  bool _useMemory;
  final _uuid = const Uuid();
  static const _channel = MethodChannel('com.wamemory.app/notifications');

  List<Chat> chats = [];
  List<Message> deleted = [];
  bool listenerEnabled = false;
  bool seeded = false;

  Future<void> init() async {
    _channel.setMethodCallHandler(_onNativeEvent);
    try {
      await refresh();
    } catch (e) {
      debugPrint('Archive refresh failed, falling back to memory: $e');
      _useMemory = true;
      chats = [];
      deleted = [];
    }
    if (chats.isEmpty) {
      try {
        await seedDemoData();
      } catch (e) {
        debugPrint('seedDemoData failed, forcing memory seed: $e');
        _useMemory = true;
        seeded = false;
        await seedDemoData();
      }
    }
    try {
      listenerEnabled = await _channel
              .invokeMethod<bool>('isNotificationAccessEnabled')
              .timeout(const Duration(seconds: 2), onTimeout: () => false) ??
          false;
    } on MissingPluginException {
      listenerEnabled = false;
    } on PlatformException {
      listenerEnabled = false;
    } catch (_) {
      listenerEnabled = false;
    }
    notifyListeners();
  }

  Future<void> refresh() async {
    if (_useMemory) {
      chats = _memory.getChats();
      deleted = _memory.getDeletedMessages();
    } else {
      chats = await _db.getChats();
      deleted = await _db.getDeletedMessages();
    }
    notifyListeners();
  }

  Future<List<Message>> messagesFor(String chatId) async {
    if (_useMemory) return _memory.getMessages(chatId);
    return _db.getMessages(chatId);
  }

  Future<void> openNotificationSettings() async {
    try {
      await _channel.invokeMethod('openNotificationAccessSettings');
    } on MissingPluginException {
      // Desktop / web
    }
  }

  Future<void> refreshListenerStatus() async {
    try {
      listenerEnabled =
          await _channel.invokeMethod<bool>('isNotificationAccessEnabled') ??
              false;
      notifyListeners();
    } on MissingPluginException {
      // ignore
    }
  }

  Future<dynamic> _onNativeEvent(MethodCall call) async {
    if (call.method == 'onWhatsAppNotification') {
      final args = Map<String, dynamic>.from(call.arguments as Map);
      await _ingestNotification(args);
    } else if (call.method == 'onPossiblyDeleted') {
      final args = Map<String, dynamic>.from(call.arguments as Map);
      final title = (args['title'] as String?) ?? 'Unknown';
      final chat = await _ensureChat(title);
      await _markDeleted(chatId: chat.id, bodyHint: (args['body'] as String?) ?? '');
      await refresh();
    }
  }

  Future<void> _ingestNotification(Map<String, dynamic> args) async {
    final title = (args['title'] as String?)?.trim();
    final body = (args['body'] as String?)?.trim();
    if (title == null || title.isEmpty || body == null || body.isEmpty) return;

    final lower = body.toLowerCase();
    final isDeleteMarker = lower.contains('this message was deleted') ||
        lower.contains('удалено') ||
        lower.contains("o'chirildi") ||
        lower.contains('ochirildi');

    final chat = await _ensureChat(title);
    if (isDeleteMarker) {
      await _markDeleted(chatId: chat.id, bodyHint: '');
      await refresh();
      return;
    }

    final key = args['key'] as String?;
    final msg = Message(
      id: _uuid.v4(),
      chatId: chat.id,
      sender: title,
      body: body,
      type: MessageType.text,
      isOutgoing: false,
      timestamp: DateTime.now(),
      notificationKey: key,
    );
    await _insertMessage(msg);
    await _upsertChat(
      chat.copyWith(
        lastMessage: body,
        lastMessageAt: msg.timestamp,
        unreadCount: chat.unreadCount + 1,
      ),
    );
    await refresh();
  }

  Future<void> _upsertChat(Chat chat) async {
    if (_useMemory) {
      _memory.upsertChat(chat);
    } else {
      await _db.upsertChat(chat);
    }
  }

  Future<void> _insertMessage(Message message) async {
    if (_useMemory) {
      _memory.insertMessage(message);
    } else {
      await _db.insertMessage(message);
    }
  }

  Future<void> _markDeleted({
    required String chatId,
    required String bodyHint,
  }) async {
    if (_useMemory) {
      _memory.markDeleted(chatId: chatId, bodyHint: bodyHint);
    } else {
      await _db.markDeleted(chatId: chatId, bodyHint: bodyHint);
    }
  }

  Future<Chat> _ensureChat(String title) async {
    final existing = chats.where((c) => c.title == title).toList();
    if (existing.isNotEmpty) return existing.first;
    final chat = Chat(
      id: _uuid.v4(),
      title: title,
      avatarColor: _colorFor(title),
      createdAt: DateTime.now(),
    );
    await _upsertChat(chat);
    return chat;
  }

  String _colorFor(String name) {
    const colors = [
      '#00A884',
      '#53BDEB',
      '#FF7A59',
      '#A855F7',
      '#F59E0B',
      '#EC4899',
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  Future<void> seedDemoData() async {
    if (seeded) return;
    seeded = true;
    final now = DateTime.now();

    final flor = Chat(
      id: _uuid.v4(),
      title: 'Flor Camden',
      avatarColor: '#00A884',
      lastMessage: 'This message was deleted',
      lastMessageAt: now.subtract(const Duration(minutes: 12)),
      unreadCount: 2,
      createdAt: now.subtract(const Duration(days: 3)),
    );
    final joanna = Chat(
      id: _uuid.v4(),
      title: 'Joanna',
      avatarColor: '#A855F7',
      lastMessage: 'Voice message',
      lastMessageAt: now.subtract(const Duration(hours: 1)),
      unreadCount: 8,
      createdAt: now.subtract(const Duration(days: 5)),
    );
    final alex = Chat(
      id: _uuid.v4(),
      title: 'Alex Rivera',
      avatarColor: '#53BDEB',
      lastMessage: 'See you tomorrow!',
      lastMessageAt: now.subtract(const Duration(hours: 3)),
      createdAt: now.subtract(const Duration(days: 2)),
    );

    for (final c in [flor, joanna, alex]) {
      await _upsertChat(c);
    }

    final florMsgs = [
      Message(
        id: _uuid.v4(),
        chatId: flor.id,
        sender: 'Flor Camden',
        body: 'Hey! Did you get the contract draft?',
        timestamp: now.subtract(const Duration(hours: 2, minutes: 20)),
      ),
      Message(
        id: _uuid.v4(),
        chatId: flor.id,
        sender: 'You',
        body: 'Yes, reviewing it now.',
        isOutgoing: true,
        timestamp: now.subtract(const Duration(hours: 2, minutes: 10)),
      ),
      Message(
        id: _uuid.v4(),
        chatId: flor.id,
        sender: 'Flor Camden',
        body: 'The payment terms are on page 3 — keep this confidential.',
        timestamp: now.subtract(const Duration(hours: 1, minutes: 40)),
        isDeleted: true,
        deletedAt: now.subtract(const Duration(minutes: 12)),
      ),
      Message(
        id: _uuid.v4(),
        chatId: flor.id,
        sender: 'Flor Camden',
        body: 'Call me when free',
        timestamp: now.subtract(const Duration(minutes: 30)),
      ),
      Message(
        id: _uuid.v4(),
        chatId: flor.id,
        sender: 'You',
        body: 'Will do 👍',
        isOutgoing: true,
        timestamp: now.subtract(const Duration(minutes: 25)),
      ),
    ];

    final joannaMsgs = [
      Message(
        id: _uuid.v4(),
        chatId: joanna.id,
        sender: 'Joanna',
        body: 'Sending the photos from yesterday',
        type: MessageType.image,
        timestamp: now.subtract(const Duration(hours: 2)),
      ),
      Message(
        id: _uuid.v4(),
        chatId: joanna.id,
        sender: 'Joanna',
        body: 'Voice message · 0:43',
        type: MessageType.voice,
        timestamp: now.subtract(const Duration(hours: 1)),
        isDeleted: true,
        deletedAt: now.subtract(const Duration(minutes: 40)),
      ),
    ];

    final alexMsgs = [
      Message(
        id: _uuid.v4(),
        chatId: alex.id,
        sender: 'Alex Rivera',
        body: 'Meeting moved to 4pm',
        timestamp: now.subtract(const Duration(hours: 4)),
      ),
      Message(
        id: _uuid.v4(),
        chatId: alex.id,
        sender: 'You',
        body: 'See you tomorrow!',
        isOutgoing: true,
        timestamp: now.subtract(const Duration(hours: 3)),
      ),
    ];

    for (final m in [...florMsgs, ...joannaMsgs, ...alexMsgs]) {
      await _insertMessage(m);
    }
    await refresh();
  }

  Future<void> simulateIncoming({
    required String title,
    required String body,
  }) async {
    await _ingestNotification({
      'title': title,
      'body': body,
      'key': _uuid.v4(),
    });
  }

  Future<void> simulateDelete(String messageId) async {
    if (_useMemory) {
      _memory.markDeletedById(messageId);
    } else {
      await _db.markDeletedById(messageId);
    }
    await refresh();
  }
}
