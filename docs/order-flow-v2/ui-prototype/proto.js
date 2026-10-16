const NOTES = {
  "c-home": "Home. Nav: Home · Orders · Cart · Pricing. Avatar → Account. Footer: How we work + brand strip. Booking from category tiles (not Pricing).",
  "c-how": "How we work: 6 steps, English, placeholder images until designer art.",
  "c-pricing": "Pricing tab only. Browse-only. Categories → services → ₹/kg AND cloth prices + Includes. No Coming Soon. No add to cart.",
  "c-account": "Account from Home avatar only. Not a nav tab.",
  "c-services": "Book services + per kg / per unit. No cloth SKUs at booking.",
  "c-cart": "Cart shows services + pricing type only.",
  "c-checkout": "Ordinary: pickup_mode × delivery_mode. Delivery ≥ pickup + PICKUP_DELIVERY_BUFFER_DAYS (2).",
  "c-checkout-ex": "Express: no schedule, both legs instant, sticky Express, EXPRESS_FEE later on bill.",
  "c-orders-placed": "Cancel (free-text reason) and reschedule only while placed (boy not assigned).",
  "c-orders-bill": "After Mark as picked up: View bill. Cannot pay. Pay Bill stays dead.",
  "c-track-pu": "Tracking only after pickup_assigned. Out for pickup. Name + photo. Call/message placeholders.",
  "c-track-done": "Mark as picked up → Pickup done. View bill.",
  "c-track-ip": "In Process through plant. Ready when all services completed.",
  "c-track-ofd": "Out for delivery the moment captain assigned. Map + path + name/phone/photo. Pay unlocked.",
  "c-pay": "One coupon from coupons table. UPI intent. Cash is boy-side fallback only.",
  "c-done": "Delivered after payment + drop photo.",
  "p-jobs": "Pickup jobs. Express chip on cards.",
  "p-accept": "Accept overlay. First accept wins. Force-assign cannot reject.",
  "p-door": "Booked services with per kg / per unit. Expand old customer item UI. Draft saved.",
  "p-expand": "Per unit counts or one weight. One photo camera/gallery.",
  "p-wait": "Button: Mark as picked up → Submit request to CM → Waiting (inactive).",
  "cm-in": "Incoming: yet to pick up AND incoming picked up. Verify only after request.",
  "cm-rec": "Received list. Send to service queue. No generate invoice (bill already exists).",
  "cm-hist": "History after send-to-queue.",
  "sm-q": "One queue. Express band then ordinary. Sort assigned_at. Poll 2 min. Any row startable.",
  "sm-work": "In progress / Completed. No Mark for later. Show assigned time.",
  "dm-plant": "In-plant: any item completed, not all. Expand whole order. Pending inactive colour.",
  "dm-wait": "Ready to dispatch. Assign visible disabled. Search running OR Available from {time}.",
  "dm-asg": "After timeout Assign enabled. Cannot reject.",
  "dm-hist": "After captain assigned. Shows delivered or not.",
  "d-ofd": "Captain: immediately Out for delivery. Same map rules.",
  "d-cash": "Paid in cash only after UPI fail. Then payment completed everywhere.",
  "d-fin": "Photo then Mark delivered. Disabled until paid.",
  "c-login": "Mobile + OTP, then location permission. Existing auth.",
  "c-cancel": "Cancel only while placed (no partner assigned). Free-text reason required. Moves order to History as Cancelled.",
  "c-resched": "Reschedule only while placed. Both legs editable. Delivery >= pickup + PICKUP_DELIVERY_BUFFER_DAYS. No reason. Search restarts or waits for new pickup time.",
  "c-cancelled": "History shows Cancelled with the customer's reason. No fee.",
  "cm-force": "After search timeout CM can assign an on-shift partner. Partner cannot reject.",
  "sm-done": "Completed tab for the service man with assigned and done times.",
  "d-jobs": "Captain job list. Drop offers arrive by SSE. Express chip.",
  "d-accept": "Drop offer overlay. First accept wins; accepting means Out for delivery immediately.",
  "a-config": "Admin variables: delivery fee, Express fee, assignment timeout, slices, max range, buffer days. Coupons use the existing table."
};

function go(id) {
  document.querySelectorAll(".scr").forEach((s) => s.classList.toggle("on", s.id === id));
  document.querySelectorAll(".rail a").forEach((a) => a.classList.toggle("on", a.dataset.go === id));
  const n = document.getElementById("note");
  n.innerHTML = `<h2>Spec</h2><p>${NOTES[id] || ""}</p><p class="tiny">id: <code>${id}</code></p>`;
  const scr = document.getElementById(id);
  const title = scr?.dataset.title || id;
  document.getElementById("scr-label").textContent = title;
}

document.addEventListener("click", (e) => {
  const t = e.target.closest("[data-go]");
  if (!t) return;
  e.preventDefault();
  go(t.dataset.go);
});

go("c-home");


// ---- Gallery mode: every screen at once (click one to open it) ----
const GROUPS = [
  ["Customer", /^c-/], ["Pickup boy", /^p-/], ["Collection manager", /^cm-/],
  ["Service man", /^sm-/], ["Distribution manager", /^dm-/], ["Delivery captain", /^d-/], ["Admin", /^a-/]
];
function buildGallery() {
  const g = document.getElementById("gallery");
  g.innerHTML = "";
  const all = [...document.querySelectorAll(".stage .phone .scr")];
  GROUPS.forEach(([name, re]) => {
    const list = all.filter((s) => re.test(s.id));
    if (!list.length) return;
    const h = document.createElement("h2");
    h.textContent = `${name} (${list.length})`;
    const row = document.createElement("div");
    row.className = "gal-row";
    list.forEach((s) => {
      const cell = document.createElement("div");
      cell.className = "gal-cell";
      cell.innerHTML = `<div class="cap">${s.dataset.title}</div><div class="gal-scale"><div class="gal-phone"><div class="status"><span>9:41</span><span>WashBee</span></div></div></div>`;
      const clone = s.cloneNode(true);
      clone.removeAttribute("id");
      clone.querySelectorAll("[data-go]").forEach((e) => e.removeAttribute("data-go"));
      clone.classList.add("on");
      cell.querySelector(".gal-phone").appendChild(clone);
      cell.querySelector(".gal-scale").addEventListener("click", () => { toggleGallery(false); go(s.id); });
      row.appendChild(cell);
    });
    g.append(h, row);
  });
}
function toggleGallery(on) {
  const g = document.getElementById("gallery");
  if (on) buildGallery();
  g.hidden = !on;
  document.body.classList.toggle("gal-on", on);
  document.getElementById("gal-btn").textContent = on ? "Back to single phone" : "Show gallery of all screens";
}
document.getElementById("gal-btn").addEventListener("click", () => toggleGallery(document.getElementById("gallery").hidden));

if (location.hash === '#gallery') toggleGallery(true);
