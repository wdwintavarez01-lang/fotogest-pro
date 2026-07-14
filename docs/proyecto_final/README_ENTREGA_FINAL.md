# FotoGest Pro - Entrega final

Este paquete corresponde al proyecto practico final de Seminario de Proyecto II
(ISW-411). La aplicacion implementa un flujo movil para fotografos de eventos,
con autenticacion, consulta de dashboard, gestion de clientes, eventos, pagos y
servicios fotograficos.

## Estado de la app

- Framework: Flutter / Dart.
- Backend: Firebase Authentication + Cloud Firestore.
- Arquitectura: MVVM con modelos, repositorio, servicios, vistas y widgets.
- Funcionalidad central: gestion de clientes, servicios, eventos, abonos e
  historial de eventos pagados.
- Persistencia: Cloud Firestore con respaldo local y acceso offline con
  credenciales guardadas.
- Pantallas: Login, Dashboard, Clientes, Formulario de cliente, Eventos, Pagos
  y Servicios.
- Validaciones: correo, contrasena, nombre, telefono, precios, eventos y pagos.

## Flujo que debe probar el evaluador

1. Abrir la app.
2. Iniciar sesion con el usuario de prueba configurado en Firebase.
3. Revisar el Dashboard.
4. Entrar a Clientes.
5. Crear un cliente nuevo.
6. Tocar un cliente para ver el detalle.
7. Editar el cliente.
8. Crear o editar un servicio fotografico.
9. Crear un evento asociado a cliente y servicio.
10. Registrar un abono del evento.
11. Revisar Pagos para confirmar que los eventos pendientes tienen prioridad.
12. Completar el pago de un evento y confirmar que pasa al Historial.
13. Revisar el Dashboard para confirmar abonado y pendiente.

## Archivos importantes

- `lib/main.dart`: configuracion inicial de la app.
- `lib/repositories/fotogest_repository.dart`: lectura y escritura en Firestore.
- `lib/viewmodels/fotogest_view_model.dart`: estado de la aplicacion.
- `lib/views/client_form_screen.dart`: formulario de creacion/edicion.
- `lib/views/package_form_screen.dart`: formulario de servicios.
- `lib/views/event_form_screen.dart`: formulario de eventos.
- `lib/views/payment_form_screen.dart`: formulario de pagos.
- `database/firestore_modelo_fotogest_pro.md`: modelo de datos.
- `database/firestore.rules`: reglas base de Firestore.
- `docs/proyecto_final/documentacion_tecnica.md`: documentacion tecnica.
- `docs/proyecto_final/manual_usuario.md`: guia para usuario final.
- `docs/proyecto_final/plan_pruebas.md`: casos de prueba.

## Comandos de verificacion

```bash
flutter analyze
flutter test
flutter build apk --release
```

## APK

El APK se genera en:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## Repositorio

```text
https://github.com/wdwintavarez01-lang/fotogest-pro.git
```
