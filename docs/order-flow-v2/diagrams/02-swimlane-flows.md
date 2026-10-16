# Swimlane flows

> Part of the order-flow v2 pack. Source of truth: [`../order-flow-spec.md`](../order-flow-spec.md). Mermaid renders in GitHub / Cursor preview.

## 3. Swimlane flows (who does what, in order)

### 3.1 Booking → pickup search → door count → CM handoff

```mermaid
flowchart TB
subgraph LC["Customer"]
  c1(["Open app"])
  c2["Pick services and per kg or per unit"]
  c3{"Express?"}
  c4["No schedule: both legs instant"]
  c5["Pick pickup mode and delivery mode"]
  c6["Confirm order, no itemised bill"]
  c7["Cancel or Change schedule visible"]
  c8["Tracking opens: Out for pickup"]
  c9["Tracker: Pickup done. View bill"]
end
subgraph LS["System"]
  s1[("Order placed: is_express, pickup_mode, delivery_mode")]
  s2{"Instant or Express?"}
  s3["Start pickup search now"]
  s4["Schedule job at pickup_time_from"]
  s5["Rings grow each slice over ASSIGNMENT_TIMEOUT"]
  s6{"Accepted before timeout?"}
  s7[("pickup_assigned: first writer wins")]
  s8["Assign enabled for CM"]
  s9["Validate every service filled"]
  s10[("Bill: lines plus DELIVERY_FEE plus EXPRESS_FEE")]
  s11[("picked_up")]
  s12[("submitted_to_cm")]
  s13[("received_by_collection")]
end
subgraph LP["Pickup boy"]
  p1[/"Offer by SSE: on-shift in ring"/]
  p2["Accept"]
  p3["Open order: booked services with per kg or per unit"]
  p4["Expand service: counts or one weight plus one photo"]
  p5["Draft autosave to server"]
  p6["Mark as picked up"]
  p7["Submit request to CM"]
  p8["Waiting for CM verification: inactive"]
end
subgraph LM["Collection manager"]
  m1["Sees order in Incoming"]
  m2["Force-assign: staff cannot reject"]
  m3["Verified and Received"]
end
c1 --> c2 --> c3
c3 -->|"yes"| c4 --> c6
c3 -->|"no"| c5 --> c6
c6 --> s1 --> s2
s1 --> c7
s2 -->|"yes"| s3
s2 -->|"no"| s4 --> s3
s3 --> s5 --> p1 --> p2 --> s6
s6 -->|"yes"| s7
s6 -->|"no, timeout"| s8 --> m2 --> s7
s1 --> m1
s7 --> c8
s7 --> p3 --> p4 --> p5
p5 -->|"all services done"| p6
p6 --> s9 --> s10 --> s11 --> c9
s11 --> p7 --> s12 --> p8
s12 --> m3 --> s13

```

### 3.2 Plant: CM → service men → DM lists

```mermaid
flowchart TB
subgraph LM2["Collection manager"]
  a1["Received list"]
  a2["Send to service queue"]
  a3["History keeps order"]
end
subgraph LS2["System"]
  b1["Create one queue row per OrderItem"]
  b2["Auto-assign: one service man per service"]
  b3["Sort: is_express first, then assigned_at"]
  b4[("submitted_to_services")]
  b5[("services_in_progress")]
  b6{"All queue rows completed?"}
  b7[("services_completed")]
  b8["Drop search trigger evaluated"]
end
subgraph LSM["Service man"]
  c1["Poll queue every 2 min while screen visible"]
  c2["Start any pending row"]
  c3["Mark completed"]
  c4["Completed tab"]
end
subgraph LDM["Distribution manager"]
  d1["In-plant: any item completed, not all"]
  d2["Expand: all items, pending inactive"]
  d3["Ready to dispatch: all done, no captain yet"]
end
subgraph LC2["Customer"]
  e1["Tracker: In Process"]
  e2["Tracker: Ready"]
end
a1 --> a2 --> b1 --> b2 --> b3 --> b4
a2 --> a3
b4 --> e1
b3 --> c1 --> c2 --> b5
b5 --> e1
c2 --> c3 --> c4
c3 --> d1 --> d2
c3 --> b6
b6 -->|"no"| c1
b6 -->|"yes"| b7 --> e2
b7 --> d3
b7 --> b8

```

