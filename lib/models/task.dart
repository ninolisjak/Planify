class Task {
  final String id;
  final String title;
  final String? subject;
  final DateTime dueDate;
  final bool isCompleted;

  Task({
    required this.id,
    required this.title,
    this.subject,
    required this.dueDate,
    this.isCompleted = false,
  });

  // Mock podatki za testiranje
  static List<Task> getMockTasks() {
    final today = DateTime.now();
    return [
      Task(
        id: '1',
        title: 'Preberi poglavje 5',
        subject: 'Matematika',
        dueDate: today,
      ),
      Task(
        id: '2',
        title: 'Končaj projekt',
        subject: 'Programiranje',
        dueDate: today,
      ),
      Task(
        id: '3',
        title: 'Priprava na kolokvij',
        subject: 'Fizika',
        dueDate: today,
      ),
    ];
  }

  // Za prazno stanje
  static List<Task> getEmptyTasks() {
    return [];
  }
}
