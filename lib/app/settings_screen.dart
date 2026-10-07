import '../l10n/ui_strings.dart';

import 'package:flutter/material.dart';

import 'app_settings.dart';
import 'about_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({required this.settings, super.key});
  final AppSettings settings;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.settings)),
    body: SafeArea(
      child: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              context.l10n.appearance,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ThemeMode>(
              key: ValueKey(settings.themeMode),
              initialValue: settings.themeMode,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: context.l10n.theme,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text(context.l10n.system),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text(context.l10n.light),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text(context.l10n.dark),
                ),
              ],
              onChanged: (mode) {
                if (mode != null) settings.setTheme(mode);
              },
            ),
            const SizedBox(height: 24),
            Text(
              context.l10n.about,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            ListTile(
              minVerticalPadding: 16,
              leading: const Icon(Icons.info_outline),
              title: Text(context.l10n.appInformation),
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
