import '../l10n/ui_strings.dart';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({this.loadInfo, this.openLink, super.key});
  final Future<PackageInfo> Function()? loadInfo;
  final Future<bool> Function(Uri)? openLink;
  static final privacyPolicyUrl = Uri.https(
    'veles1010.github.io',
    '/arrowword/privacy-policy.html',
  );
  static final supportUrl = Uri.https(
    'veles1010.github.io',
    '/arrowword/support.html',
  );
  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  late final Future<PackageInfo> _info = Future<PackageInfo>.sync(
    widget.loadInfo ?? PackageInfo.fromPlatform,
  );
  Future<void> _openLink(Uri url) async {
    var opened = false;
    try {
      opened =
          await (widget.openLink?.call(url) ??
              launchUrl(url, mode: LaunchMode.externalApplication));
    } catch (_) {
      // Browser/platform failures must not interrupt the About screen.
    }
    if (!opened && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.unableToOpenLink)));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.about)),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Arrowword',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text(context.l10n.appDescription),
            const SizedBox(height: 12),
            Text(context.l10n.answersAlwaysEnglish),
            const SizedBox(height: 24),
            FutureBuilder<PackageInfo>(
              future: _info,
              builder: (context, snapshot) {
                final info = snapshot.data;
                return Text(
                  info != null
                      ? context.l10n.versionBuild(
                          info.version,
                          info.buildNumber,
                        )
                      : snapshot.hasError
                      ? context.l10n.versionFailed
                      : context.l10n.versionLoading,
                );
              },
            ),
            const SizedBox(height: 24),
            ListTile(
              key: const ValueKey('about-privacy-policy'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.privacy_tip_outlined),
              title: Text(context.l10n.privacyPolicy),
              trailing: const Icon(Icons.open_in_new, size: 20),
              onTap: () => _openLink(AboutScreen.privacyPolicyUrl),
            ),
            ListTile(
              key: const ValueKey('about-support'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.help_outline),
              title: Text(context.l10n.support),
              trailing: const Icon(Icons.open_in_new, size: 20),
              onTap: () => _openLink(AboutScreen.supportUrl),
            ),
          ],
        ),
      ),
    ),
  );
}
