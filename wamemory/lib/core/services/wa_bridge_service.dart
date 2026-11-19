import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/phone_utils.dart';
import 'archive_service.dart';

class WaContact {
  WaContact({
    required this.id,
    required this.displayName,
    required this.pushName,
    required this.phone,
  });

  final String id;
  final String displayName;
  final String pushName;
  final String phone;

  factory WaContact.fromJson(Map<String, dynamic> j) {
    final id = '${j['id'] ?? j['remoteJid'] ?? j['jid'] ?? ''}';
    final phone = PhoneUtils.normalize(
      '${j['number'] ?? j['phone'] ?? id.split('@').first}',
    );
    final push = '${j['pushName'] ?? j['notify'] ?? ''}'.trim();
    final name = '${j['name'] ?? j['verifiedName'] ?? push}'.trim();
    return WaContact(
      id: id.isEmpty ? phone : id,
      displayName: name.isNotEmpty ? name : (push.isNotEmpty ? push : phone),
      pushName: push,
      phone: phone,
    );
  }
}

class BridgeSyncMessage {
  BridgeSyncMessage({
    required this.notificationKey,
    required this.remoteJid,
    required this.pushName,
    required this.body,
    required this.fromMe,
    required this.isDeleted,
    required this.timestamp,
    required this.seq,
    this.mediaType,
    this.mediaMime,
    this.mediaBase64,
    this.mediaUrl,
    this.fileName,
  });

  final String notificationKey;
  final String remoteJid;
  final String pushName;
  final String body;
  final bool fromMe;
  final bool isDeleted;
  final DateTime timestamp;
  final int seq;
  final String? mediaType;
  final String? mediaMime;
  final String? mediaBase64;
  final String? mediaUrl;
  final String? fileName;

  factory BridgeSyncMessage.fromJson(Map<String, dynamic> j) {
    final ts = j['timestamp'];
    final ms = ts is int
        ? (ts < 20000000000 ? ts : ts)
        : int.tryParse('$ts') ?? DateTime.now().millisecondsSinceEpoch;
    final mt = j['mediaType'];
    return BridgeSyncMessage(
      notificationKey: '${j['notificationKey'] ?? j['id']}',
      remoteJid: '${j['remoteJid'] ?? ''}',
      pushName: '${j['pushName'] ?? 'Chat'}',
      body: '${j['body'] ?? ''}',
      fromMe: j['fromMe'] == true,
      isDeleted: j['isDeleted'] == true,
      timestamp: DateTime.fromMillisecondsSinceEpoch(ms),
      seq: (j['seq'] as num?)?.toInt() ?? 0,
      mediaType: mt == null || '$mt' == 'null' ? null : '$mt',
      mediaMime: j['mediaMime'] == null ? null : '${j['mediaMime']}',
      mediaBase64: j['mediaBase64'] == null ? null : '${j['mediaBase64']}',
      mediaUrl: j['mediaUrl'] == null ? null : '${j['mediaUrl']}',
      fileName: j['fileName'] == null ? null : '${j['fileName']}',
    );
  }
}

/// Nest `/api/evolution/*` — one phone number per subscriber.
class WaBridgeService extends ChangeNotifier {
  WaBridgeService({
    SharedPreferences? prefs,
    http.Client? client,
    ArchiveService? archive,
  })  : _prefsOverride = prefs,
        _client = client ?? http.Client(),
        _archive = archive;

  static const _keyBase = 'wa_bridge_base_url';
  static const _keyPhone = 'wa_bridge_phone';
  static const _keySeq = 'wa_bridge_sync_seq';
  /// Override at build: `--dart-define=WAMEMORY_API_BASE=…`
  /// Contabo test demo is the shareable default; local/emulator overrides via define.
  static const defaultBaseUrl = String.fromEnvironment(
    'WAMEMORY_API_BASE',
    defaultValue: 'http://13.140.202.159:8090/api',
  );

  final SharedPreferences? _prefsOverride;
  final http.Client _client;
  ArchiveService? _archive;
  SharedPreferences? _prefs;
  Timer? _syncTimer;

  String baseUrl = defaultBaseUrl;
  String phone = '';
  int syncSeq = 0;
  bool configured = false;
  bool syncing = false;
  String connectionState = 'unknown';
  String? lastError;
  String? banWarning;
  String? pairingCode;
  String? qrBase64;
  String? instanceName;

  void attachArchive(ArchiveService archive) {
    _archive = archive;
  }

