INSERT INTO roles (nombre, descripcion) VALUES
('admin', 'Administrador general'),
('cajero', 'Operacion de caja y pedidos'),
('cocina', 'Operacion de cocina'),
('repartidor', 'Aplicacion de delivery'),
('supervisor', 'Control operativo')
ON DUPLICATE KEY UPDATE descripcion = VALUES(descripcion);

INSERT INTO metodos_pago (nombre, clave, activo) VALUES
('Efectivo', 'efectivo', 1),
('Tarjeta', 'tarjeta', 1),
('Transferencia', 'transferencia', 1),
('USD', 'usd', 1),
('Credito Empleado', 'credito_empleado', 1)
ON DUPLICATE KEY UPDATE nombre = VALUES(nombre), activo = VALUES(activo);

INSERT INTO tamanos_pizza (nombre, clave, diametro_cm, porciones, activo) VALUES
('Chica', 'chica', 25, 6, 1),
('Mediana', 'mediana', 32, 8, 1),
('Grande', 'grande', 40, 10, 1)
ON DUPLICATE KEY UPDATE nombre = VALUES(nombre), diametro_cm = VALUES(diametro_cm), porciones = VALUES(porciones), activo = VALUES(activo);

INSERT INTO masas_pizza (nombre, clave, precio_extra, activa) VALUES
('Regular', 'regular', 0.00, 1),
('Delgada', 'delgada', 10.00, 1)
ON DUPLICATE KEY UPDATE nombre = VALUES(nombre), precio_extra = VALUES(precio_extra), activa = VALUES(activa);

INSERT INTO orillas_pizza (nombre, clave, precio_extra, activa) VALUES
('Ninguna', 'ninguna', 0.00, 1),
('Queso Crema', 'queso_crema', 25.00, 1),
('Mozzarella', 'mozzarella', 30.00, 1)
ON DUPLICATE KEY UPDATE nombre = VALUES(nombre), precio_extra = VALUES(precio_extra), activa = VALUES(activa);

INSERT INTO pizza_mitad_reglas (nombre, tipo_regla, activa) VALUES
('Mayor precio', 'mayor_precio', 1),
('Promedio', 'promedio', 1),
('Precio fijo', 'precio_fijo', 1);

INSERT INTO unidades_medida (nombre, clave) VALUES
('Pieza', 'pieza'),
('Gramo', 'gramo'),
('Kilogramo', 'kilogramo'),
('Mililitro', 'mililitro'),
('Litro', 'litro')
ON DUPLICATE KEY UPDATE nombre = VALUES(nombre);

INSERT INTO categorias_producto (nombre, slug, descripcion, orden_visual, activa) VALUES
('Pizzas', 'pizzas', 'Pizzas base y especialidades', 1, 1),
('Alitas', 'alitas', 'Alitas y boneless', 2, 1),
('Hamburguesas', 'hamburguesas', 'Hamburguesas', 3, 1),
('Bebidas', 'bebidas', 'Bebidas frias', 4, 1),
('Extras', 'extras', 'Complementos y extras', 5, 1)
ON DUPLICATE KEY UPDATE nombre = VALUES(nombre), descripcion = VALUES(descripcion), orden_visual = VALUES(orden_visual), activa = VALUES(activa);

INSERT INTO descuentos (nombre, tipo_descuento, valor, requiere_autorizacion, activo) VALUES
('Empleado 10%', 'porcentaje', 10.00, 0, 1),
('Cortesia fija 50', 'monto_fijo', 50.00, 1, 1)
ON DUPLICATE KEY UPDATE tipo_descuento = VALUES(tipo_descuento), valor = VALUES(valor), requiere_autorizacion = VALUES(requiere_autorizacion), activo = VALUES(activo);

INSERT INTO sucursales (nombre, clave, telefono, email, direccion_linea_1, ciudad, estado, codigo_postal, activa)
VALUES ('Rons Pizza Centro', 'CENTRO', '6620000000', 'centro@ronspizza.local', 'Av Principal 100', 'Hermosillo', 'Sonora', '83000', 1)
ON DUPLICATE KEY UPDATE nombre = VALUES(nombre), telefono = VALUES(telefono), email = VALUES(email), activa = VALUES(activa);

INSERT INTO cajas (sucursal_id, nombre, activa)
SELECT s.id, 'Caja Principal', 1
FROM sucursales s
WHERE s.clave = 'CENTRO'
AND NOT EXISTS (SELECT 1 FROM cajas c WHERE c.sucursal_id = s.id AND c.nombre = 'Caja Principal');

INSERT INTO configuraciones_sucursal (sucursal_id, clave, valor, tipo, descripcion)
SELECT s.id, 'bono_repartidor', '10', 'number', 'Bono por entrega para repartidor'
FROM sucursales s
WHERE s.clave = 'CENTRO'
ON DUPLICATE KEY UPDATE valor = VALUES(valor), tipo = VALUES(tipo), descripcion = VALUES(descripcion);

INSERT INTO configuraciones_sucursal (sucursal_id, clave, valor, tipo, descripcion)
SELECT s.id, 'tipo_cambio_usd', '17.50', 'number', 'Tipo de cambio para pagos USD'
FROM sucursales s
WHERE s.clave = 'CENTRO'
ON DUPLICATE KEY UPDATE valor = VALUES(valor), tipo = VALUES(tipo), descripcion = VALUES(descripcion);

INSERT INTO configuraciones_sucursal (sucursal_id, clave, valor, tipo, descripcion)
SELECT s.id, 'delivery_distance_factor', '1.33', 'number', 'Factor para aproximar distancia real por calles'
FROM sucursales s
WHERE s.clave = 'CENTRO'
ON DUPLICATE KEY UPDATE valor = VALUES(valor), tipo = VALUES(tipo), descripcion = VALUES(descripcion);

INSERT INTO usuarios (nombre, apellido, telefono, email, pin, password_hash, rol_id, sucursal_id, activo)
SELECT 'Admin', 'Principal', '6621111111', 'admin@ronspizza.local', '1234', NULL, r.id, s.id, 1
FROM roles r
JOIN sucursales s ON s.clave = 'CENTRO'
WHERE r.nombre = 'admin'
AND NOT EXISTS (SELECT 1 FROM usuarios u WHERE u.email = 'admin@ronspizza.local');
