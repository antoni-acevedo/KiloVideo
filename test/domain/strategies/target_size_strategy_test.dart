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

    group('casos exitosos', () {
      test('calcula bitrate para 10 min apuntando a 30 MB', () {
        const strategy = TargetSizeStrategy(targetMb: 30.0);
        final bitrate = strategy.calculateBitrate(baseInfo);
        // 30 MB * 1024 KB * 8 / 600 s = 409.6 kbps total.
        // 409.6 - 64 (audio) = 345.6 kbps video.
        expect(bitrate, closeTo(345.6, 0.01));
      });

      test('calcula bitrate para 10 min apuntando a 50 MB', () {
        const strategy = TargetSizeStrategy(targetMb: 50.0);
        final bitrate = strategy.calculateBitrate(baseInfo);
        // 50 MB * 1024 * 8 / 600 = 682.67 kbps total.
        // 682.67 - 64 = 618.67 kbps video.
        expect(bitrate, closeTo(618.67, 0.01));
      });

      test('calcula bitrate para 10 min apuntando a 100 MB', () {
        const strategy = TargetSizeStrategy(targetMb: 100.0);
        final bitrate = strategy.calculateBitrate(baseInfo);
        // 100 MB * 1024 * 8 / 600 = 1365.33 kbps total.
        // 1365.33 - 64 = 1301.33 kbps video.
        expect(bitrate, closeTo(1301.33, 0.01));
      });

      test('calcula bitrate para 1 min apuntando a 2 MB', () {
        const strategy = TargetSizeStrategy(targetMb: 2.0);
        const shortInfo = VideoInfo(
          filePath: '/tmp/short.mp4',
          duration: Duration(minutes: 1),
          originalBitrateKbps: 5000,
          originalSizeMb: 100,
          codec: 'h264',
        );
        final bitrate = strategy.calculateBitrate(shortInfo);
        // 2 MB * 1024 * 8 / 60 = 273.07 kbps total.
        // 273.07 - 64 = 209.07 kbps video.
        expect(bitrate, closeTo(209.07, 0.01));
      });

      test('bitrate respeta minVideoBitrateKbps en borde inferior', () {
        // 10 min * (100 kbps video + 64 kbps audio) * 600 s / 8 / 1024.
        // = 12.01 MB mínimo exacto. Usamos 13 MB para estar seguros.
        const strategy = TargetSizeStrategy(targetMb: 13.0);
        final bitrate = strategy.calculateBitrate(baseInfo);
        // 13 * 1024 * 8 / 600 = 177.49 kbps total - 64 audio = 113.49 video.
        expect(bitrate, greaterThanOrEqualTo(100.0));
      });
    });

    group('casos de error', () {
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

      test('lanza ArgumentError si duration es negativa', () {
        const strategy = TargetSizeStrategy(targetMb: 30.0);
        const negativeInfo = VideoInfo(
          filePath: '/tmp/test.mp4',
          duration: Duration(seconds: -1),
          originalBitrateKbps: 5000,
          originalSizeMb: 100,
          codec: 'h264',
        );
        expect(
          () => strategy.calculateBitrate(negativeInfo),
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

      test('lanza ArgumentError si targetMb es negativo', () {
        const strategy = TargetSizeStrategy(targetMb: -5.0);
        expect(
          () => strategy.calculateBitrate(baseInfo),
          throwsArgumentError,
        );
      });

      test('lanza ArgumentError si targetMb es demasiado pequeño', () {
        // 10 min * 100 kbps video + 64 kbps audio = 12 MB mínimo.
        // Pedir 1 MB debe fallar.
        const strategy = TargetSizeStrategy(targetMb: 1.0);
        expect(
          () => strategy.calculateBitrate(baseInfo),
          throwsArgumentError,
        );
      });

      test('lanza ArgumentError si targetMb justo debajo del mínimo', () {
        // 11.99 MB está debajo de 12 MB mínimo.
        const strategy = TargetSizeStrategy(targetMb: 11.99);
        expect(
          () => strategy.calculateBitrate(baseInfo),
          throwsArgumentError,
        );
      });
    });
  });
}