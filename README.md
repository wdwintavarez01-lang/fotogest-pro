# FotoGest Pro 1.1.0

Aplicación Android para gestionar clientes, servicios fotográficos, eventos, ventas independientes, abonos y saldos. Entrega de Seminario de Proyecto II, UAPA, 15 de octubre de 2026.

## Ficha del proyecto

| Dato | Descripción |
| --- | --- |
| Autor | Edwin De Jesús Tavarez Minaya, matrícula 100053122 |
| Institución | Universidad Abierta para Adultos, UAPA |
| Asignatura | Seminario de Proyecto II, ISW411 |
| Facilitador | Ing. Henry Candelario |
| Versión | 1.1.0+3, Android |
| Tecnologías | Flutter, Dart, Firebase Authentication y Cloud Firestore |
| Repositorio | [wdwintavarez01-lang/fotogest-pro](https://github.com/wdwintavarez01-lang/fotogest-pro) |

[Ficha con capturas de los módulos](docs/proyecto_final/ficha_proyecto.md) · [Informe final de las seis fases](docs/proyecto_final/FotoGest_Pro_Informe_Final_Seis_Fases.docx)

### Capturas de la versión 1.1.0

Datos de ensayo del recorrido Android I01 en Firebase local; la pantalla de acceso corresponde a la APK de distribución.

<p>
  <img src="docs/proyecto_final/screenshots/v1_1_0/android_1_1_0_resumen.png" width="220" alt="Panel con resumen y sincronización" />
  <img src="docs/proyecto_final/screenshots/v1_1_0/android_1_1_0_events.png" width="220" alt="Evento con total, abono y saldo pendiente" />
  <img src="docs/proyecto_final/screenshots/v1_1_0/android_1_1_0_payments.png" width="220" alt="Módulo de cobros y pagos" />
</p>

## Preparación

Requisitos: Flutter 3.44.4, Dart 3.12.2, Android SDK y JDK 21. El paquete es `com.edwintavarez.fotogest_pro`.

```powershell
flutter pub get
flutter analyze --no-pub
flutter test --no-pub
powershell -File tools/build_apk_windows.ps1
```

El script genera la versión **1.1.0+3**. Mantiene la firma de depuración para instalación académica directa. En este equipo aplica temporalmente la alternativa TCP del selector Java. La compilación regenera los plugins release y excluye `integration_test`.

## Firebase y acceso

El proyecto configurado es `app-fotografia-881ef`, con Firebase Authentication y seis colecciones Firestore: `usuarios`, `clientes`, `paquetes`, `eventos`, `ventas` y `pagos`. Las cuentas se habilitan en Authentication. No se incluyen contraseñas ni claves administrativas en la entrega.

La primera entrada requiere conexión. Firebase conserva la sesión; al reabrir sin red se recuperan la última instantánea confirmada y los pendientes del UID. Después de cerrar sesión se necesita autenticación en línea.

Las reglas finales están publicadas. Se migraron diez documentos activos con precondiciones y verificación, sin eliminar registros. Los datos heredados se conservaron. Los ejemplos antiguos de `database/` necesitan adaptación y no deben cargarse en la base operativa.

## Arquitectura y comportamiento

MVVM con `ChangeNotifier` y `InheritedNotifier`; todo el acceso a Firestore se concentra en `FotogestRepository`. `PendingJournal` conserva la instantánea y la cola por UID en una sola estructura local. La interfaz distingue **confirmado**, **pendiente** y **rechazado**. Reintenta al actualizar, al regresar al primer plano y cada 30 segundos mientras la app está abierta.

Los abonos se confirman junto con el acumulado de su cuenta en una transacción. Las reglas comprueban propietario, referencias, destino único, saldo, centavos y revisiones. Los pagos confirmados son inmutables. Las eliminaciones son lógicas; las cuentas con abonos se conservan y pueden cancelarse. El precio acordado de un evento permanece fijo cuando cambia el catálogo.

## Verificación

Aprobaron 21 pruebas locales, 30 pruebas de reglas y la integración Android con modo avión, sincronización y conflictos. El ensayo de reinicio detuvo el proceso, recuperó sesión y pendiente sin red y confirmó un único envío. Una segunda cuenta no recibió la caché de la primera.

```powershell
npm --prefix tools/firestore-tests ci
firebase emulators:start --only firestore,auth --project demo-fotogest
```

En otra terminal:

```powershell
node tools/firestore-tests/rules.test.mjs
python tools/run_android_integration.py
python tools/run_android_integration.py integration_test/restart_test.dart PREPARAR
adb -s emulator-5554 shell am force-stop com.edwintavarez.fotogest_pro
python tools/run_android_integration.py integration_test/restart_test.dart RECUPERAR
```

El ensayo utiliza exclusivamente un AVD dedicado `emulator-5554` y servicios locales. El script alterna su modo avión y conserva la instalación con `--no-uninstall`; ajustar sus rutas Windows en otro equipo. No ejecutarlo contra un teléfono personal.

## Respaldo y documentación

```powershell
python tools/backup_firestore.py --project app-fotografia-881ef --output RUTA_PRIVADA.json
python tools/restore_backup_emulator.py RUTA_PRIVADA.json
```

La exportación usa una sesión Firebase CLI existente y no modifica registros. La restauración solo apunta a `demo-fotogest-restore` en localhost. Los respaldos anterior y posterior a la migración contienen 39 documentos; ambos se restauraron y compararon. Las cuentas Authentication se administran aparte.

- [Manual de usuario](docs/proyecto_final/manual_usuario.md)
- [Documentación técnica](docs/proyecto_final/documentacion_tecnica.md)
- [Cierre y pruebas de la versión](docs/proyecto_final/cierre_1_1_0.md)

El repositorio reúne el código de la versión 1.1.0, las pruebas, la ficha y el informe académico. El ZIP del código y las huellas de la entrega permiten verificar su correspondencia con el instalador. La defensa en video y el ensayo final en el teléfono del autor deben usar la APK 1.1.0 identificada. No se han medido tiempos de respuesta en todos los dispositivos ni se incluyen cobros bancarios, facturación fiscal o colaboración por roles.
