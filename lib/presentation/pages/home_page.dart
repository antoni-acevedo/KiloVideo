// Copyright 2026 KiloVideo. All rights reserved.
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kilovideo/di/providers.dart';
import 'package:kilovideo/domain/ports/ffmpeg_runner.dart';
import 'package:kilovideo/domain/strategies/compression_strategy.dart';
import 'package:kilovideo/domain/strategies/target_percent_strategy.dart';
import 'package:kilovideo/domain/strategies/target_size_strategy.dart';
import 'package:kilovideo/domain/strategies/tarjet_crf_strategy.dart';
import 'package:kilovideo/presentation/widgets/compress_button.dart';
import 'package:kilovideo/presentation/widgets/result_card.dart';
import 'package:kilovideo/presentation/widgets/video_input_form.dart';

/// Página principal: formulario para comprimir un video.
class HomePage extends ConsumerStatefulWidget {
  /// Crea la home page.
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final TextEditingController _pathController = TextEditingController();
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
  String? _resultado;

  Future<void> _comprimir() async {
    final path = _pathController.text.trim();

    if (path.isEmpty) {
      setState(() => _resultado = 'Error: ruta vacía');
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
      _resultado = 'Comprimiendo...';
    });

    final useCase = ref.read(compressVideoUseCaseProvider);
    final result = await useCase(inputPath: path, strategy: strategy);

    setState(() {
      _busy = false;
      _resultado = switch (result) {
        FfmpegSuccess() => '✓ Compresión exitosa',
        FfmpegFailure() => '✗ Error: ${result.message}',
      };
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
    _pathController.dispose();
    _targetMbController.dispose();
    _percentController.dispose();
    _crfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KiloVideo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VideoInputForm(
              pathController: _pathController,
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
    );
  }
}
