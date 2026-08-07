import 'package:test/test.dart';
import 'package:kilovideo/domain/entities/video_info.dart';
import 'package:kilovideo/domain/strategies/target_size_strategy.dart';

void main() {
  group('TargetSizeStrategy', () {
    const baseInfo = VideoInfo(
      filePath: '/tmp/test.mp4',
      duration: Duration(minutes: 10),
      originalBitrateKbps: 5000,
      originalSizeMb: 100,
      codec: 'h264',
    );

    test('calcula el bitrate de video para 10 min apuntando a 30 MB', () {
      const strategy = TargetSizeStrategy(targetMb: 30.0);
      final bitrate = strategy.calculateBitrate(baseInfo);
      // 30 MB * 1024 KB * 8 / 600 s = 409.6 kbps total.
      // 409.6 - 64 (audio) = 345.6 kbps video.
      expect(bitrate, closeTo(345.6, 0.01));
    });

    test('lanza ArgumentError si duration es zero', () {
      const strategy = TargetSizeStrategy(targetMb: 30.0);
      const zeroInfo = VideoInfo(
        filePath: '/tmp/test.mp4',
        duration: Duration(minutes: 0),
        originalBitrateKbps: 5000,
        originalSizeMb: 100,
        codec: 'h264',
      );
      expect(
        () => strategy.calculateBitrate(zeroInfo),
        throwsArgumentError,
      );
    });

    test('lanza ArgumentError si targetMb es 0', () {
      const strategy = TargetSizeStrategy(targetMb: 0);
      expect(
        () => strategy.calculateBitrate(baseInfo),
        throwsArgumentError,
      );
    });

    test('lanza ArgumentError si target es demasiado pequeño', () {
      // 10 min * 100 kbps video + 64 kbps audio = 164 kbps total.
      // 164 kbps * 600 s / 8 / 1024 = 12 MB mínimo.
      // Pedir 1 MB debe fallar.
      const strategy = TargetSizeStrategy(targetMb: 1.0);
      expect(
        () => strategy.calculateBitrate(baseInfo),
        throwsArgumentError,
      );
    });
  });
}
