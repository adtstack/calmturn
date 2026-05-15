import 'package:calmturn/features/settings/session_settings.dart';
import 'package:calmturn/features/timer/domain/timer_models.dart';

void main() {
  final tests = <String, void Function()>{
    'default draft builds the MVP session config': () {
      final config = SessionSettingsDraft.defaults().toSessionConfig();

      _expectEquals(config.participantA.name, 'Speaker A');
      _expectEquals(config.participantB.name, 'Speaker B');
      _expectEquals(config.participantA.totalAllocatedSeconds, 300);
      _expectEquals(config.participantB.totalAllocatedSeconds, 300);
      _expectEquals(config.turnLimitSeconds, 60);
      _expectEquals(config.firstSpeakerId, 'a');
      _expectEquals(config.penaltyConfig.thresholdSeconds, 60);
      _expectEquals(config.alertConfig.warningBeforeSeconds, 10);
      _expectEquals(config.alertConfig.visualEnabled, true);
      _expectEquals(config.alertConfig.soundEnabled, false);
      _expectEquals(config.alertConfig.hapticEnabled, true);
    },
    'custom per participant totals can build an A 3 minute B 7 minute config':
        () {
          final config = SessionSettingsDraft.defaults()
              .copyWith(
                participantAName: 'A',
                participantBName: 'B',
                totalTimeMode: TotalTimeMode.customPerParticipant,
                participantATotalSeconds: 180,
                participantBTotalSeconds: 420,
                penaltyThresholdSeconds: 30,
                soundEnabled: true,
              )
              .toSessionConfig();

          _expectEquals(config.participantA.name, 'A');
          _expectEquals(config.participantB.name, 'B');
          _expectEquals(config.participantA.totalAllocatedSeconds, 180);
          _expectEquals(config.participantB.totalAllocatedSeconds, 420);
          _expectEquals(config.penaltyConfig.thresholdSeconds, 30);
          _expectEquals(config.alertConfig.visualEnabled, true);
          _expectEquals(config.alertConfig.soundEnabled, true);
          _expectEquals(config.alertConfig.hapticEnabled, true);
        },
    'disabling overtime turns the turn limit behavior into auto pause': () {
      final config = SessionSettingsDraft.defaults()
          .copyWith(overtimeEnabled: false)
          .toSessionConfig();

      _expectEquals(config.overtimeConfig.enabled, false);
      _expectEquals(config.overtimeConfig.showOvertime, false);
      _expectEquals(
        config.overtimeConfig.behavior,
        TurnLimitBehavior.autoPause,
      );
    },
  };

  var failures = 0;
  for (final entry in tests.entries) {
    try {
      entry.value();
      print('PASS ${entry.key}');
    } catch (error, stackTrace) {
      failures += 1;
      print('FAIL ${entry.key}');
      print(error);
      print(stackTrace);
    }
  }

  if (failures > 0) {
    throw StateError('$failures session settings tests failed.');
  }
}

void _expectEquals(Object? actual, Object? expected) {
  if (actual != expected) {
    throw StateError('Expected <$expected>, got <$actual>.');
  }
}
