# FotoGest Pro — Mejoras versión 2 (ciclo sept-2026)

Registro de los cambios aplicados a la aplicación y de los pasos necesarios
para ponerlos en funcionamiento.

## 1. Propiedad real de los datos

**Problema anterior.** El identificador de usuario estaba escrito de forma fija
como `usr_001` en 18 puntos del código. La aplicación se documentaba como
multiusuario, pero todos los registros se guardaban bajo un mismo dueño
ficticio, y las reglas de Firestore permitían a cualquier usuario autenticado
leer y escribir toda la base de datos.

**Cambio aplicado.**

- `FotogestRepository` expone `currentUserId`, que devuelve el UID real de
  Firebase Authentication.
- Las consultas de `clientes`, `paquetes`, `eventos`, `ventas` y `pagos` se
  filtran con `where('usuarioId', isEqualTo: uid)`.
- La colección `usuarios`, que antes no se usaba, ahora registra el perfil del
  usuario autenticado la primera vez que entra a la aplicación.
- Los modelos `PhotoPackage` y `Payment` incorporaron el campo `userId`, que
  antes no tenían, de modo que todas las colecciones puedan filtrarse por
  propietario.
- `database/firestore.rules` se reescribió: cada documento solo puede leerse,
  modificarse o eliminarse por el usuario cuyo UID coincide con el campo
  `usuarioId`, y ningún usuario puede crear registros a nombre de otro. Se
  añadió además validación de tipo y de monto no negativo.

## 2. Cierre de sesión y pantalla de acceso

**Problema anterior.** No existía ninguna forma de cerrar sesión: no había una
sola ocurrencia de `signOut` en el proyecto. El formulario de acceso venía con
el correo y la contraseña de prueba ya escritos.

**Cambio aplicado.**

- Botón de cerrar sesión en la barra superior del panel de resumen, con diálogo
  de confirmación que indica la cuenta activa.
- `FotogestRepository.signOut()` cierra la sesión en Firebase Authentication y
  descarta toda la información cargada en memoria, para que el siguiente
  usuario no vea datos del anterior.
- Los campos de correo y contraseña de la pantalla de acceso inician vacíos.

## 3. Monto acordado del evento

**Problema anterior.** El saldo pendiente de un evento se calculaba contra el
precio *actual* del servicio. Al editar el precio de un servicio cambiaba
retroactivamente la deuda de eventos ya registrados.

**Cambio aplicado.**

- `PhotoEvent` incorpora el campo `agreedAmount`, que se guarda en Firestore
  como `montoAcordado`.
- El formulario de evento incluye el campo **Monto acordado**, que se completa
  automáticamente con el precio del servicio seleccionado y puede ajustarse.
- `FotogestViewModel.amountForEvent()` es ahora la única fuente del total de un
  evento. Los eventos creados antes de esta versión, cuyo monto acordado es
  cero, se resuelven con el precio actual del servicio para no perder su saldo.
- Las pantallas de eventos y de pagos usan ese método en lugar del precio del
  servicio.

## 4. Funcionamiento sin conexión

**Problema anterior.** El acceso sin conexión solo comparaba un hash SHA-256
guardado en el dispositivo. No había persistencia de Firestore, y cuando la
conexión fallaba la aplicación mostraba tres clientes, tres eventos y dos
ventas escritos en el código como si fueran datos reales del usuario.

**Cambio aplicado.**

- `FirebaseService` habilita la caché local de Cloud Firestore
  (`persistenceEnabled`), de modo que las consultas se resuelven desde el
  dispositivo cuando no hay conexión y las escrituras quedan en cola.
- Se eliminaron por completo los datos de ejemplo del repositorio. Las listas
  inician vacías y toda la información proviene de Firestore o de su caché.

## 5. Pasos para poner los cambios en funcionamiento

Los datos que ya existen en Firestore están a nombre de `usr_001`, por lo que
dejarían de verse al aplicar el filtro por usuario. El orden siguiente evita
esa pérdida.

1. **Obtener el UID.** Firebase Console → Authentication → Users → columna
   *User UID* de la cuenta con la que se inicia sesión en la aplicación.

2. **Simular la migración** para revisar qué documentos se tocarían:

   ```bash
   node tools/migrar_usuario_id.js <UID> --simular
   ```

3. **Ejecutar la migración.** Reasigna el `usuarioId` de todos los documentos y
   completa el `montoAcordado` de los eventos anteriores con el precio de su
   servicio:

   ```bash
   node tools/migrar_usuario_id.js <UID>
   ```

4. **Publicar las reglas de seguridad:**

   ```bash
   firebase deploy --only firestore:rules
   ```

5. **Verificar el proyecto y ejecutarlo:**

   ```bash
   flutter analyze
   flutter run
   ```

6. Opcional: eliminar desde Firebase Console los documentos `usr_001`,
   `usr_002` y `usr_003` de la colección `usuarios`, que quedan en desuso.

## 6. Archivos modificados

| Archivo | Cambio |
| --- | --- |
| `lib/models/photo_event.dart` | Campo `agreedAmount`. |
| `lib/models/photo_package.dart` | Campo `userId`. |
| `lib/models/payment.dart` | Campo `userId`. |
| `lib/services/firebase_service.dart` | Caché local de Firestore. |
| `lib/repositories/fotogest_repository.dart` | UID real, filtros por propietario, `signOut`, registro del usuario, eliminación de datos de ejemplo. |
| `lib/viewmodels/fotogest_view_model.dart` | `currentUserId`, `amountForEvent`, `signOut`, propagación del monto acordado. |
| `lib/views/login_screen.dart` | Campos de acceso vacíos. |
| `lib/views/dashboard_screen.dart` | Botón y confirmación de cierre de sesión. |
| `lib/views/event_form_screen.dart` | Campo Monto acordado con validación. |
| `lib/views/events_screen.dart` | Total del evento desde `amountForEvent`. |
| `lib/views/payments_screen.dart` | Total y progreso desde `amountForEvent`. |
| `database/firestore.rules` | Reglas por propietario con validación de montos. |
| `tools/migrar_usuario_id.js` | Script nuevo de migración de datos. |

## 7. Pendiente

Los cambios no se han compilado: la verificación con `flutter analyze` y
`flutter test` debe ejecutarse en el equipo de desarrollo. Queda también
pendiente sustituir la prueba de plantilla `test/widget_test.dart` por pruebas
reales de los cálculos de saldo.
