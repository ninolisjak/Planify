import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../providers/theme_provider.dart';
import '../services/calendar_service.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
const SettingsScreen({super.key});

@override
State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
bool notifications = true;
final CalendarService _calendarService = CalendarService();
bool _calendarConnected = false;
bool _isConnecting = false;

@override
void initState() {
  super.initState();
  _checkCalendarConnection();
}

Future<void> _checkCalendarConnection() async {
  final connected = await _calendarService.initialize();
  if (mounted) {
    setState(() => _calendarConnected = connected);
  }
}

Future<void> _connectCalendar() async {
  setState(() => _isConnecting = true);
  try {
    final success = await _calendarService.signInWithCalendar();
    if (mounted) {
      setState(() {
        _calendarConnected = success;
        _isConnecting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Google Calendar povezan!'
              : 'Napaka pri povezovanju'),
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      setState(() => _isConnecting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Napaka: $e')),
      );
    }
  }
}

Future<void> _logout() async {
  try {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
    // Ročna navigacija na LoginScreen
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Napaka pri odjavi: $e')),
      );
    }
  }
}

@override
Widget build(BuildContext context) {
final themeProvider = context.watch<ThemeProvider>();
final isDark = themeProvider.isDarkMode;

return Scaffold(
  backgroundColor: isDark ? const Color(0xFF121212) : null,
  body: SafeArea(
    child: ListView(
      children: [
        // GRADIENT HEADER
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF8E24AA),
                Color(0xFFEC407A),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                "Nastavitve",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Icon(Icons.settings, color: Colors.white, size: 28),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          title: Text(
            "Obvestila",
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
          value: notifications,
          onChanged: (v) => setState(() => notifications = v),
        ),
        SwitchListTile(
          title: Text(
            "Temni način",
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
          subtitle: Text(
            isDark ? "Trenutno aktiven" : "Trenutno neaktiven",
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
          ),
          value: isDark,
          onChanged: (_) => themeProvider.toggleTheme(),
        ),
        const Divider(),
        ListTile(
          title: Text(
            "Google Calendar",
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
          subtitle: Text(
            _calendarConnected
                ? "Povezan - roki se sinhronizirajo"
                : "Poveži za sinhronizacijo rokov",
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
          ),
          leading: Icon(
            _calendarConnected ? Icons.check_circle : Icons.calendar_month,
            color: _calendarConnected ? Colors.green : (isDark ? Colors.white70 : null),
          ),
          trailing: _isConnecting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : _calendarConnected
                  ? const Icon(Icons.check, color: Colors.green)
                  : TextButton(
                      onPressed: _connectCalendar,
                      child: const Text('Poveži'),
                    ),
        ),
        ListTile(
          title: Text(
            "Vremenska napoved",
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
          subtitle: Text(
            "Prikazano na domači strani",
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
          ),
          leading: Icon(Icons.cloud, color: isDark ? Colors.white70 : null),
        ),
        const Divider(),
        ListTile(
          leading: Icon(Icons.logout, color: isDark ? Colors.white70 : null),
          title: Text(
            "Odjava",
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
          onTap: _logout,
        ),
      ],
    ),
  ),
);
}
}
