import 'dart:io';

import 'app_settings.dart';

const _settingsFileName = 'calmturn_app_settings.json';

typedef AppSettingsFileResolver = Future<File> Function();

AppSettingsFileResolver? _defaultAppSettingsFileResolver;

AppSettingsStorage createDefaultAppSettingsStorage() {
  return FileAppSettingsStorage.fromResolver(defaultAppSettingsFile);
}

void setDefaultAppSettingsFileResolver(AppSettingsFileResolver? resolver) {
  _defaultAppSettingsFileResolver = resolver;
}

Future<File> defaultAppSettingsFile() async {
  final resolver = _defaultAppSettingsFileResolver;
  if (resolver != null) {
    final file = await resolver();
    _validateAbsolute(file);
    return file;
  }

  return appSettingsFileInDirectory(_defaultAppSettingsDirectory());
}

File appSettingsFileInDirectory(Directory directory) {
  final file = File(_joinPath(directory.path, _settingsFileName));
  _validateAbsolute(file);
  return file;
}

final class FileAppSettingsStorage implements AppSettingsStorage {
  final AppSettingsFileResolver _resolveFile;

  FileAppSettingsStorage(File file) : _resolveFile = (() async => file);

  const FileAppSettingsStorage.fromResolver(this._resolveFile);

  @override
  Future<String?> read() async {
    final file = await _file();
    if (!await file.exists()) {
      return null;
    }
    return file.readAsString();
  }

  @override
  Future<void> write(String value) async {
    final file = await _file();
    await file.parent.create(recursive: true);
    await file.writeAsString(value, flush: true);
  }

  @override
  Future<void> clear() async {
    final file = await _file();
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<File> _file() async {
    final file = await _resolveFile();
    _validateAbsolute(file);
    return file;
  }
}

Directory _defaultAppSettingsDirectory() {
  if (Platform.isAndroid) {
    throw StateError(
      'Android settings storage requires an app files directory resolver.',
    );
  }

  final environment = Platform.environment;
  if (Platform.isIOS) {
    final home = environment['HOME'];
    if (home != null && home.isNotEmpty) {
      return Directory(_joinPath(home, 'Documents'));
    }
  }

  if (Platform.isMacOS) {
    final home = environment['HOME'];
    if (home != null && home.isNotEmpty) {
      return Directory(
        _joinPath(
          _joinPath(_joinPath(home, 'Library'), 'Application Support'),
          'CalmTurn',
        ),
      );
    }
  }

  if (Platform.isWindows) {
    final appData = environment['APPDATA'];
    if (appData != null && appData.isNotEmpty) {
      return Directory(_joinPath(appData, 'CalmTurn'));
    }
  }

  final xdgConfigHome = environment['XDG_CONFIG_HOME'];
  if (xdgConfigHome != null && xdgConfigHome.isNotEmpty) {
    return Directory(_joinPath(xdgConfigHome, 'calmturn'));
  }

  final home = environment['HOME'] ?? environment['USERPROFILE'];
  if (home != null && home.isNotEmpty) {
    return Directory(_joinPath(_joinPath(home, '.config'), 'calmturn'));
  }

  return Directory(_joinPath(Directory.current.absolute.path, '.calmturn'));
}

String _joinPath(String parent, String child) {
  if (parent.endsWith(Platform.pathSeparator)) {
    return '$parent$child';
  }
  return '$parent${Platform.pathSeparator}$child';
}

void _validateAbsolute(File file) {
  if (!file.isAbsolute) {
    throw StateError('App settings file must use an absolute path.');
  }
}
