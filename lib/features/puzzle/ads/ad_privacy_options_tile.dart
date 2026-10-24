import 'package:flutter/material.dart';

import '../../../l10n/ui_strings.dart';
import 'ads_privacy.dart';

class AdPrivacyOptionsTile extends StatelessWidget {
  const AdPrivacyOptionsTile({this.controller, super.key});
  final AdsPrivacyController? controller;

  @override
  Widget build(BuildContext context) {
    final privacy = controller ?? hintAdsPrivacy;
    return ListenableBuilder(
      listenable: privacy,
      builder: (context, _) {
        if (!privacy.privacyOptionsRequired) return const SizedBox.shrink();
        return ListTile(
          key: const ValueKey('ad-privacy-options'),
          leading: const Icon(Icons.tune_rounded),
          title: Text(context.l10n.adPrivacyOptions),
          onTap: privacy.isBusy
              ? null
              : () async {
                  try {
                    await privacy.showPrivacyOptions();
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(context.l10n.adUnavailable)),
                      );
                    }
                  }
                },
        );
      },
    );
  }
}
