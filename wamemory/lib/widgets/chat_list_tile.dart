import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/models/chat.dart';
import '../core/theme/app_colors.dart';
import 'avatar_circle.dart';

/// Flat WhatsApp-dark list row (no glass card).
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
    AppColors.bind(context);
    final unread = chat.unreadCount > 0;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                            fontWeight:
                                unread ? FontWeight.w700 : FontWeight.w600,
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
                          fontWeight:
                              unread ? FontWeight.w600 : FontWeight.w400,
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
                            color: unread
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight:
                                unread ? FontWeight.w500 : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (unread)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.unreadBadge,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${chat.unreadCount}',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
