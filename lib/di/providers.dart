// Copyright 2026 KiloVideo. All rights reserved.
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kilovideo/application/use_cases/compress_video_use_case.dart';
import 'package:kilovideo/domain/ports/ffmpeg_runner.dart';
import 'package:kilovideo/domain/ports/video_probe.dart';
import 'package:kilovideo/domain/strategies/compression_strategy.dart';
import 'package:kilovideo/domain/strategies/target_size_strategy.dart';
import 'package:kilovideo/infrastructure/ffmpeg/process_ffmpeg_runner.dart';
import 'package:kilovideo/infrastructure/ffmpeg/process_video_probe.dart';

/// Provider del [FfmpegRunner]. Hoy: sistema. Mañana: AppImage bundled.
final ffmpegRunnerProvider = Provider<FfmpegRunner>((ref) {
  return ProcessFfmpegRunner();
});

/// Provider del [VideoProbe].
final videoProbeProvider = Provider<VideoProbe>((ref) {
  return ProcessVideoProbe();
});

/// Provider del caso de uso.
final compressVideoUseCaseProvider = Provider<CompressVideoUseCase>((ref) {
  return CompressVideoUseCase(
    videoProbe: ref.watch(videoProbeProvider),
    ffmpegRunner: ref.watch(ffmpegRunnerProvider),
  );
});

/// Provider del [CompressionStrategy] actual.
/// La UI lo selecciona y muta. Hoy: hardcoded a TargetSizeStrategy.
final compressionStrategyProvider = StateProvider<CompressionStrategy>((ref) {
  return const TargetSizeStrategy(targetMb: 25.0);
});
