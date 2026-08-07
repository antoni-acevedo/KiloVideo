# AGENTS.md — KiloVideo

> Reglas pedagogicas del proyecto. Este archivo es la **fuente de verdad** para:
> - Como escribir codigo en este repo.
> - Que patrones aplicar y por que.
> - Como decidimos arquitectura, testing, naming, errores.
> - Como aprendemos (reglas didacticas explicitas).
>
> **Audiencia:** un programador junior que ya sabe Flutter basico y esta aprendiendo
> SOLID, GoF, TDD, Clean Architecture. Todo esta sobreexplicado a proposito.

---

## 1. Identidad del proyecto

- **Nombre:** KiloVideo.
- **Tipo:** aplicacion de escritorio (Flutter Desktop).
- **Proposito:** comprimir videos desde el menu contextual del explorador de archivos.
- **Plataformas (orden de prioridad):**
  1. Linux (GNOME, KDE, XFCE, Cinnamon, MATE) — **foco actual**.
  2. macOS — despues.
  3. Windows — solo si el usuario lo pide despues.
- **Distribucion final:** AppImage auto-contenido.
- **Motor de video:** `ffmpeg` CLI externo (subproceso). El binario debe estar disponible
  en el sistema o empaquetado dentro del AppImage.
- **Regla de oro:** la app NO incluye ffmpeg en el codigo Dart. Es una dependencia del
  entorno. La verificacion de presencia ocurre al arrancar.

### Por que ffmpeg como subproceso y no como libreria?
- Mantiene el binario Flutter pequeno.
- Nos permite usar cualquier codec que el ffmpeg del usuario soporte.
- Strategy pattern encaja perfecto: cada "modo de compresion" es una composicion de flags.

---

## 2. Stack tecnologico (pinneado)

### Runtime

| Componente       | Version              | Por que                                        |
|------------------|----------------------|------------------------------------------------|
| Dart SDK         | `>=3.4.0 <4.0.0`     | Records, sealed classes, pattern matching.     |
| Flutter          | `>=3.22.0` stable    | Linux desktop estable, embedding limpio.       |
| ffmpeg           | `>=5.0`              | Codecs modernos, API estable.                  |

### Paquetes (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  args: ^2.5.0                # Parseo robusto de CLI / context menu argv.
  path: ^1.9.0                # Paths portables entre Linux/Mac.
  path_provider: ^2.1.4       # Directorios del sistema (logs, cache).
  riverpod: ^2.5.1            # State management. Code-gen opcional.
  freezed: ^2.5.7             # Sealed unions para errores y entidades.
  json_annotation: ^4.9.0     # Para serializar perfiles de compresion.

dev_dependencies:
  flutter_test:
    sdk: flutter
  test: ^1.25.0               # Tests puros sin Flutter (domain/application).
  mocktail: ^1.0.4            # Mocks sin codegen, menos magia que mockito.
  coverage: ^1.7.2            # Reportes de cobertura.
  very_good_analysis: ^6.0.0  # Reglas de lint estrictas (ver seccion 6).
  build_runner: ^2.4.13       # Code-gen para freezed/json.
  freezed_annotation: ^2.4.4
  json_serializable: ^6.8.0
```

### Por que estos y no otros?

- **`riverpod`:** sin BuildContext, testeable sin `pumpWidget`, no obliga a Provider tree.
- **`freezed`:** genera `==`, `hashCode`, `copyWith`, `toString`, y sealed unions. Ideal
  para errores y entidades inmutables.
- **`mocktail`:** no usa codegen. Escribes el mock a mano y queda claro que se stub-ea.
- **`very_good_analysis`:** reglas estrictas sinopinionadas, default sensato para juniors.

---

## 3. Principios SOLID (traducidos a Dart)

> SOLID no es opcional. Cada clase nueva debe poder justificarse contra estos 5 principios.

### S — Single Responsibility (Responsabilidad Unica)

- **Idea:** una clase, una razon para cambiar.
- **En Dart:** si tu clase tiene dos verbos principales ("comprime" Y "loguea"),
  partela en dos.
- **Truco pedagogico:** escribe la descripcion de la clase en una frase. Si lleva "y",
  probablemente viola SRP.

```dart
// MAL: hace dos cosas.
class VideoCompressorAndLogger {
  void compress(String path) { ... }
  void log(String message) { ... }
}

