// Copyright 2026 KiloVideo. All rights reserved.
// SPDX-License-Identifier: MIT

import 'package:kilovideo/domain/entities/video_info.dart';

/// Abstracción para todos los algoritmos de compresión.
///
/// **Patrón:** Strategy (GoF).
/// **Por qué:** cada subclase representa un modo de compresión distinto
/// (target exacto, porcentaje, CRF). El use case consume la abstracción
/// y la hace intercambiable.
///
/// **Forma en Dart:** `abstract interface class` permite extensión desde
/// cualquier archivo. Si más adelante quieres `switch` exhaustivo, migrate
/// a `sealed class` con directivas `part`/`part of`.
abstract interface class CompressionStrategy {
  /// Constructor base para las subclases.
  const CompressionStrategy();

  /// Calcula el bitrate objetivo (en kbps) para comprimir [info].
  ///
  /// **Lanza:** `ArgumentError` si los parámetros son inválidos.
  double calculateBitrate(VideoInfo info);
}
