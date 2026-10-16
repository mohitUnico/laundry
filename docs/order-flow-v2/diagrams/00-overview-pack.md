# WashBee locked order flow — verification diagrams

**Source of truth:** [order-flow-spec.md](../order-flow-spec.md)  
**Purpose:** visual check before development. If a box disagrees with the spec, the spec wins until you correct it here.  
**How to view:** open this file in Cursor preview (Mermaid), or open [viewer.html](viewer.html) for the full set.

Shapes: stadium = start/end · rectangle = step · diamond = decision · cylinder = DB write · parallelogram = actor sees / UI.

---

## 0. Who does what (map)

```mermaid
flowchart LR
  cust[Customer app]
  pick[Pickup boy]
  cm[Collection manager]
  sm[Service man]
  dm[Distribution manager]
  drop[Delivery captain]
  db[(Order Bill Queue)]

  cust -->|"book / cancel / reschedule / view bill / UPI"| db
  pick -->|"count items, bill, request submit"| db
  cm -->|"Verified and Received, Send to queue"| db
  sm -->|"in progress / completed"| db
  dm -->|"Assign after timeout"| db
  drop -->|"Paid in cash, photo, delivered"| db
```

---

## 1. Master spine (happy path)

Ordinary order. Express skips schedule and jumps the service-queue band (diagram 9).

```mermaid
flowchart TB
  book([Customer books services]) --> confirm[Confirm: no item bill]
  confirm --> placed[Status: placed]
  placed --> pSearch{Pickup instant?}
  pSearch -->|yes| pNow[Pickup search starts now]
  pSearch -->|no| pWait[Wait until pickup_time_from]
  pWait --> pNow
  pNow --> pWin{Partner accepts or timeout?}
  pWin -->|accept first write wins| pAsg[pickup_assigned]
  pWin -->|timeout| cmForce[CM force-assign: cannot reject]
  cmForce --> pAsg
  pAsg --> track1[Customer tracking ON: Out for pickup]
  track1 --> door[Boy: count / weigh / photo per service]
  door --> draft[Server draft until Mark as picked up]
  draft --> markPU[Mark as picked up]
  markPU --> bill[(Bill written: services + DELIVERY_FEE + EXPRESS_FEE if any)]
  bill --> picked[Status: picked_up]
  picked --> viewBill[Customer: View bill only. Tracker: Pickup done]
  viewBill --> req[Button: Submit request to CM]
  req --> subCm[Status: submitted_to_cm]
  subCm --> waitBtn[Button inactive: Waiting for CM verification]
  waitBtn --> cmRecv[CM: Verified and Received]
  cmRecv --> recv[Status: received_by_collection]
  recv --> sendQ[CM: Send to service queue]
  sendQ --> subSvc[Status: submitted_to_services]
  subSvc --> qRows[Queue rows: one per service item]
  qRows --> smWork[SM: In progress / Completed. Poll 2 min]
  smWork --> anyDone{Any item completed?}
  anyDone -->|yes| dmPlant[DM in-plant list: expand all items]
  smWork --> allDone{All items completed?}
  allDone -->|yes| ready[Status: services_completed. Tracker: Ready]
  ready --> dropStart{Delivery instant OR time reached?}
  dropStart -->|future scheduled| dmHold[Ready-to-dispatch: Assign disabled Available from time]
  dropStart -->|yes| dSearch[Drop search same engine as pickup]
  dSearch --> dWin{Accept or timeout?}
  dWin -->|accept| ofd[Status: out_for_delivery]
  dWin -->|timeout| dmAsg[DM Assign enabled: cannot reject]
  dmAsg --> ofd
  ofd --> pay[Customer UPI. Fail: boy Paid in cash]
  pay --> paid[(bill.payment_status completed)]
  paid --> photo[Boy: one drop photo]
  photo --> deliv([Status: delivered])
```

---

## 2. Customer booking

