INSERT INTO repartidores (nombre, apellidos, telefono, pin, activo, tipo_pago, notas)
SELECT 'Luis', 'Repartidor', '6622222222', '2222', 1, 'mixto', 'Repartidor base para pruebas'
WHERE NOT EXISTS (SELECT 1 FROM repartidores WHERE telefono = '6622222222');

INSERT INTO repartidor_sucursal (repartidor_id, sucursal_id, activo, created_at, updated_at)
SELECT r.id, s.id, 1, NOW(), NOW()
FROM repartidores r
JOIN sucursales s ON s.clave = 'CENTRO'
WHERE r.telefono = '6622222222'
AND NOT EXISTS (
  SELECT 1 FROM repartidor_sucursal rs
  WHERE rs.repartidor_id = r.id AND rs.sucursal_id = s.id
);

INSERT INTO usuarios (nombre, apellido, telefono, email, pin, rol_id, sucursal_id, activo, created_at, updated_at)
SELECT 'Luis', 'Driver', '6622222222', 'driver1@ronspizza.local', '2222', rol.id, suc.id, 1, NOW(), NOW()
FROM roles rol
JOIN sucursales suc ON suc.clave = 'CENTRO'
WHERE rol.nombre = 'repartidor'
AND NOT EXISTS (SELECT 1 FROM usuarios u WHERE u.email = 'driver1@ronspizza.local');

INSERT INTO tarifas_envio (sucursal_id, tipo_calculo, distancia_min_km, distancia_max_km, tarifa, prioridad, activa, created_at, updated_at)
SELECT s.id, 'distancia', 0.00, 3.00, 30.00, 1, 1, NOW(), NOW()
FROM sucursales s
WHERE s.clave = 'CENTRO'
AND NOT EXISTS (
  SELECT 1 FROM tarifas_envio te
  WHERE te.sucursal_id = s.id AND te.tipo_calculo = 'distancia' AND te.distancia_min_km = 0.00 AND te.distancia_max_km = 3.00
);

INSERT INTO tarifas_envio (sucursal_id, tipo_calculo, distancia_min_km, distancia_max_km, tarifa, prioridad, activa, created_at, updated_at)
SELECT s.id, 'distancia', 3.01, 8.00, 45.00, 2, 1, NOW(), NOW()
FROM sucursales s
WHERE s.clave = 'CENTRO'
AND NOT EXISTS (
  SELECT 1 FROM tarifas_envio te
  WHERE te.sucursal_id = s.id AND te.tipo_calculo = 'distancia' AND te.distancia_min_km = 3.01 AND te.distancia_max_km = 8.00
);

INSERT INTO zonas_entrega (sucursal_id, nombre, descripcion, distancia_min_km, distancia_max_km, tarifa_envio, activa, created_at, updated_at)
SELECT s.id, 'Centro', 'Zona centro', 0.00, 3.00, 30.00, 1, NOW(), NOW()
FROM sucursales s
WHERE s.clave = 'CENTRO'
AND NOT EXISTS (
  SELECT 1 FROM zonas_entrega z
  WHERE z.sucursal_id = s.id AND z.nombre = 'Centro'
);

INSERT INTO productos (categoria_id, nombre, slug, descripcion, tipo_producto, sku, precio_base, activo, visible_pos, visible_web, requiere_preparacion, lleva_inventario, created_at, updated_at)
SELECT c.id, 'Pizza Grande Pepperoni', 'pizza-grande-pepperoni', 'Pizza grande clasica', 'pizza', 'PIZ-GRA-PEP', 220.00, 1, 1, 1, 1, 1, NOW(), NOW()
FROM categorias_producto c
WHERE c.slug = 'pizzas'
AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.slug = 'pizza-grande-pepperoni');

INSERT INTO productos (categoria_id, nombre, slug, descripcion, tipo_producto, sku, precio_base, activo, visible_pos, visible_web, requiere_preparacion, lleva_inventario, created_at, updated_at)
SELECT c.id, 'Alitas 10 piezas', 'alitas-10-piezas', 'Alitas clasicas', 'alimento', 'ALI-10', 150.00, 1, 1, 0, 1, 1, NOW(), NOW()
FROM categorias_producto c
WHERE c.slug = 'alitas'
AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.slug = 'alitas-10-piezas');

INSERT INTO productos (categoria_id, nombre, slug, descripcion, tipo_producto, sku, precio_base, activo, visible_pos, visible_web, requiere_preparacion, lleva_inventario, created_at, updated_at)
SELECT c.id, 'Refresco 600ml', 'refresco-600ml', 'Bebida fria', 'bebida', 'BEB-600', 35.00, 1, 1, 1, 0, 1, NOW(), NOW()
FROM categorias_producto c
WHERE c.slug = 'bebidas'
AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.slug = 'refresco-600ml');

