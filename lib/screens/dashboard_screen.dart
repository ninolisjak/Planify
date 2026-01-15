import 'package:flutter/material.dart';
import '../widgets/subject_list.dart';
import '../models/weather.dart';
import '../services/weather_service.dart';
import '../services/db_service.dart';
import '../services/notification_service.dart';
import 'flashcard_decks_screen.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';
import 'subjects_screen.dart';
import 'deadlines_screen.dart';
import 'tasks_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final WeatherService _weatherService = WeatherService();
  final DBService _dbService = DBService();
  final NotificationService _notificationService = NotificationService();
  
  Weather? _weather;
  bool _isLoadingWeather = true;
  String? _weatherError;
  
  // Naloge za danes iz baze
  List<Map<String, dynamic>> _todayTasks = [];
  List<Map<String, dynamic>> _subjects = [];
  
  // Izpitni roki
  int? _daysToNextExam;
  String? _nextExamSubject;
  
  // Neprebrana obvestila
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _loadWeather();
    _loadTodayTasks();
    _loadNextExam();
    _loadUnreadCount();
    _checkUpcomingReminders();
  }
  
  /// Preveri prihajajoče roke in naloge ter ustvari obvestila
  Future<void> _checkUpcomingReminders() async {
    await _notificationService.checkUpcomingDeadlines();
    await _notificationService.checkUpcomingTasks();
  }
  
  Future<void> _loadUnreadCount() async {
    final count = await _notificationService.getUnreadCount();
    if (mounted) {
      setState(() {
        _unreadNotifications = count;
      });
    }
  }

  Future<void> _loadNextExam() async {
    try {
      await _dbService.createExamDeadlinesTable();
      final deadlines = await _dbService.getUpcomingExamDeadlines();
      if (!mounted) return;
      
      if (deadlines.isNotEmpty) {
        final nextExam = deadlines.first;
        final examDate = DateTime.parse(nextExam['exam_date'] as String);
        final now = DateTime.now();
        final difference = examDate.difference(now).inDays;
        
        setState(() {
          _daysToNextExam = difference < 0 ? 0 : difference;
          _nextExamSubject = nextExam['subject_name'] as String?;
        });
      } else {
        setState(() {
          _daysToNextExam = null;
          _nextExamSubject = null;
        });
      }
    } catch (e) {
      // Ignoriramo napake, pustimo placeholder
    }
  }

  Future<void> _loadWeather() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingWeather = true;
      _weatherError = null;
    });

    try {
      // Pridobi pravo vreme iz OpenWeather API
      final weather = await _weatherService.getWeatherByCity('Maribor');
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

  Future<void> _loadTodayTasks() async {
    try {
      final allTasks = await _dbService.getAllTasks();
      final subjects = await _dbService.getAllSubjects();
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      
      // Filtriraj naloge za danes (nedokončane in z rokom danes)
      final todayTasks = allTasks.where((task) {
        if ((task['is_completed'] ?? 0) == 1) return false;
        final dueDate = DateTime.parse(task['due_date']);
        final dueDateOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
        return dueDateOnly.isAtSameMomentAs(today) || dueDateOnly.isBefore(today);
      }).toList();
      
      if (!mounted) return;
      setState(() {
        _todayTasks = todayTasks;
        _subjects = subjects;
      });
    } catch (e) {
      // Ignoriramo napake
    }
  }
  
  String _getSubjectName(int? subjectId) {
    if (subjectId == null) return '';
    final subject = _subjects.firstWhere(
      (s) => s['id'] == subjectId,
      orElse: () => {},
    );
    return subject['name'] ?? '';
  }
  
  Color _getSubjectColor(int? subjectId) {
    if (subjectId == null) return Colors.deepPurple;
    final subject = _subjects.firstWhere(
      (s) => s['id'] == subjectId,
      orElse: () => {},
    );
    final colorHex = subject['color'];
    if (colorHex == null) return Colors.deepPurple;
    try {
      return Color(int.parse(colorHex.toString().replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.deepPurple;
    }
  }

  void _navigateToSection(String section) {
    // Navigacija glede na sekcijo
    switch (section) {
      case 'Predmeti':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SubjectsScreen()),
        ).then((_) => _refreshData());
        break;
      case 'Roki':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DeadlinesScreen()),
        ).then((_) => _refreshData());
        break;
      case 'Naloge':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TasksScreen()),
        ).then((_) => _refreshData());
        break;
    }
  }

  void _refreshData() {
    _loadTodayTasks();
    _loadNextExam();
    _loadUnreadCount();
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
                          Stack(
                            children: [
                              IconButton(
                                icon: Icon(
                                  _unreadNotifications > 0 
                                    ? Icons.notifications 
                                    : Icons.notifications_none,
                                  color: Colors.white,
                                ),
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const NotificationsScreen(),
                                    ),
                                  );
                                  // Osveži število neprebranih po vrnitvi
                                  _loadUnreadCount();
                                },
                              ),
                              if (_unreadNotifications > 0)
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    child: Text(
                                      _unreadNotifications > 9 
                                        ? '9+' 
                                        : '$_unreadNotifications',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 4),
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
                            children: [
                              Text(
                                _nextExamSubject != null
                                    ? "Do izpita: $_nextExamSubject"
                                    : "Do naslednjega izpita",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _daysToNextExam != null
                                    ? _daysToNextExam == 0
                                        ? "DANES!"
                                        : _daysToNextExam == 1
                                            ? "1 dan"
                                            : "$_daysToNextExam dni"
                                    : "Ni rokov",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _daysToNextExam != null
                                    ? _daysToNextExam! <= 3
                                        ? "Čas je za intenzivno učenje!"
                                        : _daysToNextExam! <= 7
                                            ? "Pripravi se na izpit!"
                                            : "Ostani na poti do cilja!"
                                    : "Dodaj izpitne roke",
                                style: const TextStyle(
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
                          ).then((_) => _refreshData());
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
      children: _todayTasks.take(5).map((task) {
        final subjectName = _getSubjectName(task['subject_id']);
        final subjectColor = _getSubjectColor(task['subject_id']);
        final dueDate = DateTime.parse(task['due_date']);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final isOverdue = DateTime(dueDate.year, dueDate.month, dueDate.day).isBefore(today);
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isOverdue ? Colors.red : subjectColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task['title'] ?? 'Brez naslova',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isOverdue)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Zamujeno',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (subjectName.isNotEmpty)
                      Text(
                        subjectName,
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
        );
      }).toList(),
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
