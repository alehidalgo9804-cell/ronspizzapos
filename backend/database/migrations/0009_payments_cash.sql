CREATE TABLE IF NOT EXISTS metodos_pago (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(80) NOT NULL,
  clave VARCHAR(40) NOT NULL,
  activo TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_metodos_pago_clave (clave)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS pagos (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  pedido_id BIGINT UNSIGNED NOT NULL,
  metodo_pago_id BIGINT UNSIGNED NOT NULL,
  moneda VARCHAR(10) NOT NULL DEFAULT 'MXN',
  monto DECIMAL(12,2) NOT NULL,
  tipo_cambio DECIMAL(12,6) NULL,
  monto_mxn_equivalente DECIMAL(12,2) NOT NULL,
  referencia_externa VARCHAR(120) NULL,
  estado VARCHAR(30) NOT NULL DEFAULT 'aplicado',
  recibido_por_usuario_id BIGINT UNSIGNED NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_pagos_pedido_id (pedido_id),
  KEY idx_pagos_metodo_pago_id (metodo_pago_id),
  KEY idx_pagos_estado (estado),
  CONSTRAINT fk_pagos_pedido FOREIGN KEY (pedido_id) REFERENCES pedidos(id) ON DELETE CASCADE,
  CONSTRAINT fk_pagos_metodo FOREIGN KEY (metodo_pago_id) REFERENCES metodos_pago(id),
  CONSTRAINT fk_pagos_recibido_por FOREIGN KEY (recibido_por_usuario_id) REFERENCES usuarios(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS pago_detalle (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  pago_id BIGINT UNSIGNED NOT NULL,
  clave VARCHAR(80) NOT NULL,
  valor TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_pago_detalle_pago FOREIGN KEY (pago_id) REFERENCES pagos(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS devoluciones_pago (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  pago_id BIGINT UNSIGNED NOT NULL,
  monto DECIMAL(12,2) NOT NULL,
  motivo VARCHAR(255) NULL,
  usuario_id BIGINT UNSIGNED NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_devoluciones_pago_pago FOREIGN KEY (pago_id) REFERENCES pagos(id) ON DELETE CASCADE,
  CONSTRAINT fk_devoluciones_pago_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS cajas (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  sucursal_id BIGINT UNSIGNED NOT NULL,
  nombre VARCHAR(120) NOT NULL,
  activa TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_cajas_sucursal FOREIGN KEY (sucursal_id) REFERENCES sucursales(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS cortes_caja (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  caja_id BIGINT UNSIGNED NOT NULL,
  sucursal_id BIGINT UNSIGNED NOT NULL,
  usuario_apertura_id BIGINT UNSIGNED NOT NULL,
  usuario_cierre_id BIGINT UNSIGNED NULL,
  monto_apertura DECIMAL(12,2) NOT NULL,
  monto_cierre_sistema DECIMAL(12,2) NULL,
  monto_cierre_fisico DECIMAL(12,2) NULL,
  diferencia DECIMAL(12,2) NULL,
  estado VARCHAR(30) NOT NULL DEFAULT 'abierta',
  fecha_apertura DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_cierre DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_cortes_caja_caja FOREIGN KEY (caja_id) REFERENCES cajas(id),
  CONSTRAINT fk_cortes_caja_sucursal FOREIGN KEY (sucursal_id) REFERENCES sucursales(id),
  CONSTRAINT fk_cortes_caja_usuario_apertura FOREIGN KEY (usuario_apertura_id) REFERENCES usuarios(id),
  CONSTRAINT fk_cortes_caja_usuario_cierre FOREIGN KEY (usuario_cierre_id) REFERENCES usuarios(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS movimientos_caja (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  corte_caja_id BIGINT UNSIGNED NOT NULL,
  caja_id BIGINT UNSIGNED NOT NULL,
  sucursal_id BIGINT UNSIGNED NOT NULL,
  tipo_movimiento VARCHAR(30) NOT NULL,
  concepto VARCHAR(120) NOT NULL,
  monto DECIMAL(12,2) NOT NULL,
  moneda VARCHAR(10) NOT NULL DEFAULT 'MXN',
  referencia_tipo VARCHAR(40) NULL,
  referencia_id BIGINT NULL,
  usuario_id BIGINT UNSIGNED NOT NULL,
  observaciones TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_movimientos_caja_caja_id (caja_id),
  KEY idx_movimientos_caja_corte_id (corte_caja_id),
  KEY idx_movimientos_caja_created_at (created_at),
  CONSTRAINT fk_movimientos_caja_corte FOREIGN KEY (corte_caja_id) REFERENCES cortes_caja(id) ON DELETE CASCADE,
  CONSTRAINT fk_movimientos_caja_caja FOREIGN KEY (caja_id) REFERENCES cajas(id),
  CONSTRAINT fk_movimientos_caja_sucursal FOREIGN KEY (sucursal_id) REFERENCES sucursales(id),
  CONSTRAINT fk_movimientos_caja_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;