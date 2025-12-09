import 'dart:async';
import '../data/databases/database_helper.dart';

import 'email_service.dart';
import '../data/models/event.dart';


class EventReminderService {
  static final EventReminderService instance = EventReminderService._init();
  EventReminderService._init();

  Timer? _reminderTimer;
  final Set<String> _sentReminders = {}; // Track sent reminders to avoid duplicates

  // Start the reminder service - call this in main.dart after app initialization
  void startReminderService() {
    // Check every 6 hours for events needing reminders
    _reminderTimer = Timer.periodic(const Duration(hours: 6), (timer) {
      _checkAndSendReminders();
    });
    
    // Also check immediately on start
    _checkAndSendReminders();
  }

  Future<void> _checkAndSendReminders() async {
    try {
      final db = DatabaseHelper.instance;
      final eventsNeedingReminders = await db.getEventsNeedingReminders();
      
      for (var eventData in eventsNeedingReminders) {
        final event = eventData['event'] as Event;
        final userEmail = eventData['userEmail'] as String;
        final userName = eventData['userName'] as String;
        
        // Create unique key to avoid sending duplicate reminders
        final reminderKey = '${event.id}_$userEmail';
        
        if (!_sentReminders.contains(reminderKey)) {
          await EmailService.instance.sendEventReminderEmail(
            userEmail,
            userName,
            event.title,
            event.date,
            event.location,
            event.locationAddress,
          );
          
          _sentReminders.add(reminderKey);
          print('✅ Reminder sent to $userName ($userEmail) for event: ${event.title}');
        }
      }
    } catch (e) {
      print('❌ Error checking reminders: $e');
    }
  }

  void stopReminderService() {
    _reminderTimer?.cancel();
    _reminderTimer = null;
  }

  // Clear sent reminders cache (call this daily to allow reminders for new events)
  void clearSentReminders() {
    _sentReminders.clear();
  }
}