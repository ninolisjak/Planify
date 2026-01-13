import 'package:flutter/material.dart';
import '../services/db_service.dart';
import '../screens/flashcard_decks_screen.dart';

class SubjectList extends StatefulWidget {
  const SubjectList({super.key});

  @override
  State<SubjectList> createState() => _SubjectListState();
}

class _SubjectListState extends State<SubjectList> {
  List<Map<String, dynamic>> subjects = [];

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    final data = await DBService().getAllSubjects();
    setState(() => subjects = data);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: subjects.length,
      itemBuilder: (context, index) {
        final s = subjects[index];
        return ListTile(
          title: Text(s['name']),
          trailing: IconButton(
            icon: const Icon(Icons.school),
            onPressed: () {
              // Odpri flashcard sistem
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FlashcardDecksScreen(),
                ),
              );
            },
          ),
        );
      },
    );
  }
}