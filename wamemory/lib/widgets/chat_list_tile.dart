import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/models/chat.dart';
import '../core/theme/app_colors.dart';
import 'avatar_circle.dart';
import 'surreal_background.dart';

class ChatListTile extends StatelessWidget {
  const ChatListTile({
    super.key,
    required this.chat,
    required this.onTap,
  });

  final Chat chat;
  final VoidCallback onTap;

  String _timeLabel() {
    final t = chat.lastMessageAt;
    if (t == null) return '';
    final now = DateTime.now();
    if (now.difference(t).inDays == 0) {
      return DateFormat.Hm().format(t);
    }
    if (now.difference(t).inDays == 1) return 'Yesterday';
    return DateFormat.MMMd().format(t);
  }

  @override
  Widget build(BuildContext context) {
    final unread = chat.unreadCount > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: GlassPanel(
        radius: 18,
        blur: 12,
        opacity: 0.48,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                AvatarCircle(name: chat.title, colorHex: chat.avatarColor),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Text(
                            _timeLabel(),
                            style: TextStyle(
                              color: unread
                                  ? AppColors.accentBright
                                  : AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat.lastMessage ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                                fontWeight: unread ? FontWeight.w500 : FontWeight.w400,
                              ),
                            ),
                          ),
                          if (unread) ...[
                            const SizedBox(width: 8),
                            ConstrainedBox(
                              constraints:
                                  const BoxConstraints(minWidth: 22, minHeight: 22),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.unreadBadge,
                                  borderRadius: BorderRadius.circular(11),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.accentBright.withValues(alpha: 0.45),
                                      blurRadius: 10,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${chat.unreadCount}',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
