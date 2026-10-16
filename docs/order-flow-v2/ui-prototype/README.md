# WashBee UI prototype (for the designer)

Click-through of **locked** flows from `order-flow-spec.md`. Not production Flutter.

## Open

Open `index.html` in a browser (double-click, or Live Server).

Left: role + screen list.  
Centre: phone frame.  
Right: spec notes for the current screen.

Click in the phone to walk the flow. The list jumps you to any screen.

**Gallery:** click "Show gallery of all screens" (top-left), or open `index.html#gallery`. Click any thumbnail to open it as a full phone.

## Edit a screen

Each screen is an `<article class="scr" id="...">` in `index.html`.

- Change copy, colours, spacing in that article (and `proto.css`).
- Do **not** invent extra steps that contradict the notes panel.
- Express = coral chip `#FF4D5E`. Primary indigo `#2C3CA5`. Currency **₹**.

## Roles covered

| App | Ids prefix |
|---|---|
| Customer | `c-` |
| Pickup boy | `p-` |
| Collection manager | `cm-` |
| Service man | `sm-` |
| Distribution manager | `dm-` |
| Delivery captain | `d-` |
| Admin | `a-` |

## Replace later

How-we-work images are colour blocks. Swap in designer assets when ready.
