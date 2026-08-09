import 'dart:async';

import 'package:test/test.dart';
import 'package:kilovideo/application/use_cases/compress_video_use_case.dart';
import 'package:kilovideo/domain/entities/video_info.dart';
import 'package:kilovideo/domain/ports/ffmpeg_runner.dart';
import 'package:kilovideo/domain/ports/video_probe.dart';
import 'package:kilovideo/domain/strategies/target_percent_strategy.dart';
import 'package:kilovideo/domain/strategies/target_size_strategy.dart';

// ─────────────── Stubs ───────────────

class _StubProbe implements VideoProbe {
  _StubProbe(this._info, {this.shouldThrow = false});
  final VideoInfo _info;
  final bool shouldThrow;

  String? lastProbedPath;
  int probeCalls = 0;

  @override
  Future<VideoInfo> probe(String path) async {
    probeCalls++;
    lastProbedPath = path;
    if (shouldThrow) throw StateError('probe falló');
    return _info;
  }
}

class _StubRunner implements FfmpegRunner {
  _StubRunner({this.result = const FfmpegSuccess()});
  final FfmpegResult result;

  List<String> receivedArgs = <String>[];
  int runCalls = 0;

  @override
  Stream<double> get progress => const Stream<double>.empty();

  @override
  Future<FfmpegResult> run(List<String> args) async {
    runCalls++;
    receivedArgs = args;
    return result;
  }
}

// ─────────────── Helpers ───────────────

const _baseInfo = VideoInfo(
  filePath: '/tmp/movie.mp4',
  duration: Duration(minutes: 10),
  originalBitrateKbps: 5000,
  originalSizeMb: 100,
  codec: 'h264',
);

// ─────────────── Tests ───────────────

void main() {
  group('CompressVideoUseCase', () {
    test('devuelve FfmpegSuccess cuando todo sale bien', () async {
      final probe = _StubProbe(_baseInfo);
      final runner = _StubRunner();
      final useCase = CompressVideoUseCase(
        videoProbe: probe,
        ffmpegRunner: runner,
      );

      final result = await useCase(
        inputPath: '/tmp/movie.mp4',
        strategy: const TargetSizeStrategy(targetMb: 30.0),
      );

      expect(result, isA<FfmpegSuccess>());
      expect(probe.probeCalls, 1);
      expect(probe.lastProbedPath, '/tmp/movie.mp4');
      expect(runner.runCalls, 1);
    });

    test('usa audio 64 kbps para TargetSizeStrategy', () async {
      final probe = _StubProbe(_baseInfo);
      final runner = _StubRunner();
      final useCase = CompressVideoUseCase(
        videoProbe: probe,
        ffmpegRunner: runner,
      );

      await useCase(
        inputPath: '/tmp/movie.mp4',
        strategy: const TargetSizeStrategy(targetMb: 30.0),
      );

      final audioIdx = runner.receivedArgs.indexOf('-b:a');
      expect(audioIdx, isNonNegative);
      expect(runner.receivedArgs[audioIdx + 1], '64.0k');
    });

    test('usa audio 128 kbps para TargetPercentStrategy', () async {
      final probe = _StubProbe(_baseInfo);
      final runner = _StubRunner();
      final useCase = CompressVideoUseCase(
        videoProbe: probe,
        ffmpegRunner: runner,
      );

      await useCase(
        inputPath: '/tmp/movie.mp4',
        strategy: const TargetPercentStrategy(percentCompression: 50),
      );

      final audioIdx = runner.receivedArgs.indexOf('-b:a');
      expect(audioIdx, isNonNegative);
      expect(runner.receivedArgs[audioIdx + 1], '128.0k');
    });

    test('construye outputPath con timestamp y _compressed', () async {
      final probe = _StubProbe(_baseInfo);
      final runner = _StubRunner();
      final useCase = CompressVideoUseCase(
        videoProbe: probe,
        ffmpegRunner: runner,
      );

      await useCase(
        inputPath: '/tmp/movie.mp4',
        strategy: const TargetSizeStrategy(targetMb: 30.0),
      );

      final output = runner.receivedArgs.last;
      // Formato: /tmp/movie_YYYY-MM-DD_HHMMSS_compressed.mp4
      expect(output, matches(RegExp(r'^/tmp/movie_\d{4}-\d{2}-\d{2}_\d{6}_compressed\.mp4$')));
    });

    test('pasa bitrate video calculado por strategy al runner', () async {
      final probe = _StubProbe(_baseInfo);
      final runner = _StubRunner();
      final useCase = CompressVideoUseCase(
        videoProbe: probe,
        ffmpegRunner: runner,
      );

      // 50% de 5000 = 2500 kbps.
      await useCase(
        inputPath: '/tmp/movie.mp4',
        strategy: const TargetPercentStrategy(percentCompression: 50),
      );

      final videoIdx = runner.receivedArgs.indexOf('-b:v');
      expect(runner.receivedArgs[videoIdx + 1], '2500.0k');
    });

    test('pasa bitrate 345.6k con TargetSizeStrategy 30 MB', () async {
      final probe = _StubProbe(_baseInfo);
      final runner = _StubRunner();
      final useCase = CompressVideoUseCase(
        videoProbe: probe,
        ffmpegRunner: runner,
      );

      await useCase(
        inputPath: '/tmp/movie.mp4',
        strategy: const TargetSizeStrategy(targetMb: 30.0),
      );

      final videoIdx = runner.receivedArgs.indexOf('-b:v');
      expect(runner.receivedArgs[videoIdx + 1], '345.6k');
    });

    test('propaga excepción del probe y no llama ffmpeg', () async {
      final probe = _StubProbe(_baseInfo, shouldThrow: true);
      final runner = _StubRunner();
      final useCase = CompressVideoUseCase(
        videoProbe: probe,
        ffmpegRunner: runner,
      );

      await expectLater(
        () => useCase(
          inputPath: '/tmp/movie.mp4',
          strategy: const TargetSizeStrategy(targetMb: 30.0),
        ),
        throwsA(isA<StateError>()),
      );
      expect(runner.runCalls, 0);
    });

    test('propaga ArgumentError del strategy y no llama ffmpeg', () async {
      final probe = _StubProbe(_baseInfo);
      final runner = _StubRunner();
      final useCase = CompressVideoUseCase(
        videoProbe: probe,
        ffmpegRunner: runner,
      );

      await expectLater(
        () => useCase(
          inputPath: '/tmp/movie.mp4',
          strategy: const TargetPercentStrategy(percentCompression: -1),
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(runner.runCalls, 0);
    });

    test('devuelve FfmpegFailure cuando runner falla', () async {
      final probe = _StubProbe(_baseInfo);
      final runner = _StubRunner(
        result: const FfmpegFailure(exitCode: 1, message: 'codec error'),
      );
      final useCase = CompressVideoUseCase(
        videoProbe: probe,
        ffmpegRunner: runner,
      );

      final result = await useCase(
        inputPath: '/tmp/movie.mp4',
        strategy: const TargetSizeStrategy(targetMb: 30.0),
      );

      expect(result, isA<FfmpegFailure>());
      final failure = result as FfmpegFailure;
      expect(failure.exitCode, 1);
      expect(failure.message, 'codec error');
    });
  });
}