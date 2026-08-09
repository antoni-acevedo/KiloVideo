import 'package:file_selector/file_selector.dart';
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
class VideoInputForm extends StatefulWidget {
  /// Crea el formulario.
  const VideoInputForm({
    super.key,
    required this.pathController,
    required this.targetMbController,
    required this.percentController,
    required this.crfController,
    required this.mode,
    required this.onModeChanged,
  });

  /// Controller del campo de ruta.
  final TextEditingController pathController;

  /// Controller del campo de tamaño objetivo en MB.
  final TextEditingController targetMbController;

  /// Controller del campo de porcentaje de compresión.
  final TextEditingController percentController;

  /// Controller del campo de CRF.
  final TextEditingController crfController;

  /// Modo actual de compresión.
  final CompressionMode mode;

  /// Callback al cambiar de modo.
  final ValueChanged<CompressionMode> onModeChanged;

  @override
  State<VideoInputForm> createState() => _VideoInputFormState();
}

class _VideoInputFormState extends State<VideoInputForm> {
  bool _dragHover = false;

  @override
  void initState() {
    super.initState();
    widget.pathController.addListener(_onAnyChange);
    widget.percentController.addListener(_onAnyChange);
    widget.crfController.addListener(_onAnyChange);
  }

  @override
  void dispose() {
    widget.pathController.removeListener(_onAnyChange);
    widget.percentController.removeListener(_onAnyChange);
    widget.crfController.removeListener(_onAnyChange);
    super.dispose();
  }

  void _onAnyChange() => setState(() {});

  Future<void> _pickFile() async {
    const typeGroup = XTypeGroup(
      label: 'Videos',
      extensions: <String>['mp4', 'mov', 'mkv', 'avi', 'webm'],
    );
    final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file != null) {
      widget.pathController.text = file.path;
    }
  }

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

  Widget _buildFilePicker() {
    final path = widget.pathController.text.trim();
    return DragTarget<String>(
      onWillAcceptWithDetails: (_) {
        setState(() => _dragHover = true);
        return true;
      },
      onLeave: (_) => setState(() => _dragHover = false),
      onAcceptWithDetails: (details) {
        setState(() => _dragHover = false);
        widget.pathController.text = details.data;
      },
      builder: (context, candidate, rejected) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: _dragHover ? Colors.blue : Colors.grey,
              width: 2,
              style: _dragHover ? BorderStyle.solid : BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(8),
            color: _dragHover ? Colors.blue.withValues(alpha: 0.05) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      path.isEmpty ? 'Ningún archivo seleccionado' : path,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: path.isEmpty ? Colors.grey : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Seleccionar'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<CompressionMode>(
          segments: const [
            ButtonSegment(
              value: CompressionMode.size,
              label: Text('Tamaño'),
              icon: Icon(Icons.straighten),
            ),
            ButtonSegment(
              value: CompressionMode.percent,
              label: Text('Porcentaje'),
              icon: Icon(Icons.percent),
            ),
            ButtonSegment(
              value: CompressionMode.crf,
              label: Text('CRF'),
              icon: Icon(Icons.tune),
            ),
          ],
          selected: {widget.mode},
          onSelectionChanged: (selection) =>
              widget.onModeChanged(selection.first),
        ),
        const SizedBox(height: 16),
        _buildFilePicker(),
        const SizedBox(height: 16),
        if (widget.mode == CompressionMode.size)
          _buildSizeField()
        else if (widget.mode == CompressionMode.percent)
          _buildPercentSlider()
        else
          _buildCrfSlider(),
      ],
    );
  }
}
