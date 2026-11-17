import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/models/chat.dart';
import '../../core/models/message.dart';
import '../../core/services/archive_service.dart';
import '../../core/services/wa_bridge_service.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/avatar_circle.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/surreal_background.dart';
import '../../widgets/wa_icons.dart';

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({super.key, required this.chat});

  final Chat chat;

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  static const _channel = MethodChannel('com.wamemory.app/notifications');
  List<Message> _messages = [];
  bool _loading = true;
  bool _sendingMedia = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final archive = context.read<ArchiveService>();
    final msgs = await archive.messagesFor(widget.chat.id);
    if (!mounted) return;
    setState(() {
      _messages = msgs;
      _loading = false;
    });
  }

  String? _digitsFromTitle(String title) {
    final d = title.replaceAll(RegExp(r'[^\d]'), '');
    return d.length >= 8 ? d : null;
  }

  Future<String?> _resolveNumber() async {
    var number = _digitsFromTitle(widget.chat.title);
    if (number != null) return number;
    return _askNumber();
  }

  Future<void> _handleSend(String text) async {
    final archive = context.read<ArchiveService>();
    final bridge = context.read<WaBridgeService>();
    await archive.appendOutgoing(chatId: widget.chat.id, body: text);
    await _load();

    if (!bridge.isLinked) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Saved locally. Link WhatsApp in Settings → Connect to send live.',
          ),
        ),
      );
      return;
    }

    final number = await _resolveNumber();
    if (number == null || number.isEmpty) return;
    final ok = await bridge.sendText(number: number, text: text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Sent via Evolution'
              : 'Send failed: ${bridge.lastError ?? 'unknown'}',
        ),
      ),
    );
  }

  Future<void> _handlePickMedia({required String mime}) async {
    if (_sendingMedia) return;
    setState(() => _sendingMedia = true);
    try {
      final path = await _channel.invokeMethod<String?>('pickChatMedia', {
        'mime': mime,
        'fileName': mime.startsWith('image/')
            ? 'chat_${DateTime.now().millisecondsSinceEpoch}.jpg'
            : mime.startsWith('video/')
                ? 'chat_${DateTime.now().millisecondsSinceEpoch}.mp4'
                : 'chat_${DateTime.now().millisecondsSinceEpoch}.bin',
      });
      if (path == null || path.isEmpty) return;

      final file = File(path);
      if (!await file.exists()) return;
      final bytes = await file.readAsBytes();
      // Video/audio archive: allow larger files (Nest body limit 40mb).
      final maxBytes = mime.startsWith('video/')
          ? 28 * 1024 * 1024
          : 16 * 1024 * 1024;
      if (bytes.length > maxBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'File too large (max ${(maxBytes / (1024 * 1024)).round()} MB)',
            ),
          ),
        );
        return;
      }

      final mediaType = mime.startsWith('video/')
          ? 'video'
          : mime.startsWith('audio/')
              ? 'audio'
              : mime.startsWith('image/')
                  ? 'image'
                  : 'document';
      final mimetype = mime.contains('*')
          ? (mediaType == 'image'
              ? 'image/jpeg'
              : mediaType == 'video'
                  ? 'video/mp4'
                  : 'application/octet-stream')
          : mime;
      final b64 = base64Encode(bytes);
      final preview = mediaType == 'image'
          ? 'Photo'
          : mediaType == 'video'
              ? 'Video'
              : mediaType == 'audio'
                  ? 'Audio'
                  : 'Document';

      if (!mounted) return;
      final archive = context.read<ArchiveService>();
      final bridge = context.read<WaBridgeService>();
      await archive.appendOutgoing(
        chatId: widget.chat.id,
        body: preview,
        type: mediaType == 'image'
            ? MessageType.image
            : mediaType == 'video'
                ? MessageType.video
                : mediaType == 'audio'
                    ? MessageType.audio
                    : MessageType.document,
        mediaPath: path,
      );
      await _load();

      if (!bridge.isLinked) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved locally. Link WhatsApp to send live.'),
          ),
        );
        return;
      }

      final number = await _resolveNumber();
      if (number == null || number.isEmpty) return;
      final ok = await bridge.sendMedia(
        number: number,
        mediaType: mediaType,
        mimetype: mimetype,
        mediaBase64: b64,
        fileName: path.split('/').last,
        caption: preview,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Media sent via Evolution'
                : 'Media send failed: ${bridge.lastError ?? 'unknown'}',
          ),
        ),
      );
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pick failed: ${e.message ?? e.code}')),
      );
    } finally {
      if (mounted) setState(() => _sendingMedia = false);
    }
  }

  Future<String?> _askNumber() async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: const Text('Recipient number'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: '998901234567',
            hintStyle: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return SurrealBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: AppColors.appBar.withValues(alpha: 0.72),
          titleSpacing: 0,
          title: Row(
            children: [
              AvatarCircle(
                name: widget.chat.title,
                colorHex: widget.chat.avatarColor,
                size: 36,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.chat.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      context.watch<WaBridgeService>().isLinked
                          ? 'Linked · Evolution'
                          : 'Archive · local',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: const [
            WaIcon(WaIcons.video, size: 22),
            SizedBox(width: 14),
            WaIcon(WaIcons.call, size: 22),
            SizedBox(width: 14),
            WaIcon(WaIcons.more, size: 22),
            SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.accent),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: _messages.length,
                      itemBuilder: (context, i) =>
                          MessageBubble(message: _messages[i]),
                    ),
            ),
            if (_sendingMedia)
              const LinearProgressIndicator(
                minHeight: 2,
                color: AppColors.accent,
              ),
            _ComposerBar(
              onSend: (text) => _handleSend(text),
              onAttachPhoto: () => _handlePickMedia(mime: 'image/*'),
              onAttachVideo: () => _handlePickMedia(mime: 'video/*'),
              onAttachFile: () => _handlePickMedia(mime: '*/*'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposerBar extends StatefulWidget {
  const _ComposerBar({
    required this.onSend,
    required this.onAttachPhoto,
    required this.onAttachVideo,
    required this.onAttachFile,
  });
  final ValueChanged<String> onSend;
  final VoidCallback onAttachPhoto;
  final VoidCallback onAttachVideo;
  final VoidCallback onAttachFile;

  @override
  State<_ComposerBar> createState() => _ComposerBarState();
}

class _ComposerBarState extends State<_ComposerBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _showAttachSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const WaIcon(WaIcons.image, size: 22),
              title: const Text('Photo'),
              onTap: () {
                Navigator.pop(ctx);
                widget.onAttachPhoto();
              },
            ),
            ListTile(
              leading: const WaIcon(WaIcons.video, size: 22),
              title: const Text('Video'),
              onTap: () {
                Navigator.pop(ctx);
                widget.onAttachVideo();
              },
            ),
            ListTile(
              leading: const WaIcon(WaIcons.document, size: 22),
              title: const Text('Document'),
              onTap: () {
                Navigator.pop(ctx);
                widget.onAttachFile();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.panel,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _showAttachSheet,
                      icon: const WaIcon(
                        WaIcons.plus,
                        size: 22,
                        color: AppColors.accentBright,
                        secondaryColor: AppColors.accentBright,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          hintText: 'Type here',
                          border: InputBorder.none,
                          filled: false,
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onAttachPhoto,
                      icon: const WaIcon(WaIcons.camera, size: 22),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _send,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentBright.withValues(alpha: 0.35),
                      blurRadius: 12,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const WaIcon(
                  WaIcons.send,
                  size: 20,
                  color: Colors.white,
                  secondaryColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
  }
}
