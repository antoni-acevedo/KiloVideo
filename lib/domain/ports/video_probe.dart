// Copyright 2026 KiloVideo. All rights reserved.
// SPDX-License-Identifier: MIT

import 'package:kilovideo/domain/entities/video_info.dart';

/// Contrato para inspeccionar un archivo de video y obtener sus metadatos.
///
/// **Patrón:** Port (DIP).
/// **Por qué:** el dominio pregunta "¿cuál es la duración/bitrate de
/// este video?" sin saber si la respuesta viene de ffmpeg, MediaInfo,
/// o un mock en tests.
abstract interface class VideoProbe {
  /// Inspecciona el archivo en [path] y devuelve su información.
  Future<VideoInfo> probe(String path);
}
