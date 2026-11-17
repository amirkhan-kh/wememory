import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/archive_service.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/avatar_circle.dart';
import '../../widgets/perspective_scroll_list.dart';
import '../../widgets/surreal_background.dart';
import '../../widgets/wa_icons.dart';
import '../chat_detail/chat_detail_screen.dart';

/// Contact list derived from archived chat profiles (Evolution contacts later).
class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final archive = context.watch<ArchiveService>();
    final contacts = archive.chats.where((c) {
      if (_query.isEmpty) return true;
      return c.title.toLowerCase().contains(_query.toLowerCase());
    }).toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    return SurrealBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(
                  'Contacts',
                  style: TextStyle(
                    color: AppColors.accentBright,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: GlassPanel(
                  radius: 14,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextField(
                    controller: _search,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      icon: WaIcon(WaIcons.search, size: 20),
                      hintText: 'Search contacts',
                      hintStyle: TextStyle(color: AppColors.textSecondary),
                      border: InputBorder.none,
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
              ),
              Expanded(
                child: contacts.isEmpty
                    ? const Center(
                        child: Text(
                          'No contacts yet — archive chats first',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : PerspectiveScrollList(
                        itemCount: contacts.length,
                        itemBuilder: (context, i) {
                          final c = contacts[i];
                          return ListTile(
                            leading: AvatarCircle(
                              name: c.title,
                              colorHex: c.avatarColor,
                              size: 48,
                            ),
                            title: Text(
                              c.title,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              c.lastMessage ?? 'Tap to open chat',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => ChatDetailScreen(chat: c),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
