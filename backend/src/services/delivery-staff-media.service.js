const logger = require('../utils/logger');
const { ValidationError } = require('../utils/errors');
const { uploadBuffer } = require('./cloudinary-upload.service');

const IMAGE_MIME_TYPES = new Set(['image/jpeg', 'image/png', 'image/webp']);
const DOC_MIME_TYPES = new Set([
    'application/pdf',
    'image/jpeg',
    'image/png',
    'image/webp',
]);

function getFileExt(mimetype) {
    switch (mimetype) {
        case 'image/jpeg':
            return 'jpg';
        case 'image/png':
            return 'png';
        case 'image/webp':
            return 'webp';
        case 'application/pdf':
            return 'pdf';
        default:
            return null;
    }
}

async function uploadMediaFile({ folder, file }) {
    if (!getFileExt(file.mimetype)) {
        throw new ValidationError('Unsupported file type');
    }

    const publicUrl = await uploadBuffer({
        buffer: file.buffer,
        folder,
        mimetype: file.mimetype,
    });

    logger.info('Media uploaded to Cloudinary', { folder, url: publicUrl });
    return publicUrl;
}

exports.uploadDeliveryStaffProfileImage = async ({ registrationKey, file }) => {
    if (!registrationKey) throw new ValidationError('registrationKey is required');
    if (!file) throw new ValidationError('Profile image file is required');
    if (!IMAGE_MIME_TYPES.has(file.mimetype)) {
        throw new ValidationError('Profile image must be JPEG, PNG, or WEBP');
    }

    return uploadMediaFile({
        folder: `delivery-staff/registrations/${registrationKey}/profile`,
        file,
    });
};

exports.uploadDeliveryStaffDocument = async ({ registrationKey, kind, file }) => {
    if (!registrationKey) throw new ValidationError('registrationKey is required');
    if (!kind) throw new ValidationError('Document kind is required');
    if (!file) throw new ValidationError('Document file is required');

    if (!DOC_MIME_TYPES.has(file.mimetype)) {
        throw new ValidationError('Document must be PDF, JPG, PNG, or WEBP');
    }

    const safeKind = String(kind).replace(/[^a-z0-9_-]/gi, '_').toLowerCase();
    return uploadMediaFile({
        folder: `delivery-staff/registrations/${registrationKey}/documents/${safeKind}`,
        file,
    });
};

exports.uploadDeliveryProofImage = async ({ deliveryId, kind, file }) => {
    if (!deliveryId) throw new ValidationError('deliveryId is required');
    if (!kind) throw new ValidationError('kind is required');
    if (!file) throw new ValidationError('Proof image file is required');
    if (!IMAGE_MIME_TYPES.has(file.mimetype)) {
        throw new ValidationError('Proof image must be JPEG, PNG, or WEBP');
    }

    const safeKind = String(kind).replace(/[^a-z0-9_-]/gi, '_').toLowerCase();
    return uploadMediaFile({
        folder: `delivery-proofs/${deliveryId}/${safeKind}`,
        file,
    });
};
