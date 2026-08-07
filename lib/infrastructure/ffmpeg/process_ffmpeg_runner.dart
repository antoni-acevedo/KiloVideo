// Copyright 2026 KiloVideo. All rights reserved.
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:kilovideo/domain/ports/ffmpeg_runner.dart';

/// Implementación de [FfmpegRunner] que invoca el binario `ffmpeg` del sistema.
///
/// **Patrón:** Adapter + DIP.
/// **Por qué:** el dominio no sabe de `Process`. Esta clase lo hace.
class ProcessFfmpegRunner implements FfmpegRunner {
  /// Crea el runner que invoca `ffmpeg` desde el PATH.
  ProcessFfmpegRunner();

  @override
  Future<FfmpegResult> run(List<String> args) async {
    final result = await Process.run('ffmpeg', args);
    if (result.exitCode == 0) {
      return const FfmpegSuccess();
    }
    return FfmpegFailure(
      exitCode: result.exitCode,
      message: result.stderr.toString(),
    );
  }

  @override
  Stream<double> get progress {
    // Placeholder: emitirá el progreso real parseando stderr de ffmpeg
    // en una iteración futura. Por ahora stream vacío.
    return const Stream<double>.empty();
  }
}
