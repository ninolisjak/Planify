import 'dart:async';
import 'package:flutter/foundation.dart';

class FocusProvider extends ChangeNotifier {
  // dolžine faz
  static const int workMinutes = 25;
  static const int breakMinutes = 5;

  // TAKOJ inicializiramo
  int _remainingSeconds = workMinutes * 60;
  bool _isRunning = false;
  bool _isBreak = false; // false = fokus, true = odmor
  bool _isFullscreen = false; // za fullscreen način
  Timer? _timer;

  bool get isRunning => _isRunning;
  bool get isBreak => _isBreak;
  bool get isFullscreen => _isFullscreen;
  int get remainingSeconds => _remainingSeconds;

  String get formattedTime {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _startTimer() {
    _timer?.cancel();
    _isRunning = true;
    _isFullscreen = true; // Vstopi v fullscreen ko začneš

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        // faza končana
        _timer?.cancel();
        _isRunning = false;
        _isFullscreen = false; // Izhod iz fullscreen

        if (!_isBreak) {
          // končan fokus -> odmor
          _isBreak = true;
          _remainingSeconds = breakMinutes * 60;
        } else {
          // končan odmor -> spet fokus
          _isBreak = false;
          _remainingSeconds = workMinutes * 60;
        }
        notifyListeners();
      }
    });

    notifyListeners();
  }

  void start() {
    if (_isRunning) return;
    _startTimer();
  }

  void pause() {
    _timer?.cancel();
    _isRunning = false;
    // NE izhodi iz fullscreen pri pavzi
    notifyListeners();
  }

  void exitFullscreen() {
    _isFullscreen = false;
    notifyListeners();
  }

  void enterFullscreen() {
    if (_isRunning) {
      _isFullscreen = true;
      notifyListeners();
    }
  }

  void reset() {
    _timer?.cancel();
    _isRunning = false;
    _isBreak = false;
    _isFullscreen = false;
    _remainingSeconds = workMinutes * 60;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
