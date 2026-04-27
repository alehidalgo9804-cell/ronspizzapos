SET NAMES utf8mb4;

INSERT INTO permisos (clave, modulo, descripcion) VALUES
('dashboard.view', 'dashboard', 'Ver dashboard operativo'),
('branches.view', 'branches', 'Ver sucursales'),
('branches.manage', 'branches', 'Crear y editar sucursales'),
('users.view', 'users', 'Ver usuarios'),
('users.manage', 'users', 'Crear y editar usuarios'),
('roles.view', 'roles', 'Ver roles'),
('roles.manage', 'roles', 'Editar permisos por rol'),
('customers.view', 'customers', 'Ver clientes'),
('customers.manage', 'customers', 'Crear y editar clientes'),
('catalog.categories.view', 'catalog', 'Ver categorias'),
('catalog.categories.manage', 'catalog', 'Crear y editar categorias'),
('catalog.products.view', 'catalog', 'Ver productos'),
('catalog.products.manage', 'catalog', 'Crear y editar productos'),
('catalog.prices.manage', 'catalog', 'Editar precios'),
('catalog.media.manage', 'catalog', 'Gestionar fotos de productos'),
('ingredients.view', 'ingredients', 'Ver ingredientes'),
('ingredients.manage', 'ingredients', 'Crear y editar ingredientes'),
('recipes.view', 'recipes', 'Ver recetas'),
('recipes.manage', 'recipes', 'Crear y editar recetas'),
('builders.view', 'builders', 'Ver configuradores'),
('builders.manage', 'builders', 'Crear y editar configuradores'),
('promotions.view', 'promotions', 'Ver promociones'),
('promotions.manage', 'promotions', 'Crear y editar promociones'),
('orders.view', 'orders', 'Ver ordenes'),
('orders.create', 'orders', 'Crear ordenes'),
('orders.update', 'orders', 'Editar ordenes'),
('orders.close_without_payment', 'orders', 'Cerrar sin pago'),
('payments.charge', 'payments', 'Cobrar ordenes'),
('payments.refund', 'payments', 'Aplicar devoluciones'),
('cash.open', 'cash', 'Abrir turno de caja'),
('cash.close', 'cash', 'Cerrar turno de caja'),
('cash.movement', 'cash', 'Agregar movimientos de caja'),
('delivery.view', 'delivery', 'Ver entregas'),
('delivery.assign', 'delivery', 'Asignar repartidor'),
('delivery.settle', 'delivery', 'Liquidar repartidores'),
('tickets.print', 'tickets', 'Imprimir ticket'),
('tickets.reprint', 'tickets', 'Reimprimir ticket'),
('inventory.view', 'inventory', 'Ver inventario'),
('inventory.manage', 'inventory', 'Crear movimientos de inventario'),
('reports.view', 'reports', 'Ver reportes'),
('settings.view', 'settings', 'Ver configuracion global'),
('settings.manage', 'settings', 'Editar configuracion global y tipo de cambio'),
('audit.view', 'audit', 'Ver bitacora de auditoria')
ON DUPLICATE KEY UPDATE
  modulo = VALUES(modulo),
  descripcion = VALUES(descripcion),
  updated_at = NOW();

INSERT INTO rol_permisos (rol_id, permiso_id, permitido)
SELECT r.id, p.id, 1
FROM roles r
JOIN permisos p ON 1 = 1
WHERE r.nombre = 'admin'
ON DUPLICATE KEY UPDATE permitido = VALUES(permitido), updated_at = NOW();

INSERT INTO rol_permisos (rol_id, permiso_id, permitido)
SELECT r.id, p.id, 1
FROM roles r
JOIN permisos p ON p.clave IN (
  'dashboard.view', 'branches.view', 'users.view', 'customers.view', 'customers.manage',
  'catalog.categories.view', 'catalog.categories.manage', 'catalog.products.view', 'catalog.products.manage',
  'ingredients.view', 'ingredients.manage', 'recipes.view', 'recipes.manage',
  'builders.view', 'builders.manage', 'promotions.view', 'promotions.manage',
  'orders.view', 'orders.create', 'orders.update', 'orders.close_without_payment',
  'payments.charge', 'cash.open', 'cash.close', 'cash.movement',
  'delivery.view', 'delivery.assign', 'tickets.print', 'tickets.reprint',
  'inventory.view', 'inventory.manage', 'reports.view', 'settings.view'
)
WHERE r.nombre = 'supervisor'
ON DUPLICATE KEY UPDATE permitido = VALUES(permitido), updated_at = NOW();

INSERT INTO rol_permisos (rol_id, permiso_id, permitido)
SELECT r.id, p.id, 1
FROM roles r
JOIN permisos p ON p.clave IN (
  'dashboard.view', 'customers.view', 'customers.manage',
  'catalog.categories.view', 'catalog.products.view',
  'orders.view', 'orders.create', 'orders.update', 'orders.close_without_payment',
  'payments.charge', 'cash.open', 'cash.close', 'cash.movement',
  'tickets.print', 'tickets.reprint'
)
WHERE r.nombre = 'cajero'
ON DUPLICATE KEY UPDATE permitido = VALUES(permitido), updated_at = NOW();

