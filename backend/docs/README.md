# Backend

Order flow v2 is implemented in `src/`. Read [docs/ORDER_FLOW.md](ORDER_FLOW.md) for the status machine and [docs/DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md) for the rest.

Run the API from this directory with the env file. Tests use `laundry_test` only (`npm run test:int`). Apply migrations with `npx prisma migrate deploy` before using the new API. Do not reset the real database; categories, services, and cloth items stay.
