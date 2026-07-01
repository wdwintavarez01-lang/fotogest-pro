-- FotoGest Pro - Script de creacion y datos de prueba
-- Compatible con SQLite para validacion academica del modelo logico.
PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS pagos;
DROP TABLE IF EXISTS eventos;
DROP TABLE IF EXISTS paquetes;
DROP TABLE IF EXISTS clientes;
DROP TABLE IF EXISTS usuarios;

CREATE TABLE usuarios (
  usuario_id TEXT PRIMARY KEY,
  nombre TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  rol TEXT NOT NULL CHECK (rol IN ('fotografo','asistente','administrador')),
  activo INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL
);

CREATE TABLE clientes (
  cliente_id TEXT PRIMARY KEY,
  usuario_id TEXT NOT NULL,
  nombre TEXT NOT NULL,
  telefono TEXT NOT NULL,
  notas TEXT,
  created_at TEXT NOT NULL,
  FOREIGN KEY (usuario_id) REFERENCES usuarios(usuario_id)
);

CREATE TABLE paquetes (
  paquete_id TEXT PRIMARY KEY,
  nombre TEXT NOT NULL,
  descripcion TEXT,
  precio REAL NOT NULL CHECK (precio >= 0),
  activo INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL
);

CREATE TABLE eventos (
  evento_id TEXT PRIMARY KEY,
  cliente_id TEXT NOT NULL,
  paquete_id TEXT NOT NULL,
  usuario_id TEXT NOT NULL,
  tipo TEXT NOT NULL,
  fecha_hora TEXT NOT NULL,
  ubicacion TEXT NOT NULL,
  estado TEXT NOT NULL CHECK (estado IN ('programado','en_proceso','completado','cancelado')),
  created_at TEXT NOT NULL,
  FOREIGN KEY (cliente_id) REFERENCES clientes(cliente_id),
  FOREIGN KEY (paquete_id) REFERENCES paquetes(paquete_id),
  FOREIGN KEY (usuario_id) REFERENCES usuarios(usuario_id)
);

CREATE TABLE pagos (
  pago_id TEXT PRIMARY KEY,
  evento_id TEXT NOT NULL,
  monto REAL NOT NULL CHECK (monto >= 0),
  metodo TEXT NOT NULL CHECK (metodo IN ('efectivo','transferencia','otro')),
  fecha_pago TEXT NOT NULL,
  nota TEXT,
  FOREIGN KEY (evento_id) REFERENCES eventos(evento_id)
);

INSERT INTO usuarios VALUES
('usr_001','Edwin Tavarez','edwin.tavarez@example.com','fotografo',1,'2026-07-01T09:00:00'),
('usr_002','Asistente Demo','asistente@example.com','asistente',1,'2026-07-01T09:10:00'),
('usr_003','Admin FotoGest','admin@example.com','administrador',1,'2026-07-01T09:20:00');

INSERT INTO clientes VALUES
('cli_001','usr_001','Maria Fernandez','809-555-1101','Prefiere contacto por WhatsApp','2026-07-01T10:00:00'),
('cli_002','usr_001','Jose Ramirez','809-555-2202','Solicita album impreso','2026-07-01T10:05:00'),
('cli_003','usr_001','Laura Gomez','809-555-3303','Evento en iglesia y recepcion','2026-07-01T10:10:00');

INSERT INTO paquetes VALUES
('paq_001','Basico Evento','20 fotos editadas y entrega digital',3500,1,'2026-07-01T10:20:00'),
('paq_002','Premium Familiar','40 fotos editadas, album digital y 5 impresas',6500,1,'2026-07-01T10:25:00'),
('paq_003','Cobertura Completa','80 fotos editadas, album impreso y entrega express',12000,1,'2026-07-01T10:30:00');

INSERT INTO eventos VALUES
('evt_001','cli_001','paq_002','usr_001','bautizo','2026-07-05T15:00:00','Parroquia San Judas','programado','2026-07-01T11:00:00'),
('evt_002','cli_002','paq_001','usr_001','cumpleanos','2026-07-06T18:00:00','Salon Vista Alegre','en_proceso','2026-07-01T11:10:00'),
('evt_003','cli_003','paq_003','usr_001','boda','2026-07-12T16:30:00','Santiago Centro','programado','2026-07-01T11:20:00');

INSERT INTO pagos VALUES
('pag_001','evt_001',3000,'transferencia','2026-07-01T12:00:00','Abono inicial'),
('pag_002','evt_002',1500,'efectivo','2026-07-01T12:10:00','Reserva de fecha'),
('pag_003','evt_003',5000,'transferencia','2026-07-01T12:20:00','Separacion de paquete premium');

SELECT 'usuarios' AS tabla, COUNT(*) AS total FROM usuarios
UNION ALL SELECT 'clientes', COUNT(*) FROM clientes
UNION ALL SELECT 'paquetes', COUNT(*) FROM paquetes
UNION ALL SELECT 'eventos', COUNT(*) FROM eventos
UNION ALL SELECT 'pagos', COUNT(*) FROM pagos;
