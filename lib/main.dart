import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/focus_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/focus_timer_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/flashcards_screen.dart';
import 'services/db_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
WidgetsFlutterBinding.ensureInitialized();

await DBService().database; // ustvari bazo, če še ne obstaja
await testDB();             // pokliče funkcijo za debug

runApp(
ChangeNotifierProvider(
create: (_) => FocusProvider(),
child: const PlanifyApp(),
),
);
}

Future<void> testDB() async {
final db = await DBService().database;

final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
print("Tabele v bazi:");
for (var table in tables) {
print(table['name']);
}

final users = await db.query('profiles');
print("Število uporabnikov: ${users.length}");
for (var user in users) {
print(user); // prikaže vse stolpce, npr. id in email
}
}

class PlanifyApp extends StatelessWidget {
const PlanifyApp({super.key});

Future<bool> _checkLogin() async {
final prefs = await SharedPreferences.getInstance();
final userId = prefs.getString('user_id');
return userId != null;
}

@override
Widget build(BuildContext context) {
return MaterialApp(
title: 'Planify MVP',
theme: ThemeData(
useMaterial3: true,
colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
),
initialRoute: '/login',
routes: {
'/login': (context) => const LoginScreen(),
'/home': (context) => const PlanifyHomeScreen(),
},
home: FutureBuilder<bool>(
future: _checkLogin(),
builder: (context, snapshot) {
if (!snapshot.hasData) {
return const Scaffold(
body: Center(child: CircularProgressIndicator()),
);
}
final isLoggedIn = snapshot.data!;
return isLoggedIn ? const PlanifyHomeScreen() : const LoginScreen();
},
),
);
}
}

class PlanifyHomeScreen extends StatefulWidget {
const PlanifyHomeScreen({super.key});

@override
State<PlanifyHomeScreen> createState() => _PlanifyHomeScreenState();
}

class _PlanifyHomeScreenState extends State<PlanifyHomeScreen> {
int _index = 0;

final screens = [
  const DashboardScreen(),
  const FocusTimerScreen(),
  const SettingsScreen(),
];


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
BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Nastavitve"),
],
),
);
}
}