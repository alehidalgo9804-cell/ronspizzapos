CREATE TABLE IF NOT EXISTS categorias_producto (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(120) NOT NULL,
  slug VARCHAR(140) NOT NULL,
  descripcion VARCHAR(255) NULL,
  orden_visual INT NOT NULL DEFAULT 0,
  activa TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_categorias_producto_slug (slug)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS impresoras_destino (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  sucursal_id BIGINT UNSIGNED NOT NULL,
  nombre VARCHAR(120) NOT NULL,
  tipo VARCHAR(40) NOT NULL DEFAULT 'termica',
  ip VARCHAR(45) NULL,
  puerto INT NULL,
  area VARCHAR(80) NULL,
  activa TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_impresoras_sucursal_id (sucursal_id),
  CONSTRAINT fk_impresoras_sucursal FOREIGN KEY (sucursal_id) REFERENCES sucursales(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS productos (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  categoria_id BIGINT UNSIGNED NOT NULL,
  nombre VARCHAR(160) NOT NULL,
  slug VARCHAR(180) NOT NULL,
  descripcion TEXT NULL,
  tipo_producto VARCHAR(40) NOT NULL,
  sku VARCHAR(80) NULL,
  precio_base DECIMAL(12,2) NOT NULL,
  activo TINYINT(1) NOT NULL DEFAULT 1,
  visible_pos TINYINT(1) NOT NULL DEFAULT 1,
  visible_web TINYINT(1) NOT NULL DEFAULT 0,
  requiere_preparacion TINYINT(1) NOT NULL DEFAULT 1,
  lleva_inventario TINYINT(1) NOT NULL DEFAULT 0,
  impresora_destino_id BIGINT UNSIGNED NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at DATETIME NULL,
  UNIQUE KEY uq_productos_slug (slug),
  UNIQUE KEY uq_productos_sku (sku),
  KEY idx_productos_categoria_id (categoria_id),
  CONSTRAINT fk_productos_categoria FOREIGN KEY (categoria_id) REFERENCES categorias_producto(id),
  CONSTRAINT fk_productos_impresora FOREIGN KEY (impresora_destino_id) REFERENCES impresoras_destino(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS producto_sucursal (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  producto_id BIGINT UNSIGNED NOT NULL,
  sucursal_id BIGINT UNSIGNED NOT NULL,
  precio DECIMAL(12,2) NOT NULL,
  disponible TINYINT(1) NOT NULL DEFAULT 1,
  visible TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_producto_sucursal (producto_id, sucursal_id),
  CONSTRAINT fk_producto_sucursal_producto FOREIGN KEY (producto_id) REFERENCES productos(id) ON DELETE CASCADE,
  CONSTRAINT fk_producto_sucursal_sucursal FOREIGN KEY (sucursal_id) REFERENCES sucursales(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS modificadores (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(120) NOT NULL,
  tipo VARCHAR(40) NOT NULL DEFAULT 'opciones',
  obligatorio TINYINT(1) NOT NULL DEFAULT 0,
  multiple TINYINT(1) NOT NULL DEFAULT 0,
  min_selecciones INT NOT NULL DEFAULT 0,
  max_selecciones INT NOT NULL DEFAULT 1,
  activo TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS modificador_opciones (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  modificador_id BIGINT UNSIGNED NOT NULL,
  nombre VARCHAR(120) NOT NULL,
  descripcion VARCHAR(255) NULL,
  precio_extra DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  orden_visual INT NOT NULL DEFAULT 0,
  activo TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_modificador_opciones_modificador_id (modificador_id),
  CONSTRAINT fk_modificador_opciones_modificador FOREIGN KEY (modificador_id) REFERENCES modificadores(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS producto_modificadores (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  producto_id BIGINT UNSIGNED NOT NULL,
  modificador_id BIGINT UNSIGNED NOT NULL,
  orden_visual INT NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_producto_modificador (producto_id, modificador_id),
  CONSTRAINT fk_producto_modificador_producto FOREIGN KEY (producto_id) REFERENCES productos(id) ON DELETE CASCADE,
  CONSTRAINT fk_producto_modificador_modificador FOREIGN KEY (modificador_id) REFERENCES modificadores(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;