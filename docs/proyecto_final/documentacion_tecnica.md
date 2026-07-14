# Documentacion tecnica - FotoGest Pro

## Descripcion del problema

Fotografos independientes suelen manejar clientes, eventos, paquetes y pagos en
notas, hojas de calculo o mensajes sueltos. Esto dificulta consultar saldos,
recordar fechas y mantener un historial ordenado del servicio. FotoGest Pro
organiza esa informacion en una aplicacion movil sencilla.

## Objetivo general

Desarrollar una aplicacion movil funcional que permita gestionar clientes de un
negocio fotografico y consultar eventos, pagos y paquetes desde una interfaz
adaptada a dispositivos moviles.

## Alcance de esta version

Incluye inicio de sesion, dashboard, CRUD completo de clientes, consulta de
eventos, consulta de pagos y consulta de paquetes fotograficos. No incluye
subida de fotografias, facturacion fiscal, pagos en linea ni publicacion en
tienda de aplicaciones.

## Tecnologias utilizadas

- Flutter: desarrollo movil multiplataforma.
- Dart: lenguaje principal de la aplicacion.
- Firebase Authentication: inicio de sesion.
- Cloud Firestore: base de datos remota.
- Material Design: componentes visuales moviles.

## Arquitectura

La app usa un patron MVVM sencillo:

- `models`: entidades principales del dominio.
- `repositories`: comunicacion con Firestore y datos locales de respaldo.
- `services`: inicializacion de Firebase.
- `viewmodels`: estado de la app y operaciones disponibles para las vistas.
- `views`: pantallas principales.
- `widgets`: componentes reutilizables.

## Modelo de datos

Colecciones principales en Firestore:

- `usuarios`: usuarios del sistema.
- `clientes`: clientes del fotografo.
- `eventos`: sesiones o eventos fotograficos.
- `paquetes`: paquetes de servicio.
- `pagos`: abonos o pagos asociados a eventos.

## Funcionalidad CRUD implementada

La funcionalidad central completa se implemento sobre `clientes`:

- Crear cliente desde el formulario.
- Leer clientes desde la lista.
- Ver detalle del cliente en una hoja inferior.
- Editar cliente existente.
- Eliminar cliente con confirmacion.

## Validaciones

- El correo es obligatorio y debe tener formato basico valido.
- La contrasena es obligatoria y debe tener al menos 6 caracteres.
- El nombre del cliente es obligatorio y debe tener al menos 3 caracteres.
- El telefono es obligatorio y debe contener al menos 10 digitos.

## Decisiones de diseno

Se eligio Firestore porque permite persistencia remota, integracion directa con
Flutter y una estructura flexible por colecciones. Se mantuvieron datos locales
de respaldo para que la app pueda abrirse en modo demo si Firebase no responde.

## Pruebas

Las pruebas principales se documentan en `plan_pruebas.md`. Adicionalmente se
ejecutaron:

```bash
flutter analyze
flutter test
```

Ambos comandos pasan sin errores en la version actual.
