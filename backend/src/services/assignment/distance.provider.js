/**
 * Distance used by the assignment rings. Haversine (straight line) for now.
 * A road-distance provider can replace distanceKm later.
 */

function toRad(deg) {
    return (Number(deg) * Math.PI) / 180;
}

function haversineKm(from, to) {
    if (
        from?.latitude == null ||
        from?.longitude == null ||
        to?.latitude == null ||
        to?.longitude == null
    ) {
        return null;
    }
    const R = 6371;
    const dLat = toRad(Number(to.latitude) - Number(from.latitude));
    const dLng = toRad(Number(to.longitude) - Number(from.longitude));
    const a =
        Math.sin(dLat / 2) ** 2 +
        Math.cos(toRad(from.latitude)) * Math.cos(toRad(to.latitude)) * Math.sin(dLng / 2) ** 2;
    return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

module.exports = {
    distanceKm: haversineKm,
};
