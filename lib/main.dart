import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'features/hardware_info/presentation/hardware_info_page.dart';
import 'features/payment_simulation/presentation/payment_simulation_page.dart';

void main() => runApp(const PlatformChannelApp());

class PlatformChannelApp extends StatelessWidget {
  const PlatformChannelApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF155EEF);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Platform Channel Lab',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: Color(0xFFE8ECF3)),
          ),
        ),
      ),
      home: const PlatformChannelHome(),
    );
  }
}

class PlatformChannelHome extends StatefulWidget {
  const PlatformChannelHome({super.key});

  @override
  State<PlatformChannelHome> createState() => _PlatformChannelHomeState();
}

class _PlatformChannelHomeState extends State<PlatformChannelHome> {
  int _selectedIndex = 0;

  static const _pages = [
    DeviceLabPage(),
    HardwareInfoPage(),
    PaymentSimulationPage(),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(index: _selectedIndex, children: _pages),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) => setState(() => _selectedIndex = index),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.bluetooth_rounded),
          label: 'Platform Channel',
        ),
        NavigationDestination(
          icon: Icon(Icons.memory_rounded),
          label: 'Donanım',
        ),
        NavigationDestination(
          icon: Icon(Icons.credit_card_rounded),
          label: 'Ödeme Demo',
        ),
      ],
    ),
  );
}

class DeviceLabPage extends StatefulWidget {
  const DeviceLabPage({super.key});

  @override
  State<DeviceLabPage> createState() => _DeviceLabPageState();
}

class _DeviceLabPageState extends State<DeviceLabPage> {
  static const _deviceChannel = MethodChannel(
    'com.example.platform_channel/device',
  );
  static const _bluetoothEvents = EventChannel(
    'com.example.platform_channel/bluetooth_state',
  );

  Stream<String>? _stateStream;
  Map<String, dynamic>? _deviceInfo;
  String? _queriedBluetoothState;
  String? _channelError;
  bool _loading = true;
  bool _permissionGranted = false;
  bool _imeiPermissionRequired = false;

  @override
  void initState() {
    super.initState();
    _stateStream = _bluetoothEvents.receiveBroadcastStream().map((event) {
      if (event is Map) return event['state']?.toString() ?? 'unknown';
      return event.toString();
    }).asBroadcastStream();
    unawaited(_loadDeviceInfo());
  }

