import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/models/message.dart';
import '../core/theme/app_colors.dart';
import 'wa_icons.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
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
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(out ? 16 : 4),
              bottomRight: Radius.circular(out ? 4 : 16),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: bg.withValues(alpha: out ? 0.92 : 0.78),
                  border: Border.all(
                    color: deleted
                        ? AppColors.warning.withValues(alpha: 0.4)
                        : AppColors.glassBorder,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.10),
                      Colors.white.withValues(alpha: 0.02),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
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
                      if (message.type == MessageType.voice)
                        _VoicePreview(outgoing: out)
                      else if (message.type == MessageType.image)
                        const _MediaPreview(
                          label: 'Photo',
                          icon: WaIcons.image,
                        )
                      else if (message.type == MessageType.video)
                        const _MediaPreview(
                          label: 'Video',
                          icon: WaIcons.video,
                        )
                      else if (message.type == MessageType.document)
                        const _MediaPreview(
                          label: 'Document',
                          icon: WaIcons.document,
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
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            DateFormat.Hm().format(message.timestamp),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                          if (out) ...[
                            const SizedBox(width: 4),
                            const WaIcon(
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
          ),
        ),
      ),
    );
  }
}

class _VoicePreview extends StatelessWidget {
  const _VoicePreview({required this.outgoing});
  final bool outgoing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: outgoing ? AppColors.accent : AppColors.accentSoft,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.accentBright.withValues(alpha: 0.35),
                blurRadius: 10,
              ),
            ],
          ),
          child: const WaIcon(
            WaIcons.play,
            size: 18,
            color: Colors.white,
            secondaryColor: Colors.white,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 28,
                child: CustomPaint(
                  painter: _WavePainter(color: AppColors.accentBright),
                  size: const Size(double.infinity, 28),
                ),
              ),
              const Text(
                '0:43',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MediaPreview extends StatelessWidget {
  const _MediaPreview({required this.label, required this.icon});
  final String label;
  final WaIcons icon;

  @override
  Widget build(BuildContext context) {
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
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    const bars = 28;
    for (var i = 0; i < bars; i++) {
      final x = i * (size.width / bars);
      final h = 6 + (i % 5) * 4.0 + ((i % 3) * 3);
      canvas.drawLine(
        Offset(x, size.height / 2 - h / 2),
        Offset(x, size.height / 2 + h / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
