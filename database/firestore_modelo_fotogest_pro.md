# Modelo Firestore - FotoGest Pro

La base oficial seleccionada para FotoGest Pro es Firebase Firestore, una base de datos NoSQL orientada a documentos. El DER de la Semana 4 se usa como modelo conceptual para identificar entidades, campos y relaciones; en Firestore esas entidades se implementan como colecciones.

## Relacion entre DER y Firestore

| Entidad del DER | Coleccion Firestore | Relacion |
| --- | --- | --- |
| usuarios | `usuarios` | Usuario autenticado con rol de fotografo, asistente o administrador. |
| clientes | `clientes` | Cada cliente guarda `usuarioId`, que referencia al usuario que lo registro. |
| paquetes | `paquetes` | Catalogo de servicios fotograficos con precio. |
| eventos | `eventos` | Cada evento guarda `clienteId`, `paqueteId` y `usuarioId`. |
| pagos | `pagos` | Cada pago guarda `eventoId`, que lo vincula al evento fotografico. |

## Colecciones

### usuarios

```json
{
  "usuarioId": "usr_001",
  "nombre": "Edwin Tavarez",
  "email": "edwin.tavarez@example.com",
  "rol": "fotografo",
  "activo": true,
  "createdAt": "2026-07-01T09:00:00"
}
```

### clientes

```json
{
  "clienteId": "cli_001",
  "usuarioId": "usr_001",
  "nombre": "Maria Fernandez",
  "telefono": "809-555-1101",
  "notas": "Prefiere contacto por WhatsApp",
  "createdAt": "2026-07-01T10:00:00"
}
```

### paquetes

```json
{
  "paqueteId": "paq_001",
  "nombre": "Basico Evento",
  "descripcion": "20 fotos editadas y entrega digital",
  "precio": 3500,
  "activo": true,
  "createdAt": "2026-07-01T10:20:00"
}
```

### eventos

```json
{
  "eventoId": "evt_001",
  "clienteId": "cli_001",
  "paqueteId": "paq_002",
  "usuarioId": "usr_001",
  "tipo": "bautizo",
  "fechaHora": "2026-07-05T15:00:00",
  "ubicacion": "Parroquia San Judas",
  "estado": "programado",
  "createdAt": "2026-07-01T11:00:00"
}
```

### pagos

```json
{
  "pagoId": "pag_001",
  "eventoId": "evt_001",
  "monto": 3000,
  "metodo": "transferencia",
  "fechaPago": "2026-07-01T12:00:00",
  "nota": "Abono inicial"
}
```

## Por que tambien existe un archivo SQL

El archivo `fotogest_pro_semana4.sql` sirve como validacion local del modelo logico: permite comprobar llaves, relaciones y datos de prueba sin depender de credenciales de Firebase. No reemplaza a Firestore. La implementacion prevista de la aplicacion es Firestore, representada por:

- `firestore_modelo_fotogest_pro.md`
- `firestore_seed_data.json`
- `firestore_seed_fotogest_pro.js`
- `firestore.rules`

