# Supabase Realtime

## Overview

Supabase Realtime is enabled for these tables to reduce database egress:
- `orders`
- `delivery`
- `service_queue`
- `delivery_staffs`

## Backend Role

The backend **does not subscribe** to Supabase Realtime. It is the **source of writes**:

1. When the backend updates data via Prisma (e.g. `prisma.order.update()`), the write goes to PostgreSQL.
2. Supabase Realtime (via logical replication) broadcasts that change to subscribed clients.
3. Mobile/web apps subscribe to Realtime channels and receive updates without polling the backend.

## Egress Reduction

As clients switch from REST polling to Realtime subscriptions:
- Fewer `GET /orders`, `GET /delivery`, etc. requests hit the backend
- Less database egress (fewer SELECT queries from polling)
- Clients receive updates instantly via WebSocket

## Client Implementation

- **Customer app**: Subscribes to `orders` (home, orders list), `delivery_staffs` (driver tracking), `coupons`
- **Management app**: Can subscribe to `delivery`, `orders`, `service_queue` for staff roles (future)