// BIEN: dos clases.
class VideoCompressor { void compress(String path) { ... } }
class AppLogger { void info(String message) { ... } }
```

### O — Open/Closed (Abierto/Cerrado)

- **Idea:** extender comportamiento sin modificar codigo existente.
- **En Dart:** `sealed class` + `switch` exhaustivo permite anadir variantes sin tocar
  las que ya existen. El compilador te obliga a manejarlas.
- **Truco:** si cada vez que anades una "estrategia de compresion" tienes que modificar
  el `if/else` central, estas violando OCP. Strategy pattern lo resuelve (ver seccion 4).

```dart
sealed class CompressionStrategy {
  const CompressionStrategy();
}
class TargetSizeStrategy extends CompressionStrategy { ... }
class PercentageReductionStrategy extends CompressionStrategy { ... }

// Pattern matching exhaustivo. Si anades una 3ra estrategia, el compilador
// rompera en TODOS los `switch` que no la manejen.
double calculateTargetBitrate(
  CompressionStrategy s,
  VideoInfo info,
) => switch (s) {
  TargetSizeStrategy(:final megabytes) => ...,
  PercentageReductionStrategy(:final percent) => ...,
};
```

### L — Liskov Substitution (Sustitucion de Liskov)

- **Idea:** si `B` hereda de `A`, cualquier codigo que use `A` debe funcionar igual con `B`.
- **En Dart:** las subclases NO deben estrechar precondiciones ni ampliar postcondiciones.
- **Truco:** evita `implements` con metodos que lancen `UnimplementedError`. Si una
  subclase no soporta una operacion, **no la heredes**; usa composicion.

```dart
// MAL: rompe LSP.
abstract class VideoExporter {
  void exportTo(String path);
}
class Mp4Exporter implements VideoExporter {
  @override
  void exportTo(String path) { ... }
}
class GifExporter implements VideoExporter {
  @override
  void exportTo(String path) => throw UnimplementedError(); // LSP roto.
}

// BIEN: composicion.
abstract class VideoExporter { Future<void> export(String path); }
class Mp4Exporter implements VideoExporter { ... }
class AnimatedExporter implements VideoExporter { ... } // contrato explicito.
```

### I — Interface Segregation (Segregacion de Interfaces)

- **Idea:** no obligues a implementar metodos que no usas.
- **En Dart:** prefiere **muchas interfaces pequenas** (abstract class con 1-2 metodos)
  sobre una gorda. Luego las clases implementan solo las que necesitan.
- **Truco:** si una interface tiene mas de 5 metodos publicos, probablemente
  contiene multiples roles.

```dart
// MAL: interface gorda.
abstract class VideoService {
  void compress();
  void extractAudio();
  void generateThumbnails();
  void uploadToCloud();
}

// BIEN: segregadas.
abstract class Compressable { Future<void> compress(); }
abstract class AudioExtractable { Future<void> extractAudio(); }
abstract class ThumbnailGenerable { Future<Uint8List> thumbnail(); }

class Mp4Processor implements Compressable, ThumbnailGenerable { ... }
```

### D — Dependency Inversion (Inversion de Dependencias)

- **Idea:** depender de abstracciones, no de concreciones.
- **En Dart:** los `use cases` NO importan `package:ffmpeg_kit`. Importan **interfaces
  propias** (ej. `FfmpegRunner`) que la capa de infraestructura implementa.
- **Regla:** `domain/` y `application/` no importan `dart:io`, `package:flutter`, ni
  `package:ffmpeg_*`. Nunca.

```dart
// En domain/ports/ffmpeg_runner.dart:
abstract interface class FfmpegRunner {
  Future<FfmpegResult> run(List<String> args);
  Stream<double> get progress;
}

