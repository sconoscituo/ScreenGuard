import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScreenGuard Tests', () {
    test('Usage time formatting', () {
      // 초를 h:mm 형식으로 변환 테스트
      String formatDuration(int seconds) {
        final h = seconds ~/ 3600;
        final m = (seconds % 3600) ~/ 60;
        return h > 0 ? '${h}h ${m}m' : '${m}m';
      }
      expect(formatDuration(3661), '1h 1m');
      expect(formatDuration(120), '2m');
      expect(formatDuration(7200), '2h 0m');
    });

    test('Limit exceeded check', () {
      bool isExceeded(int usedSeconds, int limitSeconds) {
        return usedSeconds >= limitSeconds;
      }
      expect(isExceeded(3700, 3600), true);
      expect(isExceeded(1800, 3600), false);
    });
  });
}
