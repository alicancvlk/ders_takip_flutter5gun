import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/platform_hardware_info_repository.dart';
import '../domain/device_hardware_info.dart';

class HardwareInfoPage extends StatefulWidget {
  const HardwareInfoPage({super.key});

  @override
  State<HardwareInfoPage> createState() => _HardwareInfoPageState();
}

class _HardwareInfoPageState extends State<HardwareInfoPage> {
  final _repository = PlatformHardwareInfoRepository();
  late Future<DeviceHardwareInfo> _hardwareInfo;

  @override
  void initState() {
    super.initState();
    _hardwareInfo = _repository.getHardwareInfo();
  }

  void _refresh() {
    setState(() => _hardwareInfo = _repository.getHardwareInfo());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<DeviceHardwareInfo>(
          future: _hardwareInfo,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return _ErrorView(
                message: _errorMessage(snapshot.error),
                onRetry: _refresh,
              );
            }
            return _HardwareInfoContent(
              info: snapshot.requireData,
              onRefresh: _refresh,
              theme: theme,
            );
          },
        ),
      ),
    );
  }

  String _errorMessage(Object? error) {
    if (error is MissingPluginException) {
      return 'Donanım bilgileri bu Android uygulamasında kullanılabilir.';
    }
    if (error is PlatformException) {
      return error.message ?? 'Donanım bilgileri alınamadı.';
    }
    return 'Donanım bilgileri alınırken beklenmeyen bir hata oluştu.';
  }
}

class _HardwareInfoContent extends StatelessWidget {
  const _HardwareInfoContent({
    required this.info,
    required this.onRefresh,
    required this.theme,
  });

  final DeviceHardwareInfo info;
  final VoidCallback onRefresh;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
        sliver: SliverList.list(
          children: [
            _header(context),
            const SizedBox(height: 20),
            _infoCard(
              title: 'Cihaz',
              icon: Icons.phone_android_rounded,
              color: const Color(0xFF3157D5),
              rows: [
                _InfoRow('Üretici', info.manufacturer),
                _InfoRow('Marka', info.brand),
                _InfoRow('Model', info.model),
                _InfoRow('Cihaz kodu', info.device),
                _InfoRow('Ürün', info.product),
              ],
            ),
            const SizedBox(height: 14),
            _infoCard(
              title: 'Sistem',
              icon: Icons.android_rounded,
              color: const Color(0xFF087E5B),
              rows: [
                _InfoRow('Android sürümü', info.androidVersion),
                _InfoRow('API seviyesi', '${info.apiLevel}'),
                _InfoRow('Güvenlik yaması', info.securityPatch),
                _InfoRow('İşlemci çekirdeği', '${info.processorCores}'),
                _InfoRow('Mimariler', info.supportedAbis.join(', ')),
              ],
            ),
            const SizedBox(height: 14),
            _infoCard(
              title: 'Bellek ve ekran',
              icon: Icons.memory_rounded,
              color: const Color(0xFF8A4DC5),
              rows: [
                _InfoRow('Toplam RAM', info.totalRamLabel),
                _InfoRow('Kullanılabilir RAM', info.availableRamLabel),
                _InfoRow('Çözünürlük', info.screenResolutionLabel),
                _InfoRow('Yoğunluk', '${info.densityDpi} dpi'),
                _InfoRow('Ölçek', '${info.density.toStringAsFixed(2)}×'),
              ],
            ),
            const SizedBox(height: 14),
            _featureCard(),
            const SizedBox(height: 14),
            const _PrivacyNote(),
            const SizedBox(height: 18),
            Center(
              child: Text(
                'Flutter MethodChannel  ↔  Android Kotlin',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF7B8496),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _header(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFE8EEFF),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Text(
                'YENİ ÖZELLİK  •  ANDROID',
                style: TextStyle(
                  color: Color(0xFF344E9A),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              'Donanım bilgileri',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -.6),
            ),
            const SizedBox(height: 5),
            Text(
              'Cihazın özellikleri Kotlin’den alınıyor.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: const Color(0xFF737D90)),
            ),
          ],
        ),
      ),
      IconButton.filledTonal(
        tooltip: 'Yenile',
        onPressed: onRefresh,
        icon: const Icon(Icons.refresh_rounded),
      ),
    ],
  );

  Widget _infoCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<_InfoRow> rows,
  }) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SectionIcon(icon: icon, color: color),
              const SizedBox(width: 12),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (var index = 0; index < rows.length; index++) ...[
            if (index > 0) const Divider(height: 18),
            _InfoLine(row: rows[index]),
          ],
        ],
      ),
    ),
  );

  Widget _featureCard() {
    final entries = info.features.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _SectionIcon(
                  icon: Icons.sensors_rounded,
                  color: Color(0xFFBE5C24),
                ),
                const SizedBox(width: 12),
                Text(
                  'Donanım özellikleri',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in entries)
                  _FeatureChip(label: entry.key, available: entry.value),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.row});

  final _InfoRow row;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Text(
          row.label,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: const Color(0xFF7A8497)),
        ),
      ),
      const SizedBox(width: 14),
      Flexible(
        child: Text(
          row.value,
          textAlign: TextAlign.end,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );
}

class _SectionIcon extends StatelessWidget {
  const _SectionIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Icon(icon, color: color, size: 21),
  );
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.label, required this.available});

  final String label;
  final bool available;

  @override
  Widget build(BuildContext context) {
    final color = available ? const Color(0xFF087E5B) : const Color(0xFF7A8497);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: available ? const Color(0xFFE8F7F1) : const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            available ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 15,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFEFF6FF),
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Text(
      'Bu sayfa seri numarası, IMEI veya hesap bilgisi toplamaz. Donanım özellikleri yalnızca Android API’lerinden okunur.',
      style: TextStyle(color: Color(0xFF31557E), fontSize: 12, height: 1.45),
    ),
  );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.device_unknown_rounded, size: 46),
          const SizedBox(height: 14),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Yeniden dene'),
          ),
        ],
      ),
    ),
  );
}
