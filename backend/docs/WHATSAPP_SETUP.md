# WhatsApp Notifications Setup

Order updates (and other notifications that use FCM) can also be sent to customers via **WhatsApp** using the Twilio WhatsApp API. Customers receive the same order status updates on their WhatsApp number if they have a **phone** saved in their profile.

## Flow

- When order status changes, the backend calls `notifyOrderStatusChange` (same as for FCM).
- **FCM**: If the customer has an `fcm_token`, a push notification is sent.
- **WhatsApp**: If the customer has a `phone` and WhatsApp is enabled, a WhatsApp message is sent (fire-and-forget alongside FCM).

No API or app changes are required for existing order flows; WhatsApp is additive.

## Prerequisites

1. **Twilio account** with WhatsApp enabled (Sandbox or WhatsApp Business API).
2. **WhatsApp sender number** (Sandbox: use the number Twilio provides, e.g. `whatsapp:+14155238886`).
3. **Pre-approved template** (recommended for production): Business-initiated WhatsApp messages typically require a pre-approved message template. Create one in Twilio Console (Content Template Builder) and use its Content SID.

## Environment Variables

Add to your `.env`:

| Variable | Required | Description |
|----------|----------|-------------|
| `WHATSAPP_ENABLED` | Yes (to enable) | Set to `true` to send WhatsApp notifications. |
| `TWILIO_ACCOUNT_SID` | Yes | From [Twilio Console](https://console.twilio.com). |
| `TWILIO_AUTH_TOKEN` | Yes | From Twilio Console. |
| `TWILIO_WHATSAPP_FROM` | Yes | Sender in WhatsApp format, e.g. `whatsapp:+14155238886`. |
| `WHATSAPP_DEFAULT_COUNTRY_CODE` | No | Default country code for normalizing phone numbers (e.g. `91` for India). |
| `WHATSAPP_ORDER_UPDATE_CONTENT_SID` | No | Twilio Content Template SID for order updates. If not set, a plain text body is used (sandbox / within 24h window). |

Example:

```env
WHATSAPP_ENABLED=true
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=your_auth_token
TWILIO_WHATSAPP_FROM=whatsapp:+14155238886
WHATSAPP_DEFAULT_COUNTRY_CODE=91
WHATSAPP_ORDER_UPDATE_CONTENT_SID=HXxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

## Phone Number Format

- Customer **phone** is stored in the `customers` table (optional).
- The service normalizes numbers to **E.164** (e.g. `919876543210` for India) using `WHATSAPP_DEFAULT_COUNTRY_CODE` when the number does not already include a country code.
- Ensure customers have a valid phone number in their profile (e.g. collected during registration or in profile settings).

## Twilio Content Template (recommended for production)

1. In Twilio Console go to **Messaging** → **Content Template Builder** (or **Try it out** → **Send a WhatsApp message** for Sandbox).
2. Create a template for order updates, e.g.:
   - **Name**: `order_status_update`
   - **Body**: `Your order {{1}} status is now: {{2}}.`
3. After approval, copy the **Content SID** (starts with `HX...`) and set `WHATSAPP_ORDER_UPDATE_CONTENT_SID` in `.env`.
4. The backend maps:
   - `{{1}}` → order ID  
   - `{{2}}` → human-readable status (e.g. "Out for Delivery")

If your template uses different variable indices, update `whatsapp.service.js` → `sendOrderStatusUpdate` → `contentVariables` accordingly.

## Testing

1. Set `WHATSAPP_ENABLED=true` and Twilio credentials.
2. Use Twilio Sandbox: join the sandbox by sending the join code from your WhatsApp to the sandbox number.
3. Set a customer's `phone` (e.g. your number with country code or without; normalization will add default country code).
4. Trigger an order status change (e.g. from collection manager or delivery app); the customer should receive both FCM (if token set) and WhatsApp (if phone set).

## Extending to Other Notifications

To send more notification types over WhatsApp (e.g. order placed, payment reminder):

- Reuse `whatsapp.service.sendWhatsAppMessage()` or `sendOrderStatusUpdate()` from the same places you currently send FCM or other notifications.
- Add more Content Template SIDs and helper functions in `whatsapp.service.js` (e.g. `sendOrderPlaced`, `sendPaymentReminder`) following the same pattern.

## Troubleshooting

- **No message received**: Check Twilio logs (Console → Monitor → Logs). Ensure the recipient has opted in to the Sandbox or your Business number.
- **Template rejected**: Use only approved templates for business-initiated messages; variable indices must match the template.
- **Invalid phone**: Ensure `phone` is stored and normalizes to a valid E.164 number (see `normalizePhoneToE164` in `whatsapp.service.js`).
