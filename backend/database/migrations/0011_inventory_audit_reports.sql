CREATE TABLE IF NOT EXISTS movimientos_inventario (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  sucursal_id BIGINT UNSIGNED NOT NULL,
  ingrediente_id BIGINT UNSIGNED NOT NULL,
  tipo_movimiento VARCHAR(30) NOT NULL,
  cantidad DECIMAL(12,3) NOT NULL,
  unidad_medida_id BIGINT UNSIGNED NOT NULL,
  costo_unitario DECIMAL(12,2) NULL,
  referencia_tipo VARCHAR(50) NULL,
  referencia_id BIGINT NULL,
  motivo VARCHAR(255) NULL,
  usuario_id BIGINT UNSIGNED NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_mov_inventario_ingrediente_id (ingrediente_id),
  KEY idx_mov_inventario_sucursal_id (sucursal_id),
  KEY idx_mov_inventario_created_at (created_at),
  CONSTRAINT fk_mov_inventario_sucursal FOREIGN KEY (sucursal_id) REFERENCES sucursales(id),
  CONSTRAINT fk_mov_inventario_ingrediente FOREIGN KEY (ingrediente_id) REFERENCES ingredientes(id),
  CONSTRAINT fk_mov_inventario_unidad FOREIGN KEY (unidad_medida_id) REFERENCES unidades_medida(id),
  CONSTRAINT fk_mov_inventario_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS inventario_conteos (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  sucursal_id BIGINT UNSIGNED NOT NULL,
  nombre VARCHAR(120) NOT NULL,
  estado VARCHAR(30) NOT NULL DEFAULT 'abierto',
  fecha_inicio DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_cierre DATETIME NULL,
  usuario_id BIGINT UNSIGNED NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_inventario_conteos_sucursal FOREIGN KEY (sucursal_id) REFERENCES sucursales(id),
  CONSTRAINT fk_inventario_conteos_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS inventario_conteo_detalle (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  inventario_conteo_id BIGINT UNSIGNED NOT NULL,
  ingrediente_id BIGINT UNSIGNED NOT NULL,
  stock_sistema DECIMAL(12,3) NOT NULL,
  stock_fisico DECIMAL(12,3) NOT NULL,
  diferencia DECIMAL(12,3) NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_inventario_conteo_detalle_conteo FOREIGN KEY (inventario_conteo_id) REFERENCES inventario_conteos(id) ON DELETE CASCADE,
  CONSTRAINT fk_inventario_conteo_detalle_ingrediente FOREIGN KEY (ingrediente_id) REFERENCES ingredientes(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS resumen_ventas_diarias (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  sucursal_id BIGINT UNSIGNED NOT NULL,
  fecha DATE NOT NULL,
  total_ventas DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  total_pedidos INT NOT NULL DEFAULT 0,
  ticket_promedio DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_resumen_ventas_sucursal_fecha (sucursal_id, fecha),
  CONSTRAINT fk_resumen_ventas_sucursal FOREIGN KEY (sucursal_id) REFERENCES sucursales(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS resumen_productos_diarios (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  sucursal_id BIGINT UNSIGNED NOT NULL,
  producto_id BIGINT UNSIGNED NOT NULL,
  fecha DATE NOT NULL,
  cantidad_vendida DECIMAL(12,3) NOT NULL DEFAULT 0.000,
  total_vendido DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_resumen_producto_sucursal_fecha (sucursal_id, producto_id, fecha),
  CONSTRAINT fk_resumen_productos_sucursal FOREIGN KEY (sucursal_id) REFERENCES sucursales(id),
  CONSTRAINT fk_resumen_productos_producto FOREIGN KEY (producto_id) REFERENCES productos(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS auditoria_eventos (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  usuario_id BIGINT UNSIGNED NULL,
  sucursal_id BIGINT UNSIGNED NULL,
  entidad VARCHAR(100) NOT NULL,
  entidad_id BIGINT NULL,
  accion VARCHAR(80) NOT NULL,
  payload_json JSON NULL,
  ip VARCHAR(45) NULL,
  user_agent VARCHAR(255) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_auditoria_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL,
  CONSTRAINT fk_auditoria_sucursal FOREIGN KEY (sucursal_id) REFERENCES sucursales(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS sesiones_usuario (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  usuario_id BIGINT UNSIGNED NOT NULL,
  token VARCHAR(128) NULL,
  plataforma VARCHAR(40) NOT NULL,
  fecha_inicio DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_fin DATETIME NULL,
  activa TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_sesiones_usuario_usuario_id (usuario_id),
  KEY idx_sesiones_usuario_token (token),
  CONSTRAINT fk_sesiones_usuario_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;