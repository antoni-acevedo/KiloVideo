// Copyright 2026 KiloVideo. All rights reserved.
// SPDX-License-Identifier: MIT

/// Construye los argumentos de ffmpeg para comprimir un video.
///
/// **Patrón:** Builder (GoF).
/// **Por qué:** armar listas de args a mano es verboso y propenso a errores.
/// Esta clase encapsula los detalles de flags de ffmpeg.
class FfmpegArgsBuilder {
  /// Crea un constructor vacío.
  FfmpegArgsBuilder();

  final List<String> _args = [];

  /// Input: archivo de origen.
  FfmpegArgsBuilder input(String path) {
    _args.addAll(['-i', path]);
    return this;
  }

  /// Bitrate de video objetivo en kbps.
  FfmpegArgsBuilder videoBitrateKbps(double bitrate) {
    _args.addAll(['-b:v', '${bitrate}k']);
    return this;
  }

  /// Codec de video (por defecto 'libx264').
  FfmpegArgsBuilder videoCodec(String codec) {
    _args.addAll(['-c:v', codec]);
    return this;
  }

  /// Bitrate de audio en kbps.
  FfmpegArgsBuilder audioBitrateKbps(double bitrate) {
    _args.addAll(['-b:a', '${bitrate}k']);
    return this;
  }

  /// Codec de audio (por defecto 'aac').
  FfmpegArgsBuilder audioCodec(String codec) {
    _args.addAll(['-c:a', codec]);
    return this;
  }

  /// Output: archivo de destino.
  FfmpegArgsBuilder output(String path) {
    _args.add(path);
    return this;
  }

  /// Sobreescribe el output sin preguntar.
  FfmpegArgsBuilder overwrite() {
    _args.addAll(['-y']);
    return this;
  }

  /// Construye la lista final de args.
  List<String> build() => List.unmodifiable(_args);
}
