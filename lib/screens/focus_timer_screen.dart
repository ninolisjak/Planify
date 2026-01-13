import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/focus_provider.dart';

class FocusTimerScreen extends StatelessWidget {
  const FocusTimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<FocusProvider>();

    // Če je fullscreen aktiven, prikaži fullscreen view
    if (timer.isFullscreen) {
      return _FullscreenTimerView(timer: timer);
    }

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

// FULLSCREEN TIMER VIEW
class _FullscreenTimerView extends StatefulWidget {
  final FocusProvider timer;

  const _FullscreenTimerView({required this.timer});

  @override
  State<_FullscreenTimerView> createState() => _FullscreenTimerViewState();
}

class _FullscreenTimerViewState extends State<_FullscreenTimerView> {
  @override
  void initState() {
    super.initState();
    // Skrij status bar in navigacijo za pravi fullscreen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // Vrni sistemske elemente
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _exitFullscreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    widget.timer.exitFullscreen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {}, // Prepreči naključne kllike
        child: SafeArea(
          child: Stack(
            children: [
              // Glavna vsebina - timer
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Status ikona
                    Icon(
                      widget.timer.isBreak ? Icons.coffee : Icons.psychology,
                      size: 64,
                      color: widget.timer.isBreak 
                          ? Colors.green.shade400 
                          : Colors.purple.shade300,
                    ),
                    const SizedBox(height: 24),
                    
                    // Naslov
                    Text(
                      widget.timer.isBreak ? "ODMOR" : "FOKUS",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w300,
                        color: Colors.white.withOpacity(0.7),
                        letterSpacing: 8,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Veliki časovnik
                    Text(
                      widget.timer.formattedTime,
                      style: const TextStyle(
                        fontSize: 120,
                        fontWeight: FontWeight.w200,
                        color: Colors.white,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 48),
                    
                    // Kontrole
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Pavza / Nadaljuj
                        _FullscreenButton(
                          icon: widget.timer.isRunning 
                              ? Icons.pause_rounded 
                              : Icons.play_arrow_rounded,
                          label: widget.timer.isRunning ? "Pavza" : "Nadaljuj",
                          onTap: () {
                            if (widget.timer.isRunning) {
                              widget.timer.pause();
                            } else {
                              widget.timer.start();
                            }
                          },
                          isPrimary: true,
                        ),
                        const SizedBox(width: 32),
                        // Reset
                        _FullscreenButton(
                          icon: Icons.refresh_rounded,
                          label: "Reset",
                          onTap: () {
                            widget.timer.reset();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Izhod gumb - zgornji desni kot
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white54,
                    size: 32,
                  ),
                  onPressed: _exitFullscreen,
                  tooltip: 'Izhod iz fullscreen',
                ),
              ),
              
              // Motivacijski tekst spodaj
              Positioned(
                bottom: 48,
                left: 0,
                right: 0,
                child: Text(
                  widget.timer.isBreak 
                      ? "Vzemi si zaslužen odmor." 
                      : "Ostani osredotočen. Zmoreš!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FullscreenButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _FullscreenButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isPrimary 
                  ? Colors.white.withOpacity(0.15) 
                  : Colors.white.withOpacity(0.08),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              size: 36,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
