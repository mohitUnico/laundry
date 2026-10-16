const prisma = require('../../config/database');

/**
 * On-shift, verified, active staff inside radiusKm of origin,
 * excluding staff already recipients of this request.
 */
async function findRingCandidates({ origin, radiusKm, requestId }) {
    const lat = Number(origin.latitude);
    const lng = Number(origin.longitude);
    const rows = await prisma.$queryRaw`
        SELECT s.staff_id AS "staffId",
               s.current_latitude AS "latitude",
               s.current_longitude AS "longitude",
               (
                 6371 * acos(LEAST(1::float8, GREATEST(-1::float8,
                   cos(radians(${lat})) * cos(radians(s.current_latitude::float8))
                   * cos(radians(s.current_longitude::float8) - radians(${lng}))
                   + sin(radians(${lat})) * sin(radians(s.current_latitude::float8))
                 )))
               ) AS "distanceKm"
        FROM delivery_staffs s
        INNER JOIN delivery_staff_shifts sh
          ON sh.staff_id = s.staff_id
         AND sh.is_active = true
         AND sh.ended_at IS NULL
        WHERE s.is_active = true
          AND s.is_verified_by_admin = true
          AND s.current_latitude IS NOT NULL
          AND s.current_longitude IS NOT NULL
          AND NOT EXISTS (
            SELECT 1 FROM delivery_assignment_recipients r
            WHERE r.request_id::text = ${requestId}
              AND r.staff_id = s.staff_id
          )
    `;

    return rows
        .map((row) => ({
            staffId: row.staffId,
            distanceKm: Number(row.distanceKm),
        }))
        .filter((row) => Number.isFinite(row.distanceKm) && row.distanceKm <= radiusKm);
}

module.exports = {
    findRingCandidates,
};
