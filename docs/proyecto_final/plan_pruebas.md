# Plan y resultados de pruebas - FotoGest Pro

| # | Caso de prueba | Pasos | Resultado esperado | Estado |
|---|---|---|---|---|
| 1 | Abrir aplicacion | Instalar APK y abrir FotoGest Pro. | La app muestra la pantalla de inicio de sesion. | Aprobado |
| 2 | Validar correo vacio | Dejar correo vacio y presionar Entrar. | Se muestra mensaje de correo obligatorio. | Aprobado |
| 3 | Validar contrasena corta | Escribir contrasena menor a 6 caracteres. | Se muestra mensaje de longitud minima. | Aprobado |
| 4 | Iniciar sesion | Escribir credenciales validas. | La app navega al Dashboard. | Aprobado |
| 5 | Crear cliente | Ir a Clientes, presionar Nuevo y guardar datos validos. | El cliente aparece en la lista y se intenta guardar en Firebase. | Aprobado |
| 6 | Validar telefono | Crear cliente con telefono menor a 10 digitos. | El formulario muestra mensaje de telefono valido. | Aprobado |
| 7 | Ver detalle de cliente | Tocar un cliente en la lista. | Se abre detalle con telefono, notas y acciones. | Aprobado |
| 8 | Editar cliente | Abrir detalle, presionar Editar y guardar cambios. | La lista muestra los datos actualizados. | Aprobado |
| 9 | Eliminar cliente | Presionar Eliminar y confirmar. | El cliente desaparece de la lista. | Aprobado |
| 10 | Consultar eventos | Entrar a Eventos. | Se muestran eventos con cliente, paquete y saldo pendiente. | Aprobado |
| 11 | Consultar pagos | Entrar a Pagos. | Se muestran pagos con evento y cliente asociado. | Aprobado |
| 12 | Consultar paquetes | Entrar a Paquetes. | Se muestran paquetes, descripcion y precio. | Aprobado |

## Errores corregidos

- Se agregaron mensajes para listas vacias.
- Se evito que la app falle si Firestore contiene referencias incompletas.
- Se reforzaron validaciones de correo, contrasena, nombre y telefono.
- Se agrego vista de detalle para completar mejor el flujo de clientes.
