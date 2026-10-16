# Event catalogue

> Part of the order-flow v2 pack. Source of truth: [`../order-flow-spec.md`](../order-flow-spec.md). Mermaid renders in GitHub / Cursor preview.

## 8. Event catalogue

| # | Event | Actor | Guard | Writes | Visible effect | API |
|---|---|---|---|---|---|---|
| 1 | Place order | Customer | Services in cart; delivery ≥ pickup + buffer (ordinary) | Order placed, no Bill | Orders list; search begins | POST order [TODAY] changes needed |
| 2 | Place Express order | Customer | No schedule | is_express, both instant | Chip on every card | same POST [NEW] flag |
| 3 | Cancel | Customer | status = placed; reason required | cancelled, cancel_reason | History Cancelled; stop job | POST cancel [NEW] |
| 4 | Reschedule | Customer | status = placed; not Express | times; stop and restart search | Order card updated | PATCH schedule [NEW] |
| 5 | Offer pickup | Worker | on-shift in ring | Request + recipients | Overlay on staff | BullMQ + SSE [TODAY] rings new |
| 6 | Accept pickup | Pickup boy | first writer | pickup_assigned | Tracking opens | accept offer [TODAY] |
| 7 | Force-assign pickup | CM | after timeout | pickup_assigned | SSE; cannot reject | assignPickupDirect [TODAY] |
| 8 | Save draft per service | Pickup boy | assigned to him | items_confirmed=false | Restores after app kill | PATCH items [NEW] |
| 9 | Mark as picked up | Pickup boy | all services filled + photos | Bill, items_confirmed, picked_up | Pickup done; View bill | POST confirm [NEW] |
| 10 | Submit request to CM | Pickup boy | picked_up | submitted_to_cm | Button inactive | delivery action submitted_to_cm [TODAY] semantics change |
| 11 | Verified and Received | CM | submitted_to_cm | received_by_collection; pickup Delivery completed | Row leaves boy list | markOrderReceived [TODAY] tighten guard |
| 12 | Send to service queue | CM | received_by_collection; SM exists per service | queue rows; submitted_to_services | CM history; SM queue | submit-to-services [TODAY] |
| 13 | Poll queue | Service man | screen visible | — | New rows at bottom of band | GET queue [TODAY] |
| 14 | Start item | Service man | not completed | in_progress; services_in_progress | — | PATCH queue [TODAY] |
| 15 | Complete item | Service man | — | completed; maybe services_completed | DM in-plant; Ready when last | PATCH queue [TODAY] |
| 16 | Start drop search | System | all done + (instant \| Express \| time reached) | Drop request | DM Assign disabled | worker twin [NEW] |
| 17 | Accept drop | Captain | first writer | out_for_delivery | Map + cards | accept offer [TODAY] |
| 18 | Force-assign drop | DM | after timeout | out_for_delivery | SSE; cannot reject | assign-drop-direct [TODAY] drop verify gate |
| 19 | Apply coupon | Customer | out_for_delivery; one code | Bill.discount | Total updates | coupon apply [NEW] |
| 20 | Pay UPI | Customer | out_for_delivery | — | Opens UPI app | create payment [NEW] |
| 21 | UPI success | PSP | — | payment completed upi | Paid everywhere | webhook [NEW] |
| 22 | Paid in cash | Captain | UPI failed and not completed | payment completed cod | Paid everywhere | record cash [NEW] |
| 23 | Mark as delivered | Captain | payment completed; one photo | drop_proof; delivered | Delivered | dropped [TODAY] add payment gate |
| 24 | Location tick | Captain | on shift | current lat/lng | Pin moves | updateLiveLocation [TODAY] |
| 25 | Directions refresh | System | off path; ≥2 min since last | — | Path redrawn | Directions [NEW] |
