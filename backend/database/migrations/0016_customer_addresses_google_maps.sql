ALTER TABLE direcciones_cliente
  ADD COLUMN IF NOT EXISTS place_id VARCHAR(191) NULL AFTER lng;

SET @idx_exists := (
  SELECT COUNT(1)
  FROM information_schema.STATISTICS
  WHERE table_schema = DATABASE()
    AND table_name = 'direcciones_cliente'
    AND index_name = 'idx_direcciones_place_id'
);

SET @idx_sql := IF(
  @idx_exists = 0,
  'CREATE INDEX idx_direcciones_place_id ON direcciones_cliente(place_id)',
  'SELECT 1'
);

PREPARE idx_stmt FROM @idx_sql;
EXECUTE idx_stmt;
DEALLOCATE PREPARE idx_stmt;
