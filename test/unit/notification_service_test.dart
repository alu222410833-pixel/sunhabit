import 'package:flutter/services.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sunhabit/core/services/reminder_service.dart';
import 'package:sunhabit/core/services/notification_service.dart';
import 'package:sunhabit/features/habits/data/habit_model.dart';

class _FakeNotificationsPlatform extends FlutterLocalNotificationsPlatform {
  @override
  Future<void> show({
    required int id,
    String? title,
    String? body,
    String? payload,
  }) async {}

  @override
  Future<void> cancel({required int id}) async {}
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    FlutterLocalNotificationsPlatform.instance = _FakeNotificationsPlatform();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dexterous.com/flutter/local_notifications'),
      (MethodCall methodCall) async => true,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.gdelataillade.alarm/alarm'),
      (MethodCall methodCall) async => true,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_timezone'),
      (MethodCall methodCall) async => 'UTC',
    );
    SharedPreferences.setMockInitialValues({});
  });

  group('ReminderService', () {
    test('scheduleHabit with no reminders completes without throwing', () {
      expect(
        () => ReminderService.instance.scheduleHabit(
          Habit(id: '1', title: 'T', categoryId: 'health'),
        ),
        returnsNormally,
      );
    });

    test('cancelHabit with no reminders completes without throwing', () {
      expect(
        () => ReminderService.instance.cancelHabit(
          Habit(id: '1', title: 'T', categoryId: 'health'),
        ),
        returnsNormally,
      );
    });

    test('idFor is stable for same inputs', () {
      final habit = Habit(id: 'h1', title: 'T', categoryId: 'health');
      final date = DateTime(2026, 8, 30);
      final id1 = ReminderService.instance.idFor(habit, 0, date);
      final id2 = ReminderService.instance.idFor(habit, 0, date);
      expect(id1, id2);
    });

    test('idFor differs for different habits', () {
      final date = DateTime(2026, 8, 30);
      final id1 = ReminderService.instance.idFor(
        Habit(id: 'h1', title: 'A', categoryId: 'health'),
        0,
        date,
      );
      final id2 = ReminderService.instance.idFor(
        Habit(id: 'h2', title: 'B', categoryId: 'health'),
        0,
        date,
      );
      expect(id1, isNot(id2));
    });

    test('idFor produces positive 31-bit integers', () {
      final habit = Habit(id: 'h_long_hash_test_12345', title: 'A', categoryId: 'health');
      final date = DateTime(2026, 12, 31);
      final id = ReminderService.instance.idFor(habit, 3, date);
      expect(id, greaterThanOrEqualTo(0));
      expect(id, lessThanOrEqualTo(0x7FFFFFFF));
    });
  });

  group('NotificationService', () {
    test('snoozeHabit with missing habit completes without throwing', () {
      expect(
        () => NotificationService.snoozeHabit('missing', 10),
        returnsNormally,
      );
    });
  });
}
