# FotoGest Pro - Entrega final

Este paquete corresponde al proyecto practico final de Seminario de Proyecto II
(ISW-411). La aplicacion implementa un flujo movil para fotografos de eventos,
con autenticacion, consulta de dashboard, gestion de clientes, eventos, pagos y
paquetes fotograficos.

## Estado de la app

- Framework: Flutter / Dart.
- Backend: Firebase Authentication + Cloud Firestore.
- Arquitectura: MVVM con modelos, repositorio, servicios, vistas y widgets.
- Funcionalidad central: CRUD completo de clientes.
- Persistencia: Cloud Firestore con respaldo local de Firestore cuando aplica.
- Pantallas: Login, Dashboard, Clientes, Formulario de cliente, Eventos, Pagos
  y Paquetes.
- Validaciones: correo, contrasena, nombre y telefono.

## Flujo que debe probar el evaluador

1. Abrir la app.
2. Iniciar sesion con el usuario de prueba configurado en Firebase.
3. Revisar el Dashboard.
4. Entrar a Clientes.
5. Crear un cliente nuevo.
6. Tocar un cliente para ver el detalle.
7. Editar el cliente.
8. Eliminar el cliente.
9. Revisar Eventos, Pagos y Paquetes.

## Archivos importantes

- `lib/main.dart`: configuracion inicial de la app.
- `lib/repositories/fotogest_repository.dart`: lectura y escritura en Firestore.
- `lib/viewmodels/fotogest_view_model.dart`: estado de la aplicacion.
- `lib/views/client_form_screen.dart`: formulario de creacion/edicion.
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
