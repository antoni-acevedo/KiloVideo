// Copyright 2026 KiloVideo. All rights reserved.
// SPDX-License-Identifier: MIT

/// Información de un video de entrada, obtenida al "probe" (inspeccionar)
/// el archivo con `ffmpeg -i ruta`.
///
/// **Patrón:** Entity (DDD).
/// **Por qué:** representa un concepto del dominio (el video) con identidad
/// por valor. Compartir entre capas sin acoplar a `dart:io`.
class VideoInfo {
  /// Crea la información inmutable de un video.
  const VideoInfo({
    required this.filePath,
    required this.duration,
    required this.originalBitrateKbps,
    required this.originalSizeMb,
    required this.codec,
  });

  /// Ruta absoluta del archivo en disco.
  final String filePath;

  /// Duración del video.
  final Duration duration;

  /// Bitrate promedio de video en kbps (obtenido del probe).
  final double originalBitrateKbps;

  /// Tamaño del archivo en MB.
  final double originalSizeMb;

  /// Codec de video (ej: 'h264', 'hevc', 'vp9').
  final String codec;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoInfo &&
          other.filePath == filePath &&
          other.duration == duration &&
          other.originalBitrateKbps == originalBitrateKbps &&
          other.originalSizeMb == originalSizeMb &&
          other.codec == codec;

  @override
  int get hashCode => Object.hash(
        filePath,
        duration,
        originalBitrateKbps,
        originalSizeMb,
        codec,
      );

  @override
  String toString() => 'VideoInfo($filePath, $duration, $codec)';
}
