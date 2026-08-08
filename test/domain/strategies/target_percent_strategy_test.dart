import 'package:test/test.dart';
import 'package:kilovideo/domain/entities/video_info.dart';
import 'package:kilovideo/domain/strategies/target_percent_strategy.dart';

void main() {
  group('TargetPercentStrategy', () {
    const baseInfo = VideoInfo(
      filePath: '/tmp/test.mp4',
      duration: Duration(minutes: 10),
      originalBitrateKbps: 5000,
      originalSizeMb: 100,
      codec: 'h264',
    );

    group('casos exitosos', () {
      test('calcula 20% de 5000 kbps → 1000 kbps', () {
        const strategy = TargetPercentStrategy(percentCompression: 20);
        final bitrate = strategy.calculateBitrate(baseInfo);
        expect(bitrate, closeTo(1000, 0.01));
      });

      test('calcula 50% de 5000 kbps → 2500 kbps', () {
        const strategy = TargetPercentStrategy(percentCompression: 50);
        final bitrate = strategy.calculateBitrate(baseInfo);
        expect(bitrate, closeTo(2500, 0.01));
      });

      test('calcula 80% de 5000 kbps → 4000 kbps', () {
        const strategy = TargetPercentStrategy(percentCompression: 80);
        final bitrate = strategy.calculateBitrate(baseInfo);
        expect(bitrate, closeTo(4000, 0.01));
      });

      test('acepta el mínimo válido (2%)', () {
        const strategy = TargetPercentStrategy(percentCompression: 2);
        final bitrate = strategy.calculateBitrate(baseInfo);
        // 5000 * 2 / 100 = 100 kbps.
        expect(bitrate, closeTo(100, 0.01));
      });

      test('acepta el máximo válido (100%)', () {
        const strategy = TargetPercentStrategy(percentCompression: 100);
        final bitrate = strategy.calculateBitrate(baseInfo);
        // 5000 * 100 / 100 = 5000 kbps.
        expect(bitrate, closeTo(5000, 0.01));
      });

      test('escala con distintos originalBitrateKbps', () {
        const highInfo = VideoInfo(
          filePath: '/tmp/test.mp4',
          duration: Duration(minutes: 10),
          originalBitrateKbps: 10000,
          originalSizeMb: 200,
          codec: 'h264',
        );
        const strategy = TargetPercentStrategy(percentCompression: 30);
        final bitrate = strategy.calculateBitrate(highInfo);
        // 10000 * 30 / 100 = 3000 kbps.
        expect(bitrate, closeTo(3000, 0.01));
      });
    });

    group('casos de error', () {
      test('lanza ArgumentError si percentCompression es negativo', () {
        const strategy = TargetPercentStrategy(percentCompression: -20);
        expect(
          () => strategy.calculateBitrate(baseInfo),
          throwsArgumentError,
        );
      });

      test('lanza ArgumentError si percentCompression es 0', () {
        const strategy = TargetPercentStrategy(percentCompression: 0);
        expect(
          () => strategy.calculateBitrate(baseInfo),
          throwsArgumentError,
        );
      });

      test('lanza ArgumentError si percentCompression es 1 (bajo mínimo)', () {
        const strategy = TargetPercentStrategy(percentCompression: 1);
        expect(
          () => strategy.calculateBitrate(baseInfo),
          throwsArgumentError,
        );
      });

      test('lanza ArgumentError si percentCompression es 101 (sobre máximo)', () {
        const strategy = TargetPercentStrategy(percentCompression: 101);
        expect(
          () => strategy.calculateBitrate(baseInfo),
          throwsArgumentError,
        );
      });

      test('lanza ArgumentError si percentCompression es 200', () {
        const strategy = TargetPercentStrategy(percentCompression: 200);
        expect(
          () => strategy.calculateBitrate(baseInfo),
          throwsArgumentError,
        );
      });
    });
  });
}