// En infrastructure/ffmpeg/process_runner.dart:
class ProcessFfmpegRunner implements FfmpegRunner {
  @override
  Future<FfmpegResult> run(List<String> args) async {
    // usa dart:io Process aqui.
  }
}
```

---

## 4. Patrones GoF que aplicamos (lista cerrada)

> No aplicamos TODOS los patrones. Solo los que resuelven problemas reales de KiloVideo.
> Cada patron lleva: definicion corta, cuando usarlo, donde vive en este repo.

### 4.1 Strategy (Estrategia)

- **Problema:** calculo del bitrate objetivo depende del modo elegido (MB exacto,
  porcentaje).
- **Donde vive:** `lib/domain/strategies/`.
- **Forma en Dart:** `sealed class CompressionStrategy` + `switch` exhaustivo.
- **Regla:** cada estrategia nueva requiere su propio test unitario. El `switch`
  exhaustivo en el use case obliga a actualizar el switch (gracias, compilador).

### 4.2 Factory Method (Fabrica)

- **Problema:** crear el `FfmpegRunner` correcto segun el sistema (subprocess local,
  AppImage bundled, mock en tests).
- **Donde vive:** `lib/infrastructure/factories/`.
- **Forma en Dart:** clase con metodo estatico `create()` que devuelve la abstraccion
  (`FfmpegRunner`), no la concrecion.

```dart
abstract interface class FfmpegRunner { ... }

class FfmpegRunnerFactory {
  static FfmpegRunner create({required FfmpegLocation location}) =>
    switch (location) {
      FfmpegLocation.systemPath => ProcessFfmpegRunner(),
      FfmpegLocation.appBundle => BundledFfmpegRunner(),
    };
}
```

### 4.3 Observer (Observador)

- **Problema:** la UI quiere saber el progreso del encode. No queremos acoplar
  `ffmpeg_runner.dart` a Flutter.
- **Donde vive:** `FfmpegRunner` emite un `Stream<double>` de progreso (0.0 a 1.0).
- **Regla:** los observers son **streams Dart nativos**. No usar `ChangeNotifier` ni
  `EventEmitter` externo. Riverpod los consume con `StreamProvider`.

### 4.4 Command (Comando)

- **Problema:** cuando el usuario selecciona 10 videos, queremos encolarlos y procesarlos
  en serie, con la posibilidad de cancelar.
- **Donde vive:** `lib/domain/commands/compression_job.dart`.
- **Forma en Dart:** cada video se envuelve en un `CompressionJobCommand` que implementa
  `execute()` y `cancel()`. Una `JobQueue` los ejecuta en orden.

```dart
abstract interface class CompressionJobCommand {
  Future<CompressionResult> execute();
  Future<void> cancel();
}

