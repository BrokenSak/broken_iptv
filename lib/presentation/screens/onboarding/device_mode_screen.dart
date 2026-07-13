import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/services/device_mode_service.dart';
import '../../common/glass_surface.dart';
import '../../common/tv_focusable.dart';

class DeviceModeScreen extends StatefulWidget {
  const DeviceModeScreen({super.key});

  @override
  State<DeviceModeScreen> createState() => _DeviceModeScreenState();
}

class _DeviceModeScreenState extends State<DeviceModeScreen> {
  final _service = DeviceModeService();
  DeviceMode? _suggested;

  @override
  void initState() {
    super.initState();
    _service.detectIsTv().then((isTv) {
      if (mounted) setState(() => _suggested = isTv ? DeviceMode.tv : DeviceMode.touch);
    });
  }

  Future<void> _choose(DeviceMode mode) async {
    await _service.save(mode);
    if (!mounted) return;
    context.go('/profiles');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.live_tv, size: 56, color: AppColors.accent),
                const SizedBox(height: 16),
                Text('Come stai guardando?', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'Adattiamo la navigazione al tuo dispositivo. Puoi cambiarla in qualsiasi momento dalle Impostazioni.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 40),
                Row(
                  children: [
                    Expanded(
                      child: _ModeCard(
                        icon: Icons.tv,
                        title: 'TV / Telecomando',
                        subtitle: 'Firestick, Android TV e simili',
                        suggested: _suggested == DeviceMode.tv,
                        autofocus: true,
                        onTap: () => _choose(DeviceMode.tv),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _ModeCard(
                        icon: Icons.smartphone,
                        title: 'Telefono / Tablet',
                        subtitle: 'Tocco e schermo touch',
                        suggested: _suggested == DeviceMode.touch,
                        onTap: () => _choose(DeviceMode.touch),
                      ),
                    ),
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

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.suggested = false,
    this.autofocus = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool suggested;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TvFocusable(
      autofocus: autofocus,
      onTap: onTap,
      child: GlassSurface(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: Column(
            children: [
              Icon(icon, size: 40, color: AppColors.accent),
              const SizedBox(height: 16),
              Text(title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
              if (suggested) ...[
                const SizedBox(height: 12),
                const Chip(
                  label: Text('Consigliato', style: TextStyle(color: Colors.black)),
                  backgroundColor: Colors.white,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
