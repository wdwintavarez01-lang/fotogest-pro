# Semana 4 - Base de datos y prototipo navegable

Esta carpeta contiene las evidencias principales de la Semana 4 para FotoGest Pro.

## Archivos

- `../../database/firestore_modelo_fotogest_pro.md`: modelo oficial de colecciones Firestore.
- `../../database/firestore_seed_data.json`: datos de prueba para las colecciones.
- `../../database/firestore_seed_fotogest_pro.js`: script para insertar los datos en Firestore con Firebase Admin.
- `../../database/firestore.rules`: reglas base de seguridad para Firestore.
- `../../database/fotogest_pro_semana4.sql`: validacion local equivalente del modelo logico.
- `diagrama_entidad_relacion_fotogest.png`: diagrama ER con entidades, atributos principales y cardinalidades.
- `mapa_navegacion_fotogest.png`: flujo de navegacion del prototipo.
- `screenshots/`: capturas reales del prototipo Flutter.
- `evidencia_base_datos/`: capturas de estructura, datos de prueba y conexion de la base de datos.

## Validaciones realizadas

```bash
flutter analyze
flutter test
flutter build apk --release
```

Resultado: el proyecto compila correctamente y genera el APK release.

## Nota sobre Firebase y SQL

El proyecto fue planteado desde el inicio con Firebase Authentication + Cloud Firestore. Por eso la implementacion oficial de datos se documenta como colecciones Firestore. El SQL incluido no cambia el stack; se usa solo como evidencia local de normalizacion y prueba del modelo conceptual.

## Pantallas implementadas

- Login
- Dashboard
- Clientes
- Formulario de cliente
- Eventos
- Pagos
- Paquetes fotograficos
