# Semana 4 - Base de datos y prototipo navegable

Esta carpeta contiene las evidencias principales de la Semana 4 para FotoGest Pro.

## Archivos

- `../../database/firestore_modelo_fotogest_pro.md`: modelo oficial de colecciones Firestore.
- `../../database/firestore_seed_data.json`: datos de prueba para las colecciones.
- `../../database/firestore_seed_fotogest_pro.js`: script para insertar los datos en Firestore con Firebase Admin.
- `../../database/firestore.rules`: reglas base de seguridad para Firestore.
- `diagrama_entidad_relacion_fotogest.png`: diagrama ER con entidades, atributos principales y cardinalidades.
- `mapa_navegacion_fotogest.png`: flujo de navegacion del prototipo.
- `screenshots/`: capturas reales del prototipo Flutter.
- `evidencia_base_datos/`: capturas de estructura, datos de prueba y conexion de la base de datos.

## Validaciones realizadas

```bash
flutter analyze
flutter test
flutter build apk --release
node tools/verify_firestore_connection.js
```

Resultado: el proyecto compila correctamente y genera el APK release.
La conexion con Firebase Cloud Firestore tambien fue verificada desde el entorno de desarrollo.
El APK incluye configuracion Firebase para Android y usa Cloud Firestore como fuente real cuando Authentication esta activo.

## Nota sobre Firebase

El proyecto fue planteado desde el inicio con Firebase Authentication + Cloud Firestore. Por eso la implementacion oficial de datos se documenta como colecciones Firestore y la evidencia apunta a la base real del proyecto Firebase.

Para activar el login real en la app, en Firebase Console se debe habilitar Authentication con proveedor Correo/Contrasena y crear el usuario de prueba `edwin.tavarez@example.com`.

## Base Firestore real

Proyecto Firebase: `app-fotografia-881ef`

Base de datos: `(default)`

Colecciones cargadas:

- `usuarios`: 3 documentos
- `clientes`: 3 documentos
- `paquetes`: 3 documentos
- `eventos`: 3 documentos
- `pagos`: 3 documentos

URL para ver la base:

```text
https://console.firebase.google.com/project/app-fotografia-881ef/firestore/databases/-default-/data
```

## Pantallas implementadas

- Login
- Dashboard
- Clientes
- Formulario de cliente
- Eventos
- Pagos
- Paquetes fotograficos
