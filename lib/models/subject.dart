class Subject {
  final int? id;
  final String name;
  final String professor;
  final String colorHex;

  Subject({
    this.id,
    required this.name,
    required this.professor,
    required this.colorHex,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'professor': professor,
      'colorHex': colorHex,
    };
  }

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      id: map['id'] as int?,
      name: map['name'] as String,
      professor: map['professor'] as String,
      colorHex: map['colorHex'] as String,
    );
  }
}