class JobQueue {
  final List<CompressionJobCommand> _jobs = [];
  Future<void> enqueue(CompressionJobCommand job) async { ... }
}
```

### 4.5 Facade (Fachada)

- **Problema:** `ffmpeg` tiene cientos de flags. Nuestro codigo NO deberia memorizar
  `-c:v libx264 -crf 28 ...`.
- **Donde vive:** `lib/infrastructure/ffmpeg/ffmpeg_facade.dart`.
- **Forma en Dart:** clase `FfmpegFacade` con metodos de alto nivel
  (`encodeH264(info, bitrate)`, `extractAudio(path)`). Internamente construye args.

### 4.6 Builder (Constructor)

- **Problema:** construir listas de args de ffmpeg es verboso. Necesitamos chaining.
- **Donde vive:** `lib/infrastructure/ffmpeg/args_builder.dart`.
- **Forma en Dart:** clase inmutable con `copyWith` y `build()` final. Freezed ayuda.

### 4.7 Singleton (Instancia Unica)

- **Problema:** un solo logger para toda la app.
- **Donde vive:** `lib/infrastructure/logging/app_logger.dart`.
- **Forma en Dart:** `class AppLogger { static final AppLogger _i = AppLogger._(); factory AppLogger() => _i; }`.
- **Regla:** solo para **infraestructura transversal** (logger, clock, path provider).
  Nunca para use cases.

### 4.8 Template Method (Metodo Plantilla)

- **Problema:** todos los presets de compresion ("Alta calidad", "Web", "Archivar")
  comparten pasos: probe -> calcular bitrate -> ejecutar -> mover.
- **Donde vive:** `lib/application/presets/compression_preset_base.dart`.
- **Forma en Dart:** clase abstracta con metodo `run()` que llama a `probe()`, `plan()`,
  `execute()`, `finalize()`. Subclases override `plan()` y opcionalmente `execute()`.

---

## 5. Estructura de carpetas (Clean-ish Architecture)

```
kilovideo/
├── AGENTS.md                      # ← este archivo.
├── README.md
├── pubspec.yaml
├── analysis_options.yaml          # very_good_analysis activado.
├── lib/
│   ├── main.dart                  # entry point. Solo configura providers y runApp.
│   ├── domain/                    # PURE. Cero imports de flutter, dart:io, ffmpeg.
│   │   ├── entities/              # VideoInfo, CompressionProfile, JobResult.
│   │   ├── value_objects/         # Bitrate, Duration, FileSize.
│   │   ├── strategies/            # CompressionStrategy (sealed).
│   │   ├── ports/                 # Interfaces: FfmpegRunner, FileSystem, Clock.
│   │   └── errors/                # CompressionFailure (sealed).
│   ├── application/               # Use cases. Importa domain + ports.
│   │   ├── use_cases/             # CompressVideoUseCase, BatchCompressUseCase.
│   │   ├── presets/               # CompressionPresetBase + HighQuality/Web/Archive.
│   │   └── jobs/                  # JobQueue + CompressionJobCommand.
│   ├── infrastructure/            # Implementaciones concretas.
│   │   ├── ffmpeg/                # FfmpegRunner, FfmpegFacade, ArgsBuilder.
│   │   ├── filesystem/            # LinuxFileSystem (xattr mime, etc).
│   │   └── logging/               # AppLogger singleton.
│   ├── presentation/              # Flutter UI.
│   │   ├── app.dart               # MaterialApp + router.
│   │   ├── pages/                 # HomePage, SettingsPage, ProgressPage.
│   │   ├── widgets/               # CompressionForm, ProgressBar, DropZone.
│   │   └── providers/             # Riverpod providers.
│   └── di/                        # Dependency injection. providers.dart central.
├── linux/                         # .desktop file, scripts instalador.
├── test/                          # Tests paralelos a lib/.
│   ├── domain/
│   ├── application/
│   ├── infrastructure/
│   └── presentation/
├── tool/                          # Scripts de tooling (instalador, AppImage build).
└── integration_test/              # Tests E2E.
```

### Regla de imports (estricta)

| Capa              | Puede importar                              | NO puede importar       |
|-------------------|---------------------------------------------|-------------------------|
| `domain/`         | solo paquetes Dart puros (`dart:core`, `dart:async`). | `flutter`, `dart:io`, ffmpeg |
| `application/`    | `domain/`, `dart:async`, `dart:collection`.  | `flutter`, `dart:io`.   |
| `infrastructure/` | todo lo anterior + `dart:io` + paquetes externos. | `presentation/`.        |
| `presentation/`   | todo lo anterior + `flutter` + `riverpod`.  | -                       |
| `main.dart`       | todo.                                       | -                       |

### Por que esta separacion?
- **Testabilidad:** domain y application se testean sin Flutter ni `pumpWidget`.
- **Reemplazabilidad:** cambiar ffmpeg por MediaCodec (Android) o AVFoundation (Mac)
  es solo cambiar la implementacion de `FfmpegRunner`.
- **Didactica:** cada capa tiene una responsabilidad clara que podemos explicar.

---

## 6. Reglas de codigo

### Naming (Dart style + convenciones del proyecto)

| Elemento                  | Convencion                       | Ejemplo                          |
|---------------------------|----------------------------------|----------------------------------|
| Archivos                  | `snake_case.dart`                | `video_info.dart`                |
| Clases                    | `PascalCase`                     | `VideoInfo`                       |
| Extensiones Freezed       | Sufijo descriptivo               | `VideoInfo` (no `VideoInfoModel`) |
| Metodos publicos          | `lowerCamelCase`                 | `calculateBitrate`               |
| Variables privadas        | `_lowerCamelCase`                | `_currentJob`                    |
| Constantes                | `lowerCamelCase` o `kPrefixed`   | `kMaxConcurrentJobs = 4`         |
| Enums                     | `PascalCase` tipo, `lowerCamelCase` valores | `enum CodecFamily { h264, h265, av1 }` |

### Estilo

- **Longitud de linea:** 80 caracteres (regla de very_good_analysis).
- **Imports:** ordenados alfabeticamente. `dart:`, `package:`, relativos. Tres bloques.
- **Una clase publica por archivo.** Excepcion: extensiones `Freezed` declaradas juntas.
- **`print()` PROHIBIDO.** Usa `AppLogger.i()` / `.w()` / `.e()`.
- **`// ignore_for_file:` PROHIBIDO** sin un comentario multilinea explicando por que.
- **No usar `dynamic`.** Usa `Object?` o tipos genericos.
- **No usar `as` para downcasting** salvo que sea imposible evitarlo (y siempre con
  chequeo previo `is`).

