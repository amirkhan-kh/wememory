import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/chat.dart';
import '../models/message.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'wamemory.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE chats (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            avatar_color TEXT,
            last_message TEXT,
            last_message_at INTEGER,
            unread_count INTEGER NOT NULL DEFAULT 0,
            is_group INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE messages (
            id TEXT PRIMARY KEY,
            chat_id TEXT NOT NULL,
            sender TEXT,
            body TEXT NOT NULL,
            type TEXT NOT NULL,
            is_outgoing INTEGER NOT NULL DEFAULT 0,
            is_deleted INTEGER NOT NULL DEFAULT 0,
            timestamp INTEGER NOT NULL,
            deleted_at INTEGER,
            media_path TEXT,
            notification_key TEXT,
            FOREIGN KEY (chat_id) REFERENCES chats (id)
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_messages_chat ON messages(chat_id, timestamp)',
        );
        await db.execute(
          'CREATE INDEX idx_messages_deleted ON messages(is_deleted, deleted_at)',
        );
        await db.execute(
          'CREATE UNIQUE INDEX IF NOT EXISTS idx_messages_notif_key ON messages(notification_key) WHERE notification_key IS NOT NULL',
        );
      },
    );
  }

  Future<List<Chat>> getChats() async {
    final db = await database;
    final rows = await db.query(
      'chats',
      orderBy: 'COALESCE(last_message_at, 0) DESC, created_at DESC',
    );
    return rows.map(Chat.fromMap).toList();
  }

  Future<Chat?> getChat(String id) async {
    final db = await database;
    final rows = await db.query('chats', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Chat.fromMap(rows.first);
  }

  Future<void> upsertChat(Chat chat) async {
    final db = await database;
    await db.insert(
      'chats',
      chat.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Message>> getMessages(String chatId) async {
    final db = await database;
    final rows = await db.query(
      'messages',
      where: 'chat_id = ?',
      whereArgs: [chatId],
      orderBy: 'timestamp ASC',
    );
    return rows.map(Message.fromMap).toList();
  }

  Future<List<Message>> getDeletedMessages() async {
    final db = await database;
    final rows = await db.query(
      'messages',
      where: 'is_deleted = 1',
      orderBy: 'deleted_at DESC',
    );
    return rows.map(Message.fromMap).toList();
  }

  Future<void> insertMessage(Message message) async {
    final db = await database;
    await db.insert(
      'messages',
      message.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> markDeleted({
    required String chatId,
    required String bodyHint,
    DateTime? at,
  }) async {
    final db = await database;
    // Prefer latest matching non-deleted message in chat by body hint.
    final rows = await db.query(
      'messages',
      where: 'chat_id = ? AND is_deleted = 0 AND body LIKE ?',
      whereArgs: [chatId, '%$bodyHint%'],
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    if (rows.isEmpty) return;
    final id = rows.first['id'] as String;
    await db.update(
      'messages',
      {
        'is_deleted': 1,
        'deleted_at': (at ?? DateTime.now()).millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markDeletedById(String messageId) async {
    final db = await database;
    await db.update(
      'messages',
      {
        'is_deleted': 1,
        'deleted_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  Future<List<Message>> search(String query) async {
    final db = await database;
    final rows = await db.query(
      'messages',
      where: 'body LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'timestamp DESC',
      limit: 100,
    );
    return rows.map(Message.fromMap).toList();
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('messages');
    await db.delete('chats');
  }
}
