ALTER TABLE categorias_producto
  ADD COLUMN IF NOT EXISTS imagen_url VARCHAR(500) NULL AFTER descripcion;

ALTER TABLE productos
  ADD COLUMN IF NOT EXISTS imagen_url VARCHAR(500) NULL AFTER descripcion;

CREATE INDEX idx_productos_categoria_activo_visible
  ON productos (categoria_id, activo, visible_pos);
