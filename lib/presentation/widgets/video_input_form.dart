// Copyright 2026 KiloVideo. All rights reserved.
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

/// Formulario con los campos de entrada para comprimir un video.
///
/// **Patrón:** Stateless Widget (presentación).
/// **Por qué:** dos campos de texto reusables. La lógica de extraer
/// los valores vive en el padre (HomePage, SettingsPage, etc.).
class VideoInputForm extends StatelessWidget {
  /// Crea el formulario.
  const VideoInputForm({
    super.key,
    required this.pathController,
    required this.targetMbController,
  });

  /// Controller del campo de ruta.
  final TextEditingController pathController;

  /// Controller del campo de tamaño objetivo en MB.
  final TextEditingController targetMbController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: pathController,
          decoration: const InputDecoration(
            labelText: 'Ruta del video',
            hintText: '/home/user/video.mp4',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: targetMbController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Tamaño final (MB)',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}
