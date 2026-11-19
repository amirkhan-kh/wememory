import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
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
    // Handler must be registered before flushPending delivers stashed events.
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
    try {
      await _channel
          .invokeMethod<int>('flushPending')
          .timeout(const Duration(seconds: 2), onTimeout: () => 0);
    } on MissingPluginException {
      // Web / desktop / tests without native plugin.
    } on PlatformException {
      // ignore
    } catch (_) {
      // ignore
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

  /// Call when app returns to foreground (e.g. after Notification Access toggle).
  Future<void> onAppResumed() async {
    await refreshListenerStatus();
    try {
      await _channel
          .invokeMethod<int>('flushPending')
          .timeout(const Duration(seconds: 2), onTimeout: () => 0);
    } on MissingPluginException {
      // ignore
    } on PlatformException {
      // ignore
    } catch (_) {
      // ignore
    }
  }

  Future<dynamic> _onNativeEvent(MethodCall call) async {
    // Never let a bad notification payload crash the isolate.
    try {
      if (call.method == 'onWhatsAppNotification') {
        final raw = call.arguments;
        if (raw is! Map) return null;
        final args = Map<String, dynamic>.from(raw);
        await _ingestNotification(args);
      } else if (call.method == 'onPossiblyDeleted') {
        final raw = call.arguments;
        if (raw is! Map) return null;
        final args = Map<String, dynamic>.from(raw);
        final title = (args['title'] as String?) ?? 'Unknown';
        final chat = await _ensureChat(title);
        await _markDeleted(
          chatId: chat.id,
          bodyHint: (args['body'] as String?) ?? '',
        );
        await refresh();
      }
    } catch (e, st) {
      debugPrint('native event ${call.method} failed: $e\n$st');
    }
    return null;
  }

  Future<void> _ingestNotification(Map<String, dynamic> args) async {
    final title = (args['title'] as String?)?.trim();
    final body = (args['body'] as String?)?.trim();
    if (title == null || title.isEmpty || body == null || body.isEmpty) return;

    final lower = body.toLowerCase();
    final isDeleteMarker = lower.contains('this message was deleted') ||
        lower.contains('deleted this message') ||
        lower.contains('удалили это сообщение') ||
        lower.contains('это сообщение удалено') ||
        lower.contains('удалено') ||
        lower.contains("bu xabar o'chirildi") ||
        lower.contains('bu xabar ochirildi') ||
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

  Future<Chat> _ensureChat(String title, {String? peerPhone}) async {
    final phone = (peerPhone ?? '').replaceAll(RegExp(r'[^\d]'), '');
    if (phone.length >= 8) {
      final byPhone = chats.where((c) => c.peerPhone == phone).toList();
      if (byPhone.isNotEmpty) {
        final c = byPhone.first;
        if (c.title != title && title.isNotEmpty) {
          final updated = c.copyWith(title: title, peerPhone: phone);
          await _upsertChat(updated);
          return updated;
        }
        if ((c.peerPhone == null || c.peerPhone!.isEmpty)) {
          final updated = c.copyWith(peerPhone: phone);
          await _upsertChat(updated);
          return updated;
        }
        return c;
      }
    }
    final existing = chats.where((c) => c.title == title).toList();
    if (existing.isNotEmpty) {
      final c = existing.first;
      if (phone.length >= 8 &&
          (c.peerPhone == null || c.peerPhone!.isEmpty)) {
        final updated = c.copyWith(peerPhone: phone);
        await _upsertChat(updated);
        return updated;
      }
      return c;
    }
    final chat = Chat(
      id: phone.length >= 8 ? 'peer_$phone' : _uuid.v4(),
      title: title,
      avatarColor: _colorFor(title),
      createdAt: DateTime.now(),
      peerPhone: phone.length >= 8 ? phone : null,
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

  /// Live Evolution webhook → Nest sync → local SQLite/memory.
  Future<void> ingestBridgeMessage({
    required String remoteJid,
    required String pushName,
    required String body,
    required bool fromMe,
    required bool isDeleted,
    required DateTime timestamp,
    required String notificationKey,
    String? mediaType,
    String? mediaMime,
    String? mediaBase64,
    String? mediaUrl,
    String? fileName,
  }) async {
    final title = _titleFromJid(remoteJid, pushName, fromMe);
    final peer = _peerFromJid(remoteJid);
    final chat = await _ensureChat(title, peerPhone: peer);
    if (isDeleted) {
      await _markDeleted(chatId: chat.id, bodyHint: body);
      if (_useMemory) {
        final existing = _memory.messages.values
            .where((m) => m.notificationKey == notificationKey)
            .toList();
        for (final m in existing) {
          _memory.markDeletedById(m.id);
        }
      } else {
        final msgs = await _db.getMessages(chat.id);
        for (final m in msgs) {
          if (m.notificationKey == notificationKey && !m.isDeleted) {
            await _db.markDeletedById(m.id);
          }
        }
      }
      await refresh();
      return;
    }

    final type = _typeFromMedia(mediaType, fileName);
    String? mediaPath;
    if (!kIsWeb) {
      if (mediaBase64 != null && mediaBase64.isNotEmpty) {
        mediaPath = await _saveMediaFile(
          notificationKey: notificationKey,
          base64Data: mediaBase64,
          fileName: fileName,
          mediaType: mediaType,
        );
      }
      if ((mediaPath == null || mediaPath.isEmpty) &&
          mediaUrl != null &&
          mediaUrl.isNotEmpty) {
        mediaPath = await _downloadMediaFile(
          notificationKey: notificationKey,
          mediaUrl: mediaUrl,
          fileName: fileName,
          mediaType: mediaType,
        );
      }
    }

    final existing = await _findByNotificationKey(chat.id, notificationKey);
    if (existing != null) {
      if (mediaPath != null &&
          (existing.mediaPath == null || existing.mediaPath!.isEmpty)) {
        final updated = existing.copyWith(
          mediaPath: mediaPath,
          body: body,
          type: type,
        );
        await _replaceMessage(updated);
        await _upsertChat(
          chat.copyWith(lastMessage: body, lastMessageAt: timestamp),
        );
        await refresh();
      }
      return;
    }

    final msg = Message(
      id: notificationKey,
      chatId: chat.id,
      sender: fromMe ? 'You' : pushName,
      body: body,
      type: type,
      isOutgoing: fromMe,
      timestamp: timestamp,
      notificationKey: notificationKey,
      mediaPath: mediaPath,
    );
    await _insertMessage(msg);
    await _upsertChat(
      chat.copyWith(
        lastMessage: body,
        lastMessageAt: timestamp,
        unreadCount: fromMe ? chat.unreadCount : chat.unreadCount + 1,
      ),
    );
    await refresh();
  }

  MessageType _typeFromMedia(String? mediaType, [String? fileName]) {
    final name = (fileName ?? '').toLowerCase();
    switch ((mediaType ?? '').toLowerCase()) {
      case 'image':
        return MessageType.image;
      case 'video':
        return MessageType.video;
      case 'audio':
        if (name.contains('ptt') || name.contains('voice')) {
          return MessageType.voice;
        }
        return MessageType.audio;
      case 'document':
        return MessageType.document;
      default:
        return MessageType.text;
    }
  }

  Future<Message?> _findByNotificationKey(
    String chatId,
    String notificationKey,
  ) async {
    final msgs = _useMemory
        ? _memory.messages.values.where((m) => m.chatId == chatId).toList()
        : await _db.getMessages(chatId);
    for (final m in msgs) {
      if (m.notificationKey == notificationKey || m.id == notificationKey) {
        return m;
      }
    }
    return null;
  }

  Future<void> _replaceMessage(Message message) async {
    if (_useMemory) {
      _memory.insertMessage(message);
    } else {
      await _db.insertMessage(
        message,
      ); // ignore conflict — need update
      final db = await _db.database;
      await db.update(
        'messages',
        message.toMap(),
        where: 'id = ?',
        whereArgs: [message.id],
      );
    }
  }

  Future<Directory> _mediaDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final mediaDir = Directory(p.join(dir.path, 'media'));
    if (!await mediaDir.exists()) await mediaDir.create(recursive: true);
    return mediaDir;
  }

  String _extFor({String? fileName, String? mediaType}) {
    final n = (fileName ?? '').toLowerCase();
    if (n.contains('.')) return n.split('.').last;
    switch ((mediaType ?? '').toLowerCase()) {
      case 'image':
        return 'jpg';
      case 'video':
        return 'mp4';
      case 'audio':
        return 'ogg';
      default:
        return 'bin';
    }
  }

  Future<String?> _saveMediaFile({
    required String notificationKey,
    required String base64Data,
    String? fileName,
    String? mediaType,
  }) async {
    try {
      var b64 = base64Data.trim();
      final i = b64.indexOf('base64,');
      if (i >= 0) b64 = b64.substring(i + 7);
      final bytes = base64Decode(b64);
      final mediaDir = await _mediaDir();
      final safeKey =
          notificationKey.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final ext = _extFor(fileName: fileName, mediaType: mediaType);
      final file = File(p.join(mediaDir.path, '$safeKey.$ext'));
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (e) {
      debugPrint('save media failed: $e');
      return null;
    }
  }

  /// Download Nest-persisted media into local archive (video/audio/image).
  Future<String?> _downloadMediaFile({
    required String notificationKey,
    required String mediaUrl,
    String? fileName,
    String? mediaType,
  }) async {
    try {
      final uri = Uri.parse(mediaUrl);
      final res = await http.get(uri).timeout(const Duration(seconds: 90));
      if (res.statusCode >= 400 || res.bodyBytes.isEmpty) return null;
      final mediaDir = await _mediaDir();
      final safeKey =
          notificationKey.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final ext = _extFor(fileName: fileName, mediaType: mediaType);
      final file = File(p.join(mediaDir.path, '$safeKey.$ext'));
      await file.writeAsBytes(res.bodyBytes, flush: true);
      return file.path;
    } catch (e) {
      debugPrint('download media failed: $e');
      return null;
    }
  }

  String _titleFromJid(String remoteJid, String pushName, bool fromMe) {
    if (!fromMe && pushName.trim().isNotEmpty && pushName != 'You') {
      return pushName.trim();
    }
    final digits = _peerFromJid(remoteJid);
    if (digits.length >= 8) return digits;
    final user = remoteJid.split('@').first;
    return pushName.trim().isNotEmpty ? pushName.trim() : user;
  }

  String _peerFromJid(String remoteJid) {
    final user = remoteJid.split('@').first;
    // Skip @lid / group keys — only plain phone JIDs.
    if (remoteJid.contains('@g.us') || remoteJid.contains('@lid')) {
      final digits = user.replaceAll(RegExp(r'[^\d]'), '');
      return digits.length >= 8 && digits.length <= 15 ? digits : '';
    }
    return user.replaceAll(RegExp(r'[^\d]'), '');
  }

  /// Open existing chat by peer phone or create one (search → nickname tap).
  Future<Chat> openOrCreatePeerChat({
    required String title,
    String? peerPhone,
  }) async {
    return _ensureChat(title, peerPhone: peerPhone);
  }

  Future<Message> appendOutgoing({
    required String chatId,
    required String body,
    MessageType type = MessageType.text,
    String? mediaPath,
  }) async {
    Chat? chat;
    for (final c in chats) {
      if (c.id == chatId) {
        chat = c;
        break;
      }
    }
    if (chat == null) {
      throw StateError('Chat not found: $chatId');
    }
    final msg = Message(
      id: _uuid.v4(),
      chatId: chat.id,
      sender: 'You',
      body: body,
      type: type,
      isOutgoing: true,
      timestamp: DateTime.now(),
      notificationKey: 'out_${_uuid.v4()}',
      mediaPath: mediaPath,
    );
    await _insertMessage(msg);
    await _upsertChat(
      chat.copyWith(
        lastMessage: body,
        lastMessageAt: msg.timestamp,
      ),
    );
    await refresh();
    return msg;
  }

  Future<List<Message>> searchMessages(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    if (_useMemory) return _memory.search(q);
    return _db.search(q);
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
