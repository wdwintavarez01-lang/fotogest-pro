# Manual de usuario - FotoGest Pro

## Proposito de la aplicacion

FotoGest Pro ayuda a fotografos de eventos a organizar clientes, eventos,
servicios, ventas independientes y pagos desde una aplicacion movil.

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

El Dashboard muestra cantidad de clientes, eventos activos, monto abonado,
monto pendiente, proximos eventos, ventas abiertas y cuentas por cobrar.

## Gestion de clientes

1. Entrar a la pestana **Clientes**.
2. Presionar **Nuevo** para registrar un cliente.
3. Completar nombre, telefono y notas.
4. Presionar **Guardar cliente**.
5. Tocar un cliente de la lista para ver su detalle.
6. Desde el detalle se puede editar o eliminar si no tiene eventos ni ventas.

## Eventos

La pantalla **Eventos** muestra los eventos registrados, el cliente asociado,
la fecha, ubicacion, servicio contratado, monto abonado y monto pendiente.

Desde esta pantalla se puede crear, editar, eliminar y cobrar eventos
pendientes.

## Ventas

La pantalla **Ventas** permite registrar ingresos que no dependen de un evento,
por ejemplo:

- Foto individual.
- Impresion.
- Edicion.
- Retoque.
- Sesion rapida.
- Servicio suelto.

Cada venta se asocia a un cliente, tiene cantidad, precio unitario, total,
abonos y saldo pendiente. La descripcion es opcional; si no se escribe, la app
usa el tipo de venta como referencia. El total se calcula automaticamente al
modificar la cantidad o el precio unitario.

Al crear una venta se puede elegir:

- **Guardar venta**: registra la venta y vuelve al listado.
- **Guardar y cobrar ahora**: registra la venta y abre inmediatamente el
  formulario de abono.

## Pagos

La pantalla **Pagos** se organiza en dos pestanas:

- **Pendientes**: muestra primero los eventos que todavia tienen saldo por
  cobrar y tambien las ventas independientes pendientes.
- **Historial**: muestra los eventos y ventas que ya fueron pagados por completo
  y permite consultar sus abonos sin editar ni eliminar pagos directamente.

Cuando el saldo pendiente de un evento o venta llega a cero, deja de aparecer en
Pendientes y pasa automaticamente al Historial.

Despues de registrar un abono, la app muestra un recibo de muestra con numero,
cuenta, fecha, metodo de pago, monto abonado y saldo restante.

## Servicios

La pantalla **Servicios** muestra los servicios fotograficos disponibles, su
descripcion y precio. Desde esta pantalla se puede crear, editar, activar,
desactivar o eliminar un servicio si no esta siendo usado por eventos.

## Capturas incluidas

El manual se acompana con capturas reales de las pantallas principales en la
carpeta `screenshots`.

## Problemas comunes

- Si no inicia sesion, revisar correo, contrasena y conexion.
- Si no aparecen datos remotos, revisar que Firebase este configurado.
- Si el APK no instala, habilitar instalacion desde fuentes externas.
- Si un registro no se guarda Online, revisar reglas de Firestore y sesion
  activa.

## Soporte

Equipo FotoGest Pro.
