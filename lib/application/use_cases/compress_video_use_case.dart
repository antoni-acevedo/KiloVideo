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
  ///
  /// El output se nombra con timestamp para nunca pisar un archivo previo.
  List<String> _buildArgs(
    String inputPath,
    double videoBitrateKbps,
    double audioBitrateKbps,
  ) {
    final String outputPath = _generateOutputPath(inputPath);
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

  /// Genera una ruta de output con timestamp para no pisar archivos previos.
  ///
  /// `movie.mp4` → `movie_2026-08-08_103045_compressed.mp4`.
  /// `video` → `video_2026-08-08_103045_compressed`.
  String _generateOutputPath(String inputPath) {
    final now = DateTime.now();
    final stamp =
        '${now.year}-${_pad(now.month)}-${_pad(now.day)}_'
        '${_pad(now.hour)}${_pad(now.minute)}${_pad(now.second)}';
    final dotIdx = inputPath.lastIndexOf('.');
    if (dotIdx <= 0) {
      return '${inputPath}_${stamp}_compressed';
    }
    final base = inputPath.substring(0, dotIdx);
    final ext = inputPath.substring(dotIdx);
    return '${base}_${stamp}_compressed$ext';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}
