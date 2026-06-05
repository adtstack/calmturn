import 'package:flutter/cupertino.dart';

import '../settings/session_setup_page.dart' show formatSeconds;
import '../timer/domain/timer_models.dart';
import 'session_record.dart';
import 'session_record_store.dart';

final class HistoryScreen extends StatefulWidget {
  final SessionRecordStore recordStore;

  const HistoryScreen({super.key, required this.recordStore});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

final class _HistoryScreenState extends State<HistoryScreen> {
  List<SessionRecord> _records = const [];
  bool _isLoading = true;
  bool _isBusy = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _loadRecords(showLoading: false);
  }

  Future<void> _loadRecords({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _statusMessage = null;
      });
    }

    final records = await widget.recordStore.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _records = records;
      _isLoading = false;
    });
  }

  Future<void> _openRecord(SessionRecord record) async {
    final deleted = await Navigator.of(context).push<bool>(
      CupertinoPageRoute(
        builder: (_) {
          return HistoryDetailScreen(
            record: record,
            recordStore: widget.recordStore,
          );
        },
      ),
    );
    if (!mounted) {
      return;
    }
    if (deleted == true) {
      setState(() {
        _statusMessage = '기록을 삭제했어요.';
      });
      await _loadRecords(showLoading: false);
    }
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
      _records = const [];
      _isBusy = false;
      _statusMessage = '모든 기록을 삭제했어요.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('기록')),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 28),
          children: [
            const Text(
              '저장된 기록',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              '이 기기에 저장된 대화 기록입니다.',
              style: TextStyle(color: Color(0xFF5F6964)),
            ),
            const SizedBox(height: 18),
            if (_isLoading)
              const _StatusLine('기록을 불러오는 중이에요.')
            else if (_records.isEmpty)
              const _StatusLine('저장된 기록이 아직 없어요.')
            else ...[
              ..._records.map((record) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SavedRecordSummaryCard(
                    record: record,
                    onTap: () => _openRecord(record),
                  ),
                );
              }),
              const SizedBox(height: 4),
              CupertinoButton(
                color: CupertinoColors.systemRed,
                onPressed: _isBusy ? null : _clearRecords,
                child: const Text('모든 기록 삭제'),
              ),
            ],
            if (_statusMessage != null) ...[
              const SizedBox(height: 12),
              _StatusLine(_statusMessage!),
            ],
          ],
        ),
      ),
    );
  }
}

final class HistoryDetailScreen extends StatefulWidget {
  final SessionRecord record;
  final SessionRecordStore recordStore;

  const HistoryDetailScreen({
    super.key,
    required this.record,
    required this.recordStore,
  });

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

final class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  bool _isBusy = false;

  Future<void> _deleteRecord() async {
    setState(() {
      _isBusy = true;
    });
    await widget.recordStore.delete(widget.record.id);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('기록 자세히')),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 28),
          children: [
            Text(
              record.title,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              _formatDateTime(record.startedAt),
              style: const TextStyle(color: Color(0xFF5F6964)),
            ),
            const SizedBox(height: 16),
            _Card(
              child: _MetricGrid(
                metrics: [
                  _MetricData('대화 시간', formatSeconds(record.durationSeconds)),
                  _MetricData('종료', record.endReason.label),
                  _MetricData('휴식', record.breakCount.toString()),
                  _MetricData('휴식 시간', formatSeconds(record.totalBreakSeconds)),
                  _MetricData('주의 표시', _penaltyTotal(record).toString()),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '설정값',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  _MetricGrid(
                    metrics: [
                      _MetricData(
                        '턴 제한',
                        formatSeconds(record.config.turnLimitSeconds),
                      ),
                      _MetricData(
                        '오버타임',
                        _onOff(record.config.overtimeEnabled),
                      ),
                      _MetricData(
                        '오버타임 표시',
                        _onOff(record.config.showOvertime),
                      ),
                      _MetricData(
                        '주의 기준',
                        formatSeconds(record.config.overtimeThresholdSeconds),
                      ),
                      _MetricData(
                        '주의 반복',
                        _penaltyRepeatLabel(record.config.penaltyRepeatMode),
                      ),
                      _MetricData('알림', record.config.alertChannels),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ...record.participantResults.map((participant) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ParticipantDetailCard(participant: participant),
              );
            }),
            _NotesCard(record: record),
            const SizedBox(height: 14),
            CupertinoButton(
              color: CupertinoColors.systemRed,
              onPressed: _isBusy ? null : _deleteRecord,
              child: const Text('기록 삭제'),
            ),
          ],
        ),
      ),
    );
  }
}

