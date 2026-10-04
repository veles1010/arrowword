import 'package:flutter/material.dart';

import 'app_settings.dart';
import 'about_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({required this.settings, super.key});
  final AppSettings settings;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ayarlar')),
    body: SafeArea(
      child: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Görünüm', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            DropdownButtonFormField<ThemeMode>(
              key: ValueKey(settings.themeMode),
              initialValue: settings.themeMode,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Tema',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text('Sistem'),
                ),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Açık')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Koyu')),
              ],
              onChanged: (mode) {
                if (mode != null) settings.setTheme(mode);
              },
            ),
            const SizedBox(height: 24),
            Text('Hakkında', style: Theme.of(context).textTheme.titleLarge),
            ListTile(
              minVerticalPadding: 16,
              leading: const Icon(Icons.info_outline),
              title: const Text('Uygulama bilgileri'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute(builder: (_) => const AboutScreen()),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
