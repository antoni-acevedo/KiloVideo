import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

/// Servicio de integración con el sistema Linux.
///
/// **Patrón:** Singleton + Service.
/// **Por qué:** encapsula la lógica de instalar el script de Nautilus
/// que aparece en el submenú Scripts del menú contextual.
class LinuxIntegration {
  /// Ruta destino del script en el home del usuario.
  String get scriptPath => p.join(
        Platform.environment['HOME'] ?? '/tmp',
        '.local',
        'share',
        'nautilus',
        'scripts',
        'KiloVideo',
      );

  /// Ruta destino del archivo `.desktop` en el home del usuario.
  String get desktopFilePath => p.join(
        Platform.environment['HOME'] ?? '/tmp',
        '.local',
        'share',
        'applications',
        'kilovideo.desktop',
      );

  /// Instala el script de Nautilus para el menú contextual.
  ///
  /// Devuelve la ruta del script instalado.
  Future<String> installNautilusScript() async {
    final asset = await rootBundle.load('assets/linux/scripts/KiloVideo');
    final bytes = asset.buffer.asUint8List();

    final destFile = File(scriptPath);
    if (!await destFile.parent.exists()) {
      await destFile.parent.create(recursive: true);
    }
    await destFile.writeAsBytes(bytes, flush: true);

    // Permisos ejecutables.
    await Process.run('chmod', ['+x', scriptPath]);

    return scriptPath;
  }

  /// Instala el archivo `.desktop` (alternativa "Abrir con...").
  Future<String> installDesktopFile() async {
    final asset = await rootBundle.load('assets/linux/kilovideo.desktop');
    final bytes = asset.buffer.asUint8List();

    final destFile = File(desktopFilePath);
    if (!await destFile.parent.exists()) {
      await destFile.parent.create(recursive: true);
    }
    await destFile.writeAsBytes(bytes, flush: true);
    await Process.run('chmod', ['+x', desktopFilePath]);

    return desktopFilePath;
  }

  /// Refresca la base de datos de aplicaciones.
  Future<void> refreshAppDatabase() async {
    await Process.run(
      'update-desktop-database',
      [p.dirname(desktopFilePath)],
    );
  }
}