# Cómo agregar una funcionalidad a KiloVideo

> Guía paso a paso. Sigue siempre este orden. En cada paso: **qué haces**,
> **por qué**, y **qué principio SOLID / patrón GoF aplicas**.

---

## Antes de tocar nada

Respondé estas preguntas en papel:

1. **¿Qué quiero que la app haga?** (1 frase).
2. **¿Qué input recibe del usuario?**
3. **¿Qué output produce?**
4. **¿En qué capa vive?** (domain / application / infrastructure / presentation).

Si no podés responderlas, no estás listo para codear.

---

## Paso 1 — Empezar por `domain/` (TDD: ciclo Red)

### Qué hacés

Escribís el test **primero** en `test/domain/...`. Corrés `dart test`. **Falla.**

### Por qué

TDD = **Test-Driven Development**. El test **define** el comportamiento antes de que exista el código. Si el test pasa al escribirlo, no estaba testeando nada.

### Principios aplicados

- **SRP** (Single Responsibility): la clase hace UNA cosa.
- **Por qué test primero:** la API se diseña desde el consumidor, no desde el implementador.

### Convenciones

- Un archivo de test por clase.
- Nombre del test = comportamiento en lenguaje humano.
- Tres bloques: `# Arrange`, `# Act`, `# Assert`.

### Ejemplo

```dart
// test/domain/strategies/percentage_reduction_strategy_test.dart
test('reduce 40% un bitrate de 5000 kbps', () {
  const strategy = PercentageReductionStrategy(percent: 40);
  final result = strategy.calculateBitrate(
    duration: Duration(minutes: 10),
    originalBitrateKbps: 5000,
  );
  expect(result, closeTo(3000, 0.01));
});
```

---

## Paso 2 — Implementar `domain/` (TDD: ciclo Green)

### Qué hacés

Escribís **la implementación mínima** que pase el test. Corrés `dart test`. **Pasa.**

### Por qué

Mínima implementación = menos código que mantener. Si no es la mínima, escribís de más.

### Principios aplicados

- **OCP** (Open/Closed): la clase queda abierta para extensión, cerrada para modificación.
- **LSP** (Liskov): si la clase extiende otra, satisface su contrato.
- **Patrón GoF:** elegí ANTES de codear (Strategy, Factory, etc.).

### Convenciones

- Docstring `///` en cada miembro público.
- Comentario inline `#` para lógica no trivial.
- Sin `import 'dart:io'` ni `package:flutter`. **Domain es puro.**

### Ejemplo

```dart
// lib/domain/strategies/percentage_reduction_strategy.dart
class PercentageReductionStrategy implements CompressionStrategy {
  const PercentageReductionStrategy({required this.percent});
  final double percent;

  @override
  double calculateBitrate(VideoInfo info) {
    // validaciones
    return info.originalBitrateKbps * (1 - percent / 100);
  }
}
```

---

## Paso 3 — Refactor de `domain/` (TDD: ciclo Refactor)

### Qué hacés

Limpiás la implementación. **Tests siguen pasando.**

### Qué refactorizar

- Nombres confusos.
- Duplicación entre tests.
- Constantes con nombres.
- Docstrings pedagógicas (3 niveles).

### Por qué

El refactor es la **única** fase donde cambiás implementación sin cambiar comportamiento. Por eso corre con tests verdes.

### Principios aplicados

