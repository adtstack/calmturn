import 'package:calmturn/features/settings/session_settings.dart';
import 'package:calmturn/features/timer/domain/timer_models.dart';

void main() {
  final tests = <String, void Function()>{
    'default draft builds the v4 session config': () {
      final config = SessionSettingsDraft.defaults().toSessionConfig();

      _expectEquals(config.participantA.name, '남편');
      _expectEquals(config.participantB.name, '와이프');
      _expectEquals(config.participantA.totalAllocatedSeconds, 600);
      _expectEquals(config.participantB.totalAllocatedSeconds, 600);
      _expectEquals(config.turnLimitSeconds, 180);
      _expectEquals(config.firstSpeakerId, 'a');
      _expectEquals(config.penaltyConfig.thresholdSeconds, 60);
      _expectEquals(config.alertConfig.warningBeforeSeconds, 10);
      _expectEquals(config.alertConfig.visualEnabled, true);
      _expectEquals(config.alertConfig.turnDangerFlashEnabled, true);
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
          _expectEquals(config.alertConfig.turnDangerFlashEnabled, true);
          _expectEquals(config.alertConfig.soundEnabled, true);
          _expectEquals(config.alertConfig.hapticEnabled, true);
        },
    'session config round-trips the independent turn danger flash setting': () {
      final config = SessionSettingsDraft.fromSessionConfig(
        SessionSettingsDraft.defaults()
            .copyWith(turnDangerFlashEnabled: false)
            .toSessionConfig(),
      ).toSessionConfig();

      _expectEquals(config.alertConfig.visualEnabled, true);
      _expectEquals(config.alertConfig.turnDangerFlashEnabled, false);
    },
    'turn danger flash counts as its own alert delivery': () {
      final message = validateSessionSettingsDraft(
        SessionSettingsDraft.defaults().copyWith(
          turnWarningEnabled: false,
          totalWarningEnabled: false,
          overtimeStartAlertEnabled: false,
          penaltyAlertEnabled: false,
          visualEnabled: false,
          soundEnabled: false,
          hapticEnabled: false,
          turnDangerFlashEnabled: true,
        ),
      );

      _expectEquals(message, null);
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
      _expectEquals(config.penaltyConfig.enabled, false);
      _expectEquals(config.alertConfig.overtimeStartAlertEnabled, false);
      _expectEquals(config.alertConfig.penaltyAlertEnabled, false);
    },
    'validates turn limits that are longer than the shortest total': () {
      final message = validateSessionSettingsDraft(
        SessionSettingsDraft.defaults().copyWith(
          sharedTotalSeconds: 180,
          turnLimitSeconds: 300,
        ),
      );

      _expectEquals(message, invalidTurnLimitMessage);
    },
    'validates penalty thresholds that can never be reached': () {
      final message = validateSessionSettingsDraft(
        SessionSettingsDraft.defaults().copyWith(
          sharedTotalSeconds: 180,
          turnLimitSeconds: 60,
          penaltyThresholdSeconds: 180,
        ),
      );

      _expectEquals(message, invalidPenaltyThresholdMessage);
    },
    'validates overtime settings with no possible overtime window': () {
      final message = validateSessionSettingsDraft(
        SessionSettingsDraft.defaults().copyWith(
          sharedTotalSeconds: 180,
          turnLimitSeconds: 180,
        ),
      );

      _expectEquals(message, invalidOvertimeWindowMessage);
    },
    'validates warning moments that are not before a limit': () {
      final message = validateSessionSettingsDraft(
        SessionSettingsDraft.defaults().copyWith(
          turnLimitSeconds: 60,
          warningBeforeSeconds: 60,
        ),
      );

      _expectEquals(message, invalidWarningBeforeMessage);
    },
    'validates alert targets without delivery methods': () {
      final message = validateSessionSettingsDraft(
        SessionSettingsDraft.defaults().copyWith(
          visualEnabled: false,
          soundEnabled: false,
          hapticEnabled: false,
          turnDangerFlashEnabled: false,
        ),
      );

      _expectEquals(message, invalidAlertDeliveryMessage);
    },
    'validates delivery methods without alert targets': () {
      final message = validateSessionSettingsDraft(
        SessionSettingsDraft.defaults().copyWith(
          turnWarningEnabled: false,
          totalWarningEnabled: false,
          overtimeStartAlertEnabled: false,
          penaltyAlertEnabled: false,
          visualEnabled: true,
          turnDangerFlashEnabled: false,
          soundEnabled: false,
          hapticEnabled: false,
        ),
      );

      _expectEquals(message, invalidAlertTargetMessage);
    },
    'validates saved configs with invalid speaker ids': () {
      final message = validateSessionConfig(
        const SessionConfig(
          participantA: ParticipantConfig(
            id: 'a',
            name: 'A',
            totalAllocatedSeconds: 300,
          ),
          participantB: ParticipantConfig(
            id: 'b',
            name: 'B',
            totalAllocatedSeconds: 300,
          ),
          turnLimitSeconds: 60,
          firstSpeakerId: 'missing',
          overtimeConfig: OvertimeConfig(),
          penaltyConfig: PenaltyConfig(),
          alertConfig: AlertConfig(),
        ),
      );

      _expectEquals(message, invalidSessionConfigMessage);
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
