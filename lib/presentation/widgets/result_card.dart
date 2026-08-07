// Copyright 2026 KiloVideo. All rights reserved.
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Card que muestra un mensaje de resultado con botón para copiar.
///
/// **Patrón:** Stateless Widget.
/// **Por qué:** reusado para mostrar éxito, error de ffmpeg, error de
/// validación, o cualquier mensaje que el usuario quiera copiar.
class ResultCard extends StatelessWidget {
  /// Crea el card.
  const ResultCard({super.key, required this.message});

  /// Texto a mostrar y copiar.
  final String message;

  Future<void> _copiar(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: message));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copiado al portapapeles'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy),
          tooltip: 'Copiar mensaje',
          onPressed: () => _copiar(context),
        ),
      ],
    );
  }
}
