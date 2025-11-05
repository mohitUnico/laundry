-- CreateTable
CREATE TABLE "laundry_mart" (
    "mart_id" TEXT NOT NULL,
    "mart_name" VARCHAR(255) NOT NULL,
    "contact_email" VARCHAR(255) NOT NULL,
    "contact_phone" VARCHAR(20) NOT NULL,
    "address" TEXT NOT NULL,
    "latitude" DECIMAL(10,8) NOT NULL,
    "longitude" DECIMAL(11,8) NOT NULL,
    "service_radius_km" JSONB NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "laundry_mart_pkey" PRIMARY KEY ("mart_id")
);

-- CreateTable
CREATE TABLE "users" (
    "user_id" TEXT NOT NULL,
    "mart_id" TEXT NOT NULL,
    "full_name" VARCHAR(255) NOT NULL,
    "email" VARCHAR(255) NOT NULL,
    "phone" VARCHAR(20) NOT NULL,
    "password" VARCHAR(255) NOT NULL,
    "role" VARCHAR(50) NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("user_id")
);

-- CreateTable
CREATE TABLE "customers" (
    "customer_id" TEXT NOT NULL,
    "full_name" VARCHAR(255) NOT NULL,
    "email" VARCHAR(255) NOT NULL,
    "phone" VARCHAR(20) NOT NULL,
    "password" VARCHAR(255) NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "customers_pkey" PRIMARY KEY ("customer_id")
);

-- CreateTable
CREATE TABLE "customer_addresses" (
    "address_id" TEXT NOT NULL,
    "customer_id" TEXT NOT NULL,
    "address_label" VARCHAR(50) NOT NULL,
    "full_address" TEXT NOT NULL,
    "latitude" DECIMAL(10,8) NOT NULL,
    "longitude" DECIMAL(11,8) NOT NULL,
    "is_default" BOOLEAN NOT NULL DEFAULT false,
    "delivery_note" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "customer_addresses_pkey" PRIMARY KEY ("address_id")
);

-- CreateTable
CREATE TABLE "customer_mart_profile" (
    "profile_id" TEXT NOT NULL,
    "customer_id" TEXT NOT NULL,
    "mart_id" TEXT NOT NULL,
    "total_orders" INTEGER NOT NULL DEFAULT 0,
    "total_spent" DECIMAL(10,2) NOT NULL DEFAULT 0,
    "last_order_date" TIMESTAMP(3),
    "customer_rating" DECIMAL(3,2),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "customer_mart_profile_pkey" PRIMARY KEY ("profile_id")
);

-- CreateTable
CREATE TABLE "service_categories" (
    "category_id" TEXT NOT NULL,
    "category_name" VARCHAR(100) NOT NULL,
    "description" TEXT,
    "icon_url" VARCHAR(500),
    "display_order" INTEGER NOT NULL DEFAULT 0,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "service_categories_pkey" PRIMARY KEY ("category_id")
);

-- CreateTable
CREATE TABLE "services" (
    "service_id" TEXT NOT NULL,
    "category_id" TEXT NOT NULL,
    "mart_id" TEXT NOT NULL,
    "service_name" VARCHAR(255) NOT NULL,
    "description" TEXT,
    "base_price" DECIMAL(10,2) NOT NULL,
    "per_kg_price" DECIMAL(10,2),
    "estimated_hours" INTEGER NOT NULL,
    "icon_url" VARCHAR(500),
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "display_order" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "services_pkey" PRIMARY KEY ("service_id")
);

-- CreateTable
CREATE TABLE "clothes_items" (
    "item_id" TEXT NOT NULL,
    "item_name" VARCHAR(100) NOT NULL,
    "per_unit_price" DECIMAL(10,2) NOT NULL,
    "icon_url" VARCHAR(500),
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "display_order" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "clothes_items_pkey" PRIMARY KEY ("item_id")
);

