import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/db_service.dart';
import 'dashboard_screen.dart';
import 'focus_timer_screen.dart';
import 'settings_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = emailController.text.trim();

    // Prepreči prijavo, če email ni vnešen ali nima '@'
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vnesite veljaven email")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    final dbService = DBService();
    final db = await dbService.database;

    // Preverimo, ali uporabnik že obstaja
    final existing = await db.query(
      'profiles',
      where: 'email = ?',
      whereArgs: [email],
    );

    String userId;
    if (existing.isEmpty) {
      // Ustvarimo novega uporabnika
      userId = DateTime.now().millisecondsSinceEpoch.toString();
      await db.insert('profiles', {
        'id': userId,
        'email': email,
      });
    } else {
      // Če obstaja, uporabimo njegov ID
      userId = existing.first['id'] as String;
    }

    // Shranimo user_id v SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);

    setState(() {
      isLoading = false;
    });

    // Preusmeritev na glavni ekran
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PlanifyHomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Planify Login",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Email',
                  ),
                ),
                const SizedBox(height: 24),
                isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _login,
                        child: const Text("Prijava / Registracija"),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Glavni ekran z BottomNavigationBar
class PlanifyHomeScreen extends StatefulWidget {
  const PlanifyHomeScreen({super.key});

  @override
  State<PlanifyHomeScreen> createState() => _PlanifyHomeScreenState();
}

class _PlanifyHomeScreenState extends State<PlanifyHomeScreen> {
  int _index = 0;

  final screens = const [
    DashboardScreen(),
    FocusTimerScreen(),
    SettingsScreen(),
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
