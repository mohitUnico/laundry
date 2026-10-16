# Order flow v2

The live order statuses are the eleven values in `backend/src/constants/order-flow.js`. Every status write in the new flow goes through `assertTransition`.

```
placed → pickup_assigned → picked_up → submitted_to_cm → received_by_collection
  → submitted_to_services → services_in_progress → services_completed
  → out_for_delivery → delivered
placed → cancelled
```

`placed → placed` is a reschedule. `services_in_progress → services_in_progress` is allowed when another service starts.

Diagrams: `docs/order-flow-v2/diagrams/`.

## Who does what

| Step | Who | Endpoint |
|---|---|---|
| Place order | Customer | `POST /api/v1/orders/create_order` |
| Accept pickup | Delivery staff | `POST /api/v1/delivery-staff/assignment-requests/:id/accept` |
| Door draft / photo / confirm | Pickup partner | `/api/v1/delivery-staff-app/orders/:orderId/door` |
| Submit to collection manager | Pickup partner | `POST .../submit-to-cm` |
| Mark received | Collection manager | `POST /api/v1/staff-app/collection-manager/orders/:orderId/mark-received` |
| Submit to services | Collection manager | `POST .../submit-to-services` |
| Start or complete a service | Service man | `PATCH /api/v1/staff-app/service-man/queue/:id/status` |
| Accept drop | Delivery staff | same accept endpoint, drop request |
| Force-assign after timeout | CM or DM | `assign-pickup-direct` / `assign-drop` |
| Pay | Customer | `POST /api/v1/payments/orders/:orderId/pay-intent` |
| Cash after a failed UPI | Drop captain | `POST .../record-cash` |
| Mark delivered | Drop captain | `POST .../mark-delivered` (one photo, bill paid) |

A service is bookable when the admin has left it active and the chosen price type is available. A service man is required only at submit-to-services (`409 NO_SERVICE_MAN`).

The bill is written at Mark as picked up. Prices and fees are snapshotted then. The customer can view the bill immediately and pay from `picked_up` through `out_for_delivery`.