```mermaid
flowchart TB
  home([Home]) --> cat[Pick category]
  home --> pricingTab[Nav: Pricing tab browse-only]
  home --> how[Footer: How we work 6 steps]
  home --> brand[Brand strip]
  home --> acct[Avatar: Account]
  pricingTab --> catList[Categories then services]
  catList --> svcPrice[Per service: Rs/kg AND cloth prices AND Includes]
  cat[Services: per kg OR per unit. No SKUs] --> cart[Cart: service + pricing type]
  cart --> express{Express?}
  express -->|yes| expGo[No schedule. Both legs instant. is_express]
  express -->|no| modes[Pickup mode and delivery mode independently]
  modes --> buf{Delivery date >= pickup + PICKUP_DELIVERY_BUFFER_DAYS?}
  buf -->|no| modes
  buf -->|yes| confirm
  expGo --> confirm[Confirm: no itemised bill]
  confirm --> placed[placed]
```

---

## 3. Cancel and reschedule (only while placed)

```mermaid
flowchart TB
  placed[placed: waiting or searching] --> act{Customer action?}
  act -->|Cancel| reason[/Free-text reason/]
  reason --> confC[Confirm]
  confC --> stopP[Stop pickup search and pending offers]
  stopP --> canx[(order_status cancelled)]
  canx --> hist[History as Cancelled]
  act -->|Reschedule| both[Change pickup and/or delivery]
  both --> buf{delivery >= pickup + BUFFER_DAYS?}
  buf -->|no| both
  buf -->|yes| stop2[Stop current search]
  stop2 --> when{New pickup instant or time reached?}
  when -->|yes| searchNow[Start search again]
  when -->|no| wait[Wait until pickup_time_from]
  act -->|Boy already assigned| blocked[Cancel and Change schedule hidden]
```

After `pickup_assigned`: **no** cancel, **no** reschedule. Express: **no** Change schedule (nothing to schedule). Express cannot convert to ordinary. Cancel still allowed only before pickup assigned.

---

## 4. Pickup assignment engine (also drop)

Config: `ASSIGNMENT_TIMEOUT_MINUTES` 5/10/20 · `ASSIGNMENT_RANGE_SLICES` 5 · `ASSIGNMENT_MAX_RANGE_KM` · on-shift only · Google Maps road distance.

```mermaid
flowchart TB
  trig([Trigger]) --> slice[For each time slice 1..5]
  slice --> ring[Radius grows: slice/5 * MAX_KM]
  ring --> ping[Notify on-shift staff in ring not yet pinged]
  ping --> acc{Anyone accept?}
  acc -->|yes first writer| asg[Assigned. Stop search]
  acc -->|no| more{Slices left?}
  more -->|yes| slice
  more -->|no timeout| mgr{Pickup or drop?}
  mgr -->|pickup| cmAsg[CM Assign visible. Staff cannot reject. SSE]
  mgr -->|drop| dmAsg[DM Assign visible. Staff cannot reject. SSE]
```

| Job | Starts when |
|---|---|
| Pickup instant | Place order |
| Pickup scheduled | `pickup_time_from` |
| Drop instant (incl. Express) | All service items completed |
| Drop scheduled | All completed **and** `now >= delivery_time_from` |
| Drop scheduled, still in the future | No search. DM Assign disabled: Available from {time} |

During search: manager Assign is **visible but disabled**. After timeout: **enabled**. Late plant (completed after slot): drop search **immediately**.

---

## 5. Door count, bill, CM handshake

Pickup-boy **one button**, three labels.

