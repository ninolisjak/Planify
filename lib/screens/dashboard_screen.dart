import 'package:flutter/material.dart';
import '../widgets/subject_list.dart';
import '../models/weather.dart';
import '../models/task.dart';
import '../services/weather_service.dart';
import 'flashcard_decks_screen.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';
import 'subjects_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final WeatherService _weatherService = WeatherService();
  
  Weather? _weather;
  bool _isLoadingWeather = true;
  String? _weatherError;
  
  // Mock podatki za danes (lahko zamenjaš z DB)
  List<Task> _todayTasks = [];

  @override
  void initState() {
    super.initState();
    _loadWeather();
    _loadTodayTasks();
  }

  Future<void> _loadWeather() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingWeather = true;
      _weatherError = null;
    });

    try {
      // Uporabi mock podatke za testiranje (zamenjaj z getWeatherByCity ko imaš API ključ)
      final weather = await _weatherService.getMockWeather();
      // Za pravo uporabo:
      // final weather = await _weatherService.getWeatherByCity('Ljubljana');
      if (!mounted) return;
      setState(() {
        _weather = weather;
        _isLoadingWeather = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _weatherError = e.toString();
        _isLoadingWeather = false;
      });
    }
  }

  void _loadTodayTasks() {
    // Uporabi mock podatke - zamenjaj z DB ko bo implementirano
    setState(() {
      _todayTasks = Task.getMockTasks();
      // Za prazno stanje uporabi: _todayTasks = Task.getEmptyTasks();
    });
  }

  void _navigateToSection(String section) {
    // Navigacija glede na sekcijo
    switch (section) {
      case 'Predmeti':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SubjectsScreen()),
        );
        break;
      case 'Roki':
        // TODO: implementiraj DeadlinesScreen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Roki - kmalu na voljo')),
        );
        break;
      case 'Naloge':
        // TODO: implementiraj TasksScreen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Naloge - kmalu na voljo')),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
          
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
                  // zgornja vrstica z datumom in ikonami
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Datum: ${now.day}.${now.month}.${now.year}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.notifications_none,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const NotificationsScreen(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(
                              Icons.settings,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SettingsScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    "Planify",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Tvoj osebni študijski center",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // glavna kartica (lahko odštevanje / motivacija)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFAB47BC),
                          Color(0xFFEF5350),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                "Do naslednjega izpita",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "90 dni",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Ostani na poti do cilja!",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.school,
                          color: Colors.white,
                          size: 48,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // bližnjice
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _HeaderShortcut(
                        icon: Icons.menu_book,
                        label: "Predmeti",
                        onTap: () => _navigateToSection('Predmeti'),
                      ),
                      _HeaderShortcut(
                        icon: Icons.event_note,
                        label: "Roki",
                        onTap: () => _navigateToSection('Roki'),
                      ),
                      _HeaderShortcut(
                        icon: Icons.assignment,
                        label: "Naloge",
                        onTap: () => _navigateToSection('Naloge'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // SPODNJI DEL 
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  children: [
                    
                    // VREME KARTICA
                    _SectionCard(
                      isDark: isDark,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Vreme",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.refresh,
                                    color: isDark ? Colors.white70 : Colors.black54,
                                  ),
                                  onPressed: _loadWeather,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildWeatherContent(isDark),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // DANES KARTICA
                    _SectionCard(
                      isDark: isDark,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Danes",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildTodayContent(isDark),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    
                    _SectionCard(
                      isDark: isDark,
                      child: ListTile(
                        leading: Icon(Icons.style, color: Colors.deepPurple),
                        title: Text(
                          "Flashcards",
                          style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        ),
                        subtitle: Text(
                          "Ustvari in uči se s karticami",
                          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FlashcardDecksScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    
                    _SectionCard(
                      isDark: isDark,
                      child: SizedBox(
                        height: 260,
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: SubjectList(),
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

  Widget _buildWeatherContent(bool isDark) {
    if (_isLoadingWeather) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_weatherError != null) {
      return Column(
        children: [
          Icon(Icons.cloud_off, size: 48, color: isDark ? Colors.white38 : Colors.black38),
          const SizedBox(height: 8),
          Text(
            _weatherError!,
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _loadWeather,
            child: const Text('Poskusi znova'),
          ),
        ],
      );
    }

    if (_weather == null) {
      return Text(
        'Ni podatkov',
        style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
      );
    }

    return Row(
      children: [
        Image.network(
          _weather!.iconUrl,
          width: 64,
          height: 64,
          errorBuilder: (_, __, ___) => Icon(
            Icons.cloud,
            size: 64,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _weather!.cityName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              Text(
                '${_weather!.temperature.toStringAsFixed(1)}°C',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              Text(
                _weather!.description,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.water_drop, size: 16, color: isDark ? Colors.white54 : Colors.black45),
                const SizedBox(width: 4),
                Text(
                  '${_weather!.humidity}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.air, size: 16, color: isDark ? Colors.white54 : Colors.black45),
                const SizedBox(width: 4),
                Text(
                  '${_weather!.windSpeed} m/s',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTodayContent(bool isDark) {
    if (_todayTasks.isEmpty) {
      return Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 48,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
          const SizedBox(height: 8),
          Text(
            'Ni nalog za danes!',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Uživaj v prostem dnevu 🎉',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      );
    }

    return Column(
      children: _todayTasks.map((task) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: task.isCompleted ? Colors.green : Colors.deepPurple,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black,
                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (task.subject != null)
                    Text(
                      task.subject!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }
}

//widget za ikone v headerju
class _HeaderShortcut extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _HeaderShortcut({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}


class _SectionCard extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const _SectionCard({required this.child, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: child,
    );
  }
}
