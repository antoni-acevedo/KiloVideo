// Copyright 2026 KiloVideo. All rights reserved.
// SPDX-License-Identifier: MIT

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kilovideo/di/providers.dart';
import 'package:kilovideo/domain/ports/ffmpeg_runner.dart';
import 'package:kilovideo/domain/strategies/compression_strategy.dart';
import 'package:kilovideo/domain/strategies/target_percent_strategy.dart';
import 'package:kilovideo/domain/strategies/target_size_strategy.dart';
import 'package:kilovideo/domain/strategies/tarjet_crf_strategy.dart';
import 'package:kilovideo/presentation/widgets/compress_button.dart';
import 'package:kilovideo/presentation/widgets/file_picker_section.dart';
import 'package:kilovideo/presentation/widgets/result_card.dart';
import 'package:kilovideo/presentation/widgets/video_input_form.dart';

/// Página principal: formulario para comprimir videos.
class HomePage extends ConsumerStatefulWidget {
  /// Crea la home page.
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  List<String> _files = const [];
  final TextEditingController _targetMbController = TextEditingController(
    text: '25',
  );
  final TextEditingController _percentController = TextEditingController(
    text: '50',
  );
  final TextEditingController _crfController = TextEditingController(
    text: '20',
  );
  CompressionMode _mode = CompressionMode.size;
  bool _busy = false;
  bool _dragHover = false;
  String? _resultado;

  Future<void> _comprimir() async {
    if (_files.isEmpty) {
      setState(() => _resultado = 'Error: sin archivos');
      return;
    }

    CompressionStrategy strategy;
    try {
      strategy = _buildStrategy();
    } on ArgumentError catch (e) {
      setState(() => _resultado = '✗ Error: ${e.message}');
      return;
    }

    setState(() {
      _busy = true;
      _resultado = 'Comprimiendo ${_files.length} archivo(s)...';
    });

    final useCase = ref.read(compressVideoUseCaseProvider);
    int ok = 0;
    final List<String> errors = [];

    for (final path in _files) {
      final result = await useCase(inputPath: path, strategy: strategy);
      switch (result) {
        case FfmpegSuccess():
          ok++;
        case FfmpegFailure():
          errors.add('${path.split('/').last}: ${result.message}');
      }
    }

    setState(() {
      _busy = false;
      final summary = '✓ $ok/${_files.length} exitoso(s)';
      _resultado = errors.isEmpty
          ? summary
          : '$summary\n${errors.join('\n')}';
    });
  }

  CompressionStrategy _buildStrategy() {
    switch (_mode) {
      case CompressionMode.size:
        final targetMb = double.tryParse(_targetMbController.text.trim()) ?? 0;
        return TargetSizeStrategy(targetMb: targetMb);
      case CompressionMode.percent:
        final percent = int.tryParse(_percentController.text.trim()) ?? 0;
        return TargetPercentStrategy(percentCompression: percent);
      case CompressionMode.crf:
        final crf = int.tryParse(_crfController.text.trim()) ?? 0;
        return TargetCRFStrategy(tarjetCRF: crf);
    }
  }

  @override
  void dispose() {
    _targetMbController.dispose();
    _percentController.dispose();
    _crfController.dispose();
    super.dispose();
  }

  void _addDropped(List<String> paths) {
    final List<String> accepted = paths
        .map((p) => p.replaceFirst('file://', ''))
        .where((p) {
      final lower = p.toLowerCase();
      return lower.endsWith('.mp4') ||
          lower.endsWith('.mov') ||
          lower.endsWith('.mkv') ||
          lower.endsWith('.avi') ||
          lower.endsWith('.webm');
    }).toList();
    if (accepted.isNotEmpty) {
      setState(() => _files = [..._files, ...accepted]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KiloVideo')),
      body: DropTarget(
        onDragEntered: (_) => setState(() => _dragHover = true),
        onDragExited: (_) => setState(() => _dragHover = false),
        onDragDone: (detail) {
          setState(() => _dragHover = false);
          _addDropped(detail.files.map((f) => f.path).toList());
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          color: _dragHover ? Colors.blue.withValues(alpha: 0.05) : null,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilePickerSection(
                  files: _files,
                  onFilesChanged: (f) => setState(() => _files = f),
                ),
                const SizedBox(height: 16),
                VideoInputForm(
                  targetMbController: _targetMbController,
                  percentController: _percentController,
                  crfController: _crfController,
                  mode: _mode,
                  onModeChanged: (m) => setState(() => _mode = m),
                ),
                const SizedBox(height: 16),
                CompressButton(busy: _busy, onPressed: _comprimir),
                const SizedBox(height: 24),
                if (_resultado != null) ResultCard(message: _resultado!),
              ],
            ),
          ),
        ),
      ),
    );
  }
}