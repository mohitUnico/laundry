/**
 * Catalogue written by `node prisma/seed.js` when service_categories is empty.
 * Image links are the Cloudinary files uploaded from customer-app/assets/images.
 * Rows with no picture yet keep icon_url null.
 */

const CDN = 'https://res.cloudinary.com/dmpqe6ex3/image/upload'

const categoryImage = {
    'Regular Wash': `${CDN}/v1792575575/laundry-app/catalog/categories/regular_wash.png`,
    'Pro Clean': `${CDN}/v1792575576/laundry-app/catalog/categories/pro_clean.png`,
    'Home Linens': `${CDN}/v1792575577/laundry-app/catalog/categories/home_linen.png`,
    'Luxury Care': `${CDN}/v1792575578/laundry-app/catalog/categories/luxury_care.png`,
}

const serviceImage = {
    'Dry Cleaning': `${CDN}/v1792575579/laundry-app/catalog/services/dry_cleaning.png`,
    'Stain Removal': `${CDN}/v1792575580/laundry-app/catalog/services/stain_treatment.png`,
    'Shoe Cleaning': `${CDN}/v1792575581/laundry-app/catalog/services/shoe_cleaning.png`,
    'Winter Wear': `${CDN}/v1792575582/laundry-app/catalog/services/winter_wear.png`,
    'Delicate Wash': `${CDN}/v1792575583/laundry-app/catalog/services/delicate_fabrics.png`,
    'Steam Press': `${CDN}/v1792575584/laundry-app/catalog/services/steam_press.png`,
    'Designer Wear': `${CDN}/v1792575585/laundry-app/catalog/services/designer_wear.png`,
}

const clothImage = {
    'Heavy Stained': `${CDN}/v1792575590/laundry-app/catalog/clothes/heavy_stain.png`,
    'Light Stained': `${CDN}/v1792575591/laundry-app/catalog/clothes/light_stain.png`,
    Sneakers: `${CDN}/v1792575592/laundry-app/catalog/clothes/sneakers.png`,
    'Formal shoes': `${CDN}/v1792575593/laundry-app/catalog/clothes/formal_shoes.png`,
    'Sports shoes': `${CDN}/v1792575594/laundry-app/catalog/clothes/sports_shoes.png`,
    Loafers: `${CDN}/v1792575594/laundry-app/catalog/clothes/loafers.png`,
    Woolens: `${CDN}/v1792575595/laundry-app/catalog/clothes/woolen_wear.png`,
    Blazers: `${CDN}/v1792575597/laundry-app/catalog/clothes/blazers.png`,
    Jackets: `${CDN}/v1792575598/laundry-app/catalog/clothes/jackets.png`,
    'Cashmere Sweater': `${CDN}/v1792575598/laundry-app/catalog/clothes/cashmere.png`,
    Accessories: `${CDN}/v1792575599/laundry-app/catalog/clothes/accessories.png`,
    Carpet: `${CDN}/v1792575600/laundry-app/catalog/clothes/carpets.png`,
    Curtains: `${CDN}/v1792575601/laundry-app/catalog/clothes/curtains.png`,
    Blanket: `${CDN}/v1792575602/laundry-app/catalog/clothes/blankets.png`,
    'Table Clothes': `${CDN}/v1792575603/laundry-app/catalog/clothes/tablecloths.png`,
    Bedsheets: `${CDN}/v1792575604/laundry-app/catalog/clothes/bedsheets.png`,
}

/**
 * Same source art as Dry Cleaning, uploaded again per service.
 * A cloth row never shares another service's URL.
 */
