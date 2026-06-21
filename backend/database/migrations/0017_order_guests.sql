SET NAMES utf8mb4;

ALTER TABLE pedido_items
  ADD COLUMN guest_id INT UNSIGNED NULL AFTER parent_item_id;

CREATE INDEX idx_pedido_items_guest_id ON pedido_items (guest_id);
