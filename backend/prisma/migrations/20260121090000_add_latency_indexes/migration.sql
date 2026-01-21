-- Performance indexes to reduce latency for high-traffic read endpoints
-- (service catalog, customer orders, customer addresses)

CREATE INDEX "service_categories_is_active_display_order_idx"
  ON "service_categories" ("is_active", "display_order");

CREATE INDEX "services_category_is_active_display_order_idx"
  ON "services" ("category_id", "is_active", "display_order");

CREATE INDEX "clothes_items_service_is_active_display_order_idx"
  ON "clothes_items" ("service_id", "is_active", "display_order");

CREATE INDEX "orders_customer_created_at_idx"
  ON "orders" ("customer_id", "created_at");

CREATE INDEX "orders_customer_status_created_at_idx"
  ON "orders" ("customer_id", "order_status", "created_at");

CREATE INDEX "customer_addresses_customer_default_updated_idx"
  ON "customer_addresses" ("customer_id", "is_default", "updated_at");