```mermaid
flowchart TB
  asg[pickup_assigned] --> ui[Service list: booked services + per kg / per unit]
  ui --> exp[Expand: old customer item UI]
  exp --> unit{Pricing?}
  unit -->|per unit| qty[Count catalogue items]
  unit -->|per kg| kg[ONE weight for the service]
  qty --> pic[ONE photo: camera or gallery]
  kg --> pic
  pic --> more{All services filled?}
  more -->|no| ui
  more -->|yes| mark[Button: Mark as picked up]
  mark --> bill[(Bill: lines + DELIVERY_FEE + EXPRESS_FEE)]
  bill --> pu[picked_up]
  pu --> cust[Customer: Pickup done. View bill. Cannot pay]
  pu --> btn2[Button: Submit request to CM]
  btn2 --> scm[submitted_to_cm]
  scm --> inact[Button: Waiting for CM verification]
  inact --> cmList[CM incoming: yet-to-pick-up AND incoming]
  cmList --> verify[CM: Verified and Received only if submitted_to_cm]
  verify --> rec[received_by_collection]
  rec --> gone[Leaves pickup list on pull-to-refresh]
```

Draft: PATCH items with `items_confirmed=false` on each service expander. App kill: GET DB + `assigned_at`. No Mark for later. No edit after Mark as picked up. No boy cancel of request.

---

## 6. Plant: CM send → service man → DM

```mermaid
flowchart TB
  rec[received_by_collection] --> send[CM: Send to service queue]
  send --> histCM[CM history keeps the order]
  send --> rows[Create ServiceQueueItem per OrderItem]
  rows --> who[Auto-assign: one SM per service]
  who --> sort[ORDER BY is_express DESC, assigned_at ASC]
  sort --> smGet[SM GET queue. Poll every 2 min while visible]
  smGet --> startAny[Any pending row can start. Several in progress OK]
  startAny --> ip[queue in_progress. Order services_in_progress]
  ip --> done[queue completed]
  done --> dmSee[DM in-plant if any item done: expand all, pending inactive colour]
  done --> all{All queue rows completed?}
  all -->|no| smGet
  all -->|yes| sc[services_completed. Tracker: Ready]
  sc --> dmReady[DM ready-to-dispatch list]
```

New ordinary rows: bottom of ordinary band. New Express: after older Express, before ordinary. No SSE. No two queues.

---

## 7. Drop assignment, map, pay, delivered

```mermaid
flowchart TB
  sc[services_completed] --> when{Instant or time reached?}
  when -->|future| hold[Assign disabled: Available from time]
  when -->|yes| search[Drop expanding-radius search]
  search --> vis[Assign visible disabled until timeout]
  vis --> win{Accept?}
  win -->|yes| ofd
  win -->|timeout none| dmOn[Assign enabled]
  dmOn --> ofd[out_for_delivery immediately]
  ofd --> cards[Customer AND captain: name + phone display-only + photo]
  ofd --> map[Map ON: one Directions path + live GPS pin]
  map --> off{Pin off path?}
  off -->|yes| reroute[Refresh Directions at most every 2 min]
  ofd --> payUnlock[Customer Pay unlocked]
  payUnlock --> coupon[Optional: ONE existing Coupon]
  coupon --> upi[UPI intent to any UPI app]
  upi --> ok{UPI success?}
  ok -->|yes| paid[(payment completed everywhere)]
  ok -->|fail| retry[Retry UPI OR boy taps Paid in cash]
  retry --> paid
  paid --> delivBtn[Mark as delivered + photo ENABLED]
  delivBtn --> pic[ONE drop_proof]
  pic --> delivered([delivered])
```

Order leaves DM ready-to-dispatch at assignment; **history** shows delivered or not. No Start-delivery status gate. No cash as first option. Delivered blocked until payment completed. Do not set `payment_pending` on the order after UPI.

---

## 8. Order status machine

Customer tracker vs DB. Tracking screen **hidden until pickup_assigned**.

