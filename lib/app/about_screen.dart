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
    appBar: AppBar(title: const Text('Hakkında')),
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
            const Text(
              'Türkçe ipuçlarıyla İngilizce kelimeleri keşfedin. Normal bulmacalar, tekrar oynama ve günün bulmacası.',
            ),
            const SizedBox(height: 12),
            const Text(
              'Arrowword çalışma adıdır; nihai ürün adı henüz belirlenmedi.',
            ),
            const SizedBox(height: 24),
            FutureBuilder<PackageInfo>(
              future: _info,
              builder: (context, snapshot) {
                final info = snapshot.data;
                return Text(
                  info != null
                      ? 'Sürüm ${info.version} · Yapı ${info.buildNumber}'
                      : snapshot.hasError
                      ? 'Sürüm bilgisi alınamadı.'
                      : 'Sürüm bilgisi yükleniyor…',
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}
