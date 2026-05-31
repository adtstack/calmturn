import 'dart:io';

import 'package:calmturn/features/settings/app_settings.dart';
import 'package:calmturn/features/settings/app_settings_storage_io.dart';
import 'package:calmturn/features/timer/domain/timer_models.dart';

Future<void> main() async {
  final tests = <String, Future<void> Function()>{
    'json app settings store saves and loads the last session config':
        () async {
          final store = JsonAppSettingsStore(
            storage: InMemoryAppSettingsStorage(),
          );
          final config = _config();

          await store.saveSessionConfig(config);

          final loaded = await store.loadSessionConfig();
          _expect(loaded != null, 'stored config should load');
          _expectEquals(loaded!.participantA.name, 'A');
          _expectEquals(loaded.participantB.name, 'B');
          _expectEquals(loaded.participantA.totalAllocatedSeconds, 180);
          _expectEquals(loaded.participantB.totalAllocatedSeconds, 420);
          _expectEquals(loaded.turnLimitSeconds, 45);
          _expectEquals(loaded.firstSpeakerId, 'b');
          _expectEquals(loaded.overtimeConfig.enabled, false);
          _expectEquals(loaded.overtimeConfig.showOvertime, false);
          _expectEquals(
            loaded.overtimeConfig.behavior,
            TurnLimitBehavior.autoPause,
          );
          _expectEquals(loaded.penaltyConfig.thresholdSeconds, 30);
          _expectEquals(
            loaded.penaltyConfig.repeatMode,
            PenaltyRepeatMode.everyThreshold,
          );
          _expectEquals(loaded.alertConfig.warningBeforeSeconds, 5);
          _expectEquals(loaded.alertConfig.soundEnabled, true);
        },
    'json app settings store clears saved session config': () async {
      final store = JsonAppSettingsStore(storage: InMemoryAppSettingsStorage());

      await store.saveSessionConfig(_config());
      await store.clear();

      final loaded = await store.loadSessionConfig();
      _expect(loaded == null, 'stored config should clear');
    },
    'json app settings store ignores corrupt settings': () async {
      final storage = InMemoryAppSettingsStorage();
      await storage.write('{not-json');
      final store = JsonAppSettingsStore(storage: storage);

      final loaded = await store.loadSessionConfig();

      _expect(loaded == null, 'corrupt settings should be ignored');
    },
    'json app settings store ignores storage read failures': () async {
      final store = JsonAppSettingsStore(
        storage: _FailingReadSettingsStorage(),
      );

      final loaded = await store.loadSessionConfig();

      _expect(loaded == null, 'read failures should fall back to setup');
    },
    'default io settings storage persists across recreated stores': () async {
      final directory = await Directory.systemTemp.createTemp(
        'calmturn_settings_test_',
      );
      final file = File('${directory.path}/settings/app_settings.json');
      setDefaultAppSettingsFileResolver(() async => file);

      try {
        final store = JsonAppSettingsStore.local();

        await store.saveSessionConfig(_config());

        final defaultFile = await defaultAppSettingsFile();
        _expect(
          defaultFile.isAbsolute,
          'default settings file must be absolute',
        );
        _expect(
          defaultFile.path.startsWith(directory.path),
          'default settings file should use the configured app directory',
        );

        final reloadedStore = JsonAppSettingsStore.local();
        final loaded = await reloadedStore.loadSessionConfig();
        _expect(
          loaded != null,
          'stored config should survive store recreation',
        );
        _expectEquals(loaded!.participantA.name, 'A');
        _expectEquals(loaded.participantB.name, 'B');
      } finally {
        setDefaultAppSettingsFileResolver(null);
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      }
    },
  };

  for (final entry in tests.entries) {
    try {
      await entry.value();
      print('PASS ${entry.key}');
    } catch (error, stackTrace) {
      print('FAIL ${entry.key}');
      print(error);
      print(stackTrace);
      throw StateError('app_settings_test failed');
    }
  }
}

final class _FailingReadSettingsStorage implements AppSettingsStorage {
  @override
  Future<String?> read() async {
    throw const FileSystemException('read failed');
  }

  @override
  Future<void> write(String value) async {}

  @override
  Future<void> clear() async {}
}

SessionConfig _config() {
  return const SessionConfig(
    participantA: ParticipantConfig(
      id: 'a',
      name: 'A',
      totalAllocatedSeconds: 180,
    ),
    participantB: ParticipantConfig(
      id: 'b',
      name: 'B',
      totalAllocatedSeconds: 420,
    ),
    turnLimitSeconds: 45,
    firstSpeakerId: 'b',
    overtimeConfig: OvertimeConfig(
      enabled: false,
      showOvertime: false,
      behavior: TurnLimitBehavior.autoPause,
    ),
    penaltyConfig: PenaltyConfig(
      thresholdSeconds: 30,
      repeatMode: PenaltyRepeatMode.everyThreshold,
      labelMode: PenaltyLabelMode.warningMark,
    ),
    alertConfig: AlertConfig(
      warningBeforeSeconds: 5,
      soundEnabled: true,
      hapticEnabled: false,
    ),
  );
}

void _expect(bool condition, String message) {
  if (!condition) {
    throw StateError(message);
  }
}

void _expectEquals(Object? actual, Object? expected) {
  if (actual != expected) {
    throw StateError('Expected <$expected>, got <$actual>.');
  }
}