-- CreateTable
CREATE TABLE "orders" (
    "order_id" TEXT NOT NULL,
    "customer_id" TEXT NOT NULL,
    "mart_id" TEXT NOT NULL,
    "order_status" VARCHAR(50) NOT NULL,
    "pricing_model" VARCHAR(50) NOT NULL,
    "total_amount" DECIMAL(10,2) NOT NULL,
    "pickup_address_id" TEXT NOT NULL,
    "delivery_address_id" TEXT NOT NULL,
    "pickup_date" TIMESTAMP(3) NOT NULL,
    "delivery_date" TIMESTAMP(3) NOT NULL,
    "special_instructions" TEXT,
    "customer_rating" DECIMAL(3,2),
    "customer_review" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "orders_pkey" PRIMARY KEY ("order_id")
);

-- CreateTable
CREATE TABLE "order_items" (
    "item_id" TEXT NOT NULL,
    "order_id" TEXT NOT NULL,
    "clothes_id" TEXT NOT NULL,
    "quantity" INTEGER NOT NULL,
    "unit_price" DECIMAL(10,2) NOT NULL,
    "subtotal" DECIMAL(10,2) NOT NULL,

    CONSTRAINT "order_items_pkey" PRIMARY KEY ("item_id")
);

-- CreateTable
CREATE TABLE "order_items_kg" (
    "item_kg_id" TEXT NOT NULL,
    "order_id" TEXT NOT NULL,
    "item_name" VARCHAR(255) NOT NULL,
    "weight_kg" DECIMAL(10,2) NOT NULL,
    "price_per_kg" DECIMAL(10,2) NOT NULL,
    "subtotal" DECIMAL(10,2) NOT NULL,

    CONSTRAINT "order_items_kg_pkey" PRIMARY KEY ("item_kg_id")
);

-- CreateTable
CREATE TABLE "bills" (
    "bill_id" TEXT NOT NULL,
    "order_id" TEXT NOT NULL,
    "subtotal" DECIMAL(10,2) NOT NULL,
    "delivery_fee" DECIMAL(10,2) NOT NULL,
    "tax_amount" DECIMAL(10,2) NOT NULL,
    "discount" DECIMAL(10,2) NOT NULL DEFAULT 0,
    "final_amount" DECIMAL(10,2) NOT NULL,
    "payment_method" VARCHAR(50) NOT NULL,
    "payment_status" VARCHAR(50) NOT NULL,
    "transaction_id" VARCHAR(255),
    "paid_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "bills_pkey" PRIMARY KEY ("bill_id")
);

-- CreateTable
CREATE TABLE "delivery_staffs" (
    "staff_id" TEXT NOT NULL,
    "mart_id" TEXT NOT NULL,
    "full_name" VARCHAR(255) NOT NULL,
    "phone" VARCHAR(20) NOT NULL,
    "email" VARCHAR(255),
    "password" VARCHAR(255) NOT NULL,
    "vehicle_type" VARCHAR(50) NOT NULL,
    "vehicle_number" VARCHAR(50) NOT NULL,
    "license_number" VARCHAR(50) NOT NULL,
    "document_url" VARCHAR(500),
    "bank_account_details" JSONB,
    "verification_status" VARCHAR(50) NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "average_rating" DECIMAL(3,2),
    "total_deliveries" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "delivery_staffs_pkey" PRIMARY KEY ("staff_id")
);

-- CreateTable
CREATE TABLE "delivery" (
    "delivery_id" TEXT NOT NULL,
    "order_id" TEXT NOT NULL,
    "staff_id" TEXT NOT NULL,
    "delivery_status" VARCHAR(50) NOT NULL,
    "assigned_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "completed_at" TIMESTAMP(3),
    "delivery_rating" DECIMAL(3,2),
    "delivery_review" TEXT,
    "delivery_fee" DECIMAL(10,2) NOT NULL,
    "distance_km" DECIMAL(10,2),
    "estimated_duration" INTEGER,
    "actual_duration" INTEGER,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "delivery_pkey" PRIMARY KEY ("delivery_id")
);

-- CreateTable
CREATE TABLE "pickup_for_delivery" (
    "pickup_id" TEXT NOT NULL,
    "delivery_id" TEXT NOT NULL,
    "pickup_address" TEXT NOT NULL,
    "pickup_lat" DECIMAL(10,8) NOT NULL,
    "pickup_lng" DECIMAL(11,8) NOT NULL,
    "pickup_status" VARCHAR(50) NOT NULL,
    "pickup_time" TIMESTAMP(3),
    "pickup_proof" VARCHAR(500) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "pickup_for_delivery_pkey" PRIMARY KEY ("pickup_id")
);