### Analisis estatico

```yaml
# analysis_options.yaml
include: package:very_good_analysis/analysis_options.yaml
analyzer:
  exclude:
    - "**/*.g.dart"      # generado.
    - "**/*.freezed.dart" # generado.
linter:
  rules:
    public_member_api_docs: true     # obliga a /// doc en miembros publicos.
    prefer_single_quotes: true
    require_trailing_commas: true
    avoid_classes_with_only_static_members: false  # los factories estaticos valen.
```

### Por que `public_member_api_docs: true`?
- Te obliga a documentar cada miembro publico.
- Es la base del modo didactico (ver seccion 14).
- Genera documentacion navegable con `dart doc`.

---

## 7. Comentarios pedagogicos (3 niveles)

> Cada archivo debe tener los 3 niveles cuando aplique. Sin excepciones.

### Nivel 1 — Docstring de clase (`///`)

Explica:
- **Que es** (una frase).
- **Que patron(es) aplica** y por que.
- **Ejemplo de uso** (3-5 lineas).

```dart
/// Estrategia para calcular el bitrate objetivo cuando el usuario quiere
/// un **tamano final exacto** en megabytes.
///
/// **Patron:** Strategy (GoF).
/// **Por que:** el calculo "MB exacto" es uno de varios modos posibles
/// (otros son porcentaje, CRF fijo). Cada modo vive en su propia clase y
/// todos implementan [CompressionStrategy], permitiendo que el use case
/// consuma la abstraccion.
///
/// **Ejemplo:**
/// ```dart
/// const strategy = TargetSizeStrategy(megabytes: 25);
/// final bitrate = strategy.calculateBitrate(
///   duration: const Duration(minutes: 10),
/// );
/// ```
class TargetSizeStrategy extends CompressionStrategy { ... }
```

### Nivel 2 — Docstring de metodo publico

Explica contrato: parametros, retorno, excepciones, efectos colaterales.

```dart
/// Calcula el bitrate de video objetivo en kbps para alcanzar el tamano
/// deseado, dejando margen para el audio.
///
/// [megabytes] debe ser positivo. [duration] debe ser positivo.
  /// Devuelve un [Bitrate] en kbps (entero redondeado hacia abajo).
  ///
/// **Lanza:** [ArgumentError] si los parametros son invalidos.
double calculateBitrate({required Duration duration});
```

### Nivel 3 — Comentario inline (`//`)

Para logica no trivial. **Regla:** si tienes que pensarlo dos veces, comentalo.

```dart
// ffmpeg reserva ~128 kbps para audio AAC por defecto al calcular el
// tamaño del contenedor. Restamos ese margen para que el bitrate de
// video no haga overshoot.
final audioOverhead = 128;
final videoBitrateKbps = (totalKbps - audioOverhead).clamp(64, 100_000);
```

### Reglas adicionales

- **Idioma:** espanol obligatorio. (Usuario esta aprendiendo en espanol.)
- **No traducir nombres tecnicos:** SOLID, Strategy, Factory, LSP quedan en ingles.
- **No comentarios vacios** (`// TODO` debe incluir autor + fecha + razon).

---

## 8. Testing (TDD estricto)

### Stack de testing

- `test` para logica pura (domain, application, infrastructure no-UI).
- `flutter_test` para widgets.
- `mocktail` para mocks. NUNCA `mockito` (codegen innecesario).
- `coverage` para % lineas.

### El ciclo Red-Green-Refactor es visible en commits

```
# 1. RED: escribes el test, falla.
git commit -m "test(domain): add failing test for TargetSizeStrategy.calculateBitrate"

# 2. GREEN: minima implementacion que pasa.
git commit -m "feat(domain): implement TargetSizeStrategy.calculateBitrate"

# 3. REFACTOR: limpias nombres, duplicacion, sin cambiar comportamiento.
git commit -m "refactor(domain): extract bitrate math into value object"
```

