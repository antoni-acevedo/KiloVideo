// Copyright 2026 KiloVideo. All rights reserved.
// SPDX-License-Identifier: MIT

import 'dart:convert';
import 'dart:io';

import 'package:kilovideo/domain/entities/video_info.dart';
import 'package:kilovideo/domain/ports/video_probe.dart';

/// Implementación de [VideoProbe] que usa `ffprobe` para inspeccionar el video.
///
/// **Patrón:** Adapter + DIP.
class ProcessVideoProbe implements VideoProbe {
  /// Crea el probe que invoca `ffprobe`.
  ProcessVideoProbe();

  @override
  Future<VideoInfo> probe(String path) async {
    final result = await Process.run('ffprobe', [
      '-v', 'error',
      '-show_format',
      '-show_streams',
      '-print_format', 'json',
      path,
    ]);

    if (result.exitCode != 0) {
      throw Exception('ffprobe failed: ${result.stderr}');
    }

    final json = jsonDecode(result.stdout.toString()) as Map<String, dynamic>;
    final streams = json['streams'] as List<dynamic>;
    final videoStream = streams.firstWhere(
      (s) => s['codec_type'] == 'video',
      orElse: () => null,
    );

    if (videoStream == null) {
      throw Exception('No video stream found in $path');
    }

    final format = json['format'] as Map<String, dynamic>;
    final duration = format['duration'] as String?;

    return VideoInfo(
      filePath: path,
      duration: _parseDuration(duration ?? '0'),
      originalBitrateKbps: _parseBitrate(
        (videoStream['bit_rate'] ?? format['bit_rate']) as String?,
      ),
      originalSizeMb: _parseSize(format['size'] as String?),
      codec: videoStream['codec_name'] as String? ?? 'unknown',
    );
  }

  Duration _parseDuration(String seconds) {
    final value = double.tryParse(seconds) ?? 0.0;
    return Duration(milliseconds: (value * 1000).round());
  }

  double _parseBitrate(String? bitrate) {
    if (bitrate == null) return 0.0;
    final bps = double.tryParse(bitrate) ?? 0.0;
    return bps / 1000.0;
  }

  double _parseSize(String? size) {
    if (size == null) return 0.0;
    final bytes = double.tryParse(size) ?? 0.0;
    return bytes / (1024 * 1024);
  }
}
