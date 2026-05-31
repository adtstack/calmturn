import 'dart:io';

import 'package:flutter/services.dart';

import 'app_settings_storage_io.dart';

const _channel = MethodChannel('calmturn/app_settings');

void configurePlatformAppSettingsStorage() {
  if (!Platform.isAndroid) {
    return;
  }

  setDefaultAppSettingsFileResolver(() async {
    final directoryPath = await _channel.invokeMethod<String>('getFilesDir');
    if (directoryPath == null || directoryPath.isEmpty) {
      throw StateError('Android files directory was not provided.');
    }
    return appSettingsFileInDirectory(Directory(directoryPath));
  });
}
