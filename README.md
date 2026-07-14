# FotoGest Pro

Sistema de gestion para fotografos de eventos.

Aplicacion movil desarrollada en Flutter para organizar clientes, eventos,
servicios fotograficos y pagos. El flujo central permite iniciar sesion,
consultar un resumen del negocio y ejecutar operaciones completas de clientes,
servicios, eventos y cobros conectadas con Firebase Authentication y Cloud
Firestore.

## Stack

- Flutter 3.44.4
- Dart 3.12.2
- Arquitectura MVVM
- Firebase Authentication
- Cloud Firestore
- Acceso offline con credenciales guardadas despues de un login exitoso

## Estructura

```text
lib/
  models/
  repositories/
  services/
  utils/
  viewmodels/
  views/
  widgets/
database/
docs/semana_4/
```

## Pantallas implementadas

- Login
- Dashboard
- Clientes
- Detalle de cliente
- Formulario de cliente para crear y editar
- Eventos
- Pagos
- Servicios fotograficos

## Funcionalidad principal

Flujo funcional principal:

- Crear, consultar, editar y eliminar clientes sin eventos asociados.
- Crear, consultar, editar y eliminar servicios fotograficos.
- Crear, consultar, editar y eliminar eventos asociados a cliente y servicio.
- Registrar abonos asociados a eventos pendientes.
- Priorizar cobros pendientes y mover eventos pagados al historial.
- Calcular abonado y pendiente desde los abonos registrados.
- Entrar en modo offline usando credenciales guardadas previamente.

La base remota usa las colecciones `usuarios`, `clientes`, `paquetes`,
`eventos` y `pagos`.

## Credenciales de prueba

```text
Correo: edwin.tavarez@example.com
Contrasena: 123456
```

Estas credenciales deben existir en Firebase Authentication para probar el modo
Online. Si no hay internet, la app permite entrar con esas mismas credenciales
solo si ya fueron usadas exitosamente antes en el dispositivo.

## Validacion local

```bash
flutter analyze
flutter test
flutter build apk --release
```

APK generado:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## Documentacion final

La carpeta `docs/proyecto_final/` contiene:

- `README_ENTREGA_FINAL.md`
- `documentacion_tecnica.md`
- `manual_usuario.md`
- `plan_pruebas.md`

## Datos base

El modelo del prototipo corresponde al DER de Semana 4:

- usuarios
- clientes
- eventos
- paquetes
- pagos

La base oficial seleccionada para el proyecto es Firebase Firestore. Los archivos principales son:

- `database/firestore_modelo_fotogest_pro.md`
- `database/firestore_seed_data.json`
- `database/firestore_seed_fotogest_pro.js`
- `database/firestore.rules`

La base real esta creada en Firebase:

```text
https://console.firebase.google.com/project/app-fotografia-881ef/firestore/databases/-default-/data
```
