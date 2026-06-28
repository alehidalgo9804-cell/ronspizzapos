-- Sincroniza el costo de envío de pedidos delivery hacia la tabla entregas,
-- asegurando que el reporte de liquidación de repartidores refleje el envío cobrado.
UPDATE entregas e
JOIN pedidos p ON p.id = e.pedido_id
SET e.costo_envio = p.envio_total,
    e.total_repartidor = p.envio_total + e.bono_repartidor
WHERE p.tipo_pedido = 'delivery'
  AND p.envio_total > 0
  AND e.costo_envio = 0;
