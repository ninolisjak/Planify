import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/login_screen.dart';

class SettingsScreen extends StatefulWidget {
const SettingsScreen({super.key});

@override
State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
bool notifications = true;
bool darkMode = false;

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
return SafeArea(
child: ListView(
children: [
const ListTile(
title: Text("Nastavitve", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
),
SwitchListTile(
title: const Text("Obvestila"),
value: notifications,
onChanged: (v) => setState(() => notifications = v),
),
SwitchListTile(
title: const Text("Dark mode (placeholder)"),
value: darkMode,
onChanged: (v) => setState(() => darkMode = v),
),
const Divider(),
const ListTile(
title: Text("Google Calendar"),
subtitle: Text("TODO: integracija"),
leading: Icon(Icons.calendar_month),
),
const ListTile(
title: Text("Vremenska napoved"),
subtitle: Text("TODO: OpenWeather API"),
leading: Icon(Icons.cloud),
),
const Divider(),
ListTile(
leading: const Icon(Icons.logout),
title: const Text("Odjava"),
onTap: _logout,
),
],
),
);
}
}