INSERT INTO producto_sucursal (producto_id, sucursal_id, precio, disponible, visible, created_at, updated_at)
SELECT p.id, s.id, p.precio_base, 1, 1, NOW(), NOW()
FROM productos p
JOIN sucursales s ON s.clave = 'CENTRO'
WHERE p.slug IN ('pizza-grande-pepperoni', 'alitas-10-piezas', 'refresco-600ml')
AND NOT EXISTS (
  SELECT 1 FROM producto_sucursal ps
  WHERE ps.producto_id = p.id AND ps.sucursal_id = s.id
);

INSERT INTO ingredientes (nombre, clave, unidad_medida_id, costo_unitario, activo, created_at, updated_at)
SELECT 'Masa pizza', 'masa_pizza', um.id, 12.00, 1, NOW(), NOW()
FROM unidades_medida um
WHERE um.clave = 'pieza'
AND NOT EXISTS (SELECT 1 FROM ingredientes i WHERE i.clave = 'masa_pizza');

INSERT INTO ingredientes (nombre, clave, unidad_medida_id, costo_unitario, activo, created_at, updated_at)
SELECT 'Queso mozzarella', 'queso_mozzarella', um.id, 0.15, 1, NOW(), NOW()
FROM unidades_medida um
WHERE um.clave = 'gramo'
AND NOT EXISTS (SELECT 1 FROM ingredientes i WHERE i.clave = 'queso_mozzarella');

INSERT INTO ingredientes (nombre, clave, unidad_medida_id, costo_unitario, activo, created_at, updated_at)
SELECT 'Pepperoni', 'pepperoni', um.id, 0.25, 1, NOW(), NOW()
FROM unidades_medida um
WHERE um.clave = 'gramo'
AND NOT EXISTS (SELECT 1 FROM ingredientes i WHERE i.clave = 'pepperoni');

INSERT INTO ingredientes (nombre, clave, unidad_medida_id, costo_unitario, activo, created_at, updated_at)
SELECT 'Salsa tomate', 'salsa_tomate', um.id, 0.09, 1, NOW(), NOW()
FROM unidades_medida um
WHERE um.clave = 'gramo'
AND NOT EXISTS (SELECT 1 FROM ingredientes i WHERE i.clave = 'salsa_tomate');

INSERT INTO ingredientes (nombre, clave, unidad_medida_id, costo_unitario, activo, created_at, updated_at)
SELECT 'Alita cruda', 'alita_cruda', um.id, 6.00, 1, NOW(), NOW()
FROM unidades_medida um
WHERE um.clave = 'pieza'
AND NOT EXISTS (SELECT 1 FROM ingredientes i WHERE i.clave = 'alita_cruda');

INSERT INTO empleados (nombre, apellidos, telefono, numero_empleado, activo, created_at, updated_at)
SELECT 'Pedro', 'Empleado', '6623333333', 'EMP-001', 1, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM empleados e WHERE e.numero_empleado = 'EMP-001');

INSERT INTO ingredientes_pizza (ingrediente_id, visible_en_builder, precio_extra_chica, precio_extra_mediana, precio_extra_grande, activo, created_at, updated_at)
SELECT i.id, 1, 10.00, 15.00, 20.00, 1, NOW(), NOW()
FROM ingredientes i
WHERE i.clave IN ('queso_mozzarella', 'pepperoni')
AND NOT EXISTS (SELECT 1 FROM ingredientes_pizza ip WHERE ip.ingrediente_id = i.id);

INSERT INTO especialidades_pizza (nombre, descripcion, activa, created_at, updated_at)
SELECT 'Pepperoni Clasica', 'Especialidad de pepperoni', 1, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM especialidades_pizza WHERE nombre = 'Pepperoni Clasica');

INSERT INTO especialidad_pizza_detalle (especialidad_pizza_id, ingrediente_id, cantidad_base, created_at, updated_at)
SELECT ep.id, i.id, CASE WHEN i.clave = 'pepperoni' THEN 80 ELSE 150 END, NOW(), NOW()
FROM especialidades_pizza ep
JOIN ingredientes i ON i.clave IN ('pepperoni', 'queso_mozzarella')
WHERE ep.nombre = 'Pepperoni Clasica'
AND NOT EXISTS (
  SELECT 1 FROM especialidad_pizza_detalle ed
  WHERE ed.especialidad_pizza_id = ep.id AND ed.ingrediente_id = i.id
);

