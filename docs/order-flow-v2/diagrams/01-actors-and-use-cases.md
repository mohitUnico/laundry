# Actors, apps and use cases

> Part of the order-flow v2 pack. Source of truth: [`../order-flow-spec.md`](../order-flow-spec.md). Mermaid renders in GitHub / Cursor preview.

## 1. Actors and apps

```mermaid
flowchart LR
subgraph apps["Applications"]
  ca["Customer app Flutter"]
  sa["Staff app Flutter: pickup and delivery"]
  ma["Management app Flutter: CM SM DM"]
  ad["Mart admin React"]
end
subgraph actors["Human actors"]
  cu(["Customer"])
  pb(["Pickup boy"])
  cmA(["Collection manager"])
  smA(["Service man one per service"])
  dmA(["Distribution manager"])
  cap(["Delivery captain"])
  adm(["Admin"])
end
subgraph sys["Backend and services"]
  api["Express API plus Prisma"]
  pg[("PostgreSQL")]
  rq["Redis plus BullMQ assignment queue"]
  sse["SSE hub in memory staff offers"]
  gm["Google Maps distance and Directions"]
  fcm["FCM and WhatsApp status push"]
  psp["PSP UPI intent merchant account"]
end
cu --> ca
pb --> sa
cap --> sa
cmA --> ma
smA --> ma
dmA --> ma
adm --> ad
ca --> api
sa --> api
ma --> api
ad --> api
api --> pg
api --> rq
api --> sse
api --> gm
api --> fcm
ca -.->|"UPI at delivery"| psp
psp -.->|"payment result"| api

```

Same Staff app / management app shell hosts several roles in this codebase; role is decided at login. Pickup boy and captain are the same `DeliveryStaff` account type (pickup leg vs drop leg).

## 2. Use-case diagram (every actor, every capability)

```mermaid
flowchart LR
subgraph UCc["Customer"]
  c1(["Browse Pricing tab: kg price, cloth prices, Includes"])
  c2(["Read How we work: 6 steps"])
  c3(["Book services: per kg or per unit, no SKUs"])
  c4(["Choose Express: no schedule"])
  c5(["Schedule pickup and delivery independently"])
  c6(["Cancel with reason: before assigned"])
  c7(["Reschedule: before assigned"])
  c8(["Track: map, name, phone, photo"])
  c9(["View bill only"])
  c10(["Apply one coupon and pay UPI"])
  c11(["History incl Cancelled"])
  c12(["Account from Home avatar"])
end
subgraph UCp["Pickup boy"]
  p1(["Accept offer or be force-assigned"])
  p2(["Count per service: units or one weight"])
  p3(["One photo per service: camera or gallery"])
  p4(["Draft autosave"])
  p5(["Mark as picked up"])
  p6(["Submit request to CM"])
  p7(["Wait for CM verification"])
end
subgraph UCcm["Collection manager"]
  m1(["Incoming list: yet to pick up and incoming"])
  m2(["Force-assign pickup after timeout"])
  m3(["Verified and Received"])
  m4(["Send to service queue"])
  m5(["History"])
end
subgraph UCsm["Service man"]
  s1(["See my queue: Express band then assigned_at"])
  s2(["Start any row, several in progress"])
  s3(["Complete item"])
  s4(["Poll every 2 min"])
end
subgraph UCdm["Distribution manager"]
  d1(["In-plant list: expand whole order"])
  d2(["Ready to dispatch list"])
  d3(["Assign visible disabled until timeout"])
  d4(["Force-assign drop after timeout"])
  d5(["History: delivered or not"])
end
subgraph UCd["Delivery captain"]
  k1(["Accept drop offer or be force-assigned"])
  k2(["Out for delivery at once: map and path"])
  k3(["Paid in cash after UPI fails"])
  k4(["One drop photo then Mark as delivered"])
end
subgraph UCa["Admin"]
  a1(["Edit DELIVERY_FEE and EXPRESS_FEE"])
  a2(["Edit assignment timeout, slices, max range, buffer days"])
  a3(["Manage coupons existing table"])
end
c4 -.->|"extends"| c3
c10 -.->|"includes"| c9
p5 -.->|"includes"| p3
p6 -.->|"requires"| p5
m3 -.->|"requires"| p6
m4 -.->|"requires"| m3
d4 -.->|"after timeout"| d3
k4 -.->|"requires paid"| k3

```
