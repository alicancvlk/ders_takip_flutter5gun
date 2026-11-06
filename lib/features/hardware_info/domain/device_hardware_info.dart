class DeviceHardwareInfo {
  const DeviceHardwareInfo({
    required this.manufacturer,
    required this.brand,
    required this.model,
    required this.device,
    required this.product,
    required this.androidVersion,
    required this.apiLevel,
    required this.securityPatch,
    required this.supportedAbis,
    required this.processorCores,
    required this.totalRamBytes,
    required this.availableRamBytes,
    required this.screenWidthPx,
    required this.screenHeightPx,
    required this.densityDpi,
    required this.density,
    required this.features,
  });

  final String manufacturer;
  final String brand;
  final String model;
  final String device;
  final String product;
  final String androidVersion;
  final int apiLevel;
  final String securityPatch;
  final List<String> supportedAbis;
  final int processorCores;
  final int totalRamBytes;
  final int availableRamBytes;
  final int screenWidthPx;
  final int screenHeightPx;
  final int densityDpi;
  final double density;
  final Map<String, bool> features;

  factory DeviceHardwareInfo.fromMap(Map<String, dynamic> map) {
    int readInt(String key) => (map[key] as num?)?.toInt() ?? 0;
    double readDouble(String key) => (map[key] as num?)?.toDouble() ?? 0;

    final features = <String, bool>{};
    final rawFeatures = map['features'];
    if (rawFeatures is Map) {
      for (final entry in rawFeatures.entries) {
        features[entry.key.toString()] = entry.value == true;
      }
    }

    return DeviceHardwareInfo(
      manufacturer: map['manufacturer']?.toString() ?? 'Bilinmiyor',
      brand: map['brand']?.toString() ?? 'Bilinmiyor',
      model: map['model']?.toString() ?? 'Bilinmiyor',
      device: map['device']?.toString() ?? 'Bilinmiyor',
      product: map['product']?.toString() ?? 'Bilinmiyor',
      androidVersion: map['androidVersion']?.toString() ?? 'Bilinmiyor',
      apiLevel: readInt('apiLevel'),
      securityPatch: map['securityPatch']?.toString() ?? 'Bilinmiyor',
      supportedAbis: (map['supportedAbis'] as List? ?? const [])
          .map((abi) => abi.toString())
          .toList(growable: false),
      processorCores: readInt('processorCores'),
      totalRamBytes: readInt('totalRamBytes'),
      availableRamBytes: readInt('availableRamBytes'),
      screenWidthPx: readInt('screenWidthPx'),
      screenHeightPx: readInt('screenHeightPx'),
      densityDpi: readInt('densityDpi'),
      density: readDouble('density'),
      features: Map.unmodifiable(features),
    );
  }

  String get totalRamLabel => _formatBytes(totalRamBytes);
  String get availableRamLabel => _formatBytes(availableRamBytes);

  String get screenResolutionLabel => '$screenWidthPx × $screenHeightPx px';

  static String _formatBytes(int bytes) {
    if (bytes <= 0) return 'Bilinmiyor';
    final gib = bytes / (1024 * 1024 * 1024);
    return '${gib.toStringAsFixed(1)} GB';
  }
}
