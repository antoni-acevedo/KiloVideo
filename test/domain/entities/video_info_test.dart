import 'package:test/test.dart';
import 'package:kilovideo/domain/entities/video_info.dart';

void main() {
  group('VideoInfo', () {
    test('dos VideoInfo con los mismos campos son iguales', () {
      const a = VideoInfo(
        filePath: '/tmp/a.mp4',
        duration: Duration(minutes: 5),
        originalBitrateKbps: 5000,
        originalSizeMb: 50,
        codec: 'h264',
      );
      const b = VideoInfo(
        filePath: '/tmp/a.mp4',
        duration: Duration(minutes: 5),
        originalBitrateKbps: 5000,
        originalSizeMb: 50,
        codec: 'h264',
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('dos VideoInfo con campos distintos NO son iguales', () {
      const a = VideoInfo(
        filePath: '/tmp/a.mp4',
        duration: Duration(minutes: 5),
        originalBitrateKbps: 5000,
        originalSizeMb: 50,
        codec: 'h264',
      );
      const b = VideoInfo(
        filePath: '/tmp/b.mp4',
        duration: Duration(minutes: 10),
        originalBitrateKbps: 8000,
        originalSizeMb: 100,
        codec: 'hevc',
      );

      expect(a, isNot(equals(b)));
    });
  });
}
