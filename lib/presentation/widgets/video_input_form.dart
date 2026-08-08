import 'package:flutter/material.dart';

/// Modo de compresión: tamaño exacto o porcentaje del original.
enum CompressionMode {
  /// Target en MB.
  size,

  /// Porcentaje del bitrate original.
  percent,
}

/// Formulario con los campos de entrada para comprimir un video.
///
/// **Patrón:** Stateless Widget (presentación).
/// **Por qué:** campos reutilizables. La lógica vive en el padre.
class VideoInputForm extends StatelessWidget {
  /// Crea el formulario.
  const VideoInputForm({
    super.key,
    required this.pathController,
    required this.targetMbController,
    required this.percentController,
    required this.mode,
    required this.onModeChanged,
  });

  /// Controller del campo de ruta.
  final TextEditingController pathController;

  /// Controller del campo de tamaño objetivo en MB.
  final TextEditingController targetMbController;

  /// Controller del campo de porcentaje de compresión.
  final TextEditingController percentController;

  /// Modo actual de compresión.
  final CompressionMode mode;

  /// Callback al cambiar de modo.
  final ValueChanged<CompressionMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<CompressionMode>(
          segments: const [
            ButtonSegment(
              value: CompressionMode.size,
              label: Text('Tamaño (MB)'),
              icon: Icon(Icons.straighten),
            ),
            ButtonSegment(
              value: CompressionMode.percent,
              label: Text('Porcentaje (%)'),
              icon: Icon(Icons.percent),
            ),
          ],
          selected: {mode},
          onSelectionChanged: (selection) => onModeChanged(selection.first),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: pathController,
          decoration: const InputDecoration(
            labelText: 'Ruta del video',
            hintText: '/home/user/video.mp4',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        if (mode == CompressionMode.size)
          TextField(
            controller: targetMbController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Tamaño final (MB)',
              border: OutlineInputBorder(),
            ),
          )
        else
          TextField(
            controller: percentController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Porcentaje de compresión (%)',
              helperText: 'Entre 2 y 100',
              border: OutlineInputBorder(),
            ),
          ),
      ],
    );
  }
}