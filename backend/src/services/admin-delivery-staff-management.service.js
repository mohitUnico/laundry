const prisma = require('../config/database');
const logger = require('../utils/logger');
const { NotFoundError, ValidationError } = require('../utils/errors');

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
    const { verificationStatus, isVerifiedByAdmin } = query;
    const { safePage, safeLimit, skip } = normalizePagination(query);

    const where = {
        ...(verificationStatus ? { verification_status: verificationStatus } : {}),
        ...(typeof isVerifiedByAdmin === 'boolean' ? { is_verified_by_admin: isVerifiedByAdmin } : {}),
    };

    logger.info('Admin delivery staff list query', {
        verificationStatus: verificationStatus || null,
        isVerifiedByAdmin: typeof isVerifiedByAdmin === 'boolean' ? isVerifiedByAdmin : null,
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

