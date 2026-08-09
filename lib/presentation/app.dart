// Copyright 2026 KiloVideo. All rights reserved.
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kilovideo/di/providers.dart';
import 'package:kilovideo/presentation/pages/shell_page.dart';

/// Root widget de la app.
class KiloVideoApp extends ConsumerWidget {
  /// Crea la app.
  const KiloVideoApp({super.key, this.initialFiles = const []});

  /// Archivos recibidos como argumentos CLI (context menu integration).
  final List<String> initialFiles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'KiloVideo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2196F3)),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: mode,
      home: ShellPage(initialFiles: initialFiles),
    );
  }
}
