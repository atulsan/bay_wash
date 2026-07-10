import 'package:flutter/services.dart';

enum BayWashAppIcon { light, dark }

class AppIconService {
  static const _channel = MethodChannel('bay_wash/app_icon');

  const AppIconService();

  Future<bool> setIcon(BayWashAppIcon icon) async {
    final result = await _channel.invokeMethod<bool>(
      'setIcon',
      {'icon': icon.name},
    );
    return result ?? false;
  }
}
