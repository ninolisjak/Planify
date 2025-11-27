import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/db_service.dart'; 
import 'screens/dashboard_screen.dart';
import 'screens/focus_timer_screen.dart';
import 'screens/settings_screen.dart';
import 'providers/focus_provider.dart';


Future<void> testDB() async {
  final db = await DBService().database;

  
  final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table'");
  print("Tabele v bazi:");
  for (var table in tables) {
    print(table['name']);
  }

  final subjects = await db.query('subjects');
  print("Subjects count: ${subjects.length}");
}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

 
  final db = DBService();
  //await db.database; 
 // testDB();

  runApp(
    ChangeNotifierProvider(
      create: (_) => FocusProvider(),
      child: const PlanifyApp(),
    ),
  );
}

class PlanifyApp extends StatefulWidget {
  const PlanifyApp({super.key});

  @override
  State<PlanifyApp> createState() => _PlanifyAppState();
}

class _PlanifyAppState extends State<PlanifyApp> {
  int _index = 0;

  final screens = const [
    DashboardScreen(),
    FocusTimerScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Planify MVP',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: Scaffold(
        body: screens[_index],
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Domov"),
            BottomNavigationBarItem(icon: Icon(Icons.timer), label: "Focus"),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Nastavitve"),
          ],
        ),
      ),
    );
  }
}
