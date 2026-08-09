import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

/// Drop zone grande con ilustración de carpeta y botón Browse.
///
/// **Patrón:** StatefulWidget (presentación).
class BigFileDrop extends StatefulWidget {
  /// Crea el drop zone.
  const BigFileDrop({
    super.key,
    required this.files,
    required this.onFilesChanged,
  });

  /// Lista de archivos seleccionados.
  final List<String> files;

  /// Callback al cambiar archivos.
  final ValueChanged<List<String>> onFilesChanged;

  @override
  State<BigFileDrop> createState() => _BigFileDropState();
}

class _BigFileDropState extends State<BigFileDrop> {
  bool _dragHover = false;

  Future<void> _pickFiles() async {
    const typeGroup = XTypeGroup(
      label: 'Videos',
      extensions: <String>['mp4', 'mov', 'mkv', 'avi', 'webm', 'wmv'],
    );
    final List<XFile> picked = await openFiles(acceptedTypeGroups: [typeGroup]);
    if (picked.isNotEmpty) {
      widget.onFilesChanged([...widget.files, ...picked.map((f) => f.path)]);
    }
  }

  void _addDropped(List<String> paths) {
    final accepted = paths
        .map((p) => p.replaceFirst('file://', ''))
        .where(_isVideo)
        .toList();
    if (accepted.isNotEmpty) {
      widget.onFilesChanged([...widget.files, ...accepted]);
    }
  }

  bool _isVideo(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.wmv');
  }

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragEntered: (_) => setState(() => _dragHover = true),
      onDragExited: (_) => setState(() => _dragHover = false),
      onDragDone: (detail) {
        setState(() => _dragHover = false);
        _addDropped(detail.files.map((f) => f.path).toList());
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: _dragHover
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(16),
          color: _dragHover
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.04)
              : null,
        ),
        child: widget.files.isEmpty
            ? _buildEmpty(context)
            : _buildWithFiles(context),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer
                .withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.folder_open,
            size: 60,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Ningún archivo seleccionado',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Click para explorar o arrastra un archivo de video aquí',
          style: TextStyle(color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: 240,
          height: 56,
          child: FilledButton.icon(
            onPressed: _pickFiles,
            icon: const Icon(Icons.folder_open, size: 22),
            label: const Text(
              'Browse Files',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWithFiles(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${widget.files.length} archivo(s) seleccionado(s)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: _pickFiles,
              icon: const Icon(Icons.add),
              label: const Text('Agregar más'),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => widget.onFilesChanged(const []),
              icon: const Icon(Icons.clear_all),
              tooltip: 'Limpiar todo',
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...widget.files.map(_buildFileTile),
      ],
    );
  }

  Widget _buildFileTile(String path) {
    final filename = path.split('/').last;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.movie),
        title: Text(filename, overflow: TextOverflow.ellipsis),
        subtitle: Text(path, overflow: TextOverflow.ellipsis),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => widget.onFilesChanged(
            widget.files.where((p) => p != path).toList(),
          ),
        ),
      ),
    );
  }
}