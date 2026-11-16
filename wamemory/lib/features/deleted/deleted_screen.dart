import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/services/archive_service.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/avatar_circle.dart';
import '../../widgets/perspective_scroll_list.dart';
import '../../widgets/surreal_background.dart';
import '../../widgets/wa_icons.dart';
import '../chat_detail/chat_detail_screen.dart';

class DeletedScreen extends StatelessWidget {
  const DeletedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final archive = context.watch<ArchiveService>();
    final items = archive.deleted;

    return SurrealBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Deleted messages'),
        ),
        body: items.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Deleted messages that WAMemory already archived will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, height: 1.4),
                  ),
                ),
              )
            : PerspectiveScrollList(
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final m = items[i];
                  final chat =
                      archive.chats.where((c) => c.id == m.chatId).toList();
                  final title =
                      chat.isNotEmpty ? chat.first.title : (m.sender ?? 'Chat');
                  final color = chat.isNotEmpty ? chat.first.avatarColor : null;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    child: GlassPanel(
                      radius: 16,
                      child: ListTile(
                        leading:
                            AvatarCircle(name: title, colorHex: color, size: 44),
                        title: Text(
                          title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          m.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const WaIcon(
                              WaIcons.deleted,
                              size: 18,
                              color: AppColors.warning,
                              secondaryColor: AppColors.warning,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              m.deletedAt != null
                                  ? DateFormat.MMMd()
                                      .add_Hm()
                                      .format(m.deletedAt!)
                                  : '',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          if (chat.isEmpty) return;
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ChatDetailScreen(chat: chat.first),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
