import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sunhabit/core/services/audio_service.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('AudioService', () {
    test('is a ChangeNotifier', () {
      expect(AudioService(), isA<ChangeNotifier>());
    });

    test('initial state is idle', () {
      final service = AudioService();
      expect(service.isPlaying, false);
      expect(service.elapsedSeconds, 0);
      expect(service.durationSeconds, 0);
      expect(service.mediaDurationSeconds, 0);
    });

    test('notifies listeners when play state changes', () async {
      final service = AudioService();
      var count = 0;
      service.addListener(() => count++);

      // Call stop from idle state to trigger a notification.
      await service.stop();
      expect(count, greaterThan(0));
      expect(service.isPlaying, false);
      expect(service.elapsedSeconds, 0);
    });

    test('unload resets media duration and notifies listeners', () {
      final service = AudioService();
      var count = 0;
      service.addListener(() => count++);

      service.unload();
      expect(service.mediaDurationSeconds, 0);
      expect(count, greaterThan(0));
    });
  });
}