```mermaid
stateDiagram-v2
  [*] --> placed: Confirm order
  placed --> cancelled: Customer cancel plus reason
  placed --> pickup_assigned: Accept or CM force-assign
  pickup_assigned --> picked_up: Mark as picked up plus bill
  picked_up --> submitted_to_cm: Submit request to CM
  submitted_to_cm --> received_by_collection: CM Verified and Received
  received_by_collection --> submitted_to_services: Send to service queue
  submitted_to_services --> services_in_progress: First item In progress
  services_in_progress --> services_in_progress: More items
  services_in_progress --> services_completed: Last item Completed
  services_completed --> out_for_delivery: Captain assigned
  out_for_delivery --> delivered: Paid then photo
  cancelled --> [*]
  delivered --> [*]
```

| DB status | Customer tracker |
|---|---|
| placed | No tracking |
| pickup_assigned | Out for pickup |
| picked_up | Pickup done |
| submitted_to_cm / received_by_collection / submitted_to_services / services_in_progress | In Process |
| services_completed (searching or waiting slot) | Ready |
| out_for_delivery | Out for delivery |
| delivered | Delivered |
| cancelled | History: Cancelled |

---

## 9. Express (overlay on the same spine)

```mermaid
flowchart TB
  pick([Checkout: Express]) --> noSked[No schedule UI]
  noSked --> flags[is_express. Both legs instant]
  flags --> chip[Express chip on every role card including customer]
  flags --> pNow[Pickup search immediately]
  pNow --> same[Same door / CM / SM / DM / pay]
  same --> fee[Bill adds EXPRESS_FEE admin variable]
  same --> q[Queue: after older Express, before ordinary]
  pick -.->|cannot| normal[Cannot convert to ordinary]
  pick -.->|no| chg[No Change schedule]
```

---

## 10. Actor lists (where the order sits)

```mermaid
flowchart TB
  subgraph pickupBoy [Pickup boy]
    pb1[Assigned active] --> pb2[After CM receive: gone on pull-to-refresh]
  end
  subgraph cm [Collection manager]
    cm1[Incoming: yet to pick up + incoming] --> cm2[Received list]
    cm2 --> cm3[After send-to-queue: history]
  end
  subgraph sm [Service man]
    sm1[His service queue] --> sm2[Completed tab]
  end
  subgraph dm [Distribution manager]
    dm1[In-plant: some items done] --> dm2[Ready to dispatch: all done, no captain]
    dm2 --> dm3[History: assigned onward, delivered or not]
  end
  subgraph cust [Customer]
    c1[Active / Orders] --> c2[History includes Cancelled]
  end
```

---

## 11. Button / event cheat sheet

| When | Who | Event | Status / data |
|---|---|---|---|
| Confirm checkout | Customer | Place | `placed` |
| Cancel | Customer | Reason + confirm | `cancelled` |
| Reschedule | Customer | New pickup and/or delivery | Stop search; restart or wait |
| Accept offer | Pickup boy | First write | `pickup_assigned` |
| Timeout | CM | Force-assign | `pickup_assigned` |
| Each service expander | Pickup boy | Draft PATCH | items not confirmed |
| Mark as picked up | Pickup boy | Bill | `picked_up` |
| Submit request to CM | Pickup boy | | `submitted_to_cm` |
| Verified and Received | CM | | `received_by_collection` |
| Send to service queue | CM | Queue rows | `submitted_to_services` |
| In progress | SM | | `services_in_progress` |
| Completed last item | SM | | `services_completed` |
| Accept drop / DM assign | Captain / DM | Map on | `out_for_delivery` |
| UPI success | Customer | | `bill.payment_status=completed` |
| Paid in cash | Delivery boy | After UPI fail | same |
| Mark delivered + photo | Delivery boy | Only if paid | `delivered` |

---

## 12. What this pack deliberately omits

- Admin laundry-admin screens except config variables already named.
- Call/message: **display placeholders** (phone number shown, not `tel:`).
- CM refuse / recount (later).
- Booking fee (will not be added).
- Two service queues, Redis for SM, SSE for SM queue.

Mark the box that is wrong and we correct the spec before coding.