const standardClothUrl = {
    'Wash & Fold': {
        'Top Wear': `${CDN}/v1792579101/laundry-app/catalog/clothes/wash-fold/top-wear.png`,
        'Bottom Wear': `${CDN}/v1792579102/laundry-app/catalog/clothes/wash-fold/bottom-wear.png`,
        'Kurti/Kurta': `${CDN}/v1792579103/laundry-app/catalog/clothes/wash-fold/kurti-kurta.png`,
        Saree: `${CDN}/v1792579104/laundry-app/catalog/clothes/wash-fold/saree.png`,
    },
    'Wash & Iron': {
        'Top Wear': `${CDN}/v1792579105/laundry-app/catalog/clothes/wash-iron/top-wear.png`,
        'Bottom Wear': `${CDN}/v1792579106/laundry-app/catalog/clothes/wash-iron/bottom-wear.png`,
        'Kurti/Kurta': `${CDN}/v1792579107/laundry-app/catalog/clothes/wash-iron/kurti-kurta.png`,
        Saree: `${CDN}/v1792579108/laundry-app/catalog/clothes/wash-iron/saree.png`,
    },
    'Hand Wash': {
        'Top Wear': `${CDN}/v1792579087/laundry-app/catalog/clothes/hand-wash/top-wear.png`,
        'Bottom Wear': `${CDN}/v1792579088/laundry-app/catalog/clothes/hand-wash/bottom-wear.png`,
        'Kurti/Kurta': `${CDN}/v1792579089/laundry-app/catalog/clothes/hand-wash/kurti-kurta.png`,
        Saree: `${CDN}/v1792579089/laundry-app/catalog/clothes/hand-wash/saree.png`,
    },
    'Iron only': {
        'Top Wear': `${CDN}/v1792579093/laundry-app/catalog/clothes/iron-only/top-wear.png`,
        'Bottom Wear': `${CDN}/v1792579094/laundry-app/catalog/clothes/iron-only/bottom-wear.png`,
        'Kurti/Kurta': `${CDN}/v1792579095/laundry-app/catalog/clothes/iron-only/kurti-kurta.png`,
        Saree: `${CDN}/v1792579096/laundry-app/catalog/clothes/iron-only/saree.png`,
    },
    'Dry Cleaning': {
        'Top Wear': `${CDN}/v1792579083/laundry-app/catalog/clothes/dry-cleaning/top-wear.png`,
        'Bottom Wear': `${CDN}/v1792579084/laundry-app/catalog/clothes/dry-cleaning/bottom-wear.png`,
        'Kurti/Kurta': `${CDN}/v1792579085/laundry-app/catalog/clothes/dry-cleaning/kurti-kurta.png`,
        Saree: `${CDN}/v1792579086/laundry-app/catalog/clothes/dry-cleaning/saree.png`,
    },
    'Delicate Wash': {
        'Top Wear': `${CDN}/v1792579075/laundry-app/catalog/clothes/delicate-wash/top-wear.png`,
        'Bottom Wear': `${CDN}/v1792579076/laundry-app/catalog/clothes/delicate-wash/bottom-wear.png`,
        'Kurti/Kurta': `${CDN}/v1792579077/laundry-app/catalog/clothes/delicate-wash/kurti-kurta.png`,
        Saree: `${CDN}/v1792579078/laundry-app/catalog/clothes/delicate-wash/saree.png`,
    },
    'Steam Press': {
        'Top Wear': `${CDN}/v1792579097/laundry-app/catalog/clothes/steam-press/top-wear.png`,
        'Bottom Wear': `${CDN}/v1792579098/laundry-app/catalog/clothes/steam-press/bottom-wear.png`,
        'Kurti/Kurta': `${CDN}/v1792579099/laundry-app/catalog/clothes/steam-press/kurti-kurta.png`,
        Saree: `${CDN}/v1792579100/laundry-app/catalog/clothes/steam-press/saree.png`,
    },
    'Designer Wear': {
        'Top Wear': `${CDN}/v1792579079/laundry-app/catalog/clothes/designer-wear/top-wear.png`,
        'Bottom Wear': `${CDN}/v1792579080/laundry-app/catalog/clothes/designer-wear/bottom-wear.png`,
        'Kurti/Kurta': `${CDN}/v1792579081/laundry-app/catalog/clothes/designer-wear/kurti-kurta.png`,
        Saree: `${CDN}/v1792579082/laundry-app/catalog/clothes/designer-wear/saree.png`,
    },
}

function cloth(itemName, perUnitPrice, displayOrder, iconUrl) {
    return {
        item_name: itemName,
        per_unit_price: perUnitPrice,
        icon_url: iconUrl === undefined ? (clothImage[itemName] || null) : iconUrl,
        display_order: displayOrder,
    }
}

function standardClothes(serviceName) {
    const urls = standardClothUrl[serviceName]
    const items = [
        cloth('Top Wear', 45, 1, urls['Top Wear']),
        cloth('Bottom Wear', 50, 2, urls['Bottom Wear']),
        cloth('Kurti/Kurta', 55, 3, urls['Kurti/Kurta']),
        cloth('Saree', 65, 4, urls.Saree),
    ]
    if (serviceName !== 'Steam Press' && serviceName !== 'Designer Wear') {
        items.push(cloth('Lingerie', 35, 5, null))
    }
    return items
}

const STAIN_CLOTHES = [
    cloth('Heavy Stained', 120, 1),
    cloth('Light Stained', 80, 2),
]

