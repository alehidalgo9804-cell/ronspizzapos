CREATE TABLE IF NOT EXISTS pedidos (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  folio VARCHAR(40) NOT NULL,
  sucursal_id BIGINT UNSIGNED NOT NULL,
  usuario_id BIGINT UNSIGNED NOT NULL,
  cliente_id BIGINT UNSIGNED NULL,
  mesa_id BIGINT UNSIGNED NULL,
  tipo_pedido VARCHAR(30) NOT NULL,
  canal_origen VARCHAR(30) NOT NULL,
  estado VARCHAR(30) NOT NULL DEFAULT 'creado',
  estado_pago VARCHAR(30) NOT NULL DEFAULT 'pendiente',
  subtotal DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  descuento_total DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  promociones_total DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  envio_total DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  total DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  moneda_base VARCHAR(10) NOT NULL DEFAULT 'MXN',
  observaciones TEXT NULL,
  fecha_pedido DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_cierre DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at DATETIME NULL,
  UNIQUE KEY uq_pedidos_folio (folio),
  KEY idx_pedidos_sucursal_id (sucursal_id),
  KEY idx_pedidos_cliente_id (cliente_id),
  KEY idx_pedidos_usuario_id (usuario_id),
  KEY idx_pedidos_mesa_id (mesa_id),
  KEY idx_pedidos_fecha_pedido (fecha_pedido),
  KEY idx_pedidos_tipo_pedido (tipo_pedido),
  KEY idx_pedidos_estado (estado),
  KEY idx_pedidos_estado_pago (estado_pago),
  CONSTRAINT fk_pedidos_sucursal FOREIGN KEY (sucursal_id) REFERENCES sucursales(id),
  CONSTRAINT fk_pedidos_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id),
  CONSTRAINT fk_pedidos_cliente FOREIGN KEY (cliente_id) REFERENCES clientes(id),
  CONSTRAINT fk_pedidos_mesa FOREIGN KEY (mesa_id) REFERENCES mesas(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS pedido_items (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  pedido_id BIGINT UNSIGNED NOT NULL,
  producto_id BIGINT UNSIGNED NOT NULL,
  nombre_snapshot VARCHAR(180) NOT NULL,
  sku_snapshot VARCHAR(80) NULL,
  categoria_snapshot VARCHAR(120) NULL,
  cantidad DECIMAL(12,3) NOT NULL DEFAULT 1.000,
  precio_unitario DECIMAL(12,2) NOT NULL,
  descuento_unitario DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  total_linea DECIMAL(12,2) NOT NULL,
  notas TEXT NULL,
  estado VARCHAR(30) NOT NULL DEFAULT 'pendiente',
  impresora_destino_id BIGINT UNSIGNED NULL,
  parent_item_id BIGINT UNSIGNED NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_pedido_items_pedido_id (pedido_id),
  KEY idx_pedido_items_producto_id (producto_id),
  CONSTRAINT fk_pedido_items_pedido FOREIGN KEY (pedido_id) REFERENCES pedidos(id) ON DELETE CASCADE,
  CONSTRAINT fk_pedido_items_producto FOREIGN KEY (producto_id) REFERENCES productos(id),
  CONSTRAINT fk_pedido_items_impresora FOREIGN KEY (impresora_destino_id) REFERENCES impresoras_destino(id) ON DELETE SET NULL,
  CONSTRAINT fk_pedido_items_parent FOREIGN KEY (parent_item_id) REFERENCES pedido_items(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS pedido_item_modificadores (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  pedido_item_id BIGINT UNSIGNED NOT NULL,
  modificador_id BIGINT UNSIGNED NOT NULL,
  modificador_opcion_id BIGINT UNSIGNED NULL,
  nombre_snapshot VARCHAR(180) NOT NULL,
  precio_extra DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_pedido_item_mods_item FOREIGN KEY (pedido_item_id) REFERENCES pedido_items(id) ON DELETE CASCADE,
  CONSTRAINT fk_pedido_item_mods_modificador FOREIGN KEY (modificador_id) REFERENCES modificadores(id),
  CONSTRAINT fk_pedido_item_mods_opcion FOREIGN KEY (modificador_opcion_id) REFERENCES modificador_opciones(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS pedido_item_pizza_config (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  pedido_item_id BIGINT UNSIGNED NOT NULL,
  tamano_pizza_id BIGINT UNSIGNED NOT NULL,
  masa_pizza_id BIGINT UNSIGNED NOT NULL,
  orilla_pizza_id BIGINT UNSIGNED NOT NULL,
  especialidad_principal_id BIGINT UNSIGNED NULL,
  especialidad_secundaria_id BIGINT UNSIGNED NULL,
  mitad_y_mitad TINYINT(1) NOT NULL DEFAULT 0,
  regla_precio_mitad_id BIGINT UNSIGNED NULL,
  precio_base DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  precio_orilla DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  precio_extras DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  total_config DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_pizza_config_item (pedido_item_id),
  CONSTRAINT fk_pizza_config_item FOREIGN KEY (pedido_item_id) REFERENCES pedido_items(id) ON DELETE CASCADE,
  CONSTRAINT fk_pizza_config_tamano FOREIGN KEY (tamano_pizza_id) REFERENCES tamanos_pizza(id),
  CONSTRAINT fk_pizza_config_masa FOREIGN KEY (masa_pizza_id) REFERENCES masas_pizza(id),
  CONSTRAINT fk_pizza_config_orilla FOREIGN KEY (orilla_pizza_id) REFERENCES orillas_pizza(id),
  CONSTRAINT fk_pizza_config_especialidad_1 FOREIGN KEY (especialidad_principal_id) REFERENCES especialidades_pizza(id) ON DELETE SET NULL,
  CONSTRAINT fk_pizza_config_especialidad_2 FOREIGN KEY (especialidad_secundaria_id) REFERENCES especialidades_pizza(id) ON DELETE SET NULL,
  CONSTRAINT fk_pizza_config_regla_mitad FOREIGN KEY (regla_precio_mitad_id) REFERENCES pizza_mitad_reglas(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS pedido_item_pizza_ingredientes (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  pedido_item_pizza_config_id BIGINT UNSIGNED NOT NULL,
  ingrediente_id BIGINT UNSIGNED NOT NULL,
  tipo_accion VARCHAR(30) NOT NULL,
  cantidad DECIMAL(12,3) NOT NULL DEFAULT 1.000,
  precio_extra DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_pizza_ingredientes_config FOREIGN KEY (pedido_item_pizza_config_id) REFERENCES pedido_item_pizza_config(id) ON DELETE CASCADE,
  CONSTRAINT fk_pizza_ingredientes_ingrediente FOREIGN KEY (ingrediente_id) REFERENCES ingredientes(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS pedido_estados_historial (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  pedido_id BIGINT UNSIGNED NOT NULL,
  estado_anterior VARCHAR(30) NULL,
  estado_nuevo VARCHAR(30) NOT NULL,
  usuario_id BIGINT UNSIGNED NULL,
  observaciones TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_pedido_historial_pedido_id (pedido_id),
  CONSTRAINT fk_pedido_historial_pedido FOREIGN KEY (pedido_id) REFERENCES pedidos(id) ON DELETE CASCADE,
  CONSTRAINT fk_pedido_historial_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS pedido_notas (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  pedido_id BIGINT UNSIGNED NOT NULL,
  usuario_id BIGINT UNSIGNED NOT NULL,
  nota TEXT NOT NULL,
  tipo_nota VARCHAR(40) NOT NULL DEFAULT 'general',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_pedido_notas_pedido FOREIGN KEY (pedido_id) REFERENCES pedidos(id) ON DELETE CASCADE,
  CONSTRAINT fk_pedido_notas_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS pedido_relaciones (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  pedido_id_origen BIGINT UNSIGNED NOT NULL,
  pedido_id_relacionado BIGINT UNSIGNED NOT NULL,
  tipo_relacion VARCHAR(40) NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_pedido_relaciones_origen FOREIGN KEY (pedido_id_origen) REFERENCES pedidos(id) ON DELETE CASCADE,
  CONSTRAINT fk_pedido_relaciones_relacionado FOREIGN KEY (pedido_id_relacionado) REFERENCES pedidos(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;