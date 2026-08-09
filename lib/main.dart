// Copyright 2026 KiloVideo. All rights reserved.
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kilovideo/presentation/app.dart';
import 'package:window_manager/window_manager.dart';

/// Filtra argumentos CLI que parezcan rutas a archivos de video.
List<String> _filterVideoArgs(List<String> args) {
  return args
      .where((arg) => !arg.startsWith('-'))
      .where((arg) => arg.endsWith('.mp4') ||
          arg.endsWith('.mov') ||
          arg.endsWith('.mkv') ||
          arg.endsWith('.avi') ||
          arg.endsWith('.webm') ||
          arg.endsWith('.wmv'))
      .toList();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(700, 500),
    minimumSize: Size(700, 500),
    maximumSize: Size(700, 500),
    center: true,
    title: 'KiloVideo',
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.setResizable(false);
  });

  final initialFiles = _filterVideoArgs(Platform.executableArguments);

  runApp(
    ProviderScope(
      child: KiloVideoApp(initialFiles: initialFiles),
    ),
  );
}