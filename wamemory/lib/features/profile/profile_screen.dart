import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../core/services/profile_store.dart';
import '../../core/services/wa_bridge_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/phone_utils.dart';
import '../../widgets/avatar_circle.dart';
import '../../widgets/surreal_background.dart';
import '../../widgets/wa_icons.dart';

/// WhatsApp-like profile: photo, name, about, phone.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _channel = MethodChannel('com.wamemory.app/notifications');
  bool _busy = false;

  Future<bool> _ensurePhotosPermission() async {
    final photos = await Permission.photos.request();
    if (photos.isGranted || photos.isLimited) return true;
    final storage = await Permission.storage.request();
    if (storage.isGranted) return true;
    if (!mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Allow Photos access to set profile picture'),
      ),
    );
    return false;
  }

  Future<void> _pickPhoto(ProfileStore profile) async {
    if (!await _ensurePhotosPermission()) return;
    setState(() => _busy = true);
    try {
      final path = await _channel.invokeMethod<String?>('pickProfileImage');
      if (path != null && path.isNotEmpty) {
        await profile.update(photoPath: path);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo saved')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No photo selected')),
        );
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Photo failed: ${e.message ?? e.code}')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editField({
    required String title,
    required String initial,
    required int maxLines,
    required Future<void> Function(String) onSave,
  }) async {
    final ctrl = TextEditingController(text: initial);
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        final bottom = MediaQuery.viewInsetsOf(ctx).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: ctrl,
                maxLines: maxLines,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
    if (ok == true) {
      try {
        await onSave(ctrl.text);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
    ctrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileStore>();
    final bridge = context.watch<WaBridgeService>();
    final phone = profile.phone.isNotEmpty ? profile.phone : bridge.phone;

    return SurrealBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: Colors.transparent,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            const SizedBox(height: 12),
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  AvatarCircle(
                    name: profile.displayName,
                    colorHex: profile.avatarColor,
                    imagePath: profile.photoPath,
                    size: 140,
                  ),
                  Material(
                    color: AppColors.accent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _busy ? null : () => _pickPhoto(profile),
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: WaIcon(
                          WaIcons.camera,
                          size: 22,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_busy)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            const SizedBox(height: 10),
            const Text(
              'This photo is shown inside WAMemory. Linking WhatsApp uses Evolution (ban risk).',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 24),
            GlassPanel(
              radius: 18,
              child: Column(
                children: [
                  _Row(
                    icon: WaIcons.premium,
                    label: 'Name',
                    value: profile.displayName,
                    onTap: () => _editField(
                      title: 'Name',
                      initial: profile.displayName,
                      maxLines: 1,
                      onSave: (v) => profile.update(displayName: v),
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.divider),
                  _Row(
                    icon: WaIcons.info,
                    label: 'About',
                    value: profile.about,
                    onTap: () => _editField(
                      title: 'About',
                      initial: profile.about,
                      maxLines: 3,
                      onSave: (v) => profile.update(about: v),
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.divider),
                  _Row(
                    icon: WaIcons.lock,
                    label: 'Phone',
                    value: phone.isEmpty ? 'Not set' : '+$phone',
                    onTap: () => _editField(
                      title: 'Phone (country code)',
                      initial: phone,
                      maxLines: 1,
                      onSave: (v) async {
                        final messenger = ScaffoldMessenger.of(context);
                        final err = PhoneUtils.validationError(v);
                        if (err != null) {
                          messenger.showSnackBar(SnackBar(content: Text(err)));
                          return;
                        }
                        final digits = PhoneUtils.normalize(v);
                        await profile.update(phone: digits);
                        await bridge.setPhone(digits);
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Phone saved locally. Use Settings → Connect WhatsApp to link.',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (profile.photoPath != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => profile.update(clearPhoto: true),
                child: const Text('Remove photo'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final WaIcons icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: WaIcon(icon, size: 22, color: AppColors.accentBright),
      title: Text(
        label,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const WaIcon(
        WaIcons.settings,
        size: 18,
        color: AppColors.textSecondary,
      ),
      onTap: onTap,
    );
  }
}