Esta secuencia de **3 commits por historia** es pedagogica: tu git log muestra
exactamente como se penso el problema.

### Convenciones de tests

- **Un `describe` o `group` por clase** testeada.
- **Un `test` por comportamiento observable**, no por metodo. Si un metodo tiene 3
  comportamientos, son 3 `test`.
- **Nombres de test legibles:** `'should calculate 1000 kbps for 10 min video targeting 7.5 MB'`.
- **Arrange-Act-Assert explicito** (con comentarios si hay 5+ lineas en cada bloque).
- **Mocks minimos:** si mockeas mas de 3 metodos de una clase, probablemente la clase
  hace demasiado (seccion SRP).

### Coverage minima

| Capa            | Coverage minimo | Por que                              |
|-----------------|------------------|--------------------------------------|
| `domain/`       | 95%              | Puras funciones. Deben ser perfectas.|
| `application/`  | 85%              | Use cases. Algunas ramas valen saltarse. |
| `infrastructure/` | 70%           | Glue con el SO. Algunos paths exoticos. |
| `presentation/` | 60%              | Widget tests + golden tests parciales. |

Comando: `dart test --coverage=coverage && genhtml coverage/lcov.info -o coverage/html`.

### Tests obligatorios al anadir codigo

- [ ] Test unitario de la nueva clase/funcion.
- [ ] Si la clase toca `domain/ports/`, test que verifica que la interfaz sigue siendo
  implementable (signature test).
- [ ] Si introduces un nuevo patron GoF, doc en AGENTS.md (seccion 4) + test que
  demuestra su uso.

---

## 9. Integracion Context Menu (Linux)

### Que hace falta

1. **Un archivo `.desktop`** en `linux/kilovideo.desktop`.
2. **Un script envoltorio** en `linux/kilovideo-context-menu.sh` que traduce los
   argumentos del file manager a un llamado CLI a la app Flutter.
3. **Un instalador** en `tool/install_context_menu.sh` que copia ambos archivos a
   `~/.local/share/applications/` y `~/.local/bin/`.
4. **Argumentos CLI en la app** parseados con `package:args`:

```
kilovideo --compress <input_paths...> --target-mb 25
kilovideo --compress <input_paths...> --reduce-percent 40
kilovideo --compress <input_paths...> --preset web
```

### Plantilla `.desktop`

```ini
[Desktop Entry]
Type=Application
Name=KiloVideo Compress
Comment=Compress videos with KiloVideo
Exec=kilovideo-context-menu %F
Icon=kilovideo
MimeType=video/mp4;video/x-matroska;video/webm;video/quicktime;video/x-msvideo;
Actions=compress-size;compress-percent;compress-preset;

[Desktop Action compress-size]
Name=Compress to target size...
Exec=kilovideo-context-menu --target-mb 25 %F

[Desktop Action compress-percent]
Name=Reduce by percentage...
Exec=kilovideo-context-menu --reduce-percent 40 %F

[Desktop Action compress-preset]
Name=Apply Web preset
Exec=kilovideo-context-menu --preset web %F
```

### Por que `%F` y no `%f`?
- `%f` = un solo archivo.
- `%F` = multiples archivos (el caso batch que pediste).
- Sin `%F`, el context menu de 10 videos no apareceria.

### Compatibilidad de file managers

| File Manager    | Soporte `.desktop Actions` | Notas                              |
|-----------------|----------------------------|------------------------------------|
| Nautilus (GNOME)| Si                         | Default en Ubuntu/Fedora.          |
| Dolphin (KDE)   | Si                         | Actions en `ServiceMenus/*.desktop` para menu contextual enriquecido. |
| Caja (MATE)     | Si                         | Mismo flujo que Nautilus.          |
| Nemo (Cinnamon) | Si                         | -                                  |
| Thunar (XFCE)   | Parcial                    | Usa acciones `ucm` custom. Investigar. |
| PCManFM (LXDE)  | No                         | Necesita wrapper custom.           |

**Plan:** soportar Nautilus, Dolphin, Caja, Nemo en v1. Thunar en v1.1.

---

## 10. Manejo de errores

### Sealed class para errores de dominio

