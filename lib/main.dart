// Copyright 2026 KiloVideo. All rights reserved.
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kilovideo/presentation/app.dart';

void main() {
  runApp(
    const ProviderScope(child: KiloVideoApp()),
  );
}
