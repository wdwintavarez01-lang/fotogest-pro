# Análisis del proyecto FotoGest Pro (estado al reiniciar Seminario de Proyecto, sept-2026)

> Este documento es el diagnóstico hecho **antes** de aplicar las mejoras v2.
> Describe el estado heredado del ciclo anterior. Los puntos 1 a 7 de la
> sección 3 ya fueron corregidos; ver `mejoras_v2.md`. El resto sigue abierto.

Ruta local: `C:\Users\Soporte TI\Documents\New project\fotogest_pro_flutter`
Repo: https://github.com/wdwintavarez01-lang/fotogest-pro.git — rama `main`, commit final del ciclo pasado `b0faf94`
Firebase: proyecto `app-fotografia-881ef`, Firestore `(default)`

## 1. Qué hay en la carpeta

**Código (`lib/`, 44 archivos, MVVM)**

- `models/`: `app_user`, `client`, `photo_package`, `photo_event`, `photo_sale`, `payment` (clases inmutables con `copyWith`, sin `toMap/fromMap` — el mapeo vive en el repositorio).
- `repositories/fotogest_repository.dart`: único punto de acceso a Firestore.
- `viewmodels/fotogest_view_model.dart`: `ChangeNotifier` con todos los cálculos (abonado, pendiente, pendientes/pagados, validación de dependencias).
- `views/`: 12 pantallas (login, dashboard, clientes+form, eventos+form, paquetes/servicios+form, ventas+form, pagos+form).
- `widgets/`: `app_scope` (InheritedNotifier), `app_shell`, `fotogest_bottom_nav`, `metric_tile`, `status_chip`.
- `utils/`: `app_theme` (Material 3, semilla `#176B87`), `formatters` (RD$, es_DO).
- `services/firebase_service.dart`: init de Firebase con tolerancia a fallo.

**Datos (`database/`)**: modelo Firestore en MD, seed JSON, script Node de seed, `firestore.rules`.

**Documentación (`docs/`)**

- `semana_4/`: README, DER PNG, mapa de navegación PNG, 7 screenshots, evidencias de BD.
- `proyecto_final/`: README de entrega, documentación técnica, manual de usuario, plan de pruebas (23 casos), `Documento_Entrega_Final_FotoGest_Pro.docx`, 7 screenshots.

**Otros**: `tools/verify_firestore_connection.js`, `tools/verify_client_crud_firestore.js`, `test/widget_test.dart` (347 bytes ≈ plantilla), carpetas `android/`, `web/`, `build/`.

## 2. Stack real (verificado en `pubspec.yaml`)

Flutter SDK `^3.12.2` · firebase_core 4.11 · cloud_firestore 6.6 · firebase_auth 6.5.4 · shared_preferences 2.5.5 · crypto 3.0.7 · intl 0.20.2 · flutter_lints 6.0. Sin provider/riverpod/get_it: el estado va por `InheritedNotifier`.

## 3. Hallazgos técnicos (los que un profesor nuevo puede cuestionar)

**Críticos — CORREGIDOS en v2**

1. `usuarioId` estaba fijo en `'usr_001'` en todo el ViewModel y el repositorio (18 ocurrencias). Nunca se usaba `FirebaseAuth.currentUser.uid`.
2. `firestore.rules` permitía `read, write` a **cualquier** usuario autenticado sobre **todas** las colecciones. Sin filtro por propietario ni validación de campos.
3. El pendiente del evento se calculaba contra `paquete.precio` **actual**. Editar el precio de un servicio cambiaba retroactivamente la deuda de eventos históricos.
4. Credenciales de prueba precargadas en el formulario de login.

**Importantes — 5 y 6 corregidos en v2, el resto abierto**

5. El "modo offline" no era persistencia real: no se habilitaba `Settings(persistenceEnabled: true)`. Solo se comparaba un SHA-256 sin salt en SharedPreferences y, si Firestore no respondía, se mostraban listas semilla escritas en el código como si fueran datos del usuario.
6. No existía cerrar sesión: cero ocurrencias de `signOut` en todo `lib/`.
7. **ABIERTO** — No hay pruebas reales. `flutter test` solo corre la plantilla generada; el documento de entrega del ciclo anterior afirma "prueba automatizada aprobada".
8. **ABIERTO** — `loadRemoteData()` descarga las colecciones completas con `.get()` y filtra en memoria. Sin streams ni paginación. Aceptable a esta escala, pero no escala.
9. **CORREGIDO parcialmente** — La colección `usuarios` no se consumía en ninguna pantalla; ahora registra el perfil del usuario autenticado, pero sigue sin pantalla propia.
10. **ABIERTO** — Existe `web/` pero `firebase_options.dart` lanza `UnsupportedError` para web e iOS: solo Android compila.

**Menores — todos abiertos**

11. Toda la documentación del ciclo anterior está sin tildes (se escribió en ASCII).
12. Las rutas de APK/ZIP del documento de entrega apuntan a carpetas fuera del proyecto.
13. `app_shell.dart` está definido pero no se usa en ninguna vista.
14. `MaterialApp.builder` fija el ancho a 430 px y alinea arriba-izquierda — en tablet se ve una franja.
