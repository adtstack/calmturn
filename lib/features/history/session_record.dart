import '../timer/domain/timer_models.dart';

enum SessionEndReason {
  endedByUser,
  timeEnded;

  String get label {
    return switch (this) {
      SessionEndReason.endedByUser => '직접 종료',
      SessionEndReason.timeEnded => '전체 시간 종료',
    };
  }
}

final class SessionConfigSnapshot {
  final int turnLimitSeconds;
  final bool overtimeEnabled;
  final bool showOvertime;
  final int overtimeThresholdSeconds;
  final PenaltyRepeatMode penaltyRepeatMode;
  final PenaltyLabelMode penaltyLabelMode;
  final String alertChannels;

  const SessionConfigSnapshot({
    required this.turnLimitSeconds,
    required this.overtimeEnabled,
    required this.showOvertime,
    required this.overtimeThresholdSeconds,
    required this.penaltyRepeatMode,
    required this.penaltyLabelMode,
    required this.alertChannels,
  });

  factory SessionConfigSnapshot.fromConfig(SessionConfig config) {
    return SessionConfigSnapshot(
      turnLimitSeconds: config.turnLimitSeconds,
      overtimeEnabled: config.overtimeConfig.enabled,
      showOvertime: config.overtimeConfig.showOvertime,
      overtimeThresholdSeconds: config.penaltyConfig.thresholdSeconds,
      penaltyRepeatMode: config.penaltyConfig.repeatMode,
      penaltyLabelMode: config.penaltyConfig.labelMode,
      alertChannels: _alertMethodsLabel(config.alertConfig),
    );
  }

  factory SessionConfigSnapshot.fromJson(Map<String, Object?> json) {
    return SessionConfigSnapshot(
      turnLimitSeconds: json['turnLimitSeconds'] as int,
      overtimeEnabled: json['overtimeEnabled'] as bool,
      showOvertime: json['showOvertime'] as bool,
      overtimeThresholdSeconds: json['overtimeThresholdSeconds'] as int,
      penaltyRepeatMode: PenaltyRepeatMode.values.byName(
        json['penaltyRepeatMode'] as String,
      ),
      penaltyLabelMode: PenaltyLabelMode.values.byName(
        json['penaltyLabelMode'] as String,
      ),
      alertChannels: json['alertChannels'] as String,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'turnLimitSeconds': turnLimitSeconds,
      'overtimeEnabled': overtimeEnabled,
      'showOvertime': showOvertime,
      'overtimeThresholdSeconds': overtimeThresholdSeconds,
      'penaltyRepeatMode': penaltyRepeatMode.name,
      'penaltyLabelMode': penaltyLabelMode.name,
      'alertChannels': alertChannels,
    };
  }
}

final class ParticipantResult {
  final String id;
  final String name;
  final int totalAllocatedSeconds;
  final int totalUsedSeconds;
  final int totalRemainingSeconds;
  final int turnCount;
  final int overtimeTotalSeconds;
  final int penaltyCount;

  const ParticipantResult({
    required this.id,
    required this.name,
    required this.totalAllocatedSeconds,
    required this.totalUsedSeconds,
    required this.totalRemainingSeconds,
    required this.turnCount,
    required this.overtimeTotalSeconds,
    required this.penaltyCount,
  });

  factory ParticipantResult.fromParticipant(Participant participant) {
    return ParticipantResult(
      id: participant.id,
      name: participant.name,
      totalAllocatedSeconds: participant.totalAllocatedSeconds,
      totalUsedSeconds: participant.totalUsedSeconds,
      totalRemainingSeconds: participant.totalRemainingSeconds,
      turnCount: participant.turnCount,
      overtimeTotalSeconds: participant.overtimeTotalSeconds,
      penaltyCount: participant.penaltyCount,
    );
  }

  factory ParticipantResult.fromJson(Map<String, Object?> json) {
    return ParticipantResult(
      id: json['id'] as String,
      name: json['name'] as String,
      totalAllocatedSeconds: json['totalAllocatedSeconds'] as int,
      totalUsedSeconds: json['totalUsedSeconds'] as int,
      totalRemainingSeconds: json['totalRemainingSeconds'] as int,
      turnCount: json['turnCount'] as int,
      overtimeTotalSeconds: json['overtimeTotalSeconds'] as int,
      penaltyCount: json['penaltyCount'] as int,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'totalAllocatedSeconds': totalAllocatedSeconds,
      'totalUsedSeconds': totalUsedSeconds,
      'totalRemainingSeconds': totalRemainingSeconds,
      'turnCount': turnCount,
      'overtimeTotalSeconds': overtimeTotalSeconds,
      'penaltyCount': penaltyCount,
    };
  }
}

