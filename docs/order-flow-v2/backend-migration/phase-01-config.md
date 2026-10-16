# Phase 1: Config service

**Size:** S  **Depends on:** 0  **Migration:** `v2_p01_app_config`

## Goal

Every tunable in the spec is read from one place: DB value, else env, else default. Admin can change it without a redeploy.

## Schema

```prisma
model AppConfig {
  key         String   @id @db.VarChar(100)
  value       Json
  description String?
  updated_by  String?  @db.VarChar(100)   // admin user_id
  updated_at  DateTime @updatedAt
  @@map("app_config")
}
```

## Config keys

| Key | Default | Rule |
|---|---|---|
| `ASSIGNMENT_TIMEOUT_MINUTES` | 5 | allowed 5, 10, 20 (decimals allowed only when `NODE_ENV=test`) |
| `ASSIGNMENT_RANGE_SLICES` | 5 | integer 1 to 10 |
| `ASSIGNMENT_MAX_RANGE_KM` | 10 | number > 0 (seed value; set real value in admin) |
| `PICKUP_DELIVERY_BUFFER_DAYS` | 2 | integer 0 to 14. **One constant**, no second name (spec P6.7) |
| `DELIVERY_FEE` | 0 | number >= 0 |
| `EXPRESS_FEE` | 0 | number >= 0 |
| `SERVICE_QUEUE_POLL_SECONDS` | 120 | allowed 60 or 120 |
| `DIRECTIONS_REFRESH_SECONDS` | 120 | client hint only; backend never calls Directions |

## Tasks

1. `src/services/config.service.js`
   - Resolution order: DB row -> `process.env[KEY]` -> built-in default.
   - Typed getters (`getNumber`, `getInt`, `getEnum`), 30 s in-memory cache, cache cleared on write.
   - Joi schema per key (table above); unknown keys rejected.
2. Seed all keys with defaults.
3. Public client config: `GET /api/v1/config` (extend existing `config.routes.js`) returns only client-safe values: `pickupDeliveryBufferDays`, `serviceQueuePollSeconds`, `directionsRefreshSeconds`, `assignmentTimeoutMinutes`.
4. Admin API (roles `admin`, `owner`):
   - `GET /api/v1/admin/config` returns all keys with `value`, `source` (`db|env|default`), `description`.
   - `PUT /api/v1/admin/config/:key` body `{ value }`; validates, stores `updated_by`.
5. Do **not** touch the assignment worker yet. Phase 3 switches it to this service.

## API contract

| Method | Path | Who | Notes |
|---|---|---|---|
| GET | `/api/v1/config` | anyone | client-safe subset |
| GET | `/api/v1/admin/config` | admin, owner | all keys + source |
| PUT | `/api/v1/admin/config/:key` | admin, owner | validated per key |

## Tests

- Precedence: default -> env override -> DB override; deleting the DB row falls back.
- Validation: timeout `7` rejected; `10` accepted; unknown key 404/400.
- Cache: write then read returns the new value immediately.
- Authz: customer and staff get 403 on admin routes.

## Exit checklist

- [ ] All eight keys readable via service and API.
- [ ] Source reported correctly (`db|env|default`).
- [ ] Tests green; Postman folder "Phase 1" added.
