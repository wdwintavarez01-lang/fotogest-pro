# Documentacion tecnica - FotoGest Pro

## Descripcion del problema

Fotografos independientes suelen manejar clientes, eventos, ventas de fotos,
servicios sueltos y pagos en notas, hojas de calculo o mensajes sueltos. Esto
dificulta consultar saldos, recordar fechas y mantener un historial ordenado del
servicio. FotoGest Pro organiza esa informacion en una aplicacion movil sencilla.

## Objetivo general

Desarrollar una aplicacion movil funcional que permita gestionar clientes de un
negocio fotografico, registrar eventos, vender fotos o servicios independientes
y consultar cobros desde una interfaz adaptada a dispositivos moviles.

## Alcance de esta version

Incluye inicio de sesion, dashboard, CRUD de clientes, servicios, eventos,
ventas independientes, registro de abonos e historial de cuentas pagadas. No
incluye subida de fotografias, facturacion fiscal, pagos en linea ni publicacion
en tienda de aplicaciones.

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
- `ventas`: fotos individuales, impresiones, ediciones, retoques o servicios
  vendidos sin evento.
- `pagos`: abonos asociados a eventos o ventas.

## Funcionalidad CRUD implementada

La funcionalidad central completa se implemento sobre clientes, servicios,
eventos y ventas:

- Crear cliente desde el formulario.
- Leer clientes desde la lista.
- Ver detalle del cliente en una hoja inferior.
- Editar cliente existente.
- Eliminar cliente con confirmacion.
- Crear, editar y eliminar servicios fotograficos.
- Crear, editar y eliminar eventos asociados a cliente y servicio.
- Crear, editar y eliminar ventas independientes sin evento.
- Calcular total de venta automaticamente desde cantidad y precio unitario.
- Guardar una venta y abrir el cobro inmediato.
- Registrar abonos para eventos o ventas pendientes.
- Mostrar recibo de muestra al registrar un abono.
- Consultar historial de cuentas pagadas.

## Validaciones

- El correo es obligatorio y debe tener formato basico valido.
- La contrasena es obligatoria y debe tener al menos 6 caracteres.
- El nombre del cliente es obligatorio y debe tener al menos 3 caracteres.
- El telefono es obligatorio y debe contener al menos 10 digitos.
- Los precios y montos deben ser mayores que cero.
- Los abonos no pueden superar el saldo pendiente.
- Una venta debe tener cliente, cantidad y precio unitario. La descripcion es
  opcional.

## Decisiones de diseno

Se eligio Firestore porque permite persistencia remota, integracion directa con
Flutter y una estructura flexible por colecciones. Se mantuvieron datos locales
de respaldo y acceso offline con credenciales guardadas para que la app pueda
abrirse cuando no haya conexion.

## Pruebas

Las pruebas principales se documentan en `plan_pruebas.md`. Adicionalmente se
ejecutaron:

```bash
flutter analyze
flutter test
```

Ambos comandos pasan sin errores en la version actual.
