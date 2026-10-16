const crypto = require('crypto');

function stableStringify(value) {
    if (value === null || value === undefined) return String(value);
    if (Array.isArray(value)) {
        return `[${value.map(stableStringify).join(',')}]`;
    }
    if (typeof value === 'object') {
        const keys = Object.keys(value).sort();
        return `{${keys.map((k) => `${k}:${stableStringify(value[k])}`).join(',')}}`;
    }
    return JSON.stringify(value);
}

function checksumCatalogue({ categories, services, clothes, serviceMen }) {
    const payload = stableStringify({
        categories: (categories || []).map((c) => ({
            category_id: c.category_id,
            category_name: c.category_name,
            is_active: c.is_active,
        })),
        services: (services || []).map((s) => ({
            service_id: s.service_id,
            category_id: s.category_id,
            service_name: s.service_name,
            per_kg_price: s.per_kg_price != null ? String(s.per_kg_price) : null,
            is_active: s.is_active,
        })),
        clothes: (clothes || []).map((i) => ({
            cloth_id: i.cloth_id,
            service_id: i.service_id,
            item_name: i.item_name,
            per_unit_price: String(i.per_unit_price),
            is_active: i.is_active,
        })),
        serviceMen: (serviceMen || []).map((m) => ({
            staff_id: m.staff_id,
            service_id: m.service_id,
            email: m.email,
            is_active: m.is_active,
        })),
    });
    return crypto.createHash('sha256').update(payload).digest('hex');
}

module.exports = {
    checksumCatalogue,
};
