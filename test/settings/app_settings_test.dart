import 'dart:convert';
import 'dart:io';

import 'package:calmturn/features/settings/app_settings.dart';
import 'package:calmturn/features/settings/app_settings_storage_io.dart';
import 'package:calmturn/features/settings/session_settings.dart';
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
          _expectEquals(loaded.turnLimitSeconds, 60);
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
    'json app settings store saves and loads the full app settings': () async {
      final store = JsonAppSettingsStore(storage: InMemoryAppSettingsStorage());
      final settings = AppSettingsDraft(
        sessionDefaults: SessionSettingsDraft.fromSessionConfig(_config()),
        autoSaveRecords: true,
      );

      await store.saveSettings(settings);

      final loaded = await store.loadSettings();
      _expectEquals(loaded.autoSaveRecords, true);
      _expectEquals(loaded.sessionDefaults.participantAName, 'A');
      _expectEquals(loaded.sessionDefaults.participantBName, 'B');
      _expectEquals(loaded.sessionDefaults.turnLimitSeconds, 60);
    },
    'json app settings store ignores corrupt settings': () async {
      final storage = InMemoryAppSettingsStorage();
      await storage.write('{not-json');
      final store = JsonAppSettingsStore(storage: storage);

      final loaded = await store.loadSessionConfig();

      _expect(loaded == null, 'corrupt settings should be ignored');
    },
    'json app settings store ignores semantically impossible settings':
        () async {
          final storage = InMemoryAppSettingsStorage();
          await storage.write(
            _settingsJson(
              turnLimitSeconds: 300,
              participantATotalSeconds: 180,
              participantBTotalSeconds: 180,
            ),
          );
          final store = JsonAppSettingsStore(storage: storage);

          final loaded = await store.loadSessionConfig();

          _expect(
            loaded == null,
            'impossible stored settings should be ignored',
          );
        },
    'json app settings store ignores settings with invalid identities':
        () async {
          final storage = InMemoryAppSettingsStorage();
          await storage.write(_settingsJson(firstSpeakerId: 'missing'));
          final store = JsonAppSettingsStore(storage: storage);

          final loaded = await store.loadSessionConfig();

          _expect(loaded == null, 'invalid speaker settings should be ignored');
        },
    'json app settings store ignores settings with no alert delivery':
        () async {
          final storage = InMemoryAppSettingsStorage();
          await storage.write(
            _settingsJson(
              visualEnabled: false,
              soundEnabled: false,
              hapticEnabled: false,
            ),
          );
          final store = JsonAppSettingsStore(storage: storage);

          final loaded = await store.loadSessionConfig();

          _expect(loaded == null, 'silent alert settings should be ignored');
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
    turnLimitSeconds: 60,
    firstSpeakerId: 'b',
    overtimeConfig: OvertimeConfig(
      enabled: false,
      showOvertime: false,
      behavior: TurnLimitBehavior.autoPause,
    ),
    penaltyConfig: PenaltyConfig(
      enabled: false,
      thresholdSeconds: 30,
      repeatMode: PenaltyRepeatMode.everyThreshold,
      labelMode: PenaltyLabelMode.warningMark,
    ),
    alertConfig: AlertConfig(
      warningBeforeSeconds: 5,
      overtimeStartAlertEnabled: false,
      penaltyAlertEnabled: false,
      soundEnabled: true,
      hapticEnabled: false,
    ),
  );
}

String _settingsJson({
  int participantATotalSeconds = 300,
  int participantBTotalSeconds = 300,
  int turnLimitSeconds = 60,
  String firstSpeakerId = 'a',
  bool overtimeEnabled = true,
  bool showOvertime = true,
  TurnLimitBehavior behavior = TurnLimitBehavior.overtime,
  bool penaltyEnabled = true,
  int penaltyThresholdSeconds = 60,
  int warningBeforeSeconds = 10,
  bool turnWarningEnabled = true,
  bool totalWarningEnabled = true,
  bool overtimeStartAlertEnabled = true,
  bool penaltyAlertEnabled = true,
  bool visualEnabled = true,
  bool soundEnabled = false,
  bool hapticEnabled = true,
}) {
  return jsonEncode({
    'version': 1,
    'sessionConfig': {
      'participantA': {
        'id': 'a',
        'name': 'A',
        'totalAllocatedSeconds': participantATotalSeconds,
      },
      'participantB': {
        'id': 'b',
        'name': 'B',
        'totalAllocatedSeconds': participantBTotalSeconds,
      },
      'turnLimitSeconds': turnLimitSeconds,
      'firstSpeakerId': firstSpeakerId,
      'overtimeConfig': {
        'enabled': overtimeEnabled,
        'showOvertime': showOvertime,
        'behavior': behavior.name,
      },
      'penaltyConfig': {
        'enabled': penaltyEnabled,
        'thresholdSeconds': penaltyThresholdSeconds,
        'repeatMode': PenaltyRepeatMode.oncePerTurn.name,
        'labelMode': PenaltyLabelMode.overtimeMark.name,
      },
      'alertConfig': {
        'warningBeforeSeconds': warningBeforeSeconds,
        'turnWarningEnabled': turnWarningEnabled,
        'totalWarningEnabled': totalWarningEnabled,
        'overtimeStartAlertEnabled': overtimeStartAlertEnabled,
        'penaltyAlertEnabled': penaltyAlertEnabled,
        'visualEnabled': visualEnabled,
        'soundEnabled': soundEnabled,
        'hapticEnabled': hapticEnabled,
        'soundType': 'soft',
        'hapticStrength': 'medium',
      },
      'requireBothConsentForExtension': true,
    },
  });
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