- **DRY** (Don't Repeat Yourself): si ves el mismo número dos veces, es constante.
- **Cohesión alta**: todo lo de la clase está relacionado.

### Convenciones

- 1 commit por fase: `test:` → `feat:` → `refactor:`.
- Commits en infinitivo, no pasado.

---

## Paso 4 — Agregar port si hace falta (DIP)

### Qué hacés

Si tu funcionalidad habla con el mundo externo (ffmpeg, filesystem, red), declarás una **interfaz** en `lib/domain/ports/`.

### Por qué

**DIP** (Dependency Inversion): el dominio no sabe cómo se hace. Solo sabe qué necesita.

### Patrón GoF

- **Port** (Hexagonal Architecture): interfaz en domain, implementación en infrastructure.
- **Factory Method**: si hay varias formas de instanciar, una factory las elige.

### Convenciones

- `abstract interface class NombrePort`.
- 1 método por responsabilidad (ISP).
- Sin lógica, solo firma.

### Ejemplo

```dart
// lib/domain/ports/file_system.dart
abstract interface class FileSystem {
  Future<bool> exists(String path);
  Future<void> delete(String path);
}
```

---

## Paso 5 — Use case en `application/` (TDD)

### Qué hacés

Test del use case primero (con stubs de los ports). Después implementás.

### Por qué

El use case **orquesta**. Si una sola clase hace 3 cosas, viola SRP. El use case cohesiona.

### Principios aplicados

- **SRP**: un use case = una intención del usuario.
- **DIP**: depende de ports, no de concreciones.

### Convenciones

- Un solo método `call()` para usar como función.
- Constructor `const` con los ports como dependencias.
- Devuelve `Future<Result>` con sealed class, no `throw`.

### Ejemplo

```dart
// lib/application/use_cases/delete_video_use_case.dart
class DeleteVideoUseCase {
  const DeleteVideoUseCase({required this.fileSystem});
  final FileSystem fileSystem;

  Future<DeleteResult> call({required String path}) async {
    if (!await fileSystem.exists(path)) {
      return DeleteResult.notFound();
    }
    await fileSystem.delete(path);
    return DeleteResult.success();
  }
}
```

---

## Paso 6 — Infraestructura en `infrastructure/` (TDD si es lógica pura)

### Qué hacés

Implementás el port real. Si toca I/O, los tests son **integration tests** (no unit).

### Por qué

Infrastructure es el **adaptador al mundo real**. Acá sí va `dart:io`, `Process`, `Socket`.

### Patrón GoF

- **Adapter**: adapta la API externa a tu interfaz.
- **Facade**: si ffmpeg tiene 200 flags, tu facade expone 5 métodos.
- **Builder**: si los args de ffmpeg son verbosos, encadená.
- **Singleton**: logger, clock, etc. Una sola instancia.

### Convenciones

- `class NombreImpl implements NombrePort`.
- Inyectá dependencias por constructor.
- Sin lógica de negocio. Esa vive en domain.

### Ejemplo

```dart
// lib/infrastructure/filesystem/linux_file_system.dart
class LinuxFileSystem implements FileSystem {
  @override
  Future<bool> exists(String path) async {
    return File(path).exists();
  }

  @override
  Future<void> delete(String path) async {
    await File(path).delete();
  }
}
```

---

## Paso 7 — DI (`lib/di/providers.dart`)

### Qué hacés

Declarás los providers Riverpod que conectan ports con implementaciones.

### Por qué

**Composition Root**: un solo lugar conoce toda la app. Cambiar la implementación real = cambiar UNA línea.

### Patrón GoF

- **Factory Method**: los providers crean las instancias.
- **Singleton implícito**: Riverpod cachea por defecto.

### Convenciones

- Un provider por port.
- `Provider` para concreciones, `StateProvider` para estado.
- Override en tests con `ProviderScope(overrides: [...])`.

### Ejemplo

```dart
// lib/di/providers.dart
final fileSystemProvider = Provider<FileSystem>((ref) {
  return LinuxFileSystem();
});

final deleteVideoUseCaseProvider = Provider<DeleteVideoUseCase>((ref) {
  return DeleteVideoUseCase(fileSystem: ref.watch(fileSystemProvider));
});
```

---

## Paso 8 — Presentación en `presentation/`

### Qué hacés

- Widgets reusables en `lib/presentation/widgets/`.
- Páginas en `lib/presentation/pages/`.
- Providers específicos de UI en `lib/presentation/providers/`.

### Por qué

La UI es lo que **cambia más**. Aislada del domain, se refactoriza sin riesgo.

### Principios aplicados

- **SRP**: un widget = una responsabilidad visual.
- **OCP**: widgets aceptan parámetros, no modifican state interno.

### Patrón GoF en UI

- **Observer**: `StreamProvider` para progreso.
- **State**: Riverpod maneja el state.

### Convenciones

- Widgets chiquitos. Si pasa 100 líneas, dividí.
- `const` siempre que se pueda.
- Un widget por archivo.

### Ejemplo

```dart
// lib/presentation/widgets/delete_button.dart
class DeleteButton extends StatelessWidget {
  const DeleteButton({super.key, required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      onPressed: onPressed,
      child: const Text('Borrar'),
    );
  }
}
```

---

## Paso 9 — Verificar

### Checklist

- [ ] `dart test` todo verde.
- [ ] `flutter analyze` sin warnings.
- [ ] `dart format` aplicado.
- [ ] Coverage no bajó.
- [ ] Manual smoke test: la app arranca.
- [ ] Definición de Hecho (Agent.md sección 13) cumplida.

---

## Resumen visual

```
1. test (RED)             ─→  test/domain/...
2. impl mínima (GREEN)    ─→  lib/domain/...
3. refactor               ─→  test/domain/... + lib/domain/...
4. port (si hace falta)   ─→  lib/domain/ports/...
5. use case               ─→  lib/application/use_cases/...
6. infrastructure         ─→  lib/infrastructure/...
7. DI                     ─→  lib/di/providers.dart
8. presentation           ─→  lib/presentation/...
9. verificar
```

---

## Mapa de principios por capa

| Capa | Principios dominantes | Patrones GoF |
|------|----------------------|--------------|
| `domain/` | SRP, OCP, LSP | Strategy, sealed, value objects |
| `application/` | SRP, DIP | Use case, Template Method (presets) |
| `infrastructure/` | DIP, OCP | Adapter, Facade, Builder, Singleton |
| `presentation/` | SRP, OCP | Observer (stream), Factory (widgets) |
| `di/` | DIP | Factory Method, Singleton |

---

## Antipatrones a evitar

| Antipatrón | Por qué |
|------------|---------|
| Test después de la impl | No es TDD. Solo verificás lo que escribiste. |
| Import `package:flutter` en `domain/` | Domain deja de ser puro. Tests requieren Flutter. |
| `throw` para control de flujo | Mezclás bugs del programador con fallos del dominio. |
| `print('log')` en producción | Usá `AppLogger`. |
| `dynamic` en código | Usá `Object?` o genéricos. |
| Método de 200 líneas | Dividí. SRP. |

---

## Commit por paso

```
test(domain): add failing test for NuevaStrategy
feat(domain): implement NuevaStrategy
refactor(domain): extract constants in NuevaStrategy
feat(application): add NuevoUseCase
feat(infrastructure): implement NuevoPort
feat(di): wire NuevoUseCase
feat(presentation): add NuevoWidget
```

---

> **Última actualización:** inicio del proyecto.
> **Mantenedor:** usuario.
