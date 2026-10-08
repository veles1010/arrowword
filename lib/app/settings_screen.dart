import '../l10n/ui_strings.dart';
import '../l10n/app_language.dart';
import '../l10n/language_policy.dart';

import 'package:flutter/material.dart';

import 'app_settings.dart';
import 'about_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({required this.settings, this.language, super.key});
  final AppSettings settings;
  final AppLanguage? language;
  @override
  Widget build(BuildContext context) {
    final controller = language ?? AppLanguageScope.maybeOf(context);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settings)),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([settings, ?controller]),
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
              if (controller != null &&
                  LanguagePolicy.production.enabled.length > 1) ...[
                const SizedBox(height: 24),
                DropdownButtonFormField<AppLanguagePreference>(
                  key: ValueKey('language-${controller.preference.id}'),
                  initialValue:
                      controller.preference == AppLanguagePreference.system ||
                          LanguagePolicy.production.enabled.contains(
                            controller.preference.id,
                          )
                      ? controller.preference
                      : AppLanguagePreference.system,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: context.l10n.language,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: AppLanguagePreference.system,
                      child: Text(context.l10n.systemDefault),
                    ),
                    for (final preference in AppLanguagePreference.values)
                      if (preference != AppLanguagePreference.system &&
                          LanguagePolicy.production.enabled.contains(
                            preference.id,
                          ))
                        DropdownMenuItem(
                          value: preference,
                          child: Text(preference.autonym),
                        ),
                  ],
                  onChanged: (value) {
                    if (value != null) controller.setPreference(value);
                  },
                ),
              ],
              const SizedBox(height: 24),
              Text(
                context.l10n.audio,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SwitchListTile(
                key: const ValueKey('music-enabled'),
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.music),
                value: settings.musicEnabled,
                onChanged: settings.setMusicEnabled,
              ),
              SwitchListTile(
                key: const ValueKey('sfx-enabled'),
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.soundEffects),
                value: settings.sfxEnabled,
                onChanged: settings.setSfxEnabled,
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
}
