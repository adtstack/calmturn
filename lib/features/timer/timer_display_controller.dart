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
    ]);
    await _setSensorLandscape(true);
    await _setKeepScreenOn(true);
  }

  @override
  Future<void> restore() async {
    await _setSensorLandscape(false);
    await SystemChrome.setPreferredOrientations(const []);
    await _setKeepScreenOn(false);
  }

  Future<void> _setSensorLandscape(bool enabled) async {
    await _invokeTimerDisplayMethod('setSensorLandscape', enabled);
  }

  Future<void> _setKeepScreenOn(bool enabled) async {
    await _invokeTimerDisplayMethod('setKeepScreenOn', enabled);
  }

  Future<void> _invokeTimerDisplayMethod(String method, bool enabled) async {
    try {
      await _screenAwakeChannel.invokeMethod<void>(method, {
        'enabled': enabled,
      });
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }
}
