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
              _HistoryCalendar(
                month: _monthStart(grouped.keys.first),
                groupedRecords: grouped,
                onOpenDay: _openDay,
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
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('기록을 삭제할까요?'),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('취소'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }

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

final class _HistoryCalendar extends StatelessWidget {
  final DateTime month;
  final Map<DateTime, List<SessionRecord>> groupedRecords;
  final Future<void> Function(DateTime day, List<SessionRecord> records)
  onOpenDay;

  const _HistoryCalendar({
    required this.month,
    required this.groupedRecords,
    required this.onOpenDay,
  });

  @override
  Widget build(BuildContext context) {
    final weeks = _calendarWeeks(month);
    return _Card(
      child: Column(
        key: const ValueKey('history-calendar-grid'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${month.year}년 ${month.month}월',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          Row(
            children: const ['일', '월', '화', '수', '목', '금', '토'].map((label) {
              return Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Color(0xFF5F6964),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          ...weeks.map((week) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: week
                    .map((day) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: day == null
                              ? const SizedBox(height: 64)
                              : _CalendarDayCell(
                                  day: day,
                                  records: groupedRecords[day] ?? const [],
                                  onTap: groupedRecords.containsKey(day)
                                      ? () =>
                                            onOpenDay(day, groupedRecords[day]!)
                                      : null,
                                ),
                        ),
                      );
                    })
                    .toList(growable: false),
              ),
            );
          }),
        ],
      ),
    );
  }
}

final class _CalendarDayCell extends StatelessWidget {
  final DateTime day;
  final List<SessionRecord> records;
  final VoidCallback? onTap;

  const _CalendarDayCell({
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
        .map((record) => _calendarOutcomeMark(record.outcome))
        .join();
    final hasRecords = records.isNotEmpty;
    final child = DecoratedBox(
      decoration: BoxDecoration(
        color: hasRecords ? const Color(0xFFE7F1EC) : const Color(0xFFF8F7F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasRecords ? const Color(0xFF2D6A64) : const Color(0xFFE0DCD2),
          width: hasRecords ? 1.5 : 1,
        ),
      ),
      child: SizedBox(
        height: 64,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                day.day.toString(),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              Text(
                markText,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return GestureDetector(
      key: ValueKey('history-day-${_isoDate(day)}'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: child,
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
            participant.displayName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _MetricGrid(
            metrics: [
              _MetricData(
                '사용한 시간',
                formatSeconds(participant.totalUsedSeconds),
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

DateTime _monthStart(DateTime value) {
  return DateTime(value.year, value.month);
}

List<List<DateTime?>> _calendarWeeks(DateTime month) {
  final firstDay = _monthStart(month);
  final leadingEmptyDays = firstDay.weekday % DateTime.daysPerWeek;
  final days = <DateTime?>[
    ...List<DateTime?>.filled(leadingEmptyDays, null),
    for (var day = 1; day <= _daysInMonth(month); day += 1)
      DateTime(month.year, month.month, day),
  ];
  while (days.length % DateTime.daysPerWeek != 0) {
    days.add(null);
  }

  final weeks = <List<DateTime?>>[];
  for (var index = 0; index < days.length; index += DateTime.daysPerWeek) {
    weeks.add(days.sublist(index, index + DateTime.daysPerWeek));
  }
  return weeks;
}

int _daysInMonth(DateTime month) {
  return DateTime(month.year, month.month + 1, 0).day;
}

String _isoDate(DateTime value) {
  return '${value.year}-${_two(value.month)}-${_two(value.day)}';
}

String _calendarOutcomeMark(ConversationOutcome? outcome) {
  return switch (outcome) {
    ConversationOutcome.resolved => '✅',
    ConversationOutcome.unresolved => '❌',
    null => '-',
  };
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
