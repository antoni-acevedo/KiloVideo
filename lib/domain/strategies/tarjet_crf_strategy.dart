import 'package:kilovideo/domain/entities/video_info.dart';
import 'package:kilovideo/domain/strategies/compression_strategy.dart';

/// Estrategia para comprimir usando un valor CRF (Constant Rate Factor) de x264.
///
/// **Patrón:** Strategy (GoF).
/// **Cómo:** CRF es un valor de calidad (no bitrate). x264 acepta 0-51.
/// Acá limitamos a 1-20 para mantener calidad razonable.
class TargetCRFStrategy implements CompressionStrategy {
  /// CRF mínimo aceptado.
  static const int minCRF = 1;

  /// CRF máximo aceptado.
  static const int maxCRF = 20;

  /// Duración mínima del video en segundos.
  static const int minDurationSeconds = 5;

  /// Duración máxima del video en horas.
  static const int maxDurationHours = 4;

  /// Bitrate original mínimo aceptado (kbps).
  static const int minOriginalBitrateKbps = 100;

  /// Bitrate original máximo aceptado (kbps).
  static const int maxOriginalBitrateKbps = 50000;

  /// Crea la estrategia con el CRF objetivo.
  const TargetCRFStrategy({required this.tarjetCRF});

  /// Valor CRF objetivo (calidad).
  final int tarjetCRF;

  /// Calcula el bitrate objetivo.
  ///
  /// CRF es calidad, no bitrate. Devolvemos un bitrate de referencia
  /// proporcional al bitrate original ajustado por CRF.
  ///
  /// Fórmula: `originalBitrateKbps * factor(crf)` donde factor va de
  /// 1.0 (CRF 0 = sin pérdida) a ~0.1 (CRF 51 = muy comprimido).
  @override
  double calculateBitrate(VideoInfo info) {
    if (tarjetCRF < minCRF) {
      throw ArgumentError('CRF mínimo es $minCRF');
    }
    if (tarjetCRF > maxCRF) {
      throw ArgumentError('CRF máximo es $maxCRF');
    }
    if (info.duration <= Duration.zero) {
      throw ArgumentError('El video no tiene duración');
    }
    if (info.duration.inSeconds < minDurationSeconds) {
      throw ArgumentError(
        'Duración mínima: $minDurationSeconds segundos',
      );
    }
    if (info.duration.inHours > maxDurationHours) {
      throw ArgumentError(
        'Duración máxima: $maxDurationHours horas',
      );
    }
    if (info.originalBitrateKbps < minOriginalBitrateKbps) {
      throw ArgumentError(
        'Bitrate original mínimo: $minOriginalBitrateKbps kbps',
      );
    }
    if (info.originalBitrateKbps > maxOriginalBitrateKbps) {
      throw ArgumentError(
        'Bitrate original máximo: $maxOriginalBitrateKbps kbps',
      );
    }

    // Factor CRF: linear mapping 1..20 → 1.0..0.1.
    final factor = 1.0 - (tarjetCRF - minCRF) / (maxCRF - minCRF) * 0.9;
    return info.originalBitrateKbps * factor;
  }
}