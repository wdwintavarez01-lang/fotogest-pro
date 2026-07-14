# Manual de usuario - FotoGest Pro

## Proposito de la aplicacion

FotoGest Pro ayuda a fotografos de eventos a organizar clientes, eventos,
servicios y pagos desde una aplicacion movil.

## Requisitos

- Dispositivo Android.
- Conexion a internet para iniciar sesion y sincronizar datos con Firebase.
- APK instalado en el dispositivo.

## Instalacion

1. Copiar el archivo APK al dispositivo Android.
2. Abrir el archivo desde el dispositivo.
3. Aceptar la instalacion si Android solicita permiso.
4. Abrir FotoGest Pro desde el menu de aplicaciones.

## Inicio de sesion

1. Abrir la aplicacion.
2. Escribir correo y contrasena.
3. Presionar **Entrar**.
4. Si no hay internet, la app puede entrar offline con esas mismas credenciales
   solo si ya se usaron antes correctamente en ese celular.

## Dashboard

El Dashboard muestra un resumen del negocio:

- Cantidad de clientes.
- Eventos activos.
- Monto abonado.
- Monto pendiente.
- Proximos eventos.

## Gestion de clientes

1. Entrar a la pestana **Clientes**.
2. Presionar **Nuevo** para registrar un cliente.
3. Completar nombre, telefono y notas.
4. Presionar **Guardar cliente**.
5. Tocar un cliente de la lista para ver su detalle.
6. Desde el detalle se puede editar o eliminar.

## Eventos

La pantalla **Eventos** muestra los eventos registrados, el cliente asociado,
la fecha, ubicacion, servicio contratado, monto abonado y monto pendiente.

Desde esta pantalla se puede:

- Crear un evento nuevo.
- Editar un evento existente.
- Eliminar un evento.
- Registrar un cobro directo desde un evento pendiente.

## Pagos

La pantalla **Pagos** se organiza en dos pestañas:

- **Pendientes**: muestra primero los eventos que todavia tienen saldo por
  cobrar y permite registrar abonos.
- **Historial**: muestra los eventos que ya fueron pagados por completo y
  permite consultar sus abonos sin editar ni eliminar pagos directamente.

Cuando el saldo pendiente de un evento llega a cero, deja de aparecer en
Pendientes y pasa automaticamente al Historial.

## Servicios

La pantalla **Servicios** muestra los servicios fotograficos disponibles, su
descripcion y precio.

Desde esta pantalla se puede crear, editar, activar, desactivar o eliminar un
servicio si no esta siendo usado por eventos.

## Capturas incluidas

El manual se acompana con capturas reales de las pantallas principales en la
carpeta `screenshots`:

- `flutter_login.png`: inicio de sesion.
- `flutter_dashboard.png`: resumen general de la aplicacion.
- `flutter_clientes.png`: listado de clientes.
- `flutter_form_cliente.png`: formulario de registro/edicion de cliente.
- `flutter_contact_sheet.png`: detalle de cliente con acciones.
- `flutter_eventos.png`: listado de eventos.
- `flutter_pagos.png`: listado de pagos.

## Problemas comunes

- Si no inicia sesion, revisar correo, contrasena y conexion.
- Si no aparecen datos remotos, revisar que Firebase este configurado.
- Si el APK no instala, habilitar instalacion desde fuentes externas.
- Si un cliente no se guarda en Firebase, revisar reglas de Firestore y sesion
  activa.

## Soporte

Equipo FotoGest Pro.
