import 'package:flutter/services.dart';

abstract interface class TimerDisplayController {
  Future<void> activate();
  Future<void> restore();
}

final class PlatformTimerDisplayController implements TimerDisplayController {
  static const MethodChannel _screenAwakeChannel = MethodChannel(
    'calmturn/screen_awake',
  );

  const PlatformTimerDisplayController();

  @override
  Future<void> activate() async {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await _setKeepScreenOn(true);
  }

  @override
  Future<void> restore() async {
    await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    await _setKeepScreenOn(false);
  }

  Future<void> _setKeepScreenOn(bool enabled) async {
    try {
      await _screenAwakeChannel.invokeMethod<void>('setKeepScreenOn', {
        'enabled': enabled,
      });
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }
}