-- CreateTable
CREATE TABLE "drop_for_delivery" (
    "drop_id" TEXT NOT NULL,
    "delivery_id" TEXT NOT NULL,
    "drop_address" TEXT NOT NULL,
    "drop_lat" DECIMAL(10,8) NOT NULL,
    "drop_lng" DECIMAL(11,8) NOT NULL,
    "drop_status" VARCHAR(50) NOT NULL,
    "drop_time" TIMESTAMP(3),
    "drop_proof" VARCHAR(500) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "drop_for_delivery_pkey" PRIMARY KEY ("drop_id")
);

-- CreateTable
CREATE TABLE "mart_daily_metrics" (
    "metric_id" TEXT NOT NULL,
    "mart_id" TEXT NOT NULL,
    "metric_date" DATE NOT NULL,
    "total_orders" INTEGER NOT NULL DEFAULT 0,
    "completed_orders" INTEGER NOT NULL DEFAULT 0,
    "cancelled_orders" INTEGER NOT NULL DEFAULT 0,
    "total_revenue" DECIMAL(10,2) NOT NULL DEFAULT 0,
    "total_customers" INTEGER NOT NULL DEFAULT 0,
    "new_customers" INTEGER NOT NULL DEFAULT 0,
    "avg_order_value" DECIMAL(10,2) NOT NULL DEFAULT 0,
    "completion_rate" DECIMAL(5,2) NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "mart_daily_metrics_pkey" PRIMARY KEY ("metric_id")
);

-- CreateIndex
CREATE UNIQUE INDEX "laundry_mart_contact_email_key" ON "laundry_mart"("contact_email");

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE INDEX "users_mart_id_idx" ON "users"("mart_id");

-- CreateIndex
CREATE UNIQUE INDEX "customers_email_key" ON "customers"("email");

-- CreateIndex
CREATE UNIQUE INDEX "customers_phone_key" ON "customers"("phone");

-- CreateIndex
CREATE INDEX "customer_addresses_customer_id_idx" ON "customer_addresses"("customer_id");

-- CreateIndex
CREATE INDEX "customer_mart_profile_customer_id_idx" ON "customer_mart_profile"("customer_id");

-- CreateIndex
CREATE INDEX "customer_mart_profile_mart_id_idx" ON "customer_mart_profile"("mart_id");

-- CreateIndex
CREATE UNIQUE INDEX "customer_mart_profile_customer_id_mart_id_key" ON "customer_mart_profile"("customer_id", "mart_id");

-- CreateIndex
CREATE INDEX "services_category_id_idx" ON "services"("category_id");

-- CreateIndex
CREATE INDEX "services_mart_id_idx" ON "services"("mart_id");

-- CreateIndex
CREATE INDEX "orders_customer_id_idx" ON "orders"("customer_id");

-- CreateIndex
CREATE INDEX "orders_mart_id_idx" ON "orders"("mart_id");

-- CreateIndex
CREATE INDEX "orders_order_status_idx" ON "orders"("order_status");

-- CreateIndex
CREATE INDEX "orders_created_at_idx" ON "orders"("created_at");

-- CreateIndex
CREATE INDEX "order_items_order_id_idx" ON "order_items"("order_id");

-- CreateIndex
CREATE INDEX "order_items_kg_order_id_idx" ON "order_items_kg"("order_id");

-- CreateIndex
CREATE UNIQUE INDEX "bills_order_id_key" ON "bills"("order_id");

-- CreateIndex
CREATE INDEX "bills_payment_status_idx" ON "bills"("payment_status");

-- CreateIndex
CREATE INDEX "bills_created_at_idx" ON "bills"("created_at");

-- CreateIndex
CREATE UNIQUE INDEX "delivery_staffs_phone_key" ON "delivery_staffs"("phone");

-- CreateIndex
CREATE UNIQUE INDEX "delivery_staffs_email_key" ON "delivery_staffs"("email");

-- CreateIndex
CREATE INDEX "delivery_staffs_mart_id_idx" ON "delivery_staffs"("mart_id");

-- CreateIndex
CREATE INDEX "delivery_staffs_verification_status_idx" ON "delivery_staffs"("verification_status");

