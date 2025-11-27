import 'package:flutter/material.dart';
import '../widgets/subject_list.dart';


class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text("Planify")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Naslov in datum
              const Text(
                "Planify",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                "Datum: ${now.day}.${now.month}.${now.year}",
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),

              // Kartica za vreme
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Vreme",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text("Tu pride OpenWeather API."),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Kartica za danes
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Danes",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text("Zaenkrat ni dodanih obveznosti."),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

           

              const SizedBox(height: 24),

              // SubjectList widget
              const Expanded(child: SubjectList()),
            ],
          ),
        ),
      ),
    );
  }
}
