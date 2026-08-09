import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

/// Sección de selección de archivos: picker + lista de archivos seleccionados.
///
/// **Patrón:** StatefulWidget (presentación).
class FilePickerSection extends StatefulWidget {
  /// Crea la sección.
  const FilePickerSection({
    super.key,
    required this.files,
    required this.onFilesChanged,
  });

  /// Lista actual de rutas seleccionadas.
  final List<String> files;

  /// Callback al cambiar la lista.
  final ValueChanged<List<String>> onFilesChanged;

  @override
  State<FilePickerSection> createState() => _FilePickerSectionState();
}

class _FilePickerSectionState extends State<FilePickerSection> {
  bool _dragHover = false;

  Future<void> _pickFiles() async {
    const typeGroup = XTypeGroup(
      label: 'Videos',
      extensions: <String>['mp4', 'mov', 'mkv', 'avi', 'webm'],
    );
    final List<XFile> picked = await openFiles(acceptedTypeGroups: [typeGroup]);
    if (picked.isNotEmpty) {
      widget.onFilesChanged([...widget.files, ...picked.map((f) => f.path)]);
    }
  }

  void _remove(String path) {
    widget.onFilesChanged(widget.files.where((p) => p != path).toList());
  }

  void _clear() => widget.onFilesChanged(const []);

  void _addDropped(List<String> paths) {
    final accepted = paths
        .map((p) => p.replaceFirst('file://', ''))
        .where(_isVideo)
        .toList();
    if (accepted.isNotEmpty) {
      widget.onFilesChanged([...widget.files, ...accepted]);
    }
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: _dragHover ? Colors.blue : Colors.grey,
            width: 2,
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
                    widget.files.isEmpty
                        ? 'Ningún archivo seleccionado'
                        : '${widget.files.length} archivo(s) seleccionado(s)',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                FilledButton.icon(
                  onPressed: _pickFiles,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Seleccionar'),
                ),
                if (widget.files.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _clear,
                    icon: const Icon(Icons.clear_all),
                    tooltip: 'Limpiar todo',
                  ),
                ],
              ],
            ),
            if (widget.files.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...widget.files.map(_buildFileTile),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFileTile(String path) {
    final filename = path.split('/').last;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.movie),
        title: Text(filename, overflow: TextOverflow.ellipsis),
        subtitle: Text(path, overflow: TextOverflow.ellipsis),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Quitar',
          onPressed: () => _remove(path),
        ),
      ),
    );
  }

  bool _isVideo(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.webm');
  }
}