-- CreateIndex
CREATE UNIQUE INDEX "delivery_order_id_key" ON "delivery"("order_id");

-- CreateIndex
CREATE INDEX "delivery_staff_id_idx" ON "delivery"("staff_id");

-- CreateIndex
CREATE INDEX "delivery_delivery_status_idx" ON "delivery"("delivery_status");

-- CreateIndex
CREATE UNIQUE INDEX "pickup_for_delivery_delivery_id_key" ON "pickup_for_delivery"("delivery_id");

-- CreateIndex
CREATE INDEX "pickup_for_delivery_pickup_status_idx" ON "pickup_for_delivery"("pickup_status");

-- CreateIndex
CREATE UNIQUE INDEX "drop_for_delivery_delivery_id_key" ON "drop_for_delivery"("delivery_id");

-- CreateIndex
CREATE INDEX "drop_for_delivery_drop_status_idx" ON "drop_for_delivery"("drop_status");

-- CreateIndex
CREATE INDEX "mart_daily_metrics_mart_id_idx" ON "mart_daily_metrics"("mart_id");

-- CreateIndex
CREATE INDEX "mart_daily_metrics_metric_date_idx" ON "mart_daily_metrics"("metric_date");

-- CreateIndex
CREATE UNIQUE INDEX "mart_daily_metrics_mart_id_metric_date_key" ON "mart_daily_metrics"("mart_id", "metric_date");

-- AddForeignKey
ALTER TABLE "users" ADD CONSTRAINT "users_mart_id_fkey" FOREIGN KEY ("mart_id") REFERENCES "laundry_mart"("mart_id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "customer_addresses" ADD CONSTRAINT "customer_addresses_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "customers"("customer_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "customer_mart_profile" ADD CONSTRAINT "customer_mart_profile_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "customers"("customer_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "customer_mart_profile" ADD CONSTRAINT "customer_mart_profile_mart_id_fkey" FOREIGN KEY ("mart_id") REFERENCES "laundry_mart"("mart_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "services" ADD CONSTRAINT "services_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "service_categories"("category_id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "services" ADD CONSTRAINT "services_mart_id_fkey" FOREIGN KEY ("mart_id") REFERENCES "laundry_mart"("mart_id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "orders" ADD CONSTRAINT "orders_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "customers"("customer_id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "orders" ADD CONSTRAINT "orders_mart_id_fkey" FOREIGN KEY ("mart_id") REFERENCES "laundry_mart"("mart_id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "orders" ADD CONSTRAINT "orders_pickup_address_id_fkey" FOREIGN KEY ("pickup_address_id") REFERENCES "customer_addresses"("address_id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "orders" ADD CONSTRAINT "orders_delivery_address_id_fkey" FOREIGN KEY ("delivery_address_id") REFERENCES "customer_addresses"("address_id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "order_items" ADD CONSTRAINT "order_items_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "orders"("order_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "order_items" ADD CONSTRAINT "order_items_clothes_id_fkey" FOREIGN KEY ("clothes_id") REFERENCES "clothes_items"("item_id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "order_items_kg" ADD CONSTRAINT "order_items_kg_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "orders"("order_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bills" ADD CONSTRAINT "bills_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "orders"("order_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "delivery_staffs" ADD CONSTRAINT "delivery_staffs_mart_id_fkey" FOREIGN KEY ("mart_id") REFERENCES "laundry_mart"("mart_id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "delivery" ADD CONSTRAINT "delivery_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "orders"("order_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "delivery" ADD CONSTRAINT "delivery_staff_id_fkey" FOREIGN KEY ("staff_id") REFERENCES "delivery_staffs"("staff_id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "pickup_for_delivery" ADD CONSTRAINT "pickup_for_delivery_delivery_id_fkey" FOREIGN KEY ("delivery_id") REFERENCES "delivery"("delivery_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "drop_for_delivery" ADD CONSTRAINT "drop_for_delivery_delivery_id_fkey" FOREIGN KEY ("delivery_id") REFERENCES "delivery"("delivery_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "mart_daily_metrics" ADD CONSTRAINT "mart_daily_metrics_mart_id_fkey" FOREIGN KEY ("mart_id") REFERENCES "laundry_mart"("mart_id") ON DELETE CASCADE ON UPDATE CASCADE;
