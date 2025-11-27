import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/focus_provider.dart';

class FocusTimerScreen extends StatelessWidget {
  const FocusTimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<FocusProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        "Focus način",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      Icon(Icons.timer_outlined, color: Colors.white),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    timer.isBreak ? "Odmor" : "Fokus učenje",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    timer.isBreak
                        ? "Vzemi si kratek odmor."
                        : "Osredotoči se na učenje.",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // SPODNJI DEL
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  children: [
                   
                    _SectionCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 24, horizontal: 16),
                        child: Column(
                          children: [
                            Text(
                              timer.formattedTime,
                              style: const TextStyle(
                                fontSize: 64,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              timer.isBreak
                                  ? "Trenutno si na odmoru."
                                  : "Trenutno si v fokus seji.",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                 
                    _SectionCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (!timer.isRunning)
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.play_arrow),
                                    onPressed: () => timer.start(),
                                    label: Text(timer.isBreak
                                        ? "Začni odmor"
                                        : "Začni fokus"),
                                  )
                                else
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.pause),
                                    onPressed: () => timer.pause(),
                                    label: const Text("Pavza"),
                                  ),
                                const SizedBox(width: 12),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.refresh),
                                  onPressed: () => timer.reset(),
                                  label: const Text("Reset"),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              timer.isBreak
                                  ? "Ko se odmor izteče, se pripravi nova fokus seja."
                                  : "Po koncu fokusa sledi kratki odmor.",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                
                    const _SectionCard(
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        child: Text(
                          "Pomodoro tehnika: 25 minut fokusa + 5 minut odmora. "
                          "Ponovi več ciklov, nato si vzemi daljši odmor.",
                          style: TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: child,
    );
  }
}
