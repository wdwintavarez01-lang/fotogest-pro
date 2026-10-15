# FotoGest Pro 1.1.0

La entrega académica del 15 de octubre incorpora guardado con confirmación del servidor, una cola persistente por usuario y protección del historial de abonos. El instalador es `FotoGest_Pro_1.1.0.apk`, código Android 3. La huella y las verificaciones finales se conservan junto al instalador. Aprobaron 21 pruebas locales, 30 de reglas, el recorrido Android y las dos etapas del ensayo de reinicio. Las reglas están publicadas; diez documentos activos se normalizaron mediante un commit atómico con precondiciones, sin eliminar registros.

## Guardado y funcionamiento sin conexión

Cada operación se escribe primero en un registro local de `shared_preferences`, separado por UID de Firebase Authentication. El registro conserva la última instantánea confirmada y la cola. Los cambios se envían por orden en transacciones de Firestore. El mensaje «pendiente de sincronizar» distingue un guardado en el dispositivo de un guardado confirmado por Firebase.

La app reintenta al actualizar, al regresar al primer plano y cada 30 segundos mientras está abierta. No ejecuta una tarea de sincronización con la app cerrada. Al reabrirla recupera los pendientes y reintenta. No borrar datos, desinstalar ni cambiar de dispositivo mientras queden pendientes.

La primera autenticación requiere Internet. Si la sesión de Firebase permanece abierta, la app puede reabrirse sin red y consultar la instantánea o registrar pendientes. Después de cerrar sesión se necesita autenticación en línea. Se retiró la comprobación de contraseñas mediante hashes en preferencias; Firebase administra la sesión.

Si el servidor rechaza una operación, el panel muestra el motivo y suspende la cola. La vista vuelve a los datos confirmados, mientras los pendientes se conservan para revisión. «Actualizar y reintentar» vuelve a comprobarlos; «Descartar pendientes» requiere confirmación y elimina únicamente la cola local. Un cambio que el servidor hubiera confirmado antes de un corte reaparecerá al actualizar.

## Integridad y conservación del historial

Cada cuenta guarda el total y abonado en centavos enteros. El abono y el incremento de su cuenta se confirman en una misma transacción. Las reglas comprueban propietario, referencias, un único destino, importe positivo, saldo disponible, total de ventas y revisiones. Dos dispositivos no pueden cobrar por encima del total mediante escrituras válidas.

Los abonos confirmados son inmutables. Una cuenta que tenga abonos no se elimina: puede cancelarse conservando su historial. Clientes, servicios y cuentas sin abonos usan eliminación lógica; las referencias históricas permanecen. Las listas ocultan registros eliminados, pero la consulta del nombre conserva los registros maestros históricos.

Las ediciones requieren la revisión esperada. Un conflicto entre dispositivos se informa y detiene los pendientes para impedir sobrescribir cambios ajenos. Los identificadores combinan prefijo, microsegundos y aleatoriedad.

## Comprobaciones reproducibles

Ejecutar desde la raíz del proyecto con Flutter y Node instalados:

```powershell
flutter pub get
flutter analyze --no-pub
flutter test --no-pub
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
powershell -File tools/build_apk_windows.ps1
```

La prueba de reglas usa exclusivamente `demo-fotogest` en `127.0.0.1:8085`; limpia ese entorno de pruebas. El ensayo de reinicio se aprobó en dos procesos independientes, conservando la instalación con `--no-uninstall`. Se recuperaron sesión y pendiente sin red y se confirmó un único envío al reconectar. Una segunda cuenta no recibió datos ni pendientes de la primera. El ensayo Android utiliza un AVD dedicado, `emulator-5554`, y Firebase con nombre `fotogest-test`, conectado a Authentication 9099 y Firestore 8085. El script alterna el modo avión del AVD y conserva capturas y salida. Sus rutas Windows se ajustan si cambia el equipo. No ejecutarlo contra un teléfono personal.

## Respaldo y restauración

El respaldo privado anterior a la actualización contiene 39 documentos de seis colecciones, incluidos registros heredados. Se guarda fuera de la carpeta académica para no divulgar información de clientes. La restauración de ensayo compara todos los campos en un proyecto local separado:

```powershell
python tools/restore_backup_emulator.py RUTA_PRIVADA_DEL_RESPALDO.json
```

Para exportar: `python tools/backup_firestore.py --project app-fotografia-881ef --output RUTA_PRIVADA.json`, utilizando una sesión Firebase CLI existente. La herramienta de restauración tiene destino fijo local `demo-fotogest-restore`; no restaura en producción. Los respaldos de documentos no incluyen cuentas ni contraseñas de Authentication. El procedimiento de recuperación de cuentas se administra aparte en Firebase. Programar una exportación semanal y antes de cada migración, con retención privada y verificación de restauración.

## Alcance de la entrega

Se conserva la firma de depuración para instalación académica directa. La distribución comercial requiere firma propia, recuperación de cuenta, permisos por rol si se incorpora colaboración, monitoreo y pruebas sobre más dispositivos. La defensa y el ensayo final en el teléfono del autor deben usar exactamente la APK identificada en las evidencias.
