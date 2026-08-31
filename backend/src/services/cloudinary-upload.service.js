const cloudinary = require('cloudinary').v2;
const { v4: uuidv4 } = require('uuid');
const logger = require('../utils/logger');
const { AppError } = require('../utils/errors');

let configured = false;

function ensureConfigured() {
    if (configured) return;

    const cloudName = (process.env.CLOUDINARY_CLOUD_NAME || '').trim();
    const apiKey = (process.env.CLOUDINARY_API_KEY || '').trim();
    const apiSecret = (process.env.CLOUDINARY_API_SECRET || '').trim();

    if (!cloudName || !apiKey || !apiSecret) {
        throw new AppError(
            'Cloudinary is not configured. Set CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, and CLOUDINARY_API_SECRET.',
            500
        );
    }

    cloudinary.config({
        cloud_name: cloudName,
        api_key: apiKey,
        api_secret: apiSecret,
    });
    configured = true;
}

/**
 * Upload a file buffer to Cloudinary and return the secure HTTPS URL.
 * @param {{ buffer: Buffer, folder: string, mimetype: string }} params
 * @returns {Promise<string>}
 */
async function uploadBuffer({ buffer, folder, mimetype }) {
    ensureConfigured();

    const baseFolder = (process.env.CLOUDINARY_UPLOAD_FOLDER || 'laundry-app').replace(/\/+$/, '');
    const fullFolder = folder ? `${baseFolder}/${folder}`.replace(/\/+/g, '/') : baseFolder;
    const resourceType = mimetype === 'application/pdf' ? 'raw' : 'image';

    return new Promise((resolve, reject) => {
        const uploadStream = cloudinary.uploader.upload_stream(
            {
                folder: fullFolder,
                public_id: uuidv4(),
                resource_type: resourceType,
            },
            (error, result) => {
                if (error) {
                    logger.error('Cloudinary upload failed', {
                        error: error.message,
                        folder: fullFolder,
                    });
                    reject(new AppError('Failed to upload file', 500));
                    return;
                }

                const url = result?.secure_url;
                if (!url) {
                    logger.error('Cloudinary upload returned empty URL', { folder: fullFolder });
                    reject(new AppError('Failed to resolve file URL', 500));
                    return;
                }

                resolve(url);
            }
        );

        uploadStream.end(buffer);
    });
}

module.exports = {
    uploadBuffer,
    ensureConfigured,
};
