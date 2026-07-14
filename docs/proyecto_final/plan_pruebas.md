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
| 9 | Eliminar cliente | Presionar Eliminar y confirmar. | El cliente desaparece de la lista si no tiene eventos ni ventas. | Aprobado |
| 10 | Crear servicio | Ir a Servicios, presionar Nuevo y guardar nombre, descripcion y precio. | El servicio aparece disponible para nuevos eventos. | Aprobado |
| 11 | Editar servicio | Abrir un servicio y modificar precio o estado. | El cambio se refleja en la lista. | Aprobado |
| 12 | Crear evento | Ir a Eventos, presionar Nuevo y seleccionar cliente, servicio, fecha y ubicacion. | El evento aparece en la agenda y en el Dashboard. | Aprobado |
| 13 | Editar evento | Abrir un evento y cambiar estado o datos principales. | La agenda muestra los datos actualizados. | Aprobado |
| 14 | Crear venta independiente | Ir a Ventas, presionar Nueva y guardar una foto individual o servicio suelto. | La venta aparece en la lista y queda disponible para cobrar. | Aprobado |
| 15 | Calcular total de venta | Cambiar cantidad y precio unitario en Nueva venta. | La app muestra el total calculado automaticamente. | Aprobado |
| 16 | Descripcion opcional | Guardar una venta sin descripcion. | La app guarda la venta usando el tipo como referencia visible. | Aprobado |
| 17 | Guardar y cobrar venta | Presionar Guardar y cobrar ahora. | La app guarda la venta y abre el formulario de abono. | Aprobado |
| 18 | Registrar abono | Desde Eventos, Ventas o Pagos registrar un monto para una cuenta pendiente. | El abono reduce el saldo pendiente. | Aprobado |
| 19 | Recibo de muestra | Guardar un abono valido. | La app muestra un recibo de muestra con monto, metodo, fecha y saldo. | Aprobado |
| 20 | Validar monto de pago | Registrar un pago mayor al saldo pendiente. | El formulario bloquea el monto y muestra mensaje. | Aprobado |
| 21 | Historial de pagos | Completar el pago total de un evento o venta. | La cuenta sale de Pendientes y aparece en Historial. | Aprobado |
| 22 | Consultar abonos | Abrir el Historial y ver el detalle de abonos. | La app muestra los abonos sin botones de editar o eliminar. | Aprobado |
| 23 | Acceso offline | Iniciar sesion una vez Online, cerrar app, simular falta de internet y usar las mismas credenciales. | La app permite entrar en modo Offline con credenciales guardadas. | Aprobado |

## Errores corregidos

- Se agregaron mensajes para listas vacias.
- Se evito que la app falle si Firestore contiene referencias incompletas.
- Se reforzaron validaciones de correo, contrasena, nombre y telefono.
- Se agrego vista de detalle para completar mejor el flujo de clientes.
- Se activaron formularios reales para servicios, eventos, ventas y pagos.
- Se bloqueo el borrado de clientes con eventos o ventas registradas.
- Se agrego acceso offline usando credenciales previamente validadas.
- Se rediseno Pagos como cobros pendientes e historial de cuentas pagadas.
- Se agrego Ventas para fotos individuales, impresiones, retoques y servicios independientes de eventos.
- Se agrego total automatico en ventas, descripcion opcional, cobro inmediato y recibo de muestra.
