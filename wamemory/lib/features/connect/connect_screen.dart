import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/services/profile_store.dart';
import '../../core/services/wa_bridge_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/phone_utils.dart';
import '../../widgets/surreal_background.dart';
import '../../widgets/wa_icons.dart';

/// One subscriber → one WhatsApp number (pairing code + optional QR).
class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final _urlCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _busy = false;
  bool _seeded = false;
  bool _showAdvanced = false;
  Timer? _poll;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) return;
    _seeded = true;
    final bridge = context.read<WaBridgeService>();
    final profile = context.read<ProfileStore>();
    _urlCtrl.text = bridge.baseUrl;
    _phoneCtrl.text =
        bridge.phone.isNotEmpty ? bridge.phone : profile.phone;
  }

  @override
  void dispose() {
    _poll?.cancel();
    _urlCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _startPoll() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 3), (_) async {
      final bridge = context.read<WaBridgeService>();
      await bridge.refreshConnection();
      if (bridge.isLinked) {
        _poll?.cancel();
        _poll = null;
        if (!mounted) return;
        _toast('WhatsApp linked');
      }
    });
  }

  Future<void> _saveUrl() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty || !url.startsWith('http')) {
      _toast('API URL must start with http:// or https://');
      return;
    }
    await context.read<WaBridgeService>().setBaseUrl(url);
    if (!mounted) return;
    _toast('API URL saved');
  }

  Future<void> _link() async {
    final phoneErr = PhoneUtils.validationError(_phoneCtrl.text);
    if (phoneErr != null) {
      _toast(phoneErr);
      return;
    }
    setState(() => _busy = true);
    final bridge = context.read<WaBridgeService>();
    final profile = context.read<ProfileStore>();
    if (_urlCtrl.text.trim().isNotEmpty) {
      await bridge.setBaseUrl(_urlCtrl.text);
    }
    final ok = await bridge.linkPhone(_phoneCtrl.text);
    if (ok) {
      await profile.update(phone: bridge.phone);
      _startPoll();
    }
    if (!mounted) return;
    setState(() => _busy = false);
    _toast(
      ok
          ? (bridge.pairingCode != null
              ? 'Pairing code ready — enter it in WhatsApp → Linked devices'
              : 'Link started — scan QR if shown')
          : (bridge.lastError ?? 'Link failed'),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppColors.bind(context);
    final bridge = context.watch<WaBridgeService>();

    return SurrealBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Connect WhatsApp'),
          backgroundColor: Colors.transparent,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            GlassPanel(
              radius: 16,
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WaIcon(
                    WaIcons.warning,
                    size: 22,
                    color: AppColors.warning,
                    secondaryColor: AppColors.warning,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      bridge.banWarning ??
                          'One WhatsApp number per account. Unofficial link — ban risk. Use a dedicated test number.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassPanel(
              radius: 16,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Your WhatsApp number',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Country code + number, digits only (e.g. 998901234567). This links your existing WhatsApp — it does not create a new account.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d+]')),
                    ],
                    style: TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: '998901234567',
                      hintStyle: TextStyle(color: AppColors.textSecondary),
                      prefixText: '+ ',
                      prefixStyle: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _busy ? null : _link,
                    child: Text(_busy ? 'Linking…' : 'Link this number'),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'State: ${bridge.connectionState}'
                    '${bridge.instanceName != null ? ' · ${bridge.instanceName}' : ''}'
                    '${bridge.lastError != null ? '\n${bridge.lastError}' : ''}',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: _showAdvanced,
                onExpansionChanged: (v) => setState(() => _showAdvanced = v),
                tilePadding: const EdgeInsets.symmetric(horizontal: 4),
                title: Text(
                  'Advanced (API URL)',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                children: [
                  GlassPanel(
                    radius: 16,
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Only change this if Contabo default fails. Do not paste API keys here.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        TextField(
                          controller: _urlCtrl,
                          style: TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'http://13.140.202.159:8090/api',
                            hintStyle: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                        TextButton(
                          onPressed: _busy ? null : _saveUrl,
                          child: const Text('Save API URL only'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (bridge.pairingCode != null) ...[
              const SizedBox(height: 8),
              GlassPanel(
                radius: 16,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Enter this code in WhatsApp',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'WhatsApp → Linked devices → Link with phone number',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SelectableText(
                      bridge.pairingCode!,
                      style: TextStyle(
                        color: AppColors.accentBright,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: bridge.pairingCode!),
                        );
                        if (!context.mounted) return;
                        _toast('Code copied');
                      },
                      child: const Text('Copy code'),
                    ),
                    TextButton(
                      onPressed: () => bridge.refreshConnection(),
                      child: const Text('I entered the code — refresh status'),
                    ),
                  ],
                ),
              ),
            ],
            if (bridge.qrBase64 != null) ...[
              const SizedBox(height: 16),
              GlassPanel(
                radius: 16,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Or scan QR with WhatsApp',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'WhatsApp → Linked devices → Link a device',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        base64Decode(_normalizeB64(bridge.qrBase64!)),
                        width: 240,
                        height: 240,
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                        errorBuilder: (_, __, ___) => Text(
                          'Invalid QR data — tap Link again',
                          style: TextStyle(color: AppColors.warning),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _busy ? null : _link,
                      child: const Text('Refresh QR / code'),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            GlassPanel(
              radius: 16,
              padding: const EdgeInsets.all(14),
              child: Text(
                bridge.isLinked
                    ? 'Linked. Live sync every 2s (webhook → Nest → app).'
                    : 'Default API: Contabo. After Link, open WhatsApp → Linked devices and enter the code (or scan QR). Prefer a test number.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _normalizeB64(String raw) {
    var s = raw.trim();
    final i = s.indexOf('base64,');
    if (i >= 0) s = s.substring(i + 7);
    s = s.replaceAll(RegExp(r'\s'), '');
    final pad = s.length % 4;
    if (pad != 0) s = s.padRight(s.length + (4 - pad), '=');
    return s;
  }
}