INSERT INTO pizza_precio_base (tamano_pizza_id, precio_base, created_at, updated_at)
SELECT t.id, CASE t.clave WHEN 'chica' THEN 160.00 WHEN 'mediana' THEN 190.00 ELSE 220.00 END, NOW(), NOW()
FROM tamanos_pizza t
WHERE NOT EXISTS (SELECT 1 FROM pizza_precio_base pb WHERE pb.tamano_pizza_id = t.id);

INSERT INTO recetas (producto_id, nombre, es_default, activa, created_at, updated_at)
SELECT p.id, 'Receta base pizza pepperoni', 1, 1, NOW(), NOW()
FROM productos p
WHERE p.slug = 'pizza-grande-pepperoni'
AND NOT EXISTS (
  SELECT 1 FROM recetas r
  WHERE r.producto_id = p.id AND r.nombre = 'Receta base pizza pepperoni'
);

INSERT INTO recetas (producto_id, nombre, es_default, activa, created_at, updated_at)
SELECT p.id, 'Receta base alitas 10', 1, 1, NOW(), NOW()
FROM productos p
WHERE p.slug = 'alitas-10-piezas'
AND NOT EXISTS (
  SELECT 1 FROM recetas r
  WHERE r.producto_id = p.id AND r.nombre = 'Receta base alitas 10'
);

INSERT INTO receta_detalle (receta_id, ingrediente_id, cantidad, unidad_medida_id, es_opcional, created_at, updated_at)
SELECT r.id, i.id, rd.cantidad, i.unidad_medida_id, 0, NOW(), NOW()
FROM (
  SELECT 'Receta base pizza pepperoni' AS receta_nombre, 'masa_pizza' AS ingrediente_clave, 1.0 AS cantidad
  UNION ALL SELECT 'Receta base pizza pepperoni', 'queso_mozzarella', 180.0
  UNION ALL SELECT 'Receta base pizza pepperoni', 'pepperoni', 90.0
  UNION ALL SELECT 'Receta base pizza pepperoni', 'salsa_tomate', 120.0
  UNION ALL SELECT 'Receta base alitas 10', 'alita_cruda', 10.0
) rd
JOIN recetas r ON r.nombre = rd.receta_nombre
JOIN ingredientes i ON i.clave = rd.ingrediente_clave
WHERE NOT EXISTS (
  SELECT 1 FROM receta_detalle x
  WHERE x.receta_id = r.id AND x.ingrediente_id = i.id
);

INSERT INTO ingrediente_sucursal (ingrediente_id, sucursal_id, stock_actual, stock_minimo, stock_maximo, activo, created_at, updated_at)
SELECT i.id, s.id, 5000.0, 500.0, NULL, 1, NOW(), NOW()
FROM ingredientes i
JOIN sucursales s ON s.clave = 'CENTRO'
WHERE i.clave IN ('masa_pizza', 'queso_mozzarella', 'pepperoni', 'salsa_tomate', 'alita_cruda')
AND NOT EXISTS (
  SELECT 1 FROM ingrediente_sucursal is2
  WHERE is2.ingrediente_id = i.id AND is2.sucursal_id = s.id
);

UPDATE categorias_producto
SET imagen_url = CASE slug
  WHEN 'pizzas' THEN 'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=900&q=80'
  WHEN 'alitas' THEN 'https://images.unsplash.com/photo-1541592106381-b31e9677c0e5?auto=format&fit=crop&w=900&q=80'
  WHEN 'hamburguesas' THEN 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=900&q=80'
  WHEN 'bebidas' THEN 'https://images.unsplash.com/photo-1497534446932-c925b458314e?auto=format&fit=crop&w=900&q=80'
  WHEN 'extras' THEN 'https://images.unsplash.com/photo-1528404525361-f44f7bbf3f09?auto=format&fit=crop&w=900&q=80'
  ELSE imagen_url
END
WHERE imagen_url IS NULL OR imagen_url = '';

UPDATE productos
SET imagen_url = CASE slug
  WHEN 'pizza-grande-pepperoni' THEN 'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=900&q=80'
  WHEN 'alitas-10-piezas' THEN 'https://images.unsplash.com/photo-1541592106381-b31e9677c0e5?auto=format&fit=crop&w=900&q=80'
  WHEN 'refresco-600ml' THEN 'https://images.unsplash.com/photo-1497534446932-c925b458314e?auto=format&fit=crop&w=900&q=80'
  ELSE imagen_url
END
WHERE imagen_url IS NULL OR imagen_url = '';