const SHOE_CLOTHES = [
    cloth('Sneakers', 150, 1),
    cloth('Formal shoes', 180, 2),
    cloth('Sports shoes', 160, 3),
    cloth('Loafers', 170, 4),
]

const WINTER_CLOTHES = [
    cloth('Woolens', 90, 1),
    cloth('Blazers', 200, 2),
    cloth('Jackets', 180, 3),
    cloth('Cashmere Sweater', 250, 4),
    cloth('Accessories', 75, 5),
]

const HOME_LINEN_CLOTHES = [
    cloth('Carpet', 300, 1),
    cloth('Curtains', 120, 2),
    cloth('Blanket', 150, 3),
    cloth('Table Clothes', 80, 4),
    cloth('Napkins', 40, 5),
    cloth('Bedsheets', 100, 6),
]

function service(serviceName, fields, clothes) {
    return {
        service_name: serviceName,
        icon_url: serviceImage[serviceName] || null,
        clothes,
        ...fields,
    }
}

const CATALOG = [
    {
        category_name: 'Regular Wash',
        description: 'Fast & Fresh Laundry',
        icon_url: categoryImage['Regular Wash'],
        display_order: 1,
        services: [
            service('Wash & Fold', {
                description: 'Professional washing and folding',
                base_price: 0,
                per_kg_price: 80,
                estimated_hours: 24,
                display_order: 1,
            }, standardClothes('Wash & Fold')),
            service('Wash & Iron', {
                description: 'Professional washing and ironing',
                base_price: 0,
                per_kg_price: 95,
                estimated_hours: 48,
                display_order: 2,
            }, standardClothes('Wash & Iron')),
            service('Hand Wash', {
                description: 'Gentle hand wash for delicate everyday wear',
                base_price: 0,
                per_kg_price: 110,
                estimated_hours: 48,
                display_order: 3,
            }, standardClothes('Hand Wash')),
            service('Iron only', {
                description: 'Press and iron only — no washing',
                base_price: 0,
                per_kg_price: 60,
                estimated_hours: 24,
                display_order: 4,
            }, standardClothes('Iron only')),
        ],
    },
    {
        category_name: 'Pro Clean',
        description: 'Expert dry cleaning and specialty care',
        icon_url: categoryImage['Pro Clean'],
        display_order: 2,
        services: [
            service('Dry Cleaning', {
                description: 'Deep cleaning for garments that need dry clean',
                base_price: 0,
                per_kg_price: null,
                estimated_hours: 72,
                display_order: 1,
            }, standardClothes('Dry Cleaning')),
            service('Stain Removal', {
                description: 'Pre-treatment and removal of stains',
                base_price: 0,
                per_kg_price: null,
                estimated_hours: 48,
                display_order: 2,
            }, STAIN_CLOTHES),
            service('Shoe Cleaning', {
                description: 'Fresh and spotless shoe care',
                base_price: 0,
                per_kg_price: null,
                estimated_hours: 48,
                display_order: 3,
            }, SHOE_CLOTHES),
            service('Winter Wear', {
                description: 'Specialized cleaning for woolens and winter garments',
                base_price: 0,
                per_kg_price: null,
                estimated_hours: 72,
                display_order: 4,
            }, WINTER_CLOTHES),
            service('Delicate Wash', {
                description: 'Gentle wash for wool, silk, and delicate fabrics',
                base_price: 0,
                per_kg_price: null,
                estimated_hours: 48,
                display_order: 5,
            }, standardClothes('Delicate Wash')),
        ],
    },
    {
        category_name: 'Home Linens',
        description: 'Household linen and upholstery items',
        icon_url: categoryImage['Home Linens'],
        display_order: 3,
        services: [
            service('Home Linens', {
                description: 'Carpets, curtains, bedding, and table linen',
                base_price: 0,
                per_kg_price: null,
                estimated_hours: 72,
                display_order: 1,
            }, HOME_LINEN_CLOTHES),
        ],
    },
    {
        category_name: 'Luxury Care',
        description: 'Delicate fabric treatment and designer wear',
        icon_url: categoryImage['Luxury Care'],
        display_order: 4,
        services: [
            service('Steam Press', {
                description: 'Steam press for non iron-friendly clothes',
                base_price: 0,
                per_kg_price: null,
                estimated_hours: 24,
                display_order: 1,
            }, standardClothes('Steam Press')),
            service('Designer Wear', {
                description: 'Premium care for designer and festive wear',
                base_price: 0,
                per_kg_price: null,
                estimated_hours: 72,
                display_order: 2,
            }, standardClothes('Designer Wear')),
        ],
    },
]

module.exports = { CATALOG }
