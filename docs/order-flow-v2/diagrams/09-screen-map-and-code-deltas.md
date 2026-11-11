# Screen map and spec vs code

> Part of the order-flow v2 pack. Source of truth: [`../order-flow-spec.md`](../order-flow-spec.md). Mermaid renders in GitHub / Cursor preview.

## 11. Screen map (what each app has)

Click-through phone prototypes: ../ui-prototype/index.html (use **Gallery** to see every screen at once). Screen ids in brackets are the prototype articles.

```mermaid
flowchart LR
subgraph CS["Customer app"]
  c0["Login OTP and location [c-login]"]
  c1["Home [c-home]"]
  c2["Pricing tab [c-pricing]"]
  c3["Services [c-services]"]
  c4["Cart [c-cart]"]
  c5["Delivery Options: Express toggle, pickup and delivery slots, addresses, instructions"]
  c6["Orders [c-orders-placed] [c-orders-bill] [c-cancelled]"]
  c7["Tracking [c-track-*]"]
  c8["Pay UPI [c-pay]"]
  c9["Delivered [c-done]"]
  c10["How we work [c-how]"]
  c11["Account [c-account]"]
end
subgraph PS["Pickup boy"]
  p1["Jobs [p-jobs]"]
  p2["Accept [p-accept]"]
  p3["Door list [p-door]"]
  p4["Expand service [p-expand]"]
  p5["Waiting [p-wait]"]
end
subgraph MS["Management app"]
  m1["CM Incoming [cm-in]"]
  m2["CM Force assign [cm-force]"]
  m3["CM Received [cm-rec] History [cm-hist]"]
  m4["SM Queue [sm-q] Work [sm-work] Done [sm-done]"]
  m5["DM In-plant [dm-plant]"]
  m6["DM Ready [dm-wait] [dm-asg] History [dm-hist]"]
end
subgraph KS["Captain"]
  k1["Jobs [d-jobs]"]
  k2["Accept drop [d-accept]"]
  k3["Out for delivery [d-ofd]"]
  k4["Cash [d-cash] Deliver [d-fin]"]
end
subgraph AS["Admin"]
  a1["Config [a-config]"]
end
c0 --> c1 --> c3 --> c4 --> c5 --> c6 --> c7 --> c8 --> c9
c1 --> c2
c1 -->|"pickup cards, no cart"| c5
c1 --> c10
c1 --> c11
p1 --> p2 --> p3 --> p4 --> p5
m1 --> m3
m1 -.-> m2
m3 --> m4 --> m5 --> m6
k1 --> k2 --> k3 --> k4

```

## 12. Spec vs code today (what changes in dev)

| Area | Today | Needs |
|---|---|---|
| Booking | Cart required; cloth SKUs not needed; modes and Express exist; Express forces instant and forbids times | Cart optional (pickup cards create orders with no lines); Express = priority only with its own buffer; admin slots with date + slot_id; no bill at place |
| Slots | None; free-form timestamps | Daily slot template, status open / too_busy / closed, slot admin API, slot API for the app |
| Address | Any location accepted | SERVICE_AREA_KM radius check on add and edit |
| Door catalogue | Only the booked services | Whole catalogue; cart services pre-selected and locked; at least one line to confirm |
| Assignment | Fixed expiry, send-to-all, 2 retries | Rings, one timeout, on-shift, manager only after timeout, drop twin |
| Door | Weight on existing lines; one proof | Expander per service; one photo each; draft; bill on Mark |
| Submit to CM | One tap completes pickup delivery | Request vs CM receive; delivery completes on receive |
| CM receive guard | From placed/picked_up/etc. | Only submitted_to_cm; remove generate-invoice |
| Plant | priority per service | Sort assigned_at; Express band; drop mark-for-later in UX; poll |
| DM | Verify then dispatch | Two lists; auto drop search; remove verify; Assign disabled states |
| Delivery status | dispatch_assigned → start → out_for_delivery | out_for_delivery on assign |
| Payment | Status PATCH; cod/card/wallet; dropped without pay check | PSP UPI + coupon; cash fallback; gate delivered on paid |
| Cancel | Stub dialog | Real cancel + reason; history |
| Customer UI | 5-step tracker, 4 tabs incl Account | 6 steps, tracking open from placed, Pricing tab, avatar → Account, How we work, footer |

Related files: `order-flow-spec.md` · `../ui-prototype/index.html`
