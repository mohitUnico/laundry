# Testing

From `backend/`:

- `npm run test:unit` runs `tests/unit`.
- `npm run test:int` runs the integration suite against `laundry_test` only. `tests/setup-env.js` forces that database. Do not point it at `laundry_db`.

The suite today covers phases 0–4 (status machine, config, booking, pickup rings, cancel and reschedule). Phases 5–11 are implemented and are not in that suite yet. Coverage of the whole `src` tree is below the 70% target until that pass.

Apply migrations to the test database with `DATABASE_URL` set to `laundry_test`, then `npx prisma migrate deploy`. Never run `prisma migrate reset` on the real database. The catalogue (categories, services, cloth items) is kept.