  Future<void> _loadDeviceInfo() async {
    setState(() {
      _loading = true;
      _channelError = null;
    });
    try {
      final info = await _deviceChannel.invokeMapMethod<String, dynamic>(
        'getDeviceInfo',
      );
      final bluetoothState = await _deviceChannel.invokeMethod<String>(
        'getBluetoothState',
      );
      if (!mounted) return;
      setState(() {
        _deviceInfo = info;
        _queriedBluetoothState = bluetoothState;
        _imeiPermissionRequired = info?['imeiPermissionRequired'] == true;
        _loading = false;
      });
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() {
        _channelError = error.message ?? error.code;
        _loading = false;
      });
    } on MissingPluginException {
      if (!mounted) return;
      setState(() {
        _channelError = 'Bu örnek Android cihazda çalışır.';
        _loading = false;
      });
    }
  }

  Future<void> _requestBluetoothPermission() async {
    try {
      final granted =
          await _deviceChannel.invokeMethod<bool>(
            'requestBluetoothPermission',
          ) ??
          false;
      if (!mounted) return;
      setState(() => _permissionGranted = granted);
      if (granted) {
        await _loadDeviceInfo();
      } else {
        _showMessage('Yakındaki cihazlar izni verilmedi.');
      }
    } on PlatformException catch (error) {
      _showMessage(error.message ?? 'İzin istenirken bir hata oluştu.');
    }
  }

  Future<void> _openBluetoothSettings() async {
    try {
      await _deviceChannel.invokeMethod<void>('openBluetoothSettings');
    } on PlatformException catch (error) {
      _showMessage(error.message ?? 'Bluetooth ayarları açılamadı.');
    }
  }

  Future<void> _requestImeiPermission() async {
    try {
      final granted =
          await _deviceChannel.invokeMethod<bool>('requestImeiPermission') ??
          false;
      if (!mounted) return;
      if (granted) {
        await _loadDeviceInfo();
      } else {
        _showMessage('Telefon bilgisi izni verilmedi.');
      }
    } on PlatformException catch (error) {
      _showMessage(error.message ?? 'İzin istenirken bir hata oluştu.');
    }
  }

  Future<void> _copyValue(String value, String label) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (mounted) _showMessage('$label panoya kopyalandı.');
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
              sliver: SliverList.list(
                children: [
                  _buildHeader(theme),
                  const SizedBox(height: 22),
                  _buildBluetoothCard(theme),
                  const SizedBox(height: 16),
                  _buildDeviceCard(theme),
                  const SizedBox(height: 16),
                  _buildLearningCard(theme),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      'Flutter arayüzü  ↔  Android Kotlin',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: const Color(0xFF7B8496),
                        letterSpacing: .2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFE8EEFF),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Text(
            'FLUTTER LAB  •  ANDROID',
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
          'Cihaz köprüsü',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -.8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Platform channel ile Flutter ve Android\nbirbirine nasıl bağlanır?',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: const Color(0xFF737D90),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildBluetoothCard(ThemeData theme) {
    return StreamBuilder<String>(
      stream: _stateStream,
      builder: (context, snapshot) {
        final state = snapshot.data ?? _queriedBluetoothState ?? 'unknown';
        final enabled = state == 'on';
        final waiting = state == 'turning_on' || state == 'turning_off';
        final color = enabled
            ? const Color(0xFF087E5B)
            : const Color(0xFF667085);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _IconTile(
                      icon: Icons.bluetooth_rounded,
                      color: const Color(0xFF3157D5),
                      background: const Color(0xFFEBF0FF),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bluetooth',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _stateLabel(state),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (waiting)
                      const SizedBox.square(
                        dimension: 19,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Durum Android’den EventChannel ile canlı olarak dinlenir.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF7A8497),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                if (!_permissionGranted && state == 'permission_required')
                  FilledButton.icon(
                    onPressed: _requestBluetoothPermission,
                    icon: const Icon(Icons.lock_open_rounded),
                    label: const Text('Yakındaki cihazlar iznini ver'),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: _openBluetoothSettings,
                    icon: const Icon(Icons.settings_bluetooth_rounded),
                    label: const Text('Bluetooth ayarlarını aç'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeviceCard(ThemeData theme) {
    final androidId = _deviceInfo?['androidId']?.toString();
    final imei = _deviceInfo?['imei']?.toString();
    final imeiMessage =
        _deviceInfo?['imeiMessage']?.toString() ??
        _channelError ??
        'Bilgi alınıyor…';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _IconTile(
                  icon: Icons.phonelink_rounded,
                  color: const Color(0xFF8A4DC5),
                  background: const Color(0xFFF4ECFC),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    'Cihaz bilgileri',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Yenile',
                  onPressed: _loading ? null : _loadDeviceInfo,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _IdentifierRow(
              title: 'Android ID',
              subtitle: 'Bu uygulama imzası ve Android kullanıcısı kapsamında',
              value: androidId ?? (_loading ? 'Yükleniyor…' : 'Alınamadı'),
              icon: Icons.fingerprint_rounded,
              onCopy: androidId == null
                  ? null
                  : () => _copyValue(androidId, 'Android ID'),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1),
            ),
            _IdentifierRow(
              title: 'IMEI',
              subtitle: imei == null
                  ? imeiMessage
                  : 'Gizlilik için ekranda maskelenmiştir.',
              value: imei == null ? 'Erişim kısıtlı' : _maskImei(imei),
              icon: Icons.sim_card_rounded,
              onCopy: imei == null ? null : () => _copyValue(imei, 'IMEI'),
              warning: imei == null,
            ),
            if (_imeiPermissionRequired) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _requestImeiPermission,
                icon: const Icon(Icons.verified_user_outlined),
                label: const Text('Telefon bilgisi iznini ver'),
              ),
            ],
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7E8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Android 10 ve sonrasında IMEI normal uygulamalara kapalıdır. Emulator’da telefon modülü bulunmayabilir.',
                style: TextStyle(
                  color: Color(0xFF80601C),
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLearningCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bu örnekte',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            const _LessonLine(
              label: 'MethodChannel',
              detail: 'Dart → Kotlin: izin, ayar ekranı ve cihaz bilgisi',
              color: Color(0xFF3157D5),
            ),
            const SizedBox(height: 12),
            const _LessonLine(
              label: 'EventChannel',
              detail: 'Kotlin → Dart: Bluetooth durum yayın akışı',
              color: Color(0xFF087E5B),
            ),
          ],
        ),
      ),
    );
  }

  String _stateLabel(String state) => switch (state) {
    'on' => 'Açık',
    'off' => 'Kapalı',
    'turning_on' => 'Açılıyor',
    'turning_off' => 'Kapanıyor',
    'permission_required' => 'İzin gerekiyor',
    'unavailable' => 'Bluetooth desteklenmiyor',
    _ => 'Durum bekleniyor',
  };

  String _maskImei(String value) => value.length < 6
      ? value
      : '${value.substring(0, 3)}••••••${value.substring(value.length - 3)}';
}

class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.icon,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
    width: 46,
    height: 46,
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(15),
    ),
    child: Icon(icon, color: color),
  );
}

class _IdentifierRow extends StatelessWidget {
  const _IdentifierRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    this.onCopy,
    this.warning = false,
  });

  final String title;
  final String subtitle;
  final String value;
  final IconData icon;
  final VoidCallback? onCopy;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: warning ? const Color(0xFFB7791F) : const Color(0xFF667085),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF818A9B),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (onCopy != null)
          IconButton(
            onPressed: onCopy,
            tooltip: '$title kopyala',
            icon: const Icon(Icons.copy_rounded, size: 18),
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }
}

class _LessonLine extends StatelessWidget {
  const _LessonLine({
    required this.label,
    required this.detail,
    required this.color,
  });

  final String label;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        margin: const EdgeInsets.only(top: 4),
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              detail,
              style: const TextStyle(
                color: Color(0xFF7A8497),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
