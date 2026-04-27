SET NAMES utf8mb4;

ALTER TABLE pedidos
  ADD COLUMN IF NOT EXISTS direccion_cliente_id BIGINT UNSIGNED NULL AFTER cliente_id,
  ADD COLUMN IF NOT EXISTS repartidor_id BIGINT UNSIGNED NULL AFTER direccion_cliente_id,
  ADD COLUMN IF NOT EXISTS total_pagado DECIMAL(12,2) NOT NULL DEFAULT 0.00 AFTER total,
  ADD COLUMN IF NOT EXISTS total_pendiente DECIMAL(12,2) NOT NULL DEFAULT 0.00 AFTER total_pagado,
  ADD COLUMN IF NOT EXISTS tipo_cambio_usd_utilizado DECIMAL(12,6) NULL AFTER moneda_base,
  ADD COLUMN IF NOT EXISTS ticket_cocina_impreso_at DATETIME NULL AFTER fecha_cierre,
  ADD COLUMN IF NOT EXISTS ticket_cliente_impreso_at DATETIME NULL AFTER ticket_cocina_impreso_at,
  ADD COLUMN IF NOT EXISTS cierre_sin_pago_motivo VARCHAR(255) NULL AFTER ticket_cliente_impreso_at,
  ADD COLUMN IF NOT EXISTS payload_resumen_json JSON NULL AFTER cierre_sin_pago_motivo;

CREATE INDEX idx_pedidos_repartidor_id ON pedidos (repartidor_id);
CREATE INDEX idx_pedidos_direccion_cliente_id ON pedidos (direccion_cliente_id);

ALTER TABLE pedido_items
  MODIFY COLUMN producto_id BIGINT UNSIGNED NULL,
  ADD COLUMN IF NOT EXISTS es_item_manual TINYINT(1) NOT NULL DEFAULT 0 AFTER producto_id,
  ADD COLUMN IF NOT EXISTS nombre_manual VARCHAR(180) NULL AFTER es_item_manual,
  ADD COLUMN IF NOT EXISTS categoria_manual VARCHAR(80) NULL AFTER nombre_manual,
  ADD COLUMN IF NOT EXISTS precio_manual_unitario DECIMAL(12,2) NULL AFTER categoria_manual,
  ADD COLUMN IF NOT EXISTS config_builder_tipo VARCHAR(50) NULL AFTER precio_manual_unitario,
  ADD COLUMN IF NOT EXISTS config_builder_json JSON NULL AFTER config_builder_tipo,
  ADD COLUMN IF NOT EXISTS display_lines_json JSON NULL AFTER config_builder_json;

CREATE TABLE IF NOT EXISTS pedido_item_componentes (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  pedido_item_id BIGINT UNSIGNED NOT NULL,
  tipo_componente VARCHAR(60) NOT NULL,
  clave_componente VARCHAR(120) NULL,
  nombre_snapshot VARCHAR(180) NOT NULL,
  modo_accion VARCHAR(40) NOT NULL,
  cantidad DECIMAL(12,3) NOT NULL DEFAULT 1.000,
  precio_delta DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  metadata_json JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_pedido_item_componentes_item (pedido_item_id),
  KEY idx_pedido_item_componentes_tipo (tipo_componente, modo_accion),
  CONSTRAINT fk_pedido_item_componentes_item FOREIGN KEY (pedido_item_id) REFERENCES pedido_items(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS ticket_impresiones (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  pedido_id BIGINT UNSIGNED NOT NULL,
  pago_id BIGINT UNSIGNED NULL,
  tipo_ticket VARCHAR(30) NOT NULL,
  es_reimpresion TINYINT(1) NOT NULL DEFAULT 0,
  contenido_snapshot LONGTEXT NULL,
  impresora_nombre VARCHAR(120) NULL,
  impresora_tipo VARCHAR(40) NULL,
  estado_impresion VARCHAR(30) NOT NULL DEFAULT 'queued',
  error_detalle TEXT NULL,
  impreso_por_usuario_id BIGINT UNSIGNED NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_ticket_impresiones_pedido (pedido_id, created_at),
  KEY idx_ticket_impresiones_tipo (tipo_ticket, es_reimpresion),
  CONSTRAINT fk_ticket_impresiones_pedido FOREIGN KEY (pedido_id) REFERENCES pedidos(id) ON DELETE CASCADE,
  CONSTRAINT fk_ticket_impresiones_pago FOREIGN KEY (pago_id) REFERENCES pagos(id) ON DELETE SET NULL,
  CONSTRAINT fk_ticket_impresiones_usuario FOREIGN KEY (impreso_por_usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS pedido_cierre_sin_pago (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  pedido_id BIGINT UNSIGNED NOT NULL,
  motivo VARCHAR(120) NOT NULL,
  detalle TEXT NULL,
  cerrado_por_usuario_id BIGINT UNSIGNED NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_pedido_cierre_sin_pago_pedido (pedido_id),
  CONSTRAINT fk_pedido_cierre_sin_pago_pedido FOREIGN KEY (pedido_id) REFERENCES pedidos(id) ON DELETE CASCADE,
  CONSTRAINT fk_pedido_cierre_sin_pago_usuario FOREIGN KEY (cerrado_por_usuario_id) REFERENCES usuarios(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS pedido_repartidor_asignaciones (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  pedido_id BIGINT UNSIGNED NOT NULL,
  repartidor_id BIGINT UNSIGNED NOT NULL,
  asignado_por_usuario_id BIGINT UNSIGNED NULL,
  estado VARCHAR(30) NOT NULL DEFAULT 'asignado',
  notas TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_pedido_repartidor_asignaciones_pedido (pedido_id),
  KEY idx_pedido_repartidor_asignaciones_repartidor (repartidor_id),
  CONSTRAINT fk_pedido_repartidor_asignaciones_pedido FOREIGN KEY (pedido_id) REFERENCES pedidos(id) ON DELETE CASCADE,
  CONSTRAINT fk_pedido_repartidor_asignaciones_repartidor FOREIGN KEY (repartidor_id) REFERENCES repartidores(id) ON DELETE CASCADE,
  CONSTRAINT fk_pedido_repartidor_asignaciones_usuario FOREIGN KEY (asignado_por_usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS pedido_eventos (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  pedido_id BIGINT UNSIGNED NOT NULL,
  tipo_evento VARCHAR(60) NOT NULL,
  descripcion VARCHAR(255) NULL,
  payload_json JSON NULL,
  usuario_id BIGINT UNSIGNED NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_pedido_eventos_pedido (pedido_id, created_at),
  KEY idx_pedido_eventos_tipo (tipo_evento),
  CONSTRAINT fk_pedido_eventos_pedido FOREIGN KEY (pedido_id) REFERENCES pedidos(id) ON DELETE CASCADE,
  CONSTRAINT fk_pedido_eventos_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