INSERT INTO rol_permisos (rol_id, permiso_id, permitido)
SELECT r.id, p.id, 1
FROM roles r
JOIN permisos p ON p.clave IN ('dashboard.view', 'orders.view', 'orders.update', 'tickets.print')
WHERE r.nombre = 'cocina'
ON DUPLICATE KEY UPDATE permitido = VALUES(permitido), updated_at = NOW();

INSERT INTO rol_permisos (rol_id, permiso_id, permitido)
SELECT r.id, p.id, 1
FROM roles r
JOIN permisos p ON p.clave IN ('dashboard.view', 'orders.view', 'delivery.view', 'delivery.assign', 'delivery.settle', 'tickets.print')
WHERE r.nombre = 'repartidor'
ON DUPLICATE KEY UPDATE permitido = VALUES(permitido), updated_at = NOW();

INSERT INTO usuario_sucursales (usuario_id, sucursal_id, es_principal, activa)
SELECT u.id, u.sucursal_id, 1, 1
FROM usuarios u
WHERE u.sucursal_id IS NOT NULL
ON DUPLICATE KEY UPDATE es_principal = VALUES(es_principal), activa = VALUES(activa), updated_at = NOW();

INSERT INTO configuraciones_globales (clave, valor, tipo, descripcion) VALUES
('business.name', 'Rons Pizza', 'string', 'Nombre comercial del negocio'),
('business.currency', 'MXN', 'string', 'Moneda principal'),
('business.ticket_footer', 'Gracias por su compra', 'string', 'Pie de ticket cliente'),
('payments.usd_exchange_mode', 'manual', 'string', 'Modo de tipo de cambio USD'),
('payments.usd_exchange_default', '17.000000', 'number', 'Tipo de cambio USD default'),
('orders.default_type_takeout', 'recoger', 'string', 'Tipo de pedido por defecto sin mesa'),
('orders.require_delivery_address', 'true', 'boolean', 'Requerir direccion cuando tipo_pedido sea delivery'),
('tickets.print_customer_on_payment', 'true', 'boolean', 'Imprimir ticket cliente al completar pago'),
('tickets.print_kitchen_on_send', 'true', 'boolean', 'Imprimir ticket cocina al enviar a cocina'),
('security.max_login_attempts', '5', 'number', 'Intentos maximos antes de bloqueo temporal')
ON DUPLICATE KEY UPDATE
  valor = VALUES(valor),
  tipo = VALUES(tipo),
  descripcion = VALUES(descripcion),
  updated_at = NOW();

UPDATE tipos_cambio
SET activa = 0
WHERE moneda_origen = 'USD' AND moneda_destino = 'MXN';

INSERT INTO tipos_cambio (moneda_origen, moneda_destino, tipo_cambio, vigente_desde, vigente_hasta, fuente, activa)
SELECT 'USD', 'MXN', 17.000000, NOW(), NULL, 'seed', 1
WHERE NOT EXISTS (
  SELECT 1
  FROM tipos_cambio t
  WHERE t.moneda_origen = 'USD'
    AND t.moneda_destino = 'MXN'
    AND t.activa = 1
);

UPDATE tipos_cambio
SET tipo_cambio = 17.000000, vigente_hasta = NULL, fuente = 'seed', activa = 1, updated_at = NOW()
WHERE moneda_origen = 'USD' AND moneda_destino = 'MXN' AND activa = 1;

INSERT INTO estados_pedido_catalogo (clave, nombre, es_activo_operativo, es_terminal, orden_visual) VALUES
('pending', 'Pendiente', 1, 0, 10),
('open', 'Abierta', 1, 0, 20),
('occupied', 'Ocupada', 1, 0, 30),
('in_progress', 'En progreso', 1, 0, 40),
('awaiting_payment', 'Pendiente de pago', 1, 0, 50),
('paid', 'Pagada', 0, 1, 60),
('completed', 'Completada', 0, 1, 70),
('closed_without_payment', 'Cerrada sin pago', 0, 1, 80),
('closed', 'Cerrada', 0, 1, 90),
('cancelled', 'Cancelada', 0, 1, 100)
ON DUPLICATE KEY UPDATE
  nombre = VALUES(nombre),
  es_activo_operativo = VALUES(es_activo_operativo),
  es_terminal = VALUES(es_terminal),
  orden_visual = VALUES(orden_visual),
  updated_at = NOW();

INSERT INTO estados_pago_catalogo (clave, nombre, es_terminal, orden_visual) VALUES
('pending', 'Pendiente', 0, 10),
('partial', 'Parcial', 0, 20),
('paid', 'Pagado', 1, 30),
('refunded', 'Devuelto', 1, 40),
('cancelled', 'Cancelado', 1, 50)
ON DUPLICATE KEY UPDATE
  nombre = VALUES(nombre),
  es_terminal = VALUES(es_terminal),
  orden_visual = VALUES(orden_visual),
  updated_at = NOW();

INSERT INTO tipos_pedido_catalogo (clave, nombre, requiere_mesa, requiere_direccion, orden_visual) VALUES
('dine_in', 'Mesa', 1, 0, 10),
('recoger', 'Recoger', 0, 0, 20),
('delivery', 'Domicilio', 0, 1, 30),
('telefono', 'Telefonico', 0, 1, 40)
ON DUPLICATE KEY UPDATE
  nombre = VALUES(nombre),
  requiere_mesa = VALUES(requiere_mesa),
  requiere_direccion = VALUES(requiere_direccion),
  orden_visual = VALUES(orden_visual),
  updated_at = NOW();

