import 'package:kilovideo/domain/entities/video_info.dart';
import 'package:kilovideo/domain/strategies/compression_strategy.dart';

class TargetPercentStrategy implements CompressionStrategy {
  const TargetPercentStrategy({required this.percentCompression});
  final int percentCompression;

  @override
  double calculateBitrate(VideoInfo info) {
    if (percentCompression < 0) {
      throw ArgumentError('El porcentaje no puede ser negativo');
    }

    if (percentCompression > 100) {
      throw ArgumentError('El maximo porcentaje es 100');
    }

    if (percentCompression < 2) {
      throw ArgumentError('El 1% es demasiado bajo para un video');
    }

    double calcSize = (info.originalBitrateKbps * percentCompression) / 100;
    return calcSize;
  }
}