  Future<void> init() async {
    _prefs = _prefsOverride ?? await SharedPreferences.getInstance();
    var stored = _prefs!.getString(_keyBase) ?? defaultBaseUrl;
    // Old APKs baked emulator loopback — real phones cannot reach 10.0.2.2.
    if (stored.contains('10.0.2.2')) {
      stored = defaultBaseUrl;
      await _prefs!.setString(_keyBase, stored);
    }
    baseUrl = stored;
    phone = _prefs!.getString(_keyPhone) ?? '';
    syncSeq = _prefs!.getInt(_keySeq) ?? 0;
    notifyListeners();
    if (phone.isNotEmpty) {
      startSyncLoop();
    }
  }

  Future<void> setBaseUrl(String url) async {
    final cleaned = url.trim().replaceAll(RegExp(r'/+$'), '');
    baseUrl = cleaned.isEmpty ? defaultBaseUrl : cleaned;
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    await prefs.setString(_keyBase, baseUrl);
    notifyListeners();
    await refreshStatus();
  }

  Future<void> setPhone(String raw) async {
    phone = PhoneUtils.normalize(raw);
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    await prefs.setString(_keyPhone, phone);
    notifyListeners();
  }

  Uri _u(String path, [Map<String, String>? query]) {
    final root = baseUrl.endsWith('/api') ? baseUrl : '$baseUrl/api';
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$root$p').replace(queryParameters: query);
  }

