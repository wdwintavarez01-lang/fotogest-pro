# Plan y resultados de pruebas - FotoGest Pro

| # | Caso de prueba | Pasos | Resultado esperado | Estado |
|---|---|---|---|---|
| 1 | Abrir aplicacion | Instalar APK y abrir FotoGest Pro. | La app muestra la pantalla de inicio de sesion. | Aprobado |
| 2 | Validar correo vacio | Dejar correo vacio y presionar Entrar. | Se muestra mensaje de correo obligatorio. | Aprobado |
| 3 | Validar contrasena corta | Escribir contrasena menor a 6 caracteres. | Se muestra mensaje de longitud minima. | Aprobado |
| 4 | Iniciar sesion | Escribir credenciales validas. | La app navega al Dashboard. | Aprobado |
| 5 | Crear cliente | Ir a Clientes, presionar Nuevo y guardar datos validos. | El cliente aparece en la lista y se intenta guardar Online. | Aprobado |
| 6 | Validar telefono | Crear cliente con telefono menor a 10 digitos. | El formulario muestra mensaje de telefono valido. | Aprobado |
| 7 | Ver detalle de cliente | Tocar un cliente en la lista. | Se abre detalle con telefono, notas y acciones. | Aprobado |
| 8 | Editar cliente | Abrir detalle, presionar Editar y guardar cambios. | La lista muestra los datos actualizados. | Aprobado |
| 9 | Eliminar cliente | Presionar Eliminar y confirmar. | El cliente desaparece de la lista. | Aprobado |
| 10 | Crear servicio | Ir a Servicios, presionar Nuevo y guardar nombre, descripcion y precio. | El servicio aparece disponible para nuevos eventos. | Aprobado |
| 11 | Editar servicio | Abrir un servicio y modificar precio o estado. | El cambio se refleja en la lista. | Aprobado |
| 12 | Crear evento | Ir a Eventos, presionar Nuevo y seleccionar cliente, servicio, fecha y ubicacion. | El evento aparece en la agenda y en el Dashboard. | Aprobado |
| 13 | Editar evento | Abrir un evento y cambiar estado o datos principales. | La agenda muestra los datos actualizados. | Aprobado |
| 14 | Registrar abono | Desde Eventos o Pagos registrar un monto para un evento pendiente. | El abono reduce el saldo pendiente. | Aprobado |
| 15 | Validar monto de pago | Registrar un pago mayor al saldo pendiente. | El formulario bloquea el monto y muestra mensaje. | Aprobado |
| 16 | Historial de pagos | Completar el pago total de un evento. | El evento sale de Pendientes y aparece en Historial. | Aprobado |
| 17 | Consultar abonos | Abrir el Historial y ver el detalle de abonos. | La app muestra los abonos sin botones de editar o eliminar. | Aprobado |
| 18 | Acceso offline | Iniciar sesion una vez Online, cerrar app, simular falta de internet y usar las mismas credenciales. | La app permite entrar en modo Offline con credenciales guardadas. | Aprobado |

## Errores corregidos

- Se agregaron mensajes para listas vacias.
- Se evito que la app falle si Firestore contiene referencias incompletas.
- Se reforzaron validaciones de correo, contrasena, nombre y telefono.
- Se agrego vista de detalle para completar mejor el flujo de clientes.
- Se activaron formularios reales para servicios, eventos y pagos.
- Se bloqueo el borrado de clientes o servicios que ya estan asociados a eventos.
- Se agrego acceso offline usando credenciales previamente validadas.
- Se rediseño Pagos como cobros pendientes e historial de eventos pagados.
