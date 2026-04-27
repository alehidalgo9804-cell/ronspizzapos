SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS producto_fotos (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  producto_id BIGINT UNSIGNED NOT NULL,
  url VARCHAR(500) NOT NULL,
  ruta_local VARCHAR(500) NULL,
  alt_text VARCHAR(160) NULL,
  orden_visual INT NOT NULL DEFAULT 1,
  es_principal TINYINT(1) NOT NULL DEFAULT 0,
  activa TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_producto_fotos_producto (producto_id),
  KEY idx_producto_fotos_principal (producto_id, es_principal),
  CONSTRAINT fk_producto_fotos_producto FOREIGN KEY (producto_id) REFERENCES productos(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS configuradores (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  clave VARCHAR(80) NOT NULL,
  nombre VARCHAR(120) NOT NULL,
  descripcion VARCHAR(255) NULL,
  activo TINYINT(1) NOT NULL DEFAULT 1,
  version INT NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_configuradores_clave (clave)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS configurador_secciones (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  configurador_id BIGINT UNSIGNED NOT NULL,
  clave VARCHAR(80) NOT NULL,
  nombre VARCHAR(120) NOT NULL,
  tipo_selector VARCHAR(40) NOT NULL DEFAULT 'single',
  obligatoria TINYINT(1) NOT NULL DEFAULT 0,
  permite_multiple TINYINT(1) NOT NULL DEFAULT 0,
  orden_visual INT NOT NULL DEFAULT 1,
  metadata_json JSON NULL,
  activa TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_configurador_seccion_clave (configurador_id, clave),
  KEY idx_configurador_secciones_conf (configurador_id),
  CONSTRAINT fk_configurador_secciones_conf FOREIGN KEY (configurador_id) REFERENCES configuradores(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS configurador_opciones (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  configurador_seccion_id BIGINT UNSIGNED NOT NULL,
  clave VARCHAR(100) NOT NULL,
  nombre VARCHAR(140) NOT NULL,
  precio_delta DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  stock_controlado TINYINT(1) NOT NULL DEFAULT 0,
  permite_mitad TINYINT(1) NOT NULL DEFAULT 0,
  es_default TINYINT(1) NOT NULL DEFAULT 0,
  orden_visual INT NOT NULL DEFAULT 1,
  metadata_json JSON NULL,
  activa TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_configurador_opcion_clave (configurador_seccion_id, clave),
  KEY idx_configurador_opciones_seccion (configurador_seccion_id),
  CONSTRAINT fk_configurador_opciones_seccion FOREIGN KEY (configurador_seccion_id) REFERENCES configurador_secciones(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS producto_configuradores (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  producto_id BIGINT UNSIGNED NOT NULL,
  configurador_id BIGINT UNSIGNED NOT NULL,
  obligatorio TINYINT(1) NOT NULL DEFAULT 0,
  orden_visual INT NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_producto_configurador (producto_id, configurador_id),
  CONSTRAINT fk_producto_configuradores_producto FOREIGN KEY (producto_id) REFERENCES productos(id) ON DELETE CASCADE,
  CONSTRAINT fk_producto_configuradores_configurador FOREIGN KEY (configurador_id) REFERENCES configuradores(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS producto_precios_historico (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  producto_id BIGINT UNSIGNED NOT NULL,
  sucursal_id BIGINT UNSIGNED NULL,
  precio_anterior DECIMAL(12,2) NOT NULL,
  precio_nuevo DECIMAL(12,2) NOT NULL,
  motivo VARCHAR(255) NULL,
  cambiado_por_usuario_id BIGINT UNSIGNED NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_producto_precios_historico_producto (producto_id),
  KEY idx_producto_precios_historico_created_at (created_at),
  CONSTRAINT fk_producto_precios_historico_producto FOREIGN KEY (producto_id) REFERENCES productos(id) ON DELETE CASCADE,
  CONSTRAINT fk_producto_precios_historico_sucursal FOREIGN KEY (sucursal_id) REFERENCES sucursales(id) ON DELETE SET NULL,
  CONSTRAINT fk_producto_precios_historico_usuario FOREIGN KEY (cambiado_por_usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS promocion_condiciones (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  promocion_id BIGINT UNSIGNED NOT NULL,
  condicion_tipo VARCHAR(80) NOT NULL,
  operador VARCHAR(20) NOT NULL DEFAULT '=',
  valor VARCHAR(255) NOT NULL,
  orden_evaluacion INT NOT NULL DEFAULT 1,
  metadata_json JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_promocion_condiciones_promocion (promocion_id),
  CONSTRAINT fk_promocion_condiciones_promocion FOREIGN KEY (promocion_id) REFERENCES promociones(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS promocion_acciones (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  promocion_id BIGINT UNSIGNED NOT NULL,
  accion_tipo VARCHAR(80) NOT NULL,
  valor DECIMAL(12,2) NULL,
  metadata_json JSON NULL,
  orden_aplicacion INT NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_promocion_acciones_promocion (promocion_id),
  CONSTRAINT fk_promocion_acciones_promocion FOREIGN KEY (promocion_id) REFERENCES promociones(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE promociones
  ADD COLUMN IF NOT EXISTS codigo VARCHAR(60) NULL AFTER nombre,
  ADD COLUMN IF NOT EXISTS motor_reglas VARCHAR(40) NOT NULL DEFAULT 'legacy' AFTER tipo_promocion,
  ADD COLUMN IF NOT EXISTS config_json JSON NULL AFTER motor_reglas;

CREATE UNIQUE INDEX uq_promociones_codigo ON promociones (codigo);