final class SessionRecord {
  final String id;
  final DateTime startedAt;
  final DateTime endedAt;
  final SessionEndReason endReason;
  final SessionConfigSnapshot config;
  final List<ParticipantResult> participantResults;
  final int breakCount;
  final int totalBreakSeconds;
  final String? agreedNotes;
  final String? nextTopics;

  const SessionRecord({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.endReason,
    required this.config,
    required this.participantResults,
    required this.breakCount,
    required this.totalBreakSeconds,
    this.agreedNotes,
    this.nextTopics,
  });

  factory SessionRecord.fromTimerSnapshot({
    required String id,
    required SessionConfig config,
    required TimerSnapshot snapshot,
    required DateTime startedAt,
    required DateTime endedAt,
    required SessionEndReason endReason,
    required int breakCount,
    int totalBreakSeconds = 0,
    String? agreedNotes,
    String? nextTopics,
  }) {
    return SessionRecord(
      id: id,
      startedAt: startedAt,
      endedAt: endedAt,
      endReason: endReason,
      config: SessionConfigSnapshot.fromConfig(config),
      participantResults: List.unmodifiable(
        snapshot.participants.map(ParticipantResult.fromParticipant),
      ),
      breakCount: breakCount,
      totalBreakSeconds: totalBreakSeconds,
      agreedNotes: _nullIfBlank(agreedNotes),
      nextTopics: _nullIfBlank(nextTopics),
    );
  }

  factory SessionRecord.fromJson(Map<String, Object?> json) {
    return SessionRecord(
      id: json['id'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: DateTime.parse(json['endedAt'] as String),
      endReason: SessionEndReason.values.byName(json['endReason'] as String),
      config: SessionConfigSnapshot.fromJson(
        json['config'] as Map<String, Object?>,
      ),
      participantResults: List.unmodifiable(
        (json['participantResults'] as List<Object?>).map(
          (item) => ParticipantResult.fromJson(item as Map<String, Object?>),
        ),
      ),
      breakCount: json['breakCount'] as int,
      totalBreakSeconds: json['totalBreakSeconds'] as int,
      agreedNotes: json['agreedNotes'] as String?,
      nextTopics: json['nextTopics'] as String?,
    );
  }

  String get title {
    return participantResults
        .map((participant) => participant.name)
        .join(' / ');
  }

  int get durationSeconds {
    return endedAt.difference(startedAt).inSeconds;
  }

  SessionRecord copyWith({
    String? id,
    DateTime? startedAt,
    DateTime? endedAt,
    SessionEndReason? endReason,
    SessionConfigSnapshot? config,
    List<ParticipantResult>? participantResults,
    int? breakCount,
    int? totalBreakSeconds,
    String? agreedNotes,
    String? nextTopics,
  }) {
    return SessionRecord(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      endReason: endReason ?? this.endReason,
      config: config ?? this.config,
      participantResults: List.unmodifiable(
        participantResults ?? this.participantResults,
      ),
      breakCount: breakCount ?? this.breakCount,
      totalBreakSeconds: totalBreakSeconds ?? this.totalBreakSeconds,
      agreedNotes: _nullIfBlank(agreedNotes) ?? this.agreedNotes,
      nextTopics: _nullIfBlank(nextTopics) ?? this.nextTopics,
    );
  }

  SessionRecord withNotes({String? agreedNotes, String? nextTopics}) {
    return SessionRecord(
      id: id,
      startedAt: startedAt,
      endedAt: endedAt,
      endReason: endReason,
      config: config,
      participantResults: participantResults,
      breakCount: breakCount,
      totalBreakSeconds: totalBreakSeconds,
      agreedNotes: _nullIfBlank(agreedNotes),
      nextTopics: _nullIfBlank(nextTopics),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt.toIso8601String(),
      'endReason': endReason.name,
      'config': config.toJson(),
      'participantResults': participantResults
          .map((participant) => participant.toJson())
          .toList(growable: false),
      'breakCount': breakCount,
      'totalBreakSeconds': totalBreakSeconds,
      'agreedNotes': agreedNotes,
      'nextTopics': nextTopics,
    };
  }
}

String newSessionRecordId(DateTime now) {
  return 'session-${now.toUtc().microsecondsSinceEpoch}';
}

String? _nullIfBlank(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

String _alertMethodsLabel(AlertConfig config) {
  final methods = <String>[
    if (config.visualEnabled) '화면',
    if (config.soundEnabled) '소리',
    if (config.hapticEnabled) '진동',
  ];

  return methods.isEmpty ? '꺼짐' : methods.join(' + ');
}
