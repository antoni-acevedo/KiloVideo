// Copyright 2026 KiloVideo. All rights reserved.
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

/// Botón de comprimir con estado de busy.
///
/// **Patrón:** Stateless Widget.
/// **Por qué:** encapsula el spinner cuando la operación está en curso.
class CompressButton extends StatelessWidget {
  /// Crea el botón.
  const CompressButton({
    super.key,
    required this.busy,
    required this.onPressed,
    this.label = 'Comprimir',
  });

  /// Si está ocupado, muestra spinner y deshabilita.
  final bool busy;

  /// Callback al apretar. Si busy, no se llama.
  final VoidCallback onPressed;

  /// Texto del botón.
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: busy
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}