```dart
// lib/domain/errors/compression_failure.dart
sealed class CompressionFailure {
  const CompressionFailure(this.message);
  final String message;

  const factory CompressionFailure.ffmpegNotFound() = FfmpegNotFound;
  const factory CompressionFailure.invalidTargetSize(double megabytes) = InvalidTargetSize;
  const factory CompressionFailure.unsupportedCodec(String codec) = UnsupportedCodec;
  const factory CompressionFailure.processTimeout(Duration timeout) = ProcessTimeout;
  const factory CompressionFailure.ioError(String path, Object cause) = IoError;
  const factory CompressionFailure.cancelled() = Cancelled;
}

class FfmpegNotFound extends CompressionFailure { ... }
// etc.
```

### Por que sealed y no jerarquia con clases abstractas?
- El compilador obliga a manejar TODOS los subtipos en cualquier `switch`.
- Si anades `DiskFull` despues, TODOS los `switch` se rompen hasta que los actualizas.
- Es imposible olvidar un caso.

### Propagacion

- **Use cases** devuelven `Future<Either<CompressionFailure, Success>>` o un
  `Result<T, CompressionFailure>` custom.
- **NO usar `throw` para control de flujo** dentro del dominio. Solo para errores
  irrecuperables (bugs del programador).

### Logging obligatorio

- Cada `CompressionFailure` se loguea con `AppLogger.e(...)`.
- El log incluye: timestamp, ruta del input, modo, exit code de ffmpeg si aplica.
- Logs van a `~/.local/share/kilovideo/logs/kilovideo-YYYY-MM-DD.log`.

---

## 11. Logging

### Singleton `AppLogger`

```dart
// lib/infrastructure/logging/app_logger.dart

/// Logger singleton transversal a toda la app.
///
/// **Patron:** Singleton (GoF).
/// **Por que:** una sola fuente de verdad para logs. Multiples instancias harian
/// que cada modulo escriba a archivos distintos.
class AppLogger {
  AppLogger._();
  static final AppLogger _instance = AppLogger._();
  factory AppLogger() => _instance;

  void info(String message, {Map<String, Object?>? fields}) { ... }
  void warn(String message, {Map<String, Object?>? fields}) { ... }
  void error(String message, {Object? error, StackTrace? stack}) { ... }
}
```

### Reglas

- **Niveles:** `info` (eventos normales), `warn` (recuperable), `error` (fallo).
- **NO string interpolation en logs:** preferir campos estructurados.
  ```dart
  // MAL.
  logger.info('Comprimiendo $path a $mb MB');

  // BIEN.
  logger.info('compressing video', fields: {'path': path, 'targetMb': mb});
  ```
- **NO loguear contenido del video ni paths completos en produccion** (PII).
- **Rotacion:** log file rota diario. Maximo 7 archivos retenidos.

---

## 12. Workflow Git

### Branches

- `main` — siempre deployable. Tagged por version.
- `feature/<slug>` — feature nueva. Ej: `feature/target-size-strategy`.
- `fix/<slug>` — bug fix.
- `refactor/<slug>` — refactor sin cambio de comportamiento.
- `docs/<slug>` — solo documentacion.

### Conventional Commits (estricto)

```
feat(domain): add TargetSizeStrategy
fix(ffmpeg): handle ENOSPC exit code as DiskFull failure
test(application): add JobQueue cancellation tests
refactor(domain): extract Bitrate value object
docs(agents): document Template Method pattern usage
chore(deps): bump riverpod to 2.5.1
```

Tipos validos: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `perf`, `build`, `ci`.

### Pull Requests — plantilla obligatoria

```markdown
## Que cambia
<descripcion en 1-3 frases>

## Patron(es) aplicado(s) y por que
- <Strategy>: porque el calculo de bitrate varia segun modo.
- <Factory>: porque hay multiples formas de localizar ffmpeg.

## Que aprendimos
- LSP se rompe si una subclase lanza UnimplementedError.
- El compilador sealed nos obligo a manejar el caso Cancelled.

## Alternativas descartadas
- Strategy con Map<String, Function>: descartado por no ser type-safe.

## Checklist (Definition of Done)
- [ ] Tests pasan (unit + widget).
- [ ] `dart analyze` limpio.
- [ ] `dart format` aplicado.
- [ ] Coverage no baja.
- [ ] Docstrings actualizados.
- [ ] AGENTS.md actualizado si se anade patron nuevo.
- [ ] Comentarios pedagogicos presentes (3 niveles).
```

