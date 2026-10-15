# FotoGest Pro — contexto del proyecto

## Idioma

Edwin no lee inglés. **Todas las respuestas, explicaciones y entregables van en
español.** El código y los comentarios del repositorio están escritos sin
tildes; mantener esa convención dentro de `lib/`. La documentación en Word y
Markdown sí lleva tildes correctas.

## Qué es

Aplicación móvil Android para que fotógrafos independientes gestionen clientes,
servicios fotográficos, eventos, ventas sueltas y cobros. Es el proyecto
práctico de la asignatura Seminario de Proyecto (UAPA, ciclo agosto–octubre
2026, ocho semanas desde el 24 de agosto). Proyecto individual: Edwin asume
todos los roles.

Edwin está repitiendo la asignatura por un error administrativo. El profesor es
distinto y los entregables son distintos, así que el proyecto se presenta como
nuevo, sin referencias al ciclo anterior.

## Stack

- Flutter 3.44 / Dart 3.12, arquitectura MVVM.
- Firebase Authentication (correo y contraseña) + Cloud Firestore.
- Estado por `ChangeNotifier` + `InheritedNotifier` (`lib/widgets/app_scope.dart`).
  **No hay provider ni riverpod y no se deben introducir** sin acordarlo.
- `shared_preferences` para el acceso sin conexión, `intl` para RD$ y fechas.
- Proyecto Firebase: `app-fotografia-881ef`. Repo: `wdwintavarez01-lang/fotogest-pro`.

## Estructura

```
lib/
  models/        entidades: client, photo_package, photo_event, photo_sale, payment, app_user
  repositories/  fotogest_repository.dart — ÚNICO punto de acceso a Firestore
  services/      firebase_service.dart — init y caché offline
  viewmodels/    fotogest_view_model.dart — toda la lógica de cálculo
  views/         12 pantallas
  widgets/       componentes reutilizables
database/        modelo de datos, seed y firestore.rules
docs/            documentación académica por ciclo
tools/           scripts Node de verificación contra Firestore
```

Colecciones Firestore: `usuarios`, `clientes`, `paquetes`, `eventos`, `ventas`,
`pagos`. Los nombres de los campos están en español (`nombre`, `telefono`,
`precio`, `montoAcordado`, `usuarioId`); el mapeo entre esos campos y los
modelos en inglés vive **solo** en el repositorio.

## Reglas de diseño que hay que respetar

1. **Toda lectura y escritura de Firestore pasa por `FotogestRepository`.** Las
   vistas y el ViewModel nunca tocan `FirebaseFirestore` directamente.
2. **Los registros se filtran por propietario.** Cada documento lleva
   `usuarioId` con el UID de Firebase Auth, y las consultas usan
   `where('usuarioId', isEqualTo: uid)`. Nunca volver a un identificador fijo.
3. **El total de un evento se obtiene con `FotogestViewModel.amountForEvent()`**,
   nunca con `packageFor(event.packageId).price`. El monto se congela en el
   evento al crearlo para que cambiar el precio de un servicio no altere deudas
   anteriores.
4. **No se cargan datos de ejemplo en el código.** Las listas del repositorio
   inician vacías; sin conexión responde la caché de Firestore.
5. Las pantallas de lista deben manejar el estado vacío.

## Estado actual (mejoras v2, ya aplicadas)

`flutter analyze` pasa sin errores. Cambios hechos en septiembre 2026:

- UID real de Firebase Auth en lugar del identificador fijo `usr_001`.
- `database/firestore.rules` reescritas: acceso solo al propio `usuarioId`, más
  validación de montos. **Falta publicarlas** con
  `firebase deploy --only firestore:rules`.
- Cierre de sesión con confirmación en el panel de resumen.
- Campo `montoAcordado` en los eventos.
- Caché offline de Firestore activada; datos de ejemplo eliminados.
- Campos de correo y contraseña del login ya no vienen precargados.

Detalle completo en `docs/ciclo_2026_sept/mejoras_v2.md`.

Los documentos viejos de Firestore siguen a nombre de `usr_001`. **Eran datos de
prueba y no interesan**: se pueden borrar desde Firebase Console. El script
`tools/migrar_usuario_id.js` se escribió para rescatarlos y ya no hace falta.

## Pendiente

- Publicar las reglas de Firestore.
- Probar en dispositivo el recorrido completo: crear servicio, cliente, evento,
  venta, abono, historial, modo avión y cierre de sesión.
- Sustituir `test/widget_test.dart` (es la plantilla generada, 347 bytes) por
  pruebas reales de los cálculos de saldo. La documentación del ciclo anterior
  afirmaba tener pruebas automatizadas aprobadas, lo cual no se sostiene.
- Entregables académicos del ciclo, en `docs/ciclo_2026_sept/`.

## Comandos

```bash
flutter analyze
flutter test
flutter run
flutter build apk --release
firebase deploy --only firestore:rules
node tools/verify_firestore_connection.js
```

## Cómo trabaja Edwin

- Pide retroalimentación concreta y breve, sin rodeos.
- Espera que se le señalen los problemas de credibilidad o exactitud por
  iniciativa propia, incluso cuando no los pregunta.
- Los entregables académicos van en Word (.docx) con estilo profesional azul
  marino, no como páginas web.
- Antes de hacer cambios grandes, conviene preguntarle qué priorizar.


## Actualización verificada del 15 de octubre de 2026

La entrega actual es **1.1.0+3**. Esta sección actualiza los estados históricos anteriores: las reglas ya están publicadas y `test/widget_test.dart` contiene una prueba real, no una plantilla. Ver `docs/proyecto_final/cierre_1_1_0.md`.

- Firebase Auth conserva la sesión; se retiró el acceso por hash de contraseña en preferencias.
- `PendingJournal` conserva una instantánea confirmada y una cola por UID en preferencias. La interfaz distingue confirmado, pendiente y rechazado.
- Los pagos se confirman en una transacción con el acumulado de su cuenta y centavos enteros; son inmutables. Las eliminaciones son lógicas y no se borran cuentas con abonos.
- Cada edición lleva revisión esperada. Se ensayaron conflictos y dos cobros concurrentes sobre el mismo saldo.
- Se declararon los permisos de Internet en el manifiesto principal de Android.
- FlutterFire resuelto: core 4.15.0, auth 6.7.0, Firestore 6.10.0, interfaz 8.0.7. Esta última corrige el Future completado dos veces al fallar una transacción.
- Aprobaron 21 pruebas locales, 30 de reglas e integración Android con modo avión. El ensayo de reinicio conserva la instalación con `--no-uninstall` y recupera sesión y pendiente entre procesos.
- Respaldo privado: 39 documentos, restaurados y comparados en un emulador aislado. Migración remota: diez documentos activos con precondiciones y verificación; 26 registros heredados se conservaron sin reasignarlos ni borrarlos.
- El código 1.1.0, la ficha con capturas y el informe final se conservan en Git. La entrega incluye un ZIP con huellas; su commit de referencia se registra en las evidencias de sincronización.

Para compilar en este equipo, `tools/build_apk_windows.ps1` aplica temporalmente la alternativa TCP de Java. El video y el ensayo final en el teléfono del autor continúan a su cargo. No borrar datos de la app mientras queden cambios pendientes.
