import 'package:kilovideo/domain/strategies/tarjet_crf_strategy.dart';
import 'package:test/test.dart';
import 'package:kilovideo/domain/entities/video_info.dart';

void main() {
  group('TargetCRFStrategy', () {
    const baseInfo = VideoInfo(
      filePath: '/tmp/test.mp4',
      duration: Duration(minutes: 10),
      originalBitrateKbps: 5000,
      originalSizeMb: 100,
      codec: 'h264',
    );

    group('casos exitosos', () {
      test('CRF=1 sobre 5000 kbps da factor ~1.0', () {
        const strategy = TargetCRFStrategy(tarjetCRF: 1);
        final bitrate = strategy.calculateBitrate(baseInfo);
        // factor = 1.0 - 0 / 19 * 0.9 = 1.0. 5000 * 1.0 = 5000.
        expect(bitrate, closeTo(5000, 0.01));
      });

      test('CRF=20 sobre 5000 kbps da factor ~0.1', () {
        const strategy = TargetCRFStrategy(tarjetCRF: 20);
        final bitrate = strategy.calculateBitrate(baseInfo);
        // factor = 1.0 - 19/19 * 0.9 = 0.1. 5000 * 0.1 = 500.
        expect(bitrate, closeTo(500, 0.01));
      });

      test('CRF=10 sobre 5000 kbps da factor ~0.55', () {
        const strategy = TargetCRFStrategy(tarjetCRF: 10);
        final bitrate = strategy.calculateBitrate(baseInfo);
        // factor = 1.0 - 9/19 * 0.9 ≈ 0.5737. 5000 * 0.5737 ≈ 2868.
        expect(bitrate, closeTo(2868.4, 0.1));
      });

      test('escala con otro originalBitrateKbps', () {
        const highInfo = VideoInfo(
          filePath: '/tmp/test.mp4',
          duration: Duration(minutes: 30),
          originalBitrateKbps: 10000,
          originalSizeMb: 500,
          codec: 'h264',
        );
        const strategy = TargetCRFStrategy(tarjetCRF: 10);
        final bitrate = strategy.calculateBitrate(highInfo);
        // 10000 * 0.5737 ≈ 5737.
        expect(bitrate, closeTo(5736.8, 0.1));
      });

      test('acepta duración mínima (5 segundos)', () {
        const strategy = TargetCRFStrategy(tarjetCRF: 20);
        const minInfo = VideoInfo(
          filePath: '/tmp/short.mp4',
          duration: Duration(seconds: 5),
          originalBitrateKbps: 5000,
          originalSizeMb: 1,
          codec: 'h264',
        );
        expect(strategy.calculateBitrate(minInfo), closeTo(500, 0.01));
      });

      test('acepta duración máxima (4 horas)', () {
        const strategy = TargetCRFStrategy(tarjetCRF: 20);
        const maxInfo = VideoInfo(
          filePath: '/tmp/long.mp4',
          duration: Duration(hours: 4),
          originalBitrateKbps: 5000,
          originalSizeMb: 100,
          codec: 'h264',
        );
        expect(strategy.calculateBitrate(maxInfo), closeTo(500, 0.01));
      });

      test('bitrate siempre menor al original para CRF > 1', () {
        const strategy = TargetCRFStrategy(tarjetCRF: 10);
        final bitrate = strategy.calculateBitrate(baseInfo);
        expect(bitrate, lessThan(5000));
      });
    });

    group('casos de error', () {
      test('Mandar crf negativo', () {
        const strategy = TargetCRFStrategy(tarjetCRF: -10);
        expect(() => strategy.calculateBitrate(baseInfo), throwsArgumentError);
      });
      test('Mandar un valor mayor a 20', () {
        const strategy = TargetCRFStrategy(tarjetCRF: 30);
        expect(() => strategy.calculateBitrate(baseInfo), throwsArgumentError);
      });
      test('Mandar un valor de 0', () {
        const strategy = TargetCRFStrategy(tarjetCRF: 0);
        expect(() => strategy.calculateBitrate(baseInfo), throwsArgumentError);
      });

      test('CRF=21 sobre máximo', () {
        const strategy = TargetCRFStrategy(tarjetCRF: 21);
        expect(() => strategy.calculateBitrate(baseInfo), throwsArgumentError);
      });

      test('duration cero', () {
        const strategy = TargetCRFStrategy(tarjetCRF: 20);
        const zeroInfo = VideoInfo(
          filePath: '/tmp/test.mp4',
          duration: Duration(minutes: 0),
          originalBitrateKbps: 5000,
          originalSizeMb: 100,
          codec: 'h264',
        );
        expect(() => strategy.calculateBitrate(zeroInfo), throwsArgumentError);
      });

      test('Calcular crf con video poco largo', () {
        const strategy = TargetCRFStrategy(tarjetCRF: 20);
        const longInfo = VideoInfo(
          filePath: '/tmp/long.mp4',
          duration: Duration(seconds: 1),
          originalBitrateKbps: 5000,
          originalSizeMb: 100,
          codec: 'h264',
        );
        expect(() => strategy.calculateBitrate(longInfo), throwsArgumentError);
      });

      test('Calcular crf con video super largo', () {
        const strategy = TargetCRFStrategy(tarjetCRF: 20);
        const longInfo = VideoInfo(
          filePath: '/tmp/long.mp4',
          duration: Duration(hours: 10),
          originalBitrateKbps: 5000,
          originalSizeMb: 100,
          codec: 'h264',
        );
        expect(() => strategy.calculateBitrate(longInfo), throwsArgumentError);
      });

      test('Calcular crf con video super pesado', () {
        const strategy = TargetCRFStrategy(tarjetCRF: 20);
        const longInfo = VideoInfo(
          filePath: '/tmp/long.mp4',
          duration: Duration(hours: 1),
          originalBitrateKbps: 9999999,
          originalSizeMb: 99999999,
          codec: 'h264',
        );
        expect(() => strategy.calculateBitrate(longInfo), throwsArgumentError);
      });

      test('Calcular crf con video poco pesado', () {
        const strategy = TargetCRFStrategy(tarjetCRF: 20);
        const longInfo = VideoInfo(
          filePath: '/tmp/long.mp4',
          duration: Duration(hours: 1),
          originalBitrateKbps: 1,
          originalSizeMb: 1,
          codec: 'h264',
        );
        expect(() => strategy.calculateBitrate(longInfo), throwsArgumentError);
      });
    });
  });
}