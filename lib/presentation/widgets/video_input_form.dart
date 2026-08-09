import 'package:flutter/material.dart';

/// Modo de compresión: tamaño exacto o porcentaje del original.
enum CompressionMode {
  /// Target en MB.
  size,

  /// Porcentaje del bitrate original.
  percent,

  /// CRF (calidad fija).
  crf,
}

/// Formulario con los campos de entrada para comprimir un video.
///
/// **Patrón:** Stateful (presentación).
/// **Por qué:** los sliders requieren rebuild al cambiar. StatelessWidget
/// no se entera de mutaciones del `TextEditingController`.
///
/// **Nota:** el modo se selecciona desde el sidebar de la app. Este
/// widget solo renderiza el input correspondiente al modo recibido.
class VideoInputForm extends StatefulWidget {
  /// Crea el formulario.
  const VideoInputForm({
    super.key,
    required this.targetMbController,
    required this.percentController,
    required this.crfController,
    required this.mode,
  });

  /// Controller del campo de tamaño objetivo en MB.
  final TextEditingController targetMbController;

  /// Controller del campo de porcentaje de compresión.
  final TextEditingController percentController;

  /// Controller del campo de CRF.
  final TextEditingController crfController;

  /// Modo actual de compresión.
  final CompressionMode mode;

  @override
  State<VideoInputForm> createState() => _VideoInputFormState();
}

class _VideoInputFormState extends State<VideoInputForm> {
  @override
  void initState() {
    super.initState();
    widget.percentController.addListener(_onAnyChange);
    widget.crfController.addListener(_onAnyChange);
  }

  @override
  void dispose() {
    widget.percentController.removeListener(_onAnyChange);
    widget.crfController.removeListener(_onAnyChange);
    super.dispose();
  }

  void _onAnyChange() => setState(() {});

  Widget _buildSizeField() {
    return TextField(
      controller: widget.targetMbController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Tamaño final (MB)',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildPercentSlider() {
    final current = int.tryParse(widget.percentController.text.trim()) ?? 50;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Porcentaje: $current%'),
        Slider(
          value: current.clamp(2, 100).toDouble(),
          min: 2,
          max: 100,
          divisions: 98,
          label: '$current%',
          onChanged: (v) =>
              widget.percentController.text = v.toStringAsFixed(0),
        ),
      ],
    );
  }

  Widget _buildCrfSlider() {
    final current = int.tryParse(widget.crfController.text.trim()) ?? 20;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('CRF: $current (menor = mejor calidad)'),
        Slider(
          value: current.clamp(1, 20).toDouble(),
          min: 1,
          max: 20,
          divisions: 19,
          label: '$current',
          onChanged: (v) => widget.crfController.text = v.toStringAsFixed(0),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return switch (widget.mode) {
      CompressionMode.size => _buildSizeField(),
      CompressionMode.percent => _buildPercentSlider(),
      CompressionMode.crf => _buildCrfSlider(),
    };
  }
}