### 3.3 Drop search → out for delivery → payment → delivered

```mermaid
flowchart TB
subgraph LS3["System"]
  f1{"Delivery mode?"}
  f2{"Scheduled time reached?"}
  f3["No search: Assign disabled with Available from time"]
  f4["Start drop search now"]
  f5["Rings over ASSIGNMENT_TIMEOUT: on-shift in ring"]
  f6{"Accepted before timeout?"}
  f7[("out_for_delivery immediately")]
  f8["Assign enabled for DM"]
  f9["Directions path once plus live GPS pin"]
  f10{"Pin off path?"}
  f11["Refresh Directions at most every 2 min"]
  f12[("Bill payment_status completed: upi or cod")]
  f13{"Payment completed?"}
  f14[("delivered")]
end
subgraph LD3["Distribution manager"]
  g1["Ready to dispatch list"]
  g2["Assign visible and disabled"]
  g3["Force-assign: captain cannot reject"]
  g4["History: delivered or not"]
end
subgraph LK["Delivery captain"]
  h1[/"Offer by SSE"/]
  h2["Accept"]
  h3["Out for delivery: map, path, live pin"]
  h4["Paid in cash if UPI failed"]
  h5["One drop photo"]
  h6["Mark as delivered"]
end
subgraph LC3["Customer"]
  i1["Tracker: Ready"]
  i2["Tracker: Out for delivery"]
  i3["Name plus phone display only plus photo"]
  i4["Optional one coupon"]
  i5["Pay with UPI via PSP intent"]
  i6{"UPI success?"}
  i7["Retry UPI"]
  i8["Tracker: Delivered"]
end
f1 -->|"instant or Express"| f4
f1 -->|"scheduled"| f2
f2 -->|"no"| f3
f2 -->|"yes or already late"| f4
f3 --> g2
f4 --> g2
g1 --> g2
f4 --> f5 --> h1 --> h2 --> f6
f6 -->|"yes"| f7
f6 -->|"no, timeout"| f8 --> g3 --> f7
f7 --> i2 --> i3
f7 --> h3 --> f9 --> f10
f10 -->|"yes"| f11 --> f10
f7 --> g4
i1 --> f1
i2 --> i4 --> i5 --> i6
i6 -->|"yes"| f12
i6 -->|"no"| i7 --> i5
i6 -.->|"still failing"| h4 --> f12
f12 --> f13
f13 -->|"yes"| h5 --> h6 --> f14 --> i8
f13 -->|"no"| h4

```

### 3.4 Cancel and reschedule (only while `placed`)

```mermaid
flowchart TB
subgraph CU["Customer"]
  u1["Orders list: placed"]
  u2{"Action"}
  u3[/"Free-text reason required"/]
  u4["Confirm cancel"]
  u5["Edit pickup and or delivery times"]
  u6{"Delivery at least pickup plus BUFFER_DAYS?"}
  u7["Cancel and Change schedule hidden"]
  u8["History shows Cancelled"]
end
subgraph SY["System"]
  v1[("cancelled plus cancel_reason")]
  v2["Stop pickup job and pending offers"]
  v3["Stop current search"]
  v4{"New pickup instant or time reached?"}
  v5["Start search again"]
  v6["Wait for new pickup_time_from"]
  v7{"Boy assigned?"}
end
u1 --> v7
v7 -->|"no"| u2
v7 -->|"yes pickup_assigned"| u7
u2 -->|"Cancel"| u3 --> u4 --> v2 --> v1 --> u8
u2 -->|"Reschedule"| u5 --> u6
u6 -->|"no"| u5
u6 -->|"yes"| v3 --> v4
v4 -->|"yes"| v5
v4 -->|"no"| v6

```
