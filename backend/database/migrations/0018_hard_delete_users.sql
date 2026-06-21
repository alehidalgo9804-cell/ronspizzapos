-- Migration: permitir borrado fisico (hard delete) de usuarios sin perder datos historicos.
-- Cambia las foreign keys restrictivas hacia usuarios(id) a ON DELETE SET NULL,
-- y convierte las columnas correspondientes a NULLABLE cuando sea necesario.

-- ============================================================
-- 1. Hacer NULLABLE las columnas NOT NULL que apuntan a usuarios
-- ============================================================
ALTER TABLE comanda_eventos
    MODIFY COLUMN usuario_id BIGINT UNSIGNED NULL;

ALTER TABLE cortes_caja
    MODIFY COLUMN usuario_apertura_id BIGINT UNSIGNED NULL;

ALTER TABLE devoluciones_pago
    MODIFY COLUMN usuario_id BIGINT UNSIGNED NULL;

ALTER TABLE empleado_credito_abonos
    MODIFY COLUMN usuario_id BIGINT UNSIGNED NULL;

ALTER TABLE historial_contacto_cliente
    MODIFY COLUMN usuario_id BIGINT UNSIGNED NULL;

ALTER TABLE inventario_conteos
    MODIFY COLUMN usuario_id BIGINT UNSIGNED NULL;

ALTER TABLE movimientos_caja
    MODIFY COLUMN usuario_id BIGINT UNSIGNED NULL;

ALTER TABLE movimientos_inventario
    MODIFY COLUMN usuario_id BIGINT UNSIGNED NULL;

ALTER TABLE pagos
    MODIFY COLUMN recibido_por_usuario_id BIGINT UNSIGNED NULL;

ALTER TABLE pedidos
    MODIFY COLUMN usuario_id BIGINT UNSIGNED NULL;

ALTER TABLE pedido_cierre_sin_pago
    MODIFY COLUMN cerrado_por_usuario_id BIGINT UNSIGNED NULL;

ALTER TABLE pedido_descuentos
    MODIFY COLUMN aplicado_por_usuario_id BIGINT UNSIGNED NULL;

ALTER TABLE pedido_notas
    MODIFY COLUMN usuario_id BIGINT UNSIGNED NULL;

-- ============================================================
-- 2. Cambiar constraints a ON DELETE SET NULL
--    Se elimina la FK original y se crea una nueva con nombre
--    distinto para evitar conflictos internos de InnoDB.
-- ============================================================
ALTER TABLE comanda_eventos
    DROP FOREIGN KEY fk_comanda_eventos_usuario,
    ADD CONSTRAINT fk_comanda_eventos_usuario_setnull
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL;

ALTER TABLE cortes_caja
    DROP FOREIGN KEY fk_cortes_caja_usuario_apertura,
    ADD CONSTRAINT fk_cortes_caja_usuario_apertura_setnull
        FOREIGN KEY (usuario_apertura_id) REFERENCES usuarios(id) ON DELETE SET NULL;

ALTER TABLE devoluciones_pago
    DROP FOREIGN KEY fk_devoluciones_pago_usuario,
    ADD CONSTRAINT fk_devoluciones_pago_usuario_setnull
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL;

ALTER TABLE empleado_credito_abonos
    DROP FOREIGN KEY fk_credito_abonos_usuario,
    ADD CONSTRAINT fk_credito_abonos_usuario_setnull
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL;

ALTER TABLE historial_contacto_cliente
    DROP FOREIGN KEY fk_historial_contacto_usuario,
    ADD CONSTRAINT fk_historial_contacto_usuario_setnull
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL;

ALTER TABLE inventario_conteos
    DROP FOREIGN KEY fk_inventario_conteos_usuario,
    ADD CONSTRAINT fk_inventario_conteos_usuario_setnull
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL;

ALTER TABLE movimientos_caja
    DROP FOREIGN KEY fk_movimientos_caja_usuario,
    ADD CONSTRAINT fk_movimientos_caja_usuario_setnull
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL;

ALTER TABLE movimientos_inventario
    DROP FOREIGN KEY fk_mov_inventario_usuario,
    ADD CONSTRAINT fk_mov_inventario_usuario_setnull
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL;

ALTER TABLE pagos
    DROP FOREIGN KEY fk_pagos_recibido_por,
    ADD CONSTRAINT fk_pagos_recibido_por_setnull
        FOREIGN KEY (recibido_por_usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL;

ALTER TABLE pedidos
    DROP FOREIGN KEY fk_pedidos_usuario,
    ADD CONSTRAINT fk_pedidos_usuario_setnull
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL;

ALTER TABLE pedido_cierre_sin_pago
    DROP FOREIGN KEY fk_pedido_cierre_sin_pago_usuario,
    ADD CONSTRAINT fk_pedido_cierre_sin_pago_usuario_setnull
        FOREIGN KEY (cerrado_por_usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL;

ALTER TABLE pedido_descuentos
    DROP FOREIGN KEY fk_pedido_descuentos_usuario,
    ADD CONSTRAINT fk_pedido_descuentos_usuario_setnull
        FOREIGN KEY (aplicado_por_usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL;

ALTER TABLE pedido_notas
    DROP FOREIGN KEY fk_pedido_notas_usuario,
    ADD CONSTRAINT fk_pedido_notas_usuario_setnull
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL;
