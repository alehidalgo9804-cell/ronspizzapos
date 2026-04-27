CREATE TABLE IF NOT EXISTS comandas (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  pedido_id BIGINT UNSIGNED NOT NULL,
  sucursal_id BIGINT UNSIGNED NOT NULL,
  estado VARCHAR(30) NOT NULL DEFAULT 'pendiente',
  numero_impresion INT NOT NULL DEFAULT 0,
  enviada_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  printed_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_comandas_pedido FOREIGN KEY (pedido_id) REFERENCES pedidos(id) ON DELETE CASCADE,
  CONSTRAINT fk_comandas_sucursal FOREIGN KEY (sucursal_id) REFERENCES sucursales(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS comanda_items (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  comanda_id BIGINT UNSIGNED NOT NULL,
  pedido_item_id BIGINT UNSIGNED NOT NULL,
  estacion VARCHAR(80) NOT NULL,
  impresora_destino_id BIGINT UNSIGNED NULL,
  estado VARCHAR(30) NOT NULL DEFAULT 'pendiente',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_comanda_items_comanda FOREIGN KEY (comanda_id) REFERENCES comandas(id) ON DELETE CASCADE,
  CONSTRAINT fk_comanda_items_pedido_item FOREIGN KEY (pedido_item_id) REFERENCES pedido_items(id) ON DELETE CASCADE,
  CONSTRAINT fk_comanda_items_impresora FOREIGN KEY (impresora_destino_id) REFERENCES impresoras_destino(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS comanda_eventos (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  comanda_id BIGINT UNSIGNED NOT NULL,
  tipo_evento VARCHAR(50) NOT NULL,
  usuario_id BIGINT UNSIGNED NOT NULL,
  descripcion TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_comanda_eventos_comanda FOREIGN KEY (comanda_id) REFERENCES comandas(id) ON DELETE CASCADE,
  CONSTRAINT fk_comanda_eventos_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS entregas (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  pedido_id BIGINT UNSIGNED NOT NULL,
  sucursal_id BIGINT UNSIGNED NOT NULL,
  repartidor_id BIGINT UNSIGNED NULL,
  direccion_cliente_id BIGINT UNSIGNED NOT NULL,
  estado VARCHAR(30) NOT NULL DEFAULT 'asignada',
  costo_envio DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  bono_repartidor DECIMAL(12,2) NOT NULL DEFAULT 10.00,
  total_repartidor DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  distancia_km DECIMAL(8,2) NULL,
  lat_salida DECIMAL(10,7) NULL,
  lng_salida DECIMAL(10,7) NULL,
  lat_destino DECIMAL(10,7) NULL,
  lng_destino DECIMAL(10,7) NULL,
  fecha_asignacion DATETIME NULL,
  fecha_recogido DATETIME NULL,
  fecha_salida DATETIME NULL,
  fecha_entregado DATETIME NULL,
  notas TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_entregas_pedido_id (pedido_id),
  KEY idx_entregas_repartidor_id (repartidor_id),
  KEY idx_entregas_sucursal_id (sucursal_id),
  KEY idx_entregas_estado (estado),
  CONSTRAINT fk_entregas_pedido FOREIGN KEY (pedido_id) REFERENCES pedidos(id),
  CONSTRAINT fk_entregas_sucursal FOREIGN KEY (sucursal_id) REFERENCES sucursales(id),
  CONSTRAINT fk_entregas_repartidor FOREIGN KEY (repartidor_id) REFERENCES repartidores(id) ON DELETE SET NULL,
  CONSTRAINT fk_entregas_direccion FOREIGN KEY (direccion_cliente_id) REFERENCES direcciones_cliente(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS entrega_eventos (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  entrega_id BIGINT UNSIGNED NOT NULL,
  usuario_id BIGINT UNSIGNED NULL,
  repartidor_id BIGINT UNSIGNED NULL,
  tipo_evento VARCHAR(50) NOT NULL,
  descripcion TEXT NULL,
  lat DECIMAL(10,7) NULL,
  lng DECIMAL(10,7) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_entrega_eventos_entrega FOREIGN KEY (entrega_id) REFERENCES entregas(id) ON DELETE CASCADE,
  CONSTRAINT fk_entrega_eventos_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL,
  CONSTRAINT fk_entrega_eventos_repartidor FOREIGN KEY (repartidor_id) REFERENCES repartidores(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS rutas_sugeridas (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  sucursal_id BIGINT UNSIGNED NOT NULL,
  repartidor_id BIGINT UNSIGNED NOT NULL,
  fecha DATE NOT NULL,
  estado VARCHAR(30) NOT NULL DEFAULT 'activa',
  distancia_total_estimada DECIMAL(8,2) NULL,
  tiempo_total_estimado INT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_rutas_sugeridas_sucursal FOREIGN KEY (sucursal_id) REFERENCES sucursales(id),
  CONSTRAINT fk_rutas_sugeridas_repartidor FOREIGN KEY (repartidor_id) REFERENCES repartidores(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS rutas_sugeridas_detalle (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  ruta_sugerida_id BIGINT UNSIGNED NOT NULL,
  entrega_id BIGINT UNSIGNED NOT NULL,
  orden_entrega INT NOT NULL,
  distancia_desde_punto_anterior DECIMAL(8,2) NULL,
  tiempo_estimado INT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_ruta_entrega (ruta_sugerida_id, entrega_id),
  CONSTRAINT fk_ruta_detalle_ruta FOREIGN KEY (ruta_sugerida_id) REFERENCES rutas_sugeridas(id) ON DELETE CASCADE,
  CONSTRAINT fk_ruta_detalle_entrega FOREIGN KEY (entrega_id) REFERENCES entregas(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;