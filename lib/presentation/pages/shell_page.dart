import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kilovideo/di/providers.dart';
import 'package:kilovideo/domain/ports/ffmpeg_runner.dart';
import 'package:kilovideo/domain/strategies/compression_strategy.dart';
import 'package:kilovideo/domain/strategies/target_percent_strategy.dart';
import 'package:kilovideo/domain/strategies/target_size_strategy.dart';
import 'package:kilovideo/domain/strategies/tarjet_crf_strategy.dart';
import 'package:kilovideo/presentation/widgets/big_file_drop.dart';
import 'package:kilovideo/presentation/widgets/compress_button.dart';
import 'package:kilovideo/presentation/widgets/result_card.dart';
import 'package:kilovideo/presentation/widgets/sidebar.dart';
import 'package:kilovideo/presentation/widgets/video_input_form.dart';

/// Shell principal: sidebar + área de contenido.
class ShellPage extends ConsumerStatefulWidget {
  /// Crea el shell.
  const ShellPage({super.key, this.initialFiles = const []});

  /// Archivos iniciales (vienen de CLI args o context menu).
  final List<String> initialFiles;

  @override
  ConsumerState<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends ConsumerState<ShellPage> {
  String _selectedId = 'fixed';
  late List<String> _files = List<String>.from(widget.initialFiles);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            selectedId: _selectedId,
            onItemSelected: (id) => setState(() => _selectedId = id),
            onThemeToggle: () {
              final current = ref.read(themeModeProvider);
              ref.read(themeModeProvider.notifier).state =
                  current == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
            },
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedId) {
      case 'fixed':
        return _buildCompressionPage(
          title: 'Tamaño fijo',
          subtitle: 'Comprime tu video a un tamaño exacto en MB',
          mode: CompressionMode.size,
        );
      case 'percent':
        return _buildCompressionPage(
          title: 'Porcentaje',
          subtitle: 'Comprime tu video a un porcentaje del bitrate original',
          mode: CompressionMode.percent,
        );
      case 'quality':
        return _buildCompressionPage(
          title: 'Calidad',
          subtitle: 'Comprime tu video usando CRF (calidad fija)',
          mode: CompressionMode.crf,
        );
      case 'about':
        return _buildAbout();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCompressionPage({
    required String title,
    required String subtitle,
    required CompressionMode mode,
  }) {
    // Sync internal mode to page mode.
    if (_mode != mode) {
      _mode = mode;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        const SizedBox(height: 24),
        BigFileDrop(
          files: _files,
          onFilesChanged: (f) => setState(() => _files = f),
        ),
        const SizedBox(height: 16),
        VideoInputForm(
          targetMbController: _targetMbController,
          percentController: _percentController,
          crfController: _crfController,
          mode: mode,
        ),
        const SizedBox(height: 16),
        CompressButton(busy: _busy, onPressed: _comprimir),
        const SizedBox(height: 24),
        if (_resultado != null) ResultCard(message: _resultado!),
        const SizedBox(height: 16),
        _buildSupportedFormats(),
      ],
    );
  }

  Widget _buildAbout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Acerca de',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text('KiloVideo - Compresor de video para Linux.'),
        const SizedBox(height: 8),
        const Text('Versión 0.1.0'),
        const SizedBox(height: 24),
        _buildIntegrationCard(),
      ],
    );
  }

  Widget _buildIntegrationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.extension),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Integración con menú contextual',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        'Agrega KiloVideo al menú de Nautilus/GNOME Files.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () async {
                final integration = ref.read(linuxIntegrationProvider);
                final messenger = ScaffoldMessenger.of(context);
                try {
                  final path = await integration.installNautilusScript();
                  await integration.installDesktopFile();
                  await integration.refreshAppDatabase();
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(content: Text('Instalado en: $path')),
                  );
                } on Object catch (e) {
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              icon: const Icon(Icons.install_desktop),
              label: const Text('Instalar menú contextual'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportedFormats() {
    return Wrap(
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Formatos soportados:',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        ...['MP4', 'AVI', 'MOV', 'MKV', 'WMV'].map(
          (e) => Chip(
            label: Text(e),
            visualDensity: VisualDensity.compact,
          ),
        ),
        Text(
          'y más...',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ],
    );
  }
}