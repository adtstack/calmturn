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
