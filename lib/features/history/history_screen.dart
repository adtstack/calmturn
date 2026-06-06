import 'package:flutter/cupertino.dart';

import '../settings/session_setup_page.dart' show formatSeconds;
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

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final records = await widget.recordStore.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _records = records;
      _isLoading = false;
    });
  }

  Future<void> _openDay(DateTime day, List<SessionRecord> records) async {
    final changed = await Navigator.of(context).push<bool>(
      CupertinoPageRoute(
        builder: (_) {
          return HistoryDayScreen(
            day: day,
            records: records,
            recordStore: widget.recordStore,
          );
        },
      ),
    );
    if (changed == true) {
      await _loadRecords();
    }
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByDay(_records);
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('기록 달력')),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 28),
          children: [
            const Text(
              '기록 달력',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              '날짜 아래에는 최근 결과가 최대 3개까지 표시됩니다.',
              style: TextStyle(color: Color(0xFF5F6964)),
            ),
            const SizedBox(height: 18),
            if (_isLoading)
              const _StatusLine('기록을 불러오는 중이에요.')
            else if (grouped.isEmpty)
              const _StatusLine('저장된 기록이 아직 없어요.')
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: grouped.entries
                    .map((entry) {
                      return _CalendarDayCard(
                        day: entry.key,
                        records: entry.value,
                        onTap: () => _openDay(entry.key, entry.value),
                      );
                    })
                    .toList(growable: false),
              ),
          ],
        ),
      ),
    );
  }
}

final class HistoryDayScreen extends StatefulWidget {
  final DateTime day;
  final List<SessionRecord> records;
  final SessionRecordStore recordStore;

  const HistoryDayScreen({
    super.key,
    required this.day,
    required this.records,
    required this.recordStore,
  });

  @override
  State<HistoryDayScreen> createState() => _HistoryDayScreenState();
}

final class _HistoryDayScreenState extends State<HistoryDayScreen> {
  late List<SessionRecord> _records;

  @override
  void initState() {
    super.initState();
    _records = List<SessionRecord>.of(widget.records);
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
    if (deleted == true && mounted) {
      setState(() {
        _records = _records.where((item) => item.id != record.id).toList();
      });
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('오늘의 기록')),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 28),
          children: [
            Text(
              _isToday(widget.day) ? '오늘의 기록' : '${_dayLabel(widget.day)} 기록',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            ..._records.map((record) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _DayRecordCard(
                  record: record,
                  onTap: () => _openRecord(record),
                ),
              );
            }),
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
    if (mounted) {
      Navigator.of(context).pop(true);
    }
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
              record.summaryText ?? record.title,
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
                  _MetricData('결과', record.outcome?.label ?? '기록 없음'),
                  _MetricData('휴식', record.breakCount.toString()),
                  _MetricData('휴식 시간', formatSeconds(record.totalBreakSeconds)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '기록',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  _FieldLabel('총평'),
                  Text(record.summaryText ?? '총평이 없어요.'),
                  const SizedBox(height: 10),
                  _FieldLabel('해시태그'),
                  Text(record.tagsText ?? '해시태그가 없어요.'),
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

final class _CalendarDayCard extends StatelessWidget {
  final DateTime day;
  final List<SessionRecord> records;
  final VoidCallback onTap;

  const _CalendarDayCard({
    required this.day,
    required this.records,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final marks = List<SessionRecord>.of(records)
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    final markText = marks
        .take(3)
        .map((record) => record.outcome?.mark ?? '-')
        .join(' ');
    return SizedBox(
      width: 104,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: _Card(
          child: Column(
            children: [
              Text(
                _dayLabel(day),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                markText,
                maxLines: 1,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _DayRecordCard extends StatelessWidget {
  final SessionRecord record;
  final VoidCallback onTap;

  const _DayRecordCard({required this.record, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _timeLabel(record.startedAt),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                Text(
                  record.outcome?.mark ?? '-',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              record.summaryText ?? record.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            if (record.tagsText != null) ...[
              const SizedBox(height: 6),
              Text(
                record.tagsText!,
                style: const TextStyle(color: Color(0xFF5F6964)),
              ),
            ],
          ],
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
            ],
          ),
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

Map<DateTime, List<SessionRecord>> _groupByDay(List<SessionRecord> records) {
  final grouped = <DateTime, List<SessionRecord>>{};
  for (final record in records) {
    final local = record.startedAt.toLocal();
    final day = DateTime(local.year, local.month, local.day);
    grouped.putIfAbsent(day, () => []).add(record);
  }
  final sortedEntries = grouped.entries.toList()
    ..sort((a, b) => b.key.compareTo(a.key));
  return Map<DateTime, List<SessionRecord>>.fromEntries(sortedEntries);
}

bool _isToday(DateTime day) {
  final now = DateTime.now();
  return day.year == now.year && day.month == now.month && day.day == now.day;
}

String _dayLabel(DateTime value) {
  return '${value.month}/${value.day}';
}

String _timeLabel(DateTime value) {
  final local = value.toLocal();
  return '${_two(local.hour)}:${_two(local.minute)}';
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  return '${local.year}-${_two(local.month)}-${_two(local.day)} '
      '${_two(local.hour)}:${_two(local.minute)}';
}

String _two(int value) {
  return value.toString().padLeft(2, '0');
}
