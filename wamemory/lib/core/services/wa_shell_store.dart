import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-only WA-shell state (Status text, communities, call log, feedback).
/// Not Meta WhatsApp data — archive UI only.
class WaShellStore extends ChangeNotifier {
  WaShellStore({SharedPreferences? prefs}) : _prefsOverride = prefs;

  static const _keyStatus = 'shell_my_status';
  static const _keyCommunities = 'shell_communities_json';
  static const _keyCalls = 'shell_calls_json';
  static const _keyFeedback = 'shell_feedback_json';
  static const _keyRetention = 'shell_retention_days';

  final SharedPreferences? _prefsOverride;
  SharedPreferences? _prefs;

  String myStatus = '';
  List<ShellCommunity> communities = [];
  List<ShellCall> calls = [];
  List<ShellFeedback> feedback = [];
  int retentionDays = 90;

  Future<void> init() async {
    _prefs = _prefsOverride ?? await SharedPreferences.getInstance();
    myStatus = _prefs!.getString(_keyStatus) ?? '';
    retentionDays = _prefs!.getInt(_keyRetention) ?? 90;
    communities = _decodeList(
      _prefs!.getString(_keyCommunities),
      ShellCommunity.fromJson,
    );
    calls = _decodeList(_prefs!.getString(_keyCalls), ShellCall.fromJson);
    feedback =
        _decodeList(_prefs!.getString(_keyFeedback), ShellFeedback.fromJson);
    notifyListeners();
  }

  Future<void> setMyStatus(String text) async {
    myStatus = text.trim();
    await _prefs!.setString(_keyStatus, myStatus);
    notifyListeners();
  }

  Future<void> addCommunity(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    communities = [
      ShellCommunity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: trimmed,
        createdAtMs: DateTime.now().millisecondsSinceEpoch,
      ),
      ...communities,
    ];
    await _saveCommunities();
  }

  Future<void> removeCommunity(String id) async {
    communities = communities.where((c) => c.id != id).toList();
    await _saveCommunities();
  }

  Future<void> logCall({
    required String title,
    required String chatId,
    required bool video,
    required bool outgoing,
  }) async {
    calls = [
      ShellCall(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        chatId: chatId,
        video: video,
        outgoing: outgoing,
        atMs: DateTime.now().millisecondsSinceEpoch,
      ),
      ...calls,
    ].take(100).toList();
    await _prefs!.setString(
      _keyCalls,
      jsonEncode(calls.map((e) => e.toJson()).toList()),
    );
    notifyListeners();
  }

  Future<void> submitFeedback(String body) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return;
    feedback = [
      ShellFeedback(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        body: trimmed,
        atMs: DateTime.now().millisecondsSinceEpoch,
      ),
      ...feedback,
    ].take(50).toList();
    await _prefs!.setString(
      _keyFeedback,
      jsonEncode(feedback.map((e) => e.toJson()).toList()),
    );
    notifyListeners();
  }

  Future<void> setRetentionDays(int days) async {
    retentionDays = days;
    await _prefs!.setInt(_keyRetention, days);
    notifyListeners();
  }

  Future<void> _saveCommunities() async {
    await _prefs!.setString(
      _keyCommunities,
      jsonEncode(communities.map((e) => e.toJson()).toList()),
    );
    notifyListeners();
  }

  List<T> _decodeList<T>(
    String? raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }
}

class ShellCommunity {
  const ShellCommunity({
    required this.id,
    required this.name,
    required this.createdAtMs,
  });

  final String id;
  final String name;
  final int createdAtMs;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAtMs': createdAtMs,
      };

  factory ShellCommunity.fromJson(Map<String, dynamic> j) => ShellCommunity(
        id: '${j['id']}',
        name: '${j['name'] ?? ''}',
        createdAtMs: (j['createdAtMs'] as num?)?.toInt() ?? 0,
      );
}

class ShellCall {
  const ShellCall({
    required this.id,
    required this.title,
    required this.chatId,
    required this.video,
    required this.outgoing,
    required this.atMs,
  });

  final String id;
  final String title;
  final String chatId;
  final bool video;
  final bool outgoing;
  final int atMs;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'chatId': chatId,
        'video': video,
        'outgoing': outgoing,
        'atMs': atMs,
      };

  factory ShellCall.fromJson(Map<String, dynamic> j) => ShellCall(
        id: '${j['id']}',
        title: '${j['title'] ?? ''}',
        chatId: '${j['chatId'] ?? ''}',
        video: j['video'] == true,
        outgoing: j['outgoing'] == true,
        atMs: (j['atMs'] as num?)?.toInt() ?? 0,
      );
}

class ShellFeedback {
  const ShellFeedback({
    required this.id,
    required this.body,
    required this.atMs,
  });

  final String id;
  final String body;
  final int atMs;

  Map<String, dynamic> toJson() => {
        'id': id,
        'body': body,
        'atMs': atMs,
      };

  factory ShellFeedback.fromJson(Map<String, dynamic> j) => ShellFeedback(
        id: '${j['id']}',
        body: '${j['body'] ?? ''}',
        atMs: (j['atMs'] as num?)?.toInt() ?? 0,
      );
}
