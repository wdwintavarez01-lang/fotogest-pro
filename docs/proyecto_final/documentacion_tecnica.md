# Documentación técnica de FotoGest Pro 1.1.0

FotoGest Pro gestiona clientes, servicios, eventos, ventas y abonos. La implementación actual y sus procedimientos reproducibles se describen en [Cierre 1.1.0](cierre_1_1_0.md).

## Arquitectura

- `lib/models`: seis entidades con `copyWith`.
- `lib/views` y `lib/widgets`: doce rutas, formularios, listas, comprobantes y estado de sincronización.
- `lib/viewmodels`: saldos, pendientes, historial y coordinación mediante `ChangeNotifier`.
- `lib/repositories`: único acceso a Firebase, validaciones, transacciones y `PendingJournal`.
- `lib/services`: inicialización de Firebase y caché del SDK.
- `lib/utils`: tema y formato de moneda y fechas.

`AppScope` utiliza `InheritedNotifier`; no se usa Provider ni Riverpod. Las consultas comerciales filtran `usuarioId` por el UID de Firebase Auth.

## Modelo documental

Colecciones: usuarios, clientes, paquetes, eventos, ventas y pagos. Cliente a operaciones, servicio a eventos y cuenta a abonos tienen relaciones 1:N. Un abono pertenece a un evento o una venta, nunca a ambos. El informe Word incluye el diccionario actualizado.

Las cuentas usan `totalCentavos`, `abonadoCentavos` y `totalAbonado`; ventas añade `precioUnitarioCentavos` y pagos `montoCentavos`. `revision` impide sobrescribir ediciones desactualizadas. `operacionId` identifica reenvíos y `eliminado` conserva las referencias históricas.

## Persistencia y autenticación

La app guarda una instantánea confirmada y una cola por UID. El cambio solo se anuncia confirmado después de una respuesta de Firebase. Sin red queda pendiente; ante un rechazo se suspende la cola y la vista vuelve a los confirmados. La documentación no atribuye sincronización automática a una app cerrada: el reintento ocurre al reabrir y mientras se mantiene activa.

Firebase administra la sesión persistente; se retiró el acceso por hash de contraseña en preferencias. No hay cuentas de prueba precargadas en la interfaz ni contraseñas en el paquete académico.

## Integridad y pruebas

Las reglas y transacciones verifican propietario, referencias, total de ventas, destino de pago y saldo. Los abonos confirmados son inmutables; una cuenta con abonos no se borra. Las bajas son lógicas. El monto pactado no depende del precio posterior del catálogo.

Aprobaron análisis, 21 pruebas locales, 30 de reglas, recorrido Android y dos etapas de recuperación entre procesos. Los respaldos de 39 documentos se restauraron y compararon en un proyecto de emulador aislado. La distribución académica conserva la firma debug; la distribución comercial requiere firma propia y validaciones adicionales de operación y dispositivos.
