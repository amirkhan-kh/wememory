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

/// First-run like WhatsApp: phone → name → about → photo → done.
class SetupFlowScreen extends StatefulWidget {
  const SetupFlowScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<SetupFlowScreen> createState() => _SetupFlowScreenState();
}

class _SetupFlowScreenState extends State<SetupFlowScreen> {
  static const _channel = MethodChannel('com.wamemory.app/notifications');
  final _page = PageController();
  final _phoneCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _aboutCtrl = TextEditingController();
  int _index = 0;
  bool _busy = false;
  bool _seeded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) return;
    _seeded = true;
    final profile = context.read<ProfileStore>();
    final bridge = context.read<WaBridgeService>();
    _phoneCtrl.text = profile.phone.isNotEmpty ? profile.phone : bridge.phone;
    _nameCtrl.text =
        profile.displayName == ProfileStore.defaultName ? '' : profile.displayName;
    _aboutCtrl.text = profile.about;
  }

  @override
  void dispose() {
    _page.dispose();
    _phoneCtrl.dispose();
    _nameCtrl.dispose();
    _aboutCtrl.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    final profile = context.read<ProfileStore>();
    final bridge = context.read<WaBridgeService>();

    if (_index == 0) {
      final err = PhoneUtils.validationError(_phoneCtrl.text);
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
        return;
      }
      final digits = PhoneUtils.normalize(_phoneCtrl.text);
      // Local only — live WhatsApp link happens in Settings → Connect.
      await profile.update(phone: digits);
      await bridge.setPhone(digits);
    } else if (_index == 1) {
      final name = _nameCtrl.text.trim();
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter your name')),
        );
        return;
      }
      await profile.update(displayName: name);
    } else if (_index == 2) {
      await profile.update(about: _aboutCtrl.text);
    }

    if (_index < 3) {
      setState(() => _index += 1);
      await _page.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    await profile.markSetupComplete();
    widget.onDone();
  }

  Future<void> _pickPhoto() async {
    final photos = await Permission.photos.request();
    final ok = photos.isGranted ||
        photos.isLimited ||
        (await Permission.storage.request()).isGranted;
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Allow Photos to pick a profile picture')),
      );
      return;
    }
    final profile = context.read<ProfileStore>();
    setState(() => _busy = true);
    try {
      final path = await _channel.invokeMethod<String?>('pickProfileImage');
      if (path != null && path.isNotEmpty) {
        await profile.update(photoPath: path);
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

  @override
  Widget build(BuildContext context) {
    AppColors.bind(context);
    final profile = context.watch<ProfileStore>();
    return SurrealBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    Text(
                      'Step ${_index + 1} of 4',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (_index == 3)
                      TextButton(
                        onPressed: () async {
                          await profile.markSetupComplete();
                          widget.onDone();
                        },
                        child: const Text('Skip photo'),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _page,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _PhoneStep(controller: _phoneCtrl),
                    _NameStep(controller: _nameCtrl),
                    _AboutStep(controller: _aboutCtrl),
                    _PhotoStep(
                      profile: profile,
                      busy: _busy,
                      onPick: _pickPhoto,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: FilledButton(
                  onPressed: _busy ? null : _next,
                  child: Text(_index == 3 ? 'Finish' : 'Next'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhoneStep extends StatelessWidget {
  const _PhoneStep({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    AppColors.bind(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          WaIcon(WaIcons.lock, size: 42, color: AppColors.accentBright, glow: true),
          const SizedBox(height: 20),
          Text(
            'Your WhatsApp number',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Saved on this phone only. Live WhatsApp link is Settings → Connect (ban risk — prefer a test number).',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 28),
          TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
            decoration: InputDecoration(
              hintText: '998901234567',
              hintStyle: TextStyle(color: AppColors.textSecondary),
              prefixText: '+ ',
              prefixStyle: TextStyle(color: AppColors.textPrimary, fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _NameStep extends StatelessWidget {
  const _NameStep({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    AppColors.bind(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Profile name',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Shown in WAMemory Settings and chats header.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 28),
          TextField(
            controller: controller,
            textCapitalization: TextCapitalization.words,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
            decoration: InputDecoration(
              hintText: 'Your name',
              hintStyle: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutStep extends StatelessWidget {
  const _AboutStep({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    AppColors.bind(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'About',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Optional status line — like WhatsApp About.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 28),
          TextField(
            controller: controller,
            maxLines: 3,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Hey there! I am using WAMemory.',
              hintStyle: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoStep extends StatelessWidget {
  const _PhotoStep({
    required this.profile,
    required this.busy,
    required this.onPick,
  });

  final ProfileStore profile;
  final bool busy;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    AppColors.bind(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Profile photo',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Add a photo from your gallery.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: busy ? null : onPick,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                AvatarCircle(
                  name: profile.displayName,
                  colorHex: profile.avatarColor,
                  imagePath: profile.photoPath,
                  size: 140,
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: WaIcon(
                    WaIcons.camera,
                    size: 20,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (busy) ...[
            const SizedBox(height: 16),
            const CircularProgressIndicator(strokeWidth: 2),
          ],
        ],
      ),
    );
  }
}
