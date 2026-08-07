import 'package:test/test.dart';
import 'package:kilovideo/application/use_cases/compress_video_use_case.dart';
import 'package:kilovideo/domain/entities/video_info.dart';
import 'package:kilovideo/domain/ports/ffmpeg_runner.dart';
import 'package:kilovideo/domain/ports/video_probe.dart';
import 'package:kilovideo/domain/strategies/target_size_strategy.dart';

/// Stub de `VideoProbe` para tests: devuelve siempre la misma info.
class _StubProbe implements VideoProbe {
  const _StubProbe(this._info);
  final VideoInfo _info;

  @override
  Future<VideoInfo> probe(String path) async => _info;
}

/// Stub de `FfmpegRunner` que captura los argumentos recibidos.
class _StubRunner implements FfmpegRunner {
  final List<String> receivedArgs = <String>[];
  final FfmpegResult result;

  _StubRunner({this.result = const FfmpegSuccess()});

  @override
  Future<FfmpegResult> run(List<String> args) async {
    receivedArgs.addAll(args);
    return result;
  }

  @override
  Stream<double> get progress => const Stream<double>.empty();
}

void main() {
  group('CompressVideoUseCase', () {
    const info = VideoInfo(
      filePath: '/tmp/test.mp4',
      duration: Duration(minutes: 10),
      originalBitrateKbps: 5000,
      originalSizeMb: 100,
      codec: 'h264',
    );

    test('TargetSizeStrategy 30 MB llama ffmpeg con bitrate y audio', () async {
      final probe = _StubProbe(info);
      final runner = _StubRunner();
      final useCase = CompressVideoUseCase(
        videoProbe: probe,
        ffmpegRunner: runner,
      );
      const strategy = TargetSizeStrategy(targetMb: 30.0);

      final result = await useCase(
        inputPath: '/tmp/test.mp4',
        strategy: strategy,
      );

      // 30 MB * 1024 KB * 8 / 600 s = 409.6 kbps total.
      // 409.6 - 64 (audio) = 345.6 kbps video.
      expect(result, isA<FfmpegSuccess>());
      expect(runner.receivedArgs, contains('-b:v'));
      expect(runner.receivedArgs, contains('345.6k'));
      expect(runner.receivedArgs, contains('-b:a'));
      expect(runner.receivedArgs, contains('64.0k'));
      expect(runner.receivedArgs, contains('-c:v'));
      expect(runner.receivedArgs, contains('libx264'));
    });

    test('propaga FfmpegFailure si runner falla', () async {
      final probe = _StubProbe(info);
      final runner = _StubRunner(
        result: const FfmpegFailure(exitCode: 1, message: 'error'),
      );
      final useCase = CompressVideoUseCase(
        videoProbe: probe,
        ffmpegRunner: runner,
      );
      const strategy = TargetSizeStrategy(targetMb: 30.0);

      final result = await useCase(
        inputPath: '/tmp/test.mp4',
        strategy: strategy,
      );

      expect(result, isA<FfmpegFailure>());
    });
  });
}
