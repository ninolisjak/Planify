class ExamDeadline {
  final int? id;
  final int? subjectId;
  final String subjectName;
  final DateTime examDate;
  final String? examTime; // Format: "HH:mm"
  final int? durationMinutes;
  final String? location;
  final String? notes;
  final DateTime createdAt;

  ExamDeadline({
    this.id,
    this.subjectId,
    required this.subjectName,
    required this.examDate,
    this.examTime,
    this.durationMinutes,
    this.location,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject_id': subjectId,
      'subject_name': subjectName,
      'exam_date': examDate.toIso8601String(),
      'exam_time': examTime,
      'duration_minutes': durationMinutes,
      'location': location,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ExamDeadline.fromMap(Map<String, dynamic> map) {
    return ExamDeadline(
      id: map['id'] as int?,
      subjectId: map['subject_id'] as int?,
      subjectName: map['subject_name'] as String,
      examDate: DateTime.parse(map['exam_date'] as String),
      examTime: map['exam_time'] as String?,
      durationMinutes: map['duration_minutes'] as int?,
      location: map['location'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }

  ExamDeadline copyWith({
    int? id,
    int? subjectId,
    String? subjectName,
    DateTime? examDate,
    String? examTime,
    int? durationMinutes,
    String? location,
    String? notes,
  }) {
    return ExamDeadline(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      examDate: examDate ?? this.examDate,
      examTime: examTime ?? this.examTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }

  // Preveri ali je rok v preteklosti
  bool get isPast => examDate.isBefore(DateTime.now());

  // Preostali dnevi do roka
  int get daysRemaining {
    final now = DateTime.now();
    final difference = examDate.difference(now).inDays;
    return difference < 0 ? 0 : difference;
  }

  // Formatiran datum
  String get formattedDate {
    return '${examDate.day}.${examDate.month}.${examDate.year}';
  }

  // Formatiran čas
  String get formattedTime {
    if (examTime == null) return 'Ni določeno';
    return examTime!;
  }
}
