const prisma = require('../config/database');
const logger = require('../utils/logger');
const { NotFoundError, ValidationError } = require('../utils/errors');
const { Prisma } = require('@prisma/client');

const normalizePagination = ({ page = 1, limit = 20 } = {}) => {
    const safePage = Number.isInteger(page) ? page : parseInt(page);
    const safeLimit = Number.isInteger(limit) ? limit : parseInt(limit);

    if (!Number.isInteger(safePage) || safePage < 1) throw new ValidationError('page must be >= 1');
    if (!Number.isInteger(safeLimit) || safeLimit < 1 || safeLimit > 100) {
        throw new ValidationError('limit must be between 1 and 100');
    }

    return { safePage, safeLimit, skip: (safePage - 1) * safeLimit };
};

exports.getAdminDeliveryStaffs = async (query = {}) => {
    const { verificationStatus, isVerifiedByAdmin, isActive } = query;
    const { safePage, safeLimit, skip } = normalizePagination(query);

    const where = {
        ...(verificationStatus ? { verification_status: verificationStatus } : {}),
        ...(typeof isVerifiedByAdmin === 'boolean' ? { is_verified_by_admin: isVerifiedByAdmin } : {}),
        ...(typeof isActive === 'boolean' ? { is_active: isActive } : {}),
    };

    logger.info('Admin delivery staff list query', {
        verificationStatus: verificationStatus || null,
        isVerifiedByAdmin: typeof isVerifiedByAdmin === 'boolean' ? isVerifiedByAdmin : null,
        isActive: typeof isActive === 'boolean' ? isActive : null,
        page: safePage,
        limit: safeLimit,
    });

    const [total, rows] = await Promise.all([
        prisma.deliveryStaff.count({ where }),
        prisma.deliveryStaff.findMany({
            where,
            orderBy: { created_at: 'desc' },
            skip,
            take: safeLimit,
            select: {
                staff_id: true,
                full_name: true,
                email: true,
                phone: true,
                address: true,
                current_latitude: true,
                current_longitude: true,
                vehicle_type: true,
                vehicle_number: true,
                profile_image_url: true,
                id_proof_type: true,
                id_proof_url: true,
                driving_license_url: true,
                verification_status: true,
                is_verified_by_admin: true,
                is_active: true,
                created_at: true,
                updated_at: true,
            },
        }),
    ]);

    return {
        pagination: {
            page: safePage,
            limit: safeLimit,
            total,
            totalPages: Math.ceil(total / safeLimit),
        },
        deliveryStaffs: rows.map((r) => ({
            staffId: r.staff_id,
            fullName: r.full_name,
            email: r.email,
            phone: r.phone,
            address: r.address,
            currentCoordinates: r.current_latitude && r.current_longitude
                ? { latitude: r.current_latitude.toString(), longitude: r.current_longitude.toString() }
                : null,
            vehicleType: r.vehicle_type,
            vehicleNumber: r.vehicle_number,
            verificationStatus: r.verification_status,
            isVerifiedByAdmin: r.is_verified_by_admin,
            isActive: r.is_active,
            averageRating: r.average_rating?.toString?.() ?? (r.average_rating ?? null),
            totalDeliveries: r.total_deliveries,
            documents: {
                profileImageUrl: r.profile_image_url || null,
                idProofType: r.id_proof_type || null,
                idProofUrl: r.id_proof_url || null,
                drivingLicenseUrl: r.driving_license_url || null,
            },
            createdAt: r.created_at,
            updatedAt: r.updated_at,
        })),
    };
};

exports.getAdminDeliveryStaffSummary = async () => {
    const [totalStaffs, avgRatingAgg, availableDistinct, deliveringDistinct] = await Promise.all([
        prisma.deliveryStaff.count({}),
        prisma.deliveryStaff.aggregate({
            _avg: { average_rating: true },
            where: { average_rating: { not: null } },
        }),
        prisma.deliveryStaffShift.findMany({
            where: { is_active: true },
            distinct: ['staff_id'],
            select: { staff_id: true },
        }),
        prisma.delivery.findMany({
            where: {
                staff_id: { not: null },
                completed_at: null,
                delivery_status: { not: 'cancelled' },
            },
            distinct: ['staff_id'],
            select: { staff_id: true },
        }),
    ]);

    const averageRating = avgRatingAgg?._avg?.average_rating;

    return {
        total_staffs: totalStaffs,
        available: Array.isArray(availableDistinct) ? availableDistinct.length : 0,
        currently_delivering: Array.isArray(deliveringDistinct) ? deliveringDistinct.length : 0,
        average_rating: averageRating ? Number(averageRating.toString?.() ?? averageRating) : 0,
    };
};

