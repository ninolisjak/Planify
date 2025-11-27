import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/focus_provider.dart';

class FocusTimerScreen extends StatelessWidget {
  const FocusTimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<FocusProvider>();

    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer, size: 90, color: Colors.indigo.shade400),
            const SizedBox(height: 20),

            if (!timer.isRunning)
              ElevatedButton(
                onPressed: () => timer.start(),
                child: const Text("Začni fokus"),
              )
            else
              ElevatedButton(
                onPressed: () {
                  final duration = timer.stop();
                  if (duration != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Fokus končan: ${duration.inMinutes} min",
                        ),
                      ),
                    );
                  }
                },
                child: const Text("Končaj fokus"),
              ),
          ],
        ),
      ),
    );
  }
}