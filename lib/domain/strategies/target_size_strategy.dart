// Copyright 2026 KiloVideo. All rights reserved.
// SPDX-License-Identifier: MIT

import 'package:kilovideo/domain/entities/video_info.dart';
import 'package:kilovideo/domain/strategies/compression_strategy.dart';

/// Estrategia para comprimir cuando el usuario quiere un **tamaño final
/// exacto** en megabytes.
///
/// **Patrón:** Strategy + LSP (subclase de [CompressionStrategy]).
/// **Cálculo:** `(targetMb * 1024 * 8 / duration) - audioBitrateKbps`,
/// luego clampeado a [minVideoBitrateKbps].
///
/// **Por qué restar audio:** ffmpeg separa video y audio. Si solo decimos
/// el bitrate total, ffmpeg no sabe cuánto dejar para cada uno y produce
/// archivos corruptos cuando el target es muy chico.
class TargetSizeStrategy implements CompressionStrategy {
  /// Bitrate de audio AAC fijo en kbps.
  static const double audioBitrateKbps = 64.0;

  /// Bitrate mínimo de video. Si el cálculo da menos, lanza error.
  static const double minVideoBitrateKbps = 100.0;

  /// Crea la estrategia con el tamaño objetivo deseado.
  const TargetSizeStrategy({required this.targetMb});

  /// Tamaño final deseado en megabytes.
  final double targetMb;

  /// Calcula el bitrate de video en kbps para alcanzar [targetMb] en un
  /// video de duración `info.duration`.
  ///
  /// **Lanza:** `ArgumentError` si la duración es <= 0, [targetMb] <= 0,
  /// o si el target es demasiado pequeño para dejar un bitrate mínimo.
  @override
  double calculateBitrate(VideoInfo info) {
    if (info.duration <= Duration.zero) {
      throw ArgumentError('El video no tiene duracion');
    }
    if (targetMb <= 0) {
      throw ArgumentError('El video no tiene targetMb');
    }

    final totalKbps = (targetMb * 1024 * 8) / info.duration.inSeconds;
    final videoKbps = totalKbps - audioBitrateKbps;

    if (videoKbps < minVideoBitrateKbps) {
      throw ArgumentError(
        'Target demasiado pequeño: mínimo ${_minTargetMb(info).toStringAsFixed(2)} MB '
        'para un video de ${info.duration.inMinutes} minutos.',
      );
    }

    return videoKbps;
  }

  /// Calcula el target mínimo en MB para que el bitrate de video no baje
  /// del piso.
  double _minTargetMb(VideoInfo info) {
    final minTotalKbps = minVideoBitrateKbps + audioBitrateKbps;
    return (minTotalKbps * info.duration.inSeconds) / (1024 * 8);
  }
}
