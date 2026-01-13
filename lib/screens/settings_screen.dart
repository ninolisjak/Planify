import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../screens/login_screen.dart';

class SettingsScreen extends StatefulWidget {
const SettingsScreen({super.key});

@override
State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
bool notifications = true;

Future<void> _logout() async {
final prefs = await SharedPreferences.getInstance();
await prefs.remove('user_id');


if (mounted) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (route) => false,
  );
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
        ListTile(
          title: Text(
            "Nastavitve",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
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
            "TODO: integracija",
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
          ),
          leading: Icon(Icons.calendar_month, color: isDark ? Colors.white70 : null),
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