  /// Nest / Evolution error body → short user text (no Exception dump).
  static String parseApiError(int status, String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final msg = decoded['message'];
        if (msg is String && msg.trim().isNotEmpty) return msg.trim();
        if (msg is List && msg.isNotEmpty) {
          return msg.map((e) => '$e').where((s) => s.isNotEmpty).join('; ');
        }
      }
    } catch (_) {
      // fall through
    }
    final trimmed = body.trim();
    if (trimmed.isNotEmpty && trimmed.length < 180) return trimmed;
    return 'Request failed ($status)';
  }

  Future<Map<String, dynamic>?> _get(
    String path, [
    Map<String, String>? query,
  ]) async {
    try {
      final res =
          await _client.get(_u(path, query)).timeout(const Duration(seconds: 12));
      if (res.statusCode >= 400) {
        lastError = parseApiError(res.statusCode, res.body);
        notifyListeners();
        return null;
      }
      lastError = null;
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      lastError = 'Cannot reach API ($baseUrl). Check Wi‑Fi / Contabo.';
      notifyListeners();
      return null;
    }
  }

  Future<Map<String, dynamic>?> _post(
    String path,
    Map<String, dynamic> body, {
    Duration timeout = const Duration(seconds: 45),
  }) async {
    try {
      final res = await _client
          .post(
            _u(path),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(timeout);
      if (res.statusCode >= 400) {
        lastError = parseApiError(res.statusCode, res.body);
        notifyListeners();
        return null;
      }
      lastError = null;
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'data': decoded};
    } catch (e) {
      lastError = 'Cannot reach API ($baseUrl). Check Wi‑Fi / Contabo.';
      notifyListeners();
      return null;
    }
  }

  Future<void> refreshStatus() async {
    final data = await _get('/evolution/status');
    if (data == null) {
      configured = false;
      notifyListeners();
      return;
    }
    configured = data['configured'] == true;
    banWarning = data['banWarning'] as String?;
    notifyListeners();
    if (phone.isNotEmpty) await refreshConnection();
  }

  Future<void> refreshConnection() async {
    if (phone.isEmpty) return;
    final data = await _get('/evolution/connection', {'phone': phone});
    if (data == null) {
      connectionState = 'unreachable';
      notifyListeners();
      return;
    }
    connectionState = (data['state'] as String?) ?? 'unknown';
    instanceName = data['instance'] as String?;
    notifyListeners();
    if (isLinked) startSyncLoop();
  }

  /// Link this subscriber's single WhatsApp number (pairing code preferred).
  Future<bool> linkPhone(String rawPhone) async {
    final err = PhoneUtils.validationError(rawPhone);
    if (err != null) {
      lastError = err;
      notifyListeners();
      return false;
    }
    await setPhone(rawPhone);
    final data = await _post('/evolution/link', {'phone': phone});
    if (data == null) return false;
    pairingCode = data['pairingCode'] as String?;
    final qr = data['qrBase64'] as String?;
    qrBase64 = qr != null ? _stripDataUrl(qr) : null;
    connectionState = (data['state'] as String?) ?? 'connecting';
    instanceName = data['instance'] as String?;
    banWarning = data['banWarning'] as String? ?? banWarning;
    notifyListeners();
    startSyncLoop();
    return true;
  }

  Future<String?> fetchQrBase64() async {
    if (phone.isEmpty) {
      lastError = 'Set phone number first';
      notifyListeners();
      return null;
    }
    final ok = await linkPhone(phone);
    return ok ? qrBase64 : null;
  }

  String _stripDataUrl(String raw) {
    final i = raw.indexOf('base64,');
    if (i >= 0) return raw.substring(i + 7);
    return raw;
  }

  /// Evolution contacts for nickname search (Path B linked only).
  List<WaContact> contacts = [];
  DateTime? _contactsFetchedAt;

  Future<List<WaContact>> fetchContacts({bool force = false}) async {
    if (!force &&
        contacts.isNotEmpty &&
        _contactsFetchedAt != null &&
        DateTime.now().difference(_contactsFetchedAt!) <
            const Duration(minutes: 5)) {
      return contacts;
    }
    if (phone.isEmpty) return contacts;
    final data = await _get('/evolution/contacts', {'phone': phone});
    if (data == null) return contacts;
    final raw = data['contacts'] ?? data['data'] ?? data;
    final list = <WaContact>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is! Map) continue;
        final c = WaContact.fromJson(Map<String, dynamic>.from(item));
        if (c.displayName.isNotEmpty || c.phone.isNotEmpty) list.add(c);
      }
    }
    contacts = list;
    _contactsFetchedAt = DateTime.now();
    notifyListeners();
    return contacts;
  }

  List<WaContact> filterContacts(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return contacts.where((c) {
      return c.displayName.toLowerCase().contains(q) ||
          c.phone.contains(q) ||
          c.pushName.toLowerCase().contains(q);
    }).take(40).toList();
  }

  Future<bool> sendText({required String number, required String text}) async {
    final data = await _post('/evolution/send-text', {
      'number': number,
      'text': text,
      if (phone.isNotEmpty) 'fromPhone': phone,
    });
    return data != null;
  }

  Future<bool> sendMedia({
    required String number,
    required String mediaType,
    required String mimetype,
    required String mediaBase64,
    String? fileName,
    String? caption,
  }) async {
    final data = await _post(
      '/evolution/send-media',
      {
        'number': number,
        'mediaType': mediaType,
        'mimetype': mimetype,
        'media': mediaBase64,
        if (fileName != null) 'fileName': fileName,
        if (caption != null && caption.isNotEmpty) 'caption': caption,
        if (phone.isNotEmpty) 'fromPhone': phone,
      },
      timeout: const Duration(seconds: 90),
    );
    return data != null;
  }

  void startSyncLoop() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      unawaited(pullSync());
    });
    unawaited(pullSync());
  }

  void stopSyncLoop() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  Future<int> pullSync() async {
    if (phone.isEmpty || _archive == null) return 0;
    if (syncing) return 0;
    syncing = true;
    try {
      final data = await _get('/evolution/sync', {
        'after': '$syncSeq',
        'phone': phone,
      });
      if (data == null) return 0;
      final list = (data['messages'] as List?) ?? const [];
      var applied = 0;
      for (final raw in list) {
        if (raw is! Map) continue;
        final m = BridgeSyncMessage.fromJson(Map<String, dynamic>.from(raw));
        await _archive!.ingestBridgeMessage(
          remoteJid: m.remoteJid,
          pushName: m.pushName,
          body: m.body,
          fromMe: m.fromMe,
          isDeleted: m.isDeleted,
          timestamp: m.timestamp,
          notificationKey: m.notificationKey,
          mediaType: m.mediaType,
          mediaMime: m.mediaMime,
          mediaBase64: m.mediaBase64,
          mediaUrl: _absoluteMediaUrl(m.mediaUrl),
          fileName: m.fileName,
        );
        if (m.seq > syncSeq) syncSeq = m.seq;
        applied++;
      }
      final latest = (data['latestSeq'] as num?)?.toInt();
      if (latest != null && latest > syncSeq) syncSeq = latest;
      final prefs = _prefs;
      if (prefs != null) await prefs.setInt(_keySeq, syncSeq);
      if (applied > 0) notifyListeners();
      return applied;
    } finally {
      syncing = false;
    }
  }

  bool get isLinked =>
      connectionState == 'open' || connectionState == 'connected';

  String? _absoluteMediaUrl(String? mediaUrl) {
    if (mediaUrl == null || mediaUrl.isEmpty) return null;
    if (mediaUrl.startsWith('http://') || mediaUrl.startsWith('https://')) {
      return mediaUrl;
    }
    final root = baseUrl.endsWith('/api')
        ? baseUrl.substring(0, baseUrl.length - 4)
        : baseUrl;
    if (mediaUrl.startsWith('/')) return '$root$mediaUrl';
    return '$root/$mediaUrl';
  }

  @override
  void dispose() {
    stopSyncLoop();
    _client.close();
    super.dispose();
  }
}
