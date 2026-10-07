import '../l10n/ui_strings.dart';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({this.loadInfo, super.key});
  final Future<PackageInfo> Function()? loadInfo;
  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  late final Future<PackageInfo> _info = Future<PackageInfo>.sync(
    widget.loadInfo ?? PackageInfo.fromPlatform,
  );
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
            Text(context.l10n.workingName),
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
          ],
        ),
      ),
    ),
  );
}
