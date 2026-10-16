# Catalogue

Customers book a **service**, not a cloth SKU. A cart has one line per service, priced `per_kg` or `per_unit`.

A service is bookable when it and its category are active, and the chosen price type is available (`per_kg_price > 0`, or at least one active cloth with `per_unit_price > 0`). A service man is not required to book. Submit-to-services fails with `NO_SERVICE_MAN` until one is assigned.

`includes` and `excludes` are string lists on the service, edited by the admin service API and returned by `GET /api/v1/catalog/pricing`.

Prices on a bill are the prices at Mark as picked up. Later catalogue edits do not change that bill. Rows referenced by an order are deactivated, not deleted (`409 IN_USE_DEACTIVATE_INSTEAD`).
