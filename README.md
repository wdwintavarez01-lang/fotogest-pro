# FotoGest Pro

Sistema de gestion para fotografos de eventos.

Aplicacion movil desarrollada en Flutter para organizar clientes, eventos,
paquetes fotograficos y pagos. El flujo central permite iniciar sesion, consultar
un resumen del negocio y ejecutar un CRUD completo de clientes conectado con
Firebase Authentication y Cloud Firestore.

## Stack

- Flutter 3.44.4
- Dart 3.12.2
- Arquitectura MVVM
- Firebase Authentication
- Cloud Firestore
- Datos locales de respaldo para modo demo si Firebase no responde

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
- Paquetes fotograficos

## Funcionalidad principal

CRUD completo de clientes:

- Crear cliente.
- Consultar lista de clientes.
- Ver detalle de cliente.
- Editar cliente.
- Eliminar cliente con confirmacion.

La app tambien consulta eventos, pagos y paquetes desde el repositorio de datos.

## Credenciales de prueba

```text
Correo: edwin.tavarez@example.com
Contrasena: 123456
```

Estas credenciales deben existir en Firebase Authentication para probar el modo
remoto. Si Firebase no responde, la app abre en modo demo local.

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
