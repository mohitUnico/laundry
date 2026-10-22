# Admin catalogue images

The create and update routes below are implemented. Each one reads multipart field `file` with Multer, uploads that file to Cloudinary, and stores the HTTPS URL in `icon_url`. The client does not send a URL.

The customer app does not upload these pictures. It reads `icon_url` from `GET /api/v1/catalog` (`../customer/catalog.openapi.json`) and caches the file. Admin create and update are the only writers.

## Create

The admin form asks for the image in the same submit as the name and price. One `multipart/form-data` request. The field is `file`. JPEG, PNG, or WEBP.

The server uploads that file to Cloudinary and stores the HTTPS `secure_url` in `icon_url`. The client does not send a URL. `icon_url` is not a request field.

| Create | Contract | Stored column |
|---|---|---|
| Category | `POST /api/v1/admin/catalog/categories` | `service_categories.icon_url` |
| Service | `POST /api/v1/admin/catalog/services` | `services.icon_url` |
| Cloth item | `POST /api/v1/admin/catalog/clothes-items` | `clothes_items.icon_url` |

Cloudinary folder, under `CLOUDINARY_UPLOAD_FOLDER` (default `laundry-app`):

- `catalog/categories`
- `catalog/services`
- `catalog/clothes`

A create with no file is `400`. The saved row always has an `icon_url`.

Replacing the picture is `PATCH` on the same resource, again with `file`. A JSON `PATCH` with no file changes the other fields and leaves `icon_url` as it is. Neither form accepts an `icon_url` string.

## What is live today

`POST /api/v1/admin/catalog/...` is implemented as written here. The older writes `POST /api/v1/clothes/service-categories`, `POST /api/v1/clothes/services`, and `POST /api/v1/clothes/clothes-items` do the same upload. Their other fields stay camelCase (`categoryName`, `serviceName`, `perUnitPrice`). A client `iconUrl` is rejected on all of these. Auth is `admin` or `manager`.

Create requires `file`. Update accepts `file` only when the picture is being replaced. JPEG, PNG, or WEBP, up to 5 MB. Cloudinary folder is `catalog/categories`, `catalog/services`, or `catalog/clothes` under `CLOUDINARY_UPLOAD_FOLDER`.

`base_price` is still a required column. v2 pricing ignores it. This contract stores `0.00` when the form omits it.

## Pictures already in the app

These files are the current catalogue art. They are not on Cloudinary yet, and the database `icon_url` values are still placeholders. Each `clothes_items` row stores its own URL, even when several services share one picture file.

| File | Row |
|---|---|
| `customer-app/assets/images/home/regular_wash.png` | Category Regular Wash |
| `customer-app/assets/images/home/pro_clean.png` | Category Pro Clean |
| `customer-app/assets/images/home/home_linen.png` | Category Home Linens |
| `customer-app/assets/images/home/luxury_care.png` | Category Luxury Care |
| `customer-app/assets/images/pro_clean/dry_cleaning.png` | Service Dry Cleaning |
| `customer-app/assets/images/pro_clean/stain_treatment.png` | Service Stain Removal |
| `customer-app/assets/images/pro_clean/shoe_cleaning.png` | Service Shoe Cleaning |
| `customer-app/assets/images/pro_clean/winter_wear.png` | Service Winter Wear |
| `customer-app/assets/images/pro_clean/delicate_fabrics.png` | Service Delicate Wash |
| `customer-app/assets/images/luxury_care/steam_press.png` | Service Steam Press |
| `customer-app/assets/images/luxury_care/designer_wear.png` | Service Designer Wear |
| `customer-app/assets/images/regular_wash/top_wear.png` | Cloth Top Wear |
| `customer-app/assets/images/regular_wash/bottom_wear.png` | Cloth Bottom Wear |
| `customer-app/assets/images/regular_wash/kurta.png` | Cloth Kurti/Kurta |
| `customer-app/assets/images/regular_wash/saree.png` | Cloth Saree |
| `customer-app/assets/images/stain_treatment/heavy_stain.png` | Cloth Heavy Stained |
| `customer-app/assets/images/stain_treatment/light_stain.png` | Cloth Light Stained |
| `customer-app/assets/images/shoe_cleaning/sneakers.png` | Cloth Sneakers |
| `customer-app/assets/images/shoe_cleaning/formal_shoes.png` | Cloth Formal shoes |
| `customer-app/assets/images/shoe_cleaning/sports_shoes.png` | Cloth Sports shoes |
| `customer-app/assets/images/shoe_cleaning/loafers.png` | Cloth Loafers |
| `customer-app/assets/images/winter_wear/woolen_wear.png` | Cloth Woolens |
| `customer-app/assets/images/winter_wear/blazers.png` | Cloth Blazers |
| `customer-app/assets/images/winter_wear/jackets.png` | Cloth Jackets |
| `customer-app/assets/images/winter_wear/cashmere.png` | Cloth Cashmere Sweater |
| `customer-app/assets/images/winter_wear/accessories.png` | Cloth Accessories |
| `customer-app/assets/images/home_linen/carpets.png` | Cloth Carpet |
| `customer-app/assets/images/home_linen/curtains.png` | Cloth Curtains |
| `customer-app/assets/images/home_linen/blankets.png` | Cloth Blanket |
| `customer-app/assets/images/home_linen/tablecloths.png` | Cloth Table Clothes |
| `customer-app/assets/images/home_linen/bedsheets.png` | Cloth Bedsheets |

No file yet for the services Wash & Fold, Wash & Iron, Hand Wash, Iron only, and Home Linens, or for the cloth items Lingerie and Napkins.

Nav icons, splash screens, the login illustration, and the “How your laundry gets done” drawings stay in the app. They are not rows in this contract.

## File

- `catalog.openapi.json`
