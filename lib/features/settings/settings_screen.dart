import 'package:flutter/cupertino.dart';

import '../history/session_record_store.dart';
import '../timer/domain/timer_models.dart';
import 'app_settings.dart';
import 'session_setup_page.dart';
import 'session_settings.dart';

final class SettingsScreen extends StatefulWidget {
  final AppSettingsDraft settings;
  final ValueChanged<AppSettingsDraft> onSettingsChanged;
  final VoidCallback onBack;
  final SessionRecordStore recordStore;

  const SettingsScreen({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
    required this.onBack,
    required this.recordStore,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

final class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettingsDraft _settings;
  bool _isBusy = false;
  String? _statusMessage;

  SessionSettingsDraft get _draft => _settings.sessionDefaults;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('App Settings'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: widget.onBack,
          child: const Text('Back to setup'),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
          children: [
            const Text(
              'Defaults for new sessions',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'These values are used the next time the session setup screen opens.',
              style: TextStyle(color: Color(0xFF5F6964)),
            ),
            const SizedBox(height: 18),
            _Section(
              title: 'Speaking Time',
              children: [
                _ChoiceGroup<TotalTimeMode>(
                  value: _draft.totalTimeMode,
                  options: const [
                    ChoiceOption('Same', TotalTimeMode.same),
                    ChoiceOption(
                      'Different',
                      TotalTimeMode.customPerParticipant,
                    ),
                  ],
                  onSelected: (value) {
                    _updateDraft(_draft.copyWith(totalTimeMode: value));
                  },
                ),
                const SizedBox(height: 14),
                if (_draft.totalTimeMode == TotalTimeMode.same)
                  _ChoiceGroup<int>(
                    value: _draft.sharedTotalSeconds,
                    options: const [
                      ChoiceOption('3 min each', 180),
                      ChoiceOption('5 min each', 300),
                      ChoiceOption('10 min each', 600),
                      ChoiceOption('15 min each', 900),
                    ],
                    onSelected: (value) {
                      _updateDraft(_draft.copyWith(sharedTotalSeconds: value));
                    },
                  )
                else ...[
                  _ChoiceGroup<int>(
                    value: _draft.participantATotalSeconds,
                    options: const [
                      ChoiceOption('A 3 min', 180),
                      ChoiceOption('A 5 min', 300),
                      ChoiceOption('A 7 min', 420),
                      ChoiceOption('A 10 min', 600),
                    ],
                    onSelected: (value) {
                      _updateDraft(
                        _draft.copyWith(participantATotalSeconds: value),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _ChoiceGroup<int>(
                    value: _draft.participantBTotalSeconds,
                    options: const [
                      ChoiceOption('B 3 min', 180),
                      ChoiceOption('B 5 min', 300),
                      ChoiceOption('B 7 min', 420),
                      ChoiceOption('B 10 min', 600),
                    ],
                    onSelected: (value) {
                      _updateDraft(
                        _draft.copyWith(participantBTotalSeconds: value),
                      );
                    },
                  ),
                ],
              ],
            ),
            _Section(
              title: 'Turn Limit',
              children: [
                _ChoiceGroup<int>(
                  value: _draft.turnLimitSeconds,
                  options: const [
                    ChoiceOption('Turn 30 sec', 30),
                    ChoiceOption('Turn 45 sec', 45),
                    ChoiceOption('Turn 1 min', 60),
                    ChoiceOption('Turn 90 sec', 90),
                    ChoiceOption('Turn 2 min', 120),
                  ],
                  onSelected: (value) {
                    _updateDraft(_draft.copyWith(turnLimitSeconds: value));
                  },
                ),
              ],
            ),
            _Section(
              title: 'Overtime & Penalty',
              children: [
                _ToggleRow(
                  label: 'Overtime',
                  value: _draft.overtimeEnabled,
                  onChanged: (value) {
                    _updateDraft(
                      _draft.copyWith(
                        overtimeEnabled: value,
                        showOvertime: value,
                      ),
                    );
                  },
                ),
                _ChoiceGroup<int>(
                  value: _draft.penaltyThresholdSeconds,
                  options: const [
                    ChoiceOption('Overtime 30 sec', 30),
                    ChoiceOption('Overtime 1 min', 60),
                    ChoiceOption('Overtime 2 min', 120),
                    ChoiceOption('Overtime 3 min', 180),
                  ],
                  onSelected: (value) {
                    _updateDraft(
                      _draft.copyWith(penaltyThresholdSeconds: value),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _ToggleRow(
                  label: 'Repeat marks',
                  value:
                      _draft.penaltyRepeatMode ==
                      PenaltyRepeatMode.everyThreshold,
                  onChanged: (value) {
                    _updateDraft(
                      _draft.copyWith(
                        penaltyRepeatMode: value
                            ? PenaltyRepeatMode.everyThreshold
                            : PenaltyRepeatMode.oncePerTurn,
                      ),
                    );
                  },
                ),
              ],
            ),
            _Section(
              title: 'Alerts',
              children: [
                _ChoiceGroup<int>(
                  value: _draft.warningBeforeSeconds,
                  options: const [
                    ChoiceOption('Warn 5 sec', 5),
                    ChoiceOption('Warn 10 sec', 10),
                    ChoiceOption('Warn 15 sec', 15),
                    ChoiceOption('Warn 30 sec', 30),
                  ],
                  onSelected: (value) {
                    _updateDraft(_draft.copyWith(warningBeforeSeconds: value));
                  },
                ),
                const SizedBox(height: 12),
                _ToggleRow(
                  label: 'Turn time',
                  value: _draft.turnWarningEnabled,
                  onChanged: (value) {
                    _updateDraft(_draft.copyWith(turnWarningEnabled: value));
                  },
                ),
                _ToggleRow(
                  label: 'Total time',
                  value: _draft.totalWarningEnabled,
                  onChanged: (value) {
                    _updateDraft(_draft.copyWith(totalWarningEnabled: value));
                  },
                ),
                _ToggleRow(
                  label: 'Overtime start',
                  value: _draft.overtimeStartAlertEnabled,
                  onChanged: (value) {
                    _updateDraft(
                      _draft.copyWith(overtimeStartAlertEnabled: value),
                    );
                  },
                ),
                _ToggleRow(
                  label: 'Overtime mark',
                  value: _draft.penaltyAlertEnabled,
                  onChanged: (value) {
                    _updateDraft(_draft.copyWith(penaltyAlertEnabled: value));
                  },
                ),
                const SizedBox(height: 12),
                _ToggleRow(
                  label: 'Screen',
                  value: _draft.visualEnabled,
                  onChanged: (value) {
                    _updateDraft(_draft.copyWith(visualEnabled: value));
                  },
                ),
                _ToggleRow(
                  label: 'Sound',
                  value: _draft.soundEnabled,
                  onChanged: (value) {
                    _updateDraft(_draft.copyWith(soundEnabled: value));
                  },
                ),
                _ToggleRow(
                  label: 'Vibration',
                  value: _draft.hapticEnabled,
                  onChanged: (value) {
                    _updateDraft(_draft.copyWith(hapticEnabled: value));
                  },
                ),
              ],
            ),
            _Section(
              title: 'Records',
              children: [
                _ToggleRow(
                  label: 'Auto-save records',
                  value: _settings.autoSaveRecords,
                  onChanged: (value) {
                    setState(() {
                      _settings = _settings.copyWith(autoSaveRecords: value);
                      _statusMessage = null;
                    });
                  },
                ),
                const SizedBox(height: 10),
                CupertinoButton(
                  color: CupertinoColors.systemRed,
                  onPressed: _isBusy ? null : _clearRecords,
                  child: const Text('Delete all records'),
                ),
              ],
            ),
            CupertinoButton.filled(
              onPressed: _saveSettings,
              child: const Text('Save settings'),
            ),
            if (_statusMessage != null) ...[
              const SizedBox(height: 12),
              _StatusLine(_statusMessage!),
            ],
          ],
        ),
      ),
    );
  }

  void _updateDraft(SessionSettingsDraft draft) {
    setState(() {
      _settings = _settings.copyWith(sessionDefaults: draft);
      _statusMessage = null;
    });
  }

  void _saveSettings() {
    widget.onSettingsChanged(_settings);
    setState(() {
      _statusMessage = 'Settings saved for the next session.';
    });
  }

  Future<void> _clearRecords() async {
    setState(() {
      _isBusy = true;
      _statusMessage = null;
    });
    await widget.recordStore.clear();
    if (!mounted) {
      return;
    }
    setState(() {
      _isBusy = false;
      _statusMessage = 'All records deleted.';
    });
  }
}

final class _ChoiceGroup<T> extends StatelessWidget {
  final T value;
  final List<ChoiceOption<T>> options;
  final ValueChanged<T> onSelected;

  const _ChoiceGroup({
    required this.value,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = option.value == value;
        return CupertinoButton(
          minimumSize: const Size(0, 40),
          color: isSelected ? const Color(0xFF2D6A64) : const Color(0xFFECE7DB),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          onPressed: () {
            onSelected(option.value);
          },
          child: Text(
            option.label,
            style: TextStyle(
              color: isSelected
                  ? CupertinoColors.white
                  : const Color(0xFF1C2523),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }
}

final class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled
          ? () {
              onChanged?.call(!value);
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: enabled
                      ? const Color(0xFF1C2523)
                      : const Color(0xFF929A95),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            CupertinoSwitch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

final class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFD9D4C8)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

final class _StatusLine extends StatelessWidget {
  final String text;

  const _StatusLine(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF2D6A64),
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