---

## 13. Definition of Done

Una historia/tarea esta **hecha** solo cuando:

- [ ] Codigo escrito siguiendo TDD (3 commits red/green/refactor visibles).
- [ ] Tests pasan localmente y en CI.
- [ ] `dart analyze` sin warnings.
- [ ] `dart format --set-exit-if-changed .` limpio.
- [ ] Coverage no por debajo del minimo de su capa.
- [ ] Docstrings `///` en todos los miembros publicos.
- [ ] Comentarios pedagogicos inline donde aplique logica no trivial.
- [ ] Si introdujo un patron nuevo, AGENTS.md seccion 4 actualizado.
- [ ] PR con descripcion completa (plantilla seccion 12).
- [ ] Manual smoke test: la app arranca, el context menu aparece en Nautilus/Dolphin.

---

## 14. Modo didactico (reglas de aprendizaje)

> **Regla fundamental:** este proyecto es un aula. Cada decision debe ser explicada.

### A. En el codigo

- Cada clase lleva su seccion **"Que es / Patron / Por que / Ejemplo"** en docstring.
- Cada `switch` exhaustivo lleva un comentario que explique por que importa la
  exhaustividad (vinculado a OCP y sealed classes).
- Cada test lleva su `Arrange-Act-Assert` comentado si no es obvio.

### B. En los commits

- Mensajes de commit en **infinitivo** ("add", "fix", "extract"), no pasado.
- Si un commit es un paso de TDD, el tipo (`test:` / `feat:` / `refactor:`) lo indica.

### C. En los PRs

- La seccion **"Que aprendimos"** NO es opcional. Es donde cristaliza el aprendizaje.
- La seccion **"Alternativas descartadas"** obliga a considerar el espacio de diseno.

### D. Cuando elijas entre dos opciones

- Documenta la opcion elegida y la descartada **en el codigo o en el PR**.
- Si es una decision arquitectonica, anadela a esta AGENTS.md.

### E. Cuando NO sepas como resolver algo

- Regla de las 3 lecturas: lee 3 fuentes distintas antes de preguntar.
- Anota la duda en `docs/dudas.md` (crear si no existe).
- Si la duda es arquitectonica, abrimos un ADR (Architecture Decision Record) en
  `docs/adr/NNNN-titulo.md`.

### F. Ritmo

- **Una historia = una sesion de estudio.** No metas dos features en un solo PR.
- Si la historia es muy grande, partirla. Las historias pequenas cierran mas rapido
  y consolidan aprendizaje.

---

## Apendice A — Comandos utiles del dia a dia

```bash
# Crear proyecto (solo la primera vez).
flutter create --platforms=linux --org com.kilovideo .

# Instalar deps.
flutter pub get

# Tests.
dart test                       # logica pura.
flutter test                    # widgets.
dart test --coverage=coverage   # con cobertura.

# Calidad.
dart analyze
dart format .

# Build Linux release.
flutter build linux --release

# Empaquetar AppImage (requiere linuxdeploy).
bash tool/build_appimage.sh

# Instalar context menu en el sistema actual.
bash tool/install_context_menu.sh

# Ver logs.
tail -f ~/.local/share/kilovideo/logs/kilovideo-$(date +%F).log
```

---

## Apendice B — Glosario rapido

- **GoF:** Gang of Four. Los autores del libro "Design Patterns" (1994) que
  catalogaron 23 patrones clasicos.
- **SOLID:** cinco principios de POO (Single responsibility, Open-closed, Liskov,
  Interface segregation, Dependency inversion). Robert C. Martin.
- **Sealed class:** clase que solo puede extenderse dentro del mismo archivo.
  Dart 3 las usa para jerarquias cerradas y pattern matching exhaustivo.
- **TDD:** Test-Driven Development. Escribir el test ANTES del codigo.
- **Clean Architecture:** propuesta por Robert C. Martin. Separa el software en
  capas con reglas estrictas de dependencia.
- **AppImage:** formato de distribucion Linux auto-contenido. No requiere instalacion.

---

> **Ultima actualizacion:** inicio del proyecto.
> **Mantenedor:** usuario (con asistencia del agente opencode).
> **Rever este archivo:** cada vez que se anada un patron nuevo, una capa nueva,
> o se cambie una regla.