final class _SavedRecordSummaryCard extends StatelessWidget {
  final SessionRecord record;
  final VoidCallback onTap;

  const _SavedRecordSummaryCard({required this.record, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${record.title} 기록 자세히 보기',
      child: GestureDetector(
        onTap: onTap,
        child: _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                record.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(_formatDateTime(record.startedAt)),
              const SizedBox(height: 10),
              _MetricGrid(
                metrics: [
                  _MetricData('대화 시간', formatSeconds(record.durationSeconds)),
                  _MetricData('종료', record.endReason.label),
                  _MetricData('휴식', record.breakCount.toString()),
                  _MetricData('주의 표시', _penaltyTotal(record).toString()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _ParticipantDetailCard extends StatelessWidget {
  final ParticipantResult participant;

  const _ParticipantDetailCard({required this.participant});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            participant.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _MetricGrid(
            metrics: [
              _MetricData(
                '배정 시간',
                formatSeconds(participant.totalAllocatedSeconds),
              ),
              _MetricData(
                '사용한 시간',
                formatSeconds(participant.totalUsedSeconds),
              ),
              _MetricData(
                '남은 시간',
                formatSeconds(participant.totalRemainingSeconds),
              ),
              _MetricData('차례 수', participant.turnCount.toString()),
              _MetricData(
                '오버타임 합계',
                formatSeconds(participant.overtimeTotalSeconds),
              ),
              _MetricData('주의 표시', participant.penaltyCount.toString()),
            ],
          ),
        ],
      ),
    );
  }
}

final class _NotesCard extends StatelessWidget {
  final SessionRecord record;

  const _NotesCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final hasAgreedNotes = record.agreedNotes != null;
    final hasNextTopics = record.nextTopics != null;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '메모',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (!hasAgreedNotes && !hasNextTopics)
            const Text('메모가 없어요.')
          else ...[
            if (hasAgreedNotes) ...[
              const _FieldLabel('합의한 것'),
              Text(record.agreedNotes!),
            ],
            if (hasNextTopics) ...[
              if (hasAgreedNotes) const SizedBox(height: 10),
              const _FieldLabel('다음에 이야기할 것'),
              Text(record.nextTopics!),
            ],
          ],
        ],
      ),
    );
  }
}

final class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD9D4C8)),
      ),
      child: child,
    );
  }
}

final class _MetricData {
  final String label;
  final String value;

  const _MetricData(this.label, this.value);
}

final class _MetricGrid extends StatelessWidget {
  final List<_MetricData> metrics;

  const _MetricGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 18,
      runSpacing: 12,
      children: metrics
          .map((metric) {
            return SizedBox(
              width: 136,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metric.label,
                    style: const TextStyle(
                      color: Color(0xFF6D746F),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    metric.value,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

final class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );
  }
}

final class _StatusLine extends StatelessWidget {
  final String text;

  const _StatusLine(this.text);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFE7F1EC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  return '${local.year}-${_two(local.month)}-${_two(local.day)} '
      '${_two(local.hour)}:${_two(local.minute)}';
}

String _two(int value) {
  return value.toString().padLeft(2, '0');
}

String _onOff(bool value) {
  return value ? '켜짐' : '꺼짐';
}

String _penaltyRepeatLabel(PenaltyRepeatMode mode) {
  return switch (mode) {
    PenaltyRepeatMode.oncePerTurn => '차례당 1회',
    PenaltyRepeatMode.everyThreshold => '기준마다',
  };
}

int _penaltyTotal(SessionRecord record) {
  return record.participantResults.fold<int>(
    0,
    (total, participant) => total + participant.penaltyCount,
  );
}
