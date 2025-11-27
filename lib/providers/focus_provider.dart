import 'package:flutter/material.dart';

class FocusProvider extends ChangeNotifier {
  DateTime? _startTime;
  bool get isRunning => _startTime != null;

  DateTime? get startTime => _startTime;

  void start() {
    _startTime = DateTime.now();
    notifyListeners();
  }

  Duration? stop() {
    if (_startTime == null) return null;
    final duration = DateTime.now().difference(_startTime!);
    _startTime = null;
    notifyListeners();
    return duration;
  }
}