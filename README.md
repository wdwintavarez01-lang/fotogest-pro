# FotoGest Pro

Prototipo navegable de aplicacion movil para fotografos independientes que trabajan en eventos. Permite demostrar el flujo principal del MVP: acceso, resumen del negocio, clientes, formulario de cliente, eventos, pagos y paquetes fotograficos.

## Stack

- Flutter 3.44.4
- Dart 3.12.2
- Arquitectura MVVM
- Persistencia preparada para Firebase Authentication + Cloud Firestore
- Datos mock locales para que el prototipo compile y se ejecute sin configuracion externa

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
```

## Pantallas implementadas

- Login
- Dashboard
- Clientes
- Formulario de cliente
- Eventos
- Pagos
- Paquetes fotograficos

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

## Datos base

El modelo del prototipo corresponde al DER de Semana 4:

- usuarios
- clientes
- eventos
- paquetes
- pagos

El script de creacion y datos de prueba se entrega por separado como `fotogest_pro_semana4.sql`.
