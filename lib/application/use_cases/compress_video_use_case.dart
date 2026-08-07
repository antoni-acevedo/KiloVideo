// Copyright 2026 KiloVideo. All rights reserved.
// SPDX-License-Identifier: MIT

import 'package:kilovideo/domain/entities/video_info.dart';
import 'package:kilovideo/domain/ports/ffmpeg_runner.dart';
import 'package:kilovideo/domain/ports/video_probe.dart';
import 'package:kilovideo/domain/strategies/compression_strategy.dart';
import 'package:kilovideo/domain/strategies/target_size_strategy.dart';
import 'package:kilovideo/infrastructure/ffmpeg/ffmpeg_args_builder.dart';

/// Caso de uso: comprimir un video aplicando una estrategia.
///
/// **Patrón:** Use Case (Clean Architecture).
/// **Por qué:** orquesta tres piezas (probe, strategy, ffmpeg) sin saber
/// cómo se implementan. Es **el eslabón** que la UI llama.
///
/// **Flujo:**
/// 1. `VideoProbe` inspecciona el archivo.
/// 2. `CompressionStrategy` calcula el bitrate objetivo.
/// 3. `FfmpegRunner` ejecuta la compresión.
class CompressVideoUseCase {
  /// Crea el caso de uso con sus dependencias.
  const CompressVideoUseCase({
    required this.videoProbe,
    required this.ffmpegRunner,
  });

  /// Puerto para inspeccionar el video.
  final VideoProbe videoProbe;

  /// Puerto para ejecutar ffmpeg.
  final FfmpegRunner ffmpegRunner;

  /// Comprime el video en [inputPath] usando [strategy].
  ///
  /// Devuelve `FfmpegSuccess` si todo salió bien, `FfmpegFailure` si
  /// ffmpeg falló.
  Future<FfmpegResult> call({
    required String inputPath,
    required CompressionStrategy strategy,
  }) async {
    // 1. Probe: obtener info del video.
    final VideoInfo info = await videoProbe.probe(inputPath);

    // 2. Strategy: calcular bitrate objetivo (de video, sin audio).
    final double targetBitrate = strategy.calculateBitrate(info);

    // 3. Ffmpeg: ejecutar la compresión.
    final List<String> args = _buildArgs(
      inputPath,
      targetBitrate,
      strategy is TargetSizeStrategy
          ? TargetSizeStrategy.audioBitrateKbps
          : 128.0,
    );
    return ffmpegRunner.run(args);
  }

  /// Construye los argumentos de ffmpeg para comprimir al [videoBitrateKbps].
  ///
  /// **Por qué:** encapsular el detalle de flags. Si mañana cambiamos a
  /// libx264 con presets, solo cambia este método.
  List<String> _buildArgs(
    String inputPath,
    double videoBitrateKbps,
    double audioBitrateKbps,
  ) {
    final String outputPath = inputPath.replaceAll('.mp4', '_compressed.mp4');
    return FfmpegArgsBuilder()
        .overwrite()
        .input(inputPath)
        .videoCodec('libx264')
        .videoBitrateKbps(videoBitrateKbps)
        .audioCodec('aac')
        .audioBitrateKbps(audioBitrateKbps)
        .output(outputPath)
        .build();
  }
}
