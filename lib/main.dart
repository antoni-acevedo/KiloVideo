// Copyright 2026 KiloVideo. All rights reserved.
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kilovideo/presentation/app.dart';
import 'package:window_manager/window_manager.dart';

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

  runApp(
    const ProviderScope(child: KiloVideoApp()),
  );
}