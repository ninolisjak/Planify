import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

// Flashcards Screen
class FlashcardsScreen extends StatefulWidget {
final List<Map<String, dynamic>> flashcards;
const FlashcardsScreen({super.key, required this.flashcards});

@override
State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
int currentIndex = 0;
Timer? _timer;

@override
void initState() {
super.initState();
_nextCard();
_timer = Timer.periodic(const Duration(seconds: 30), (timer) => _nextCard());

}

void _nextCard() {
if (widget.flashcards.isEmpty) return;
setState(() {
currentIndex = Random().nextInt(widget.flashcards.length);
});
}

@override
void dispose() {
_timer?.cancel();
super.dispose();
}

@override
Widget build(BuildContext context) {
if (widget.flashcards.isEmpty) {
return  Scaffold(
appBar: AppBar(title: Text("Učenje")),
body: Center(child: Text("Ni flashcards za prikaz.")),
);
}


final card = widget.flashcards[currentIndex];

return Scaffold(
  appBar: AppBar(title: const Text("Učenje")),
  body: Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              card['title'],
              style: const TextStyle(fontSize: 24),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _nextCard,
          child: const Text("Naslednje vprašanje"),
        ),
      ],
    ),
  ),
);


}
}

// Primer integracije v Home Screen
class PlanifyHomeScreen extends StatefulWidget {
const PlanifyHomeScreen({super.key});

@override
State<PlanifyHomeScreen> createState() => _PlanifyHomeScreenState();
}

class _PlanifyHomeScreenState extends State<PlanifyHomeScreen> {
int _index = 0;

// Primer začetnih flashcards
final List<Map<String, dynamic>> flashcards = [
{'title': 'Kaj je Dart?'},
{'title': 'Kaj je Flutter?'},
{'title': 'Kaj je Stateful Widget?'},
{'title': 'Kaj je Stateless Widget?'},
];

late final List<Widget> screens;

@override
void initState() {
super.initState();
screens = [
const Center(child: Text("Dashboard")), // nadomesti z DashboardScreen()
const Center(child: Text("Focus Timer")), // nadomesti z FocusTimerScreen()
FlashcardsScreen(flashcards: flashcards),
const Center(child: Text("Settings")), // nadomesti z SettingsScreen()
];
}

@override
Widget build(BuildContext context) {
return Scaffold(
body: screens[_index],
bottomNavigationBar: BottomNavigationBar(
type: BottomNavigationBarType.fixed,
currentIndex: _index,
onTap: (i) => setState(() => _index = i),
items: const [
BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Domov"),
BottomNavigationBarItem(icon: Icon(Icons.timer), label: "Focus"),
BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: "Flashcards"),
BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Nastavitve"),
],
),
);
}
}