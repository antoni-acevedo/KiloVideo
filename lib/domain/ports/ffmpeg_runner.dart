// Copyright 2026 KiloVideo. All rights reserved.
// SPDX-License-Identifier: MIT

/// Resultado de ejecutar ffmpeg.
///
/// **Patrón:** Sealed class.
sealed class FfmpegResult {
  /// Constructor base.
  const FfmpegResult();
}

/// ffmpeg terminó con éxito.
class FfmpegSuccess extends FfmpegResult {
  /// Crea un resultado exitoso.
  const FfmpegSuccess();
}

/// ffmpeg terminó con error.
class FfmpegFailure extends FfmpegResult {
  /// Crea un resultado de fallo.
  ///
  /// [exitCode] es el código de salida del proceso. [message] es
  /// el stderr capturado.
  const FfmpegFailure({required this.exitCode, required this.message});

  /// Código de salida del proceso ffmpeg.
  final int exitCode;

  /// Mensaje de stderr.
  final String message;
}

/// Contrato para ejecutar ffmpeg.
///
/// **Patrón:** Port (DIP) + Observer (GoF).
/// **Por qué:** el dominio no sabe cómo se invoca ffmpeg. Solo conoce
/// la interfaz. La implementación en `infrastructure/` decide si usa
/// `Process`, un binario bundled, o un mock.
abstract interface class FfmpegRunner {
  /// Ejecuta ffmpeg con los argumentos [args] y devuelve el resultado.
  Future<FfmpegResult> run(List<String> args);

  /// Stream de progreso de la codificación (0.0 a 1.0).
  ///
  /// La UI lo consume con un `StreamProvider` de Riverpod.
  Stream<double> get progress;
}
