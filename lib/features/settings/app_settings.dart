import 'dart:convert';

import '../timer/domain/timer_models.dart';
import 'app_settings_storage_stub.dart'
    if (dart.library.io) 'app_settings_storage_io.dart'
    if (dart.library.js_interop) 'app_settings_storage_web.dart'
    as platform;
import 'session_settings.dart';

final class AppSettingsDraft {
  final SessionSettingsDraft sessionDefaults;
  final bool autoSaveRecords;

  const AppSettingsDraft({
    required this.sessionDefaults,
    required this.autoSaveRecords,
  });

  factory AppSettingsDraft.defaults() {
    return AppSettingsDraft(
      sessionDefaults: SessionSettingsDraft.defaults(),
      autoSaveRecords: false,
    );
  }

  AppSettingsDraft copyWith({
    SessionSettingsDraft? sessionDefaults,
    bool? autoSaveRecords,
  }) {
    return AppSettingsDraft(
      sessionDefaults: sessionDefaults ?? this.sessionDefaults,
      autoSaveRecords: autoSaveRecords ?? this.autoSaveRecords,
    );
  }
}

abstract interface class AppSettingsStorage {
  Future<String?> read();

  Future<void> write(String value);

  Future<void> clear();
}

abstract interface class AppSettingsStore {
  Future<SessionConfig?> loadSessionConfig();

  Future<void> saveSessionConfig(SessionConfig config);

  Future<void> clear();
}

final class JsonAppSettingsStore implements AppSettingsStore {
  final AppSettingsStorage storage;

  const JsonAppSettingsStore({required this.storage});

  factory JsonAppSettingsStore.local() {
    return JsonAppSettingsStore(
      storage: platform.createDefaultAppSettingsStorage(),
    );
  }

  @override
  Future<SessionConfig?> loadSessionConfig() async {
    try {
      final contents = await storage.read();
      if (contents == null || contents.trim().isEmpty) {
        return null;
      }

      final decoded = jsonDecode(contents) as Map<String, Object?>;
      if (decoded['version'] != 1) {
        return null;
      }

      final sessionConfig = decoded['sessionConfig'];
      if (sessionConfig is! Map<String, Object?>) {
        return null;
      }
      final config = _sessionConfigFromJson(sessionConfig);
      if (validateSessionConfig(config) != null) {
        return null;
      }
      return config;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveSessionConfig(SessionConfig config) async {
    final encoded = const JsonEncoder.withIndent(
      '  ',
    ).convert({'version': 1, 'sessionConfig': _sessionConfigToJson(config)});
    await storage.write(encoded);
  }

  @override
  Future<void> clear() async {
    await storage.clear();
  }
}

final class InMemoryAppSettingsStorage implements AppSettingsStorage {
  String? _value;

  @override
  Future<String?> read() async {
    return _value;
  }

  @override
  Future<void> write(String value) async {
    _value = value;
  }

  @override
  Future<void> clear() async {
    _value = null;
  }
}

Map<String, Object?> _sessionConfigToJson(SessionConfig config) {
  return {
    'participantA': _participantConfigToJson(config.participantA),
    'participantB': _participantConfigToJson(config.participantB),
    'turnLimitSeconds': config.turnLimitSeconds,
    'firstSpeakerId': config.firstSpeakerId,
    'overtimeConfig': {
      'enabled': config.overtimeConfig.enabled,
      'showOvertime': config.overtimeConfig.showOvertime,
      'behavior': config.overtimeConfig.behavior.name,
    },
    'penaltyConfig': {
      'enabled': config.penaltyConfig.enabled,
      'thresholdSeconds': config.penaltyConfig.thresholdSeconds,
      'repeatMode': config.penaltyConfig.repeatMode.name,
      'labelMode': config.penaltyConfig.labelMode.name,
    },
    'alertConfig': {
      'warningBeforeSeconds': config.alertConfig.warningBeforeSeconds,
      'turnWarningEnabled': config.alertConfig.turnWarningEnabled,
      'totalWarningEnabled': config.alertConfig.totalWarningEnabled,
      'overtimeStartAlertEnabled': config.alertConfig.overtimeStartAlertEnabled,
      'penaltyAlertEnabled': config.alertConfig.penaltyAlertEnabled,
      'visualEnabled': config.alertConfig.visualEnabled,
      'soundEnabled': config.alertConfig.soundEnabled,
      'hapticEnabled': config.alertConfig.hapticEnabled,
      'soundType': config.alertConfig.soundType,
      'hapticStrength': config.alertConfig.hapticStrength,
    },
    'requireBothConsentForExtension': config.requireBothConsentForExtension,
  };
}

SessionConfig _sessionConfigFromJson(Map<String, Object?> json) {
  final overtimeJson = json['overtimeConfig'] as Map<String, Object?>;
  final penaltyJson = json['penaltyConfig'] as Map<String, Object?>;
  final alertJson = json['alertConfig'] as Map<String, Object?>;

  return SessionConfig(
    participantA: _participantConfigFromJson(
      json['participantA'] as Map<String, Object?>,
    ),
    participantB: _participantConfigFromJson(
      json['participantB'] as Map<String, Object?>,
    ),
    turnLimitSeconds: json['turnLimitSeconds'] as int,
    firstSpeakerId: json['firstSpeakerId'] as String,
    overtimeConfig: OvertimeConfig(
      enabled: overtimeJson['enabled'] as bool,
      showOvertime: overtimeJson['showOvertime'] as bool,
      behavior: TurnLimitBehavior.values.byName(
        overtimeJson['behavior'] as String,
      ),
    ),
    penaltyConfig: PenaltyConfig(
      enabled: penaltyJson['enabled'] as bool,
      thresholdSeconds: penaltyJson['thresholdSeconds'] as int,
      repeatMode: PenaltyRepeatMode.values.byName(
        penaltyJson['repeatMode'] as String,
      ),
      labelMode: PenaltyLabelMode.values.byName(
        penaltyJson['labelMode'] as String,
      ),
    ),
    alertConfig: AlertConfig(
      warningBeforeSeconds: alertJson['warningBeforeSeconds'] as int,
      turnWarningEnabled: alertJson['turnWarningEnabled'] as bool,
      totalWarningEnabled: alertJson['totalWarningEnabled'] as bool,
      overtimeStartAlertEnabled: alertJson['overtimeStartAlertEnabled'] as bool,
      penaltyAlertEnabled: alertJson['penaltyAlertEnabled'] as bool,
      visualEnabled: alertJson['visualEnabled'] as bool,
      soundEnabled: alertJson['soundEnabled'] as bool,
      hapticEnabled: alertJson['hapticEnabled'] as bool,
      soundType: alertJson['soundType'] as String,
      hapticStrength: alertJson['hapticStrength'] as String,
    ),
    requireBothConsentForExtension:
        json['requireBothConsentForExtension'] as bool? ?? true,
  );
}

Map<String, Object?> _participantConfigToJson(ParticipantConfig config) {
  return {
    'id': config.id,
    'name': config.name,
    'totalAllocatedSeconds': config.totalAllocatedSeconds,
  };
}

ParticipantConfig _participantConfigFromJson(Map<String, Object?> json) {
  return ParticipantConfig(
    id: json['id'] as String,
    name: json['name'] as String,
    totalAllocatedSeconds: json['totalAllocatedSeconds'] as int,
  );
}
