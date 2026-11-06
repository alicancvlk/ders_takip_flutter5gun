import 'package:flutter/services.dart';

import '../domain/device_hardware_info.dart';

class PlatformHardwareInfoRepository {
  static const _channel = MethodChannel(
    'com.example.platform_channel/hardware_info',
  );

  Future<DeviceHardwareInfo> getHardwareInfo() async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'getHardwareInfo',
    );
    if (result == null) {
      throw PlatformException(
        code: 'empty_hardware_info',
        message: 'Android cihaz bilgisi döndürmedi.',
      );
    }
    return DeviceHardwareInfo.fromMap(result);
  }
}
