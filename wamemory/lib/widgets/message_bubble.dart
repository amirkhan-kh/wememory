import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../core/models/message.dart';
import '../core/theme/app_colors.dart';
import 'wa_icons.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message});

  final Message message;

  static const _channel = MethodChannel('com.wamemory.app/notifications');

  Future<void> _openMedia(BuildContext context) async {
    final path = message.mediaPath;
    if (path == null || path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Media file not saved yet')),
      );
      return;
    }
    final mime = switch (message.type) {
      MessageType.image => 'image/*',
      MessageType.video => 'video/*',
      MessageType.audio || MessageType.voice => 'audio/*',
      MessageType.document => '*/*',
      _ => '*/*',
    };
    try {
      await _channel.invokeMethod<bool>('openMediaFile', {
        'path': path,
        'mime': mime,
      });
    } on PlatformException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Open failed: ${e.message ?? e.code}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    AppColors.bind(context);
    final out = message.isOutgoing;
    final deleted = message.isDeleted;
    final bg = deleted
        ? AppColors.bubbleDeleted
        : (out ? AppColors.bubbleOut : AppColors.bubbleIn);

    return Align(
      alignment: out ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(8),
              topRight: const Radius.circular(8),
              bottomLeft: Radius.circular(out ? 8 : 2),
              bottomRight: Radius.circular(out ? 2 : 8),
            ),
            border: deleted
                ? Border.all(color: AppColors.warning.withValues(alpha: 0.45))
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(9, 6, 9, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (deleted)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        WaIcon(
                          WaIcons.deleted,
                          size: 14,
                          color: AppColors.warning,
                          secondaryColor: AppColors.warning,
                        ),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Deleted · saved in WAMemory',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.warning,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (message.type == MessageType.voice ||
                    message.type == MessageType.audio)
                  _SavedMediaTile(
                    label: message.type == MessageType.voice
                        ? 'Voice message'
                        : (message.body.startsWith('[')
                            ? 'Audio'
                            : message.body),
                    icon: WaIcons.play,
                    path: message.mediaPath,
                    onOpen: () => _openMedia(context),
                  )
                else if (message.type == MessageType.image)
                  _ImagePreview(
                    path: message.mediaPath,
                    caption: message.body.startsWith('[')
                        ? null
                        : message.body,
                    onOpen: () => _openMedia(context),
                  )
                else if (message.type == MessageType.video)
                  _SavedMediaTile(
                    label: message.body.startsWith('[')
                        ? 'Video'
                        : message.body,
                    icon: WaIcons.video,
                    path: message.mediaPath,
                    onOpen: () => _openMedia(context),
                    tall: true,
                  )
                else if (message.type == MessageType.document)
                  _SavedMediaTile(
                    label: message.body.startsWith('[')
                        ? 'Document'
                        : message.body,
                    icon: WaIcons.document,
                    path: message.mediaPath,
                    onOpen: () => _openMedia(context),
                  )
                else
                  Text(
                    message.body,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15.5,
                      height: 1.35,
                      fontStyle:
                          deleted ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (deleted && message.deletedAt != null) ...[
                      Text(
                        'del ${DateFormat.Hm().format(message.deletedAt!)}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      DateFormat.Hm().format(message.timestamp),
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    if (out) ...[
                      const SizedBox(width: 4),
                      WaIcon(
                        WaIcons.checkDouble,
                        size: 14,
                        color: AppColors.accentBright,
                        secondaryColor: AppColors.accentBright,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({this.path, this.caption, required this.onOpen});
  final String? path;
  final String? caption;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    AppColors.bind(context);
    final file = path != null && path!.isNotEmpty ? File(path!) : null;
    final has = file != null && file.existsSync();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: has ? onOpen : null,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: has
                ? Image.file(
                    file,
                    width: 220,
                    height: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const _MediaPlaceholder(
                      label: 'Photo',
                      icon: WaIcons.image,
                    ),
                  )
                : const _MediaPlaceholder(label: 'Photo', icon: WaIcons.image),
          ),
        ),
        if (caption != null && caption!.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            caption!,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14.5,
              height: 1.3,
            ),
          ),
        ],
      ],
    );
  }
}

class _SavedMediaTile extends StatelessWidget {
  const _SavedMediaTile({
    required this.label,
    required this.icon,
    required this.onOpen,
    this.path,
    this.tall = false,
  });

  final String label;
  final WaIcons icon;
  final String? path;
  final VoidCallback onOpen;
  final bool tall;

  @override
  Widget build(BuildContext context) {
    AppColors.bind(context);
    final has = path != null && path!.isNotEmpty && File(path!).existsSync();
    final sizeLabel = () {
      if (!has) return 'Waiting for file…';
      try {
        final bytes = File(path!).lengthSync();
        if (bytes >= 1024 * 1024) {
          return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB · saved';
        }
        return '${(bytes / 1024).toStringAsFixed(0)} KB · saved';
      } catch (_) {
        return 'Saved';
      }
    }();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: has ? onOpen : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 220,
          height: tall ? 140 : 88,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent.withValues(alpha: 0.25),
                ),
                alignment: Alignment.center,
                child: WaIcon(icon, size: 22, color: AppColors.accentBright),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sizeLabel,
                      style: TextStyle(
                        color: has
                            ? AppColors.accentBright
                            : AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MediaPlaceholder extends StatelessWidget {
  const _MediaPlaceholder({required this.label, required this.icon});
  final String label;
  final WaIcons icon;

  @override
  Widget build(BuildContext context) {
    AppColors.bind(context);
    return Container(
      width: 220,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          WaIcon(icon, size: 34, color: AppColors.textSecondary),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