exports.getAdminPendingDeliveryStaffVerifications = async (query = {}) => {
    const { safePage, safeLimit, skip } = normalizePagination(query);

    const where = {
        verification_status: 'pending',
        is_verified_by_admin: false,
    };

    const [total, rows] = await Promise.all([
        prisma.deliveryStaff.count({ where }),
        prisma.deliveryStaff.findMany({
            where,
            orderBy: { created_at: 'desc' },
            skip,
            take: safeLimit,
            select: {
                staff_id: true,
                full_name: true,
                email: true,
                phone: true,
                address: true,
                vehicle_type: true,
                vehicle_number: true,
                profile_image_url: true,
                id_proof_type: true,
                id_proof_url: true,
                driving_license_url: true,
                verification_status: true,
                is_verified_by_admin: true,
                is_active: true,
                created_at: true,
                updated_at: true,
            },
        }),
    ]);

    return {
        pagination: {
            page: safePage,
            limit: safeLimit,
            total,
            totalPages: Math.ceil(total / safeLimit),
        },
        pendingVerifications: rows.map((r) => ({
            staffId: r.staff_id,
            fullName: r.full_name,
            email: r.email,
            phone: r.phone,
            address: r.address,
            vehicleType: r.vehicle_type,
            vehicleNumber: r.vehicle_number,
            verificationStatus: r.verification_status,
            isVerifiedByAdmin: r.is_verified_by_admin,
            isActive: r.is_active,
            documents: {
                profileImageUrl: r.profile_image_url || null,
                idProofType: r.id_proof_type || null,
                idProofUrl: r.id_proof_url || null,
                drivingLicenseUrl: r.driving_license_url || null,
            },
            createdAt: r.created_at,
            updatedAt: r.updated_at,
        })),
    };
};

exports.verifyDeliveryStaff = async (staffId) => {
    if (!staffId) throw new ValidationError('staffId is required');

    const existing = await prisma.deliveryStaff.findUnique({
        where: { staff_id: staffId },
        select: { staff_id: true, verification_status: true, is_verified_by_admin: true },
    });

    if (!existing) {
        throw new NotFoundError('DeliveryStaff');
    }

    // Idempotent verify
    if (existing.verification_status === 'verified' && existing.is_verified_by_admin === true) {
        return prisma.deliveryStaff.findUnique({
            where: { staff_id: staffId },
            select: {
                staff_id: true,
                full_name: true,
                email: true,
                phone: true,
                verification_status: true,
                is_verified_by_admin: true,
                updated_at: true,
            },
        });
    }

    return prisma.deliveryStaff.update({
        where: { staff_id: staffId },
        data: {
            is_verified_by_admin: true,
            verification_status: 'verified',
        },
        select: {
            staff_id: true,
            full_name: true,
            email: true,
            phone: true,
            verification_status: true,
            is_verified_by_admin: true,
            updated_at: true,
        },
    });
};

exports.getAdminOnlineDeliveryStaffs = async (query = {}) => {
    const { safePage, safeLimit, skip } = normalizePagination(query);

    // Use DISTINCT ON to safely get the latest active shift per staff.
    const baseSql = Prisma.sql`
        WITH active_shifts AS (
            SELECT DISTINCT ON (s.staff_id)
                s.shift_id,
                s.staff_id,
                s.started_at,
                s.last_latitude,
                s.last_longitude,
                s.last_location_at,
                ds.full_name,
                ds.email,
                ds.phone,
                ds.vehicle_type,
                ds.vehicle_number,
                ds.profile_image_url,
                ds.verification_status,
                ds.is_verified_by_admin,
                ds.is_active
            FROM delivery_staff_shifts s
            JOIN delivery_staffs ds ON ds.staff_id = s.staff_id
            WHERE s.is_active = TRUE
              AND s.ended_at IS NULL
              AND ds.is_active = TRUE
            ORDER BY s.staff_id, s.started_at DESC
        )
    `;

    const countRows = await prisma.$queryRaw`
        ${baseSql}
        SELECT COUNT(*)::int AS total FROM active_shifts;
    `;
    const total = countRows?.[0]?.total ?? 0;

    const rows = await prisma.$queryRaw`
        ${baseSql}
        SELECT *
        FROM active_shifts
        ORDER BY started_at DESC
        LIMIT ${safeLimit}::int
        OFFSET ${skip}::int;
    `;

    return {
        pagination: {
            page: safePage,
            limit: safeLimit,
            total,
            totalPages: Math.ceil(total / safeLimit),
        },
        onlineDeliveryStaffs: (rows || []).map((r) => ({
            staffId: r.staff_id,
            fullName: r.full_name,
            email: r.email,
            phone: r.phone || null,
            vehicleType: r.vehicle_type,
            vehicleNumber: r.vehicle_number,
            profileImageUrl: r.profile_image_url || null,
            verificationStatus: r.verification_status,
            isVerifiedByAdmin: r.is_verified_by_admin,
            isActive: r.is_active,
            shift: {
                shiftId: r.shift_id,
                startedAt: r.started_at,
                lastLocationAt: r.last_location_at,
                lastLatitude: r.last_latitude,
                lastLongitude: r.last_longitude,
            },
        })),
    };
};
