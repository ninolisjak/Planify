import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

class CalendarService {
  static final CalendarService _instance = CalendarService._internal();
  factory CalendarService() => _instance;
  CalendarService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      calendar.CalendarApi.calendarScope,
    ],
    serverClientId: '110517099884-dvt7ndjtps59n3uhhpvav20cukcd5vfr.apps.googleusercontent.com',
  );

  calendar.CalendarApi? _calendarApi;
  bool _isInitialized = false;

  bool get isConnected => _isInitialized && _calendarApi != null;

  /// Inicializira Calendar API z obstoječo Google prijavo
  Future<bool> initialize() async {
    try {
      // Preveri če je uporabnik že prijavljen
      GoogleSignInAccount? account = _googleSignIn.currentUser;
      
      if (account == null) {
        // Poskusi tiho prijavo
        account = await _googleSignIn.signInSilently();
      }

      if (account == null) {
        print('CalendarService: Uporabnik ni prijavljen z Google');
        return false;
      }

      // Pridobi HTTP klienta z avtentikacijo
      final httpClient = await _googleSignIn.authenticatedClient();
      
      if (httpClient == null) {
        print('CalendarService: Ni mogoče pridobiti HTTP klienta');
        return false;
      }

      _calendarApi = calendar.CalendarApi(httpClient);
      _isInitialized = true;
      print('CalendarService: Uspešno inicializiran');
      return true;
    } catch (e) {
      print('CalendarService: Napaka pri inicializaciji: $e');
      return false;
    }
  }

  /// Prijava z Google in Calendar scope
  Future<bool> signInWithCalendar() async {
    try {
      final account = await _googleSignIn.signIn();
      
      if (account == null) {
        return false;
      }

      final httpClient = await _googleSignIn.authenticatedClient();
      
      if (httpClient == null) {
        return false;
      }

      _calendarApi = calendar.CalendarApi(httpClient);
      _isInitialized = true;
      return true;
    } catch (e) {
      print('CalendarService: Napaka pri prijavi: $e');
      return false;
    }
  }

  /// Dodaj izpitni rok v Google Calendar
  Future<String?> addDeadlineToCalendar({
    required String title,
    required String subjectName,
    required DateTime dateTime,
    String? description,
    int reminderMinutes = 1440, // 24 ur prej
  }) async {
    if (_calendarApi == null) {
      final initialized = await initialize();
      if (!initialized) return null;
    }

    try {
      final event = calendar.Event()
        ..summary = '📚 $subjectName: $title'
        ..description = description ?? 'Izpitni rok iz aplikacije Planify'
        ..start = calendar.EventDateTime(
          dateTime: dateTime,
          timeZone: 'Europe/Ljubljana',
        )
        ..end = calendar.EventDateTime(
          dateTime: dateTime.add(const Duration(hours: 2)),
          timeZone: 'Europe/Ljubljana',
        )
        ..reminders = calendar.EventReminders(
          useDefault: false,
          overrides: [
            calendar.EventReminder(method: 'popup', minutes: reminderMinutes),
            calendar.EventReminder(method: 'popup', minutes: 60), // 1 ura prej
            calendar.EventReminder(method: 'email', minutes: 1440), // 1 dan prej
          ],
        );

      final createdEvent = await _calendarApi!.events.insert(event, 'primary');
      print('CalendarService: Dodan dogodek: ${createdEvent.id}');
      return createdEvent.id;
    } catch (e) {
      print('CalendarService: Napaka pri dodajanju dogodka: $e');
      return null;
    }
  }

  /// Dodaj nalogo v Google Calendar
  Future<String?> addTaskToCalendar({
    required String taskTitle,
    required String subjectName,
    required DateTime dueDate,
    String? description,
    int reminderMinutes = 1440,
  }) async {
    if (_calendarApi == null) {
      final initialized = await initialize();
      if (!initialized) return null;
    }

    try {
      // Za celodnevni dogodek uporabimo datum brez časa
      final startOfDay = DateTime(dueDate.year, dueDate.month, dueDate.day, 9, 0);
      final endOfDay = DateTime(dueDate.year, dueDate.month, dueDate.day, 10, 0);
      
      final event = calendar.Event()
        ..summary = '📝 Naloga: $taskTitle ($subjectName)'
        ..description = description ?? 'Naloga iz aplikacije Planify'
        ..start = calendar.EventDateTime(
          dateTime: startOfDay,
          timeZone: 'Europe/Ljubljana',
        )
        ..end = calendar.EventDateTime(
          dateTime: endOfDay,
          timeZone: 'Europe/Ljubljana',
        )
        ..reminders = calendar.EventReminders(
          useDefault: false,
          overrides: [
            calendar.EventReminder(method: 'popup', minutes: reminderMinutes),
          ],
        );

      final createdEvent = await _calendarApi!.events.insert(event, 'primary');
      print('CalendarService: Dodana naloga: ${createdEvent.id}');
      return createdEvent.id;
    } catch (e) {
      print('CalendarService: Napaka pri dodajanju naloge: $e');
      return null;
    }
  }

  /// Posodobi dogodek v Google Calendar
  Future<bool> updateCalendarEvent({
    required String eventId,
    String? title,
    DateTime? dateTime,
    String? description,
  }) async {
    if (_calendarApi == null) {
      final initialized = await initialize();
      if (!initialized) return false;
    }

    try {
      // Pridobi obstoječi dogodek
      final existingEvent = await _calendarApi!.events.get('primary', eventId);
      
      if (title != null) {
        existingEvent.summary = title;
      }
      
      if (dateTime != null) {
        existingEvent.start = calendar.EventDateTime(
          dateTime: dateTime,
          timeZone: 'Europe/Ljubljana',
        );
        existingEvent.end = calendar.EventDateTime(
          dateTime: dateTime.add(const Duration(hours: 2)),
          timeZone: 'Europe/Ljubljana',
        );
      }
      
      if (description != null) {
        existingEvent.description = description;
      }

      await _calendarApi!.events.update(existingEvent, 'primary', eventId);
      print('CalendarService: Posodobljen dogodek: $eventId');
      return true;
    } catch (e) {
      print('CalendarService: Napaka pri posodabljanju: $e');
      return false;
    }
  }

  /// Izbriši dogodek iz Google Calendar
  Future<bool> deleteCalendarEvent(String eventId) async {
    if (_calendarApi == null) {
      final initialized = await initialize();
      if (!initialized) return false;
    }

    try {
      await _calendarApi!.events.delete('primary', eventId);
      print('CalendarService: Izbrisan dogodek: $eventId');
      return true;
    } catch (e) {
      print('CalendarService: Napaka pri brisanju: $e');
      return false;
    }
  }

  /// Pridobi vse dogodke iz Planify v določenem obdobju
  Future<List<calendar.Event>> getPlanifyEvents({
    DateTime? timeMin,
    DateTime? timeMax,
  }) async {
    if (_calendarApi == null) {
      final initialized = await initialize();
      if (!initialized) return [];
    }

    try {
      final events = await _calendarApi!.events.list(
        'primary',
        timeMin: timeMin?.toUtc(),
        timeMax: timeMax?.toUtc(),
        q: 'Planify', // Išči samo Planify dogodke
        singleEvents: true,
        orderBy: 'startTime',
      );

      return events.items ?? [];
    } catch (e) {
      print('CalendarService: Napaka pri pridobivanju dogodkov: $e');
      return [];
    }
  }

  /// Odjava
  Future<void> signOut() async {
    _calendarApi = null;
    _isInitialized = false;
  }
}
