SET NAMES utf8mb4;

INSERT INTO categorias_producto (nombre, slug, descripcion, imagen_url, orden_visual, activa) VALUES
('Pizzas', 'pizzas', 'Categorias y constructor de pizzas', 'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=900&q=80', 1, 1),
('Hamburguesas', 'hamburguesas', 'Constructor de hamburguesas', 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=900&q=80', 2, 1),
('Alitas', 'alitas', 'Constructor de alitas', 'https://images.unsplash.com/photo-1567620832903-9fc6debc209f?auto=format&fit=crop&w=900&q=80', 3, 1),
('Boneless', 'boneless', 'Constructor de boneless', 'https://images.unsplash.com/photo-1626645738196-c2a7c87a8f58?auto=format&fit=crop&w=900&q=80', 4, 1),
('Espagueti', 'spaghetti', 'Constructor de espagueti', 'https://images.unsplash.com/photo-1588013273468-315fd88ea34c?auto=format&fit=crop&w=900&q=80', 5, 1),
('Salsas', 'salsas', 'Salsas directas', 'https://images.unsplash.com/photo-1472476443507-c7a5948772fc?auto=format&fit=crop&w=900&q=80', 6, 1),
('Bebidas', 'bebidas', 'Bebidas agrupadas', 'https://images.unsplash.com/photo-1497534446932-c925b458314e?auto=format&fit=crop&w=900&q=80', 7, 1),
('Promociones', 'promociones', 'Promociones y combos', 'https://images.unsplash.com/photo-1600891964092-4316c288032e?auto=format&fit=crop&w=900&q=80', 8, 1),
('Extras', 'extras', 'Extras manuales', 'https://images.unsplash.com/photo-1518131678677-a50857ac6f3d?auto=format&fit=crop&w=900&q=80', 9, 1)
ON DUPLICATE KEY UPDATE
  nombre = VALUES(nombre),
  descripcion = VALUES(descripcion),
  imagen_url = VALUES(imagen_url),
  orden_visual = VALUES(orden_visual),
  activa = VALUES(activa),
  updated_at = NOW();

INSERT INTO configuradores (clave, nombre, descripcion, activo, version) VALUES
('pizza_builder', 'Constructor de Pizza', 'Configurador completo de pizzas', 1, 1),
('hamburger_builder', 'Constructor de Hamburguesa', 'Configurador completo de hamburguesas', 1, 1),
('wings_builder', 'Constructor de Alitas', 'Configurador completo de alitas y boneless', 1, 1),
('spaghetti_builder', 'Constructor de Espagueti', 'Configurador de espagueti', 1, 1),
('salad_builder', 'Constructor de Ensalada', 'Configurador de ensalada', 1, 1),
('manual_extra_builder', 'Extra Manual', 'Captura de item manual y precio libre', 1, 1)
ON DUPLICATE KEY UPDATE
  nombre = VALUES(nombre),
  descripcion = VALUES(descripcion),
  activo = VALUES(activo),
  version = VALUES(version),
  updated_at = NOW();

INSERT INTO configurador_secciones (configurador_id, clave, nombre, tipo_selector, obligatoria, permite_multiple, orden_visual, metadata_json, activa)
SELECT c.id, x.clave, x.nombre, x.tipo_selector, x.obligatoria, x.permite_multiple, x.orden_visual, x.metadata_json, 1
FROM configuradores c
JOIN (
  SELECT 'pizza_builder' AS conf, 'selection_mode' AS clave, 'Modo de seleccion' AS nombre, 'single' AS tipo_selector, 1 AS obligatoria, 0 AS permite_multiple, 10 AS orden_visual, JSON_OBJECT('ui','tabs') AS metadata_json
  UNION ALL SELECT 'pizza_builder', 'size', 'Tamano', 'single', 1, 0, 20, JSON_OBJECT('ui','chips')
  UNION ALL SELECT 'pizza_builder', 'crust_edge', 'Orilla', 'single', 1, 0, 30, JSON_OBJECT('split_supported', 1)
  UNION ALL SELECT 'pizza_builder', 'bread_type', 'Tipo de pan', 'single', 1, 0, 40, NULL
  UNION ALL SELECT 'pizza_builder', 'cooking', 'Coccion', 'single', 1, 0, 50, NULL
  UNION ALL SELECT 'pizza_builder', 'ingredients', 'Ingredientes', 'multi', 0, 1, 60, JSON_OBJECT('max', 20)
  UNION ALL SELECT 'pizza_builder', 'extra_ingredients', 'Ingredientes extra', 'multi', 0, 1, 70, JSON_OBJECT('max', 20)
  UNION ALL SELECT 'pizza_builder', 'pizza_addon', 'Complemento de pizza', 'single', 0, 0, 80, NULL
  UNION ALL SELECT 'hamburger_builder', 'burger_type', 'Tipo de hamburguesa', 'single', 1, 0, 10, NULL
  UNION ALL SELECT 'hamburger_builder', 'side', 'Acompanante', 'single', 1, 0, 20, NULL
  UNION ALL SELECT 'hamburger_builder', 'ingredients', 'Ingredientes incluidos', 'multi', 1, 1, 30, JSON_OBJECT('mode','remove_from_default')
  UNION ALL SELECT 'hamburger_builder', 'quick_actions', 'Acciones rapidas', 'multi', 0, 1, 40, NULL
  UNION ALL SELECT 'hamburger_builder', 'extras', 'Extras', 'multi', 0, 1, 50, NULL
  UNION ALL SELECT 'hamburger_builder', 'cut', 'Corte', 'single', 1, 0, 60, NULL
  UNION ALL SELECT 'wings_builder', 'size', 'Tamano', 'single', 1, 0, 10, NULL
  UNION ALL SELECT 'wings_builder', 'sauce_mode', 'Salsas', 'single', 1, 0, 20, JSON_OBJECT('modes', JSON_ARRAY('single','half_half'))
  UNION ALL SELECT 'wings_builder', 'sauce', 'Salsa', 'single', 0, 0, 30, NULL
  UNION ALL SELECT 'wings_builder', 'preparation', 'Preparacion', 'multi', 0, 1, 40, NULL
  UNION ALL SELECT 'wings_builder', 'cooking', 'Coccion', 'multi', 0, 1, 50, NULL
  UNION ALL SELECT 'wings_builder', 'piece_type', 'Tipo de pieza', 'single', 0, 0, 60, NULL
  UNION ALL SELECT 'wings_builder', 'vegetables', 'Vegetales incluidos', 'multi', 1, 1, 70, JSON_OBJECT('mode','remove_from_default')
  UNION ALL SELECT 'spaghetti_builder', 'type', 'Tipo de espagueti', 'single', 1, 0, 10, NULL
  UNION ALL SELECT 'spaghetti_builder', 'ingredients', 'Ingredientes', 'multi', 1, 1, 20, JSON_OBJECT('mode','remove_from_default')
  UNION ALL SELECT 'spaghetti_builder', 'accompaniment', 'Acompanamiento', 'single', 1, 0, 30, NULL
  UNION ALL SELECT 'spaghetti_builder', 'garlic_bread_type', 'Tipo de panes', 'single', 0, 0, 40, NULL
  UNION ALL SELECT 'spaghetti_builder', 'modifiers', 'Modificadores', 'multi', 0, 1, 50, NULL
  UNION ALL SELECT 'spaghetti_builder', 'extras', 'Extras', 'multi', 0, 1, 60, NULL
  UNION ALL SELECT 'salad_builder', 'ingredients', 'Ingredientes base', 'multi', 1, 1, 10, JSON_OBJECT('mode','remove_from_default')
  UNION ALL SELECT 'salad_builder', 'addons', 'Complementos proteina', 'multi', 0, 1, 20, NULL
  UNION ALL SELECT 'manual_extra_builder', 'manual_item', 'Item manual', 'form', 1, 0, 10, JSON_OBJECT('fields', JSON_ARRAY('name','price','qty'))
) x ON x.conf = c.clave
ON DUPLICATE KEY UPDATE
  nombre = VALUES(nombre),
  tipo_selector = VALUES(tipo_selector),
  obligatoria = VALUES(obligatoria),
  permite_multiple = VALUES(permite_multiple),
  orden_visual = VALUES(orden_visual),
  metadata_json = VALUES(metadata_json),
  activa = VALUES(activa),
  updated_at = NOW();

INSERT INTO configurador_opciones (configurador_seccion_id, clave, nombre, precio_delta, stock_controlado, permite_mitad, es_default, orden_visual, metadata_json, activa)
SELECT s.id, x.clave, x.nombre, x.precio_delta, x.stock_controlado, x.permite_mitad, x.es_default, x.orden_visual, x.metadata_json, 1
FROM configurador_secciones s
JOIN configuradores c ON c.id = s.configurador_id
JOIN (
  SELECT 'pizza_builder' AS conf, 'selection_mode' AS sec, 'specialty' AS clave, 'Especialidad' AS nombre, 0.00 AS precio_delta, 0 AS stock_controlado, 0 AS permite_mitad, 1 AS es_default, 10 AS orden_visual, NULL AS metadata_json
  UNION ALL SELECT 'pizza_builder', 'selection_mode', 'ingredients', 'Ingredientes', 0.00, 0, 0, 0, 20, NULL
  UNION ALL SELECT 'pizza_builder', 'selection_mode', 'half_half', 'Mitad y Mitad', 0.00, 0, 0, 0, 30, NULL
  UNION ALL SELECT 'pizza_builder', 'size', 'mini', 'Mini', 89.00, 0, 0, 0, 10, NULL
  UNION ALL SELECT 'pizza_builder', 'size', 'chica', 'Chica', 119.00, 0, 0, 0, 20, NULL
  UNION ALL SELECT 'pizza_builder', 'size', 'mediana', 'Mediana', 159.00, 0, 0, 1, 30, NULL
  UNION ALL SELECT 'pizza_builder', 'size', 'grande', 'Grande', 199.00, 0, 0, 0, 40, NULL
  UNION ALL SELECT 'pizza_builder', 'size', 'familiar', 'Familiar', 249.00, 0, 0, 0, 50, NULL
  UNION ALL SELECT 'pizza_builder', 'size', 'mega', 'Mega', 279.00, 0, 0, 0, 60, NULL
  UNION ALL SELECT 'pizza_builder', 'crust_edge', 'regular', 'Regular', 0.00, 0, 0, 1, 10, NULL
  UNION ALL SELECT 'pizza_builder', 'crust_edge', 'queso_crema', 'Queso crema', 55.00, 0, 1, 0, 20, NULL
  UNION ALL SELECT 'pizza_builder', 'crust_edge', 'queso_mozzarella', 'Queso mozzarella', 55.00, 0, 1, 0, 30, NULL
  UNION ALL SELECT 'pizza_builder', 'crust_edge', 'split', 'Orilla Mitad y Mitad', 55.00, 0, 0, 0, 40, NULL
  UNION ALL SELECT 'pizza_builder', 'bread_type', 'regular', 'Regular', 0.00, 0, 0, 1, 10, NULL
  UNION ALL SELECT 'pizza_builder', 'bread_type', 'delgado', 'Delgado', 0.00, 0, 0, 0, 20, NULL
  UNION ALL SELECT 'pizza_builder', 'bread_type', 'grueso', 'Grueso', 0.00, 0, 0, 0, 30, NULL
  UNION ALL SELECT 'pizza_builder', 'cooking', 'normal', 'Normal', 0.00, 0, 0, 1, 10, NULL
  UNION ALL SELECT 'pizza_builder', 'cooking', 'dorada', 'Dorada', 0.00, 0, 0, 0, 20, NULL
  UNION ALL SELECT 'pizza_builder', 'pizza_addon', 'none', 'Ninguno', 0.00, 0, 0, 1, 10, NULL
  UNION ALL SELECT 'pizza_builder', 'pizza_addon', 'garlic_bread_promo', 'Panes de ajo promo', 39.00, 0, 0, 0, 20, NULL
  UNION ALL SELECT 'hamburger_builder', 'burger_type', 'clasica', 'Clasica', 139.00, 0, 0, 1, 10, NULL
  UNION ALL SELECT 'hamburger_builder', 'burger_type', 'jamon_tocino', 'Jamon y tocino', 159.00, 0, 0, 0, 20, NULL
  UNION ALL SELECT 'hamburger_builder', 'burger_type', 'doble_carne', 'Doble carne', 169.00, 0, 0, 0, 30, NULL
  UNION ALL SELECT 'hamburger_builder', 'burger_type', 'megaburguer', 'Megaburguer', 189.00, 0, 0, 0, 40, NULL
  UNION ALL SELECT 'hamburger_builder', 'burger_type', 'especial_hamburguesas', 'Especial de hamburguesas', 190.00, 0, 0, 0, 50, NULL
  UNION ALL SELECT 'hamburger_builder', 'side', 'con_papas', 'Con papas', 0.00, 0, 0, 1, 10, NULL
  UNION ALL SELECT 'hamburger_builder', 'side', 'sin_papas', 'Sin papas', -39.00, 0, 0, 0, 20, NULL
  UNION ALL SELECT 'hamburger_builder', 'side', 'con_aros', 'Con aros', 20.00, 0, 0, 0, 30, NULL
  UNION ALL SELECT 'hamburger_builder', 'cut', 'completa', 'Completa', 0.00, 0, 0, 1, 10, NULL
  UNION ALL SELECT 'hamburger_builder', 'cut', 'half', 'Partida a la mitad', 0.00, 0, 0, 0, 20, NULL
  UNION ALL SELECT 'wings_builder', 'size', 'half_order', '1/2 orden', 149.00, 0, 0, 0, 10, NULL
  UNION ALL SELECT 'wings_builder', 'size', 'order', 'Orden', 189.00, 0, 0, 1, 20, NULL
  UNION ALL SELECT 'wings_builder', 'size', 'mega_order', 'Mega orden', 699.00, 0, 0, 0, 30, NULL
  UNION ALL SELECT 'wings_builder', 'sauce_mode', 'single', 'Salsa normal', 0.00, 0, 0, 1, 10, NULL
  UNION ALL SELECT 'wings_builder', 'sauce_mode', 'half_half', '1/2 y 1/2', 0.00, 0, 0, 0, 20, NULL
  UNION ALL SELECT 'wings_builder', 'piece_type', 'one_bone', '1 hueso', 0.00, 0, 0, 0, 10, NULL
  UNION ALL SELECT 'wings_builder', 'piece_type', 'two_bones', '2 huesos', 0.00, 0, 0, 0, 20, NULL
  UNION ALL SELECT 'spaghetti_builder', 'type', 'bolognesa', 'A la bolognesa', 139.00, 0, 0, 1, 10, NULL
  UNION ALL SELECT 'spaghetti_builder', 'type', 'jamon_champinion', 'Jamon y champinon', 139.00, 0, 0, 0, 20, NULL
  UNION ALL SELECT 'spaghetti_builder', 'type', 'supremo', 'Supremo', 169.00, 0, 0, 0, 30, NULL
  UNION ALL SELECT 'spaghetti_builder', 'accompaniment', 'garlic_bread', 'Panes de ajo', 0.00, 0, 0, 1, 10, NULL
  UNION ALL SELECT 'spaghetti_builder', 'accompaniment', 'fries', 'Papas', 0.00, 0, 0, 0, 20, NULL
  UNION ALL SELECT 'spaghetti_builder', 'garlic_bread_type', 'normal', 'Normales', 0.00, 0, 0, 1, 10, NULL
  UNION ALL SELECT 'spaghetti_builder', 'garlic_bread_type', 'queso_crema', 'Rellenos de queso crema', 35.00, 0, 0, 0, 20, NULL
  UNION ALL SELECT 'spaghetti_builder', 'garlic_bread_type', 'queso_mozzarella', 'Rellenos de queso mozzarella', 35.00, 0, 0, 0, 30, NULL
  UNION ALL SELECT 'salad_builder', 'addons', 'carne', 'Carne', 30.00, 0, 0, 0, 10, NULL
  UNION ALL SELECT 'salad_builder', 'addons', 'boneless', 'Boneless', 50.00, 0, 0, 0, 20, NULL
) x ON x.conf = c.clave AND x.sec = s.clave
ON DUPLICATE KEY UPDATE
  nombre = VALUES(nombre),
  precio_delta = VALUES(precio_delta),
  stock_controlado = VALUES(stock_controlado),
  permite_mitad = VALUES(permite_mitad),
  es_default = VALUES(es_default),
  orden_visual = VALUES(orden_visual),
  metadata_json = VALUES(metadata_json),
  activa = VALUES(activa),
  updated_at = NOW();

INSERT INTO productos (categoria_id, nombre, slug, descripcion, tipo_producto, sku, precio_base, activo, visible_pos, visible_web, requiere_preparacion, lleva_inventario, imagen_url)
SELECT c.id, x.nombre, x.slug, x.descripcion, x.tipo_producto, x.sku, x.precio_base, 1, 1, 0, 1, 0, x.imagen_url
FROM categorias_producto c
JOIN (
  SELECT 'pizzas' AS categoria_slug, 'Pizza configurable' AS nombre, 'pizza-configurable' AS slug, 'Entrada al constructor de pizza' AS descripcion, 'pizza' AS tipo_producto, 'PIZ-CONF' AS sku, 159.00 AS precio_base, 'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=900&q=80' AS imagen_url
  UNION ALL SELECT 'hamburguesas', 'Hamburguesa configurable', 'hamburguesa-configurable', 'Entrada al constructor de hamburguesa', 'alimento', 'HAM-CONF', 139.00, 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=900&q=80'
  UNION ALL SELECT 'alitas', 'Alitas configurables', 'alitas-configurables', 'Entrada al constructor de alitas', 'alimento', 'ALI-CONF', 189.00, 'https://images.unsplash.com/photo-1567620832903-9fc6debc209f?auto=format&fit=crop&w=900&q=80'
  UNION ALL SELECT 'boneless', 'Boneless configurables', 'boneless-configurables', 'Entrada al constructor de boneless', 'alimento', 'BON-CONF', 189.00, 'https://images.unsplash.com/photo-1626645738196-c2a7c87a8f58?auto=format&fit=crop&w=900&q=80'
  UNION ALL SELECT 'spaghetti', 'Espagueti configurable', 'espagueti-configurable', 'Entrada al constructor de espagueti', 'alimento', 'ESP-CONF', 139.00, 'https://images.unsplash.com/photo-1588013273468-315fd88ea34c?auto=format&fit=crop&w=900&q=80'
  UNION ALL SELECT 'extras', 'Extra manual', 'extra-manual', 'Cargo manual por nombre libre', 'manual', 'EXT-MANUAL', 0.00, 'https://images.unsplash.com/photo-1518131678677-a50857ac6f3d?auto=format&fit=crop&w=900&q=80'
) x ON x.categoria_slug = c.slug
ON DUPLICATE KEY UPDATE
  categoria_id = VALUES(categoria_id),
  nombre = VALUES(nombre),
  descripcion = VALUES(descripcion),
  tipo_producto = VALUES(tipo_producto),
  precio_base = VALUES(precio_base),
  activo = VALUES(activo),
  visible_pos = VALUES(visible_pos),
  imagen_url = VALUES(imagen_url),
  updated_at = NOW();

INSERT INTO producto_sucursal (producto_id, sucursal_id, precio, disponible, visible)
SELECT p.id, s.id, p.precio_base, 1, 1
FROM productos p
JOIN sucursales s ON s.activa = 1
WHERE p.slug IN (
  'pizza-configurable',
  'hamburguesa-configurable',
  'alitas-configurables',
  'boneless-configurables',
  'espagueti-configurable',
  'extra-manual'
)
ON DUPLICATE KEY UPDATE
  precio = VALUES(precio),
  disponible = VALUES(disponible),
  visible = VALUES(visible),
  updated_at = NOW();

INSERT INTO producto_configuradores (producto_id, configurador_id, obligatorio, orden_visual)
SELECT p.id, c.id, 1, 1
FROM productos p
JOIN configuradores c ON (
  (p.slug = 'pizza-configurable' AND c.clave = 'pizza_builder')
  OR (p.slug = 'hamburguesa-configurable' AND c.clave = 'hamburger_builder')
  OR (p.slug = 'alitas-configurables' AND c.clave = 'wings_builder')
  OR (p.slug = 'boneless-configurables' AND c.clave = 'wings_builder')
  OR (p.slug = 'espagueti-configurable' AND c.clave = 'spaghetti_builder')
  OR (p.slug = 'extra-manual' AND c.clave = 'manual_extra_builder')
)
ON DUPLICATE KEY UPDATE
  obligatorio = VALUES(obligatorio),
  orden_visual = VALUES(orden_visual),
  updated_at = NOW();

INSERT INTO producto_fotos (producto_id, url, ruta_local, alt_text, orden_visual, es_principal, activa)
SELECT p.id, p.imagen_url, NULL, p.nombre, 1, 1, 1
FROM productos p
WHERE p.imagen_url IS NOT NULL AND p.imagen_url <> ''
AND NOT EXISTS (
  SELECT 1
  FROM producto_fotos pf
  WHERE pf.producto_id = p.id
    AND pf.es_principal = 1
);

INSERT INTO promociones (
  nombre, codigo, descripcion, tipo_promocion, motor_reglas, config_json, valor, prioridad, acumulable, activa, fecha_inicio, fecha_fin, hora_inicio, hora_fin
)
VALUES (
  'Promo 2 pizzas medianas por 229',
  'PROMO_2_MED_229',
  'Aplica a dos pizzas medianas con regla Pepperoni + Especialidad o dos personalizadas de maximo 2 ingredientes',
  'precio_fijo',
  'rules_v1',
  JSON_OBJECT(
    'name', 'PROMO_2_MED_229',
    'target_total', 229,
    'size', 'mediana',
    'max_items', 2,
    'rules', JSON_ARRAY(
      JSON_OBJECT('type', 'pepperoni_plus_any_specialty'),
      JSON_OBJECT('type', 'two_custom_max_2_ingredients')
    )
  ),
  229.00, 1, 0, 1, '2026-01-01', '2035-12-31', NULL, NULL
)
ON DUPLICATE KEY UPDATE
  nombre = VALUES(nombre),
  descripcion = VALUES(descripcion),
  tipo_promocion = VALUES(tipo_promocion),
  motor_reglas = VALUES(motor_reglas),
  config_json = VALUES(config_json),
  valor = VALUES(valor),
  prioridad = VALUES(prioridad),
  acumulable = VALUES(acumulable),
  activa = VALUES(activa),
  fecha_inicio = VALUES(fecha_inicio),
  fecha_fin = VALUES(fecha_fin),
  updated_at = NOW();

INSERT INTO promocion_condiciones (promocion_id, condicion_tipo, operador, valor, orden_evaluacion, metadata_json)
SELECT p.id, 'product_type', '=', 'pizza', 10, JSON_OBJECT('scope', 'order')
FROM promociones p
WHERE p.codigo = 'PROMO_2_MED_229'
AND NOT EXISTS (
  SELECT 1 FROM promocion_condiciones pc
  WHERE pc.promocion_id = p.id AND pc.condicion_tipo = 'product_type' AND pc.valor = 'pizza'
);

INSERT INTO promocion_condiciones (promocion_id, condicion_tipo, operador, valor, orden_evaluacion, metadata_json)
SELECT p.id, 'pizza_size', '=', 'mediana', 20, JSON_OBJECT('scope', 'line_item')
FROM promociones p
WHERE p.codigo = 'PROMO_2_MED_229'
AND NOT EXISTS (
  SELECT 1 FROM promocion_condiciones pc
  WHERE pc.promocion_id = p.id AND pc.condicion_tipo = 'pizza_size' AND pc.valor = 'mediana'
);

INSERT INTO promocion_condiciones (promocion_id, condicion_tipo, operador, valor, orden_evaluacion, metadata_json)
SELECT p.id, 'eligible_pair_rules', '=', 'A_OR_B', 30, JSON_OBJECT(
  'rule_a', 'pepperoni_plus_any_specialty',
  'rule_b', 'two_custom_max_2_ingredients',
  'pair_size', 2
)
FROM promociones p
WHERE p.codigo = 'PROMO_2_MED_229'
AND NOT EXISTS (
  SELECT 1 FROM promocion_condiciones pc
  WHERE pc.promocion_id = p.id AND pc.condicion_tipo = 'eligible_pair_rules'
);

INSERT INTO promocion_acciones (promocion_id, accion_tipo, valor, metadata_json, orden_aplicacion)
SELECT p.id, 'set_pair_price', 229.00, JSON_OBJECT('description', 'Fijar precio del par en 229 MXN'), 10
FROM promociones p
WHERE p.codigo = 'PROMO_2_MED_229'
AND NOT EXISTS (
  SELECT 1 FROM promocion_acciones pa
  WHERE pa.promocion_id = p.id AND pa.accion_tipo = 'set_pair_price'
);

INSERT INTO promocion_sucursal (promocion_id, sucursal_id, activa)
SELECT p.id, s.id, 1
FROM promociones p
JOIN sucursales s ON s.activa = 1
WHERE p.codigo = 'PROMO_2_MED_229'
ON DUPLICATE KEY UPDATE activa = VALUES(activa), updated_at = NOW();

