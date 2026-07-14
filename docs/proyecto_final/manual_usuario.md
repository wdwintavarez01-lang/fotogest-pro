# Manual de usuario - FotoGest Pro

## Proposito de la aplicacion

FotoGest Pro ayuda a fotografos de eventos a organizar clientes, eventos,
paquetes y pagos desde una aplicacion movil.

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
4. Si Firebase no responde, la app puede abrir en modo demo local.

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
la fecha, ubicacion, paquete contratado y monto pendiente.

## Pagos

La pantalla **Pagos** muestra los pagos registrados, el evento relacionado, el
metodo de pago y la fecha.

## Paquetes

La pantalla **Paquetes** muestra los servicios fotograficos disponibles, su
descripcion y precio.

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
