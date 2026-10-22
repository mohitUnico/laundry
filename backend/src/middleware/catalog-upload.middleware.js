const multer = require('multer');
const { BadRequestError } = require('../utils/errors');
const { uploadBuffer } = require('../services/cloudinary-upload.service');

const ALLOWED_TYPES = new Set(['image/jpeg', 'image/png', 'image/webp']);

const upload = multer({
    storage: multer.memoryStorage(),
    limits: { fileSize: 5 * 1024 * 1024 },
});

/**
 * Read multipart field `file`, upload it to Cloudinary, and set req.catalogIconUrl.
 * A client-supplied iconUrl or icon_url is rejected. The stored value is the Cloudinary URL.
 * @param {string} folder catalog/categories, catalog/services, or catalog/clothes
 * @param {{ required: boolean }} options
 */
function catalogUpload(folder, { required }) {
    return (req, res, next) => {
        upload.single('file')(req, res, async (err) => {
            try {
                if (err) {
                    if (err.code === 'LIMIT_FILE_SIZE') {
                        throw new BadRequestError('Image must be 5 MB or smaller');
                    }
                    throw new BadRequestError('Invalid image upload');
                }

                if (req.body && (req.body.iconUrl || req.body.icon_url)) {
                    throw new BadRequestError('Send the image as file. A URL is not accepted.');
                }

                if (!req.file) {
                    if (required) throw new BadRequestError('Image file is required');
                    return next();
                }

                if (!ALLOWED_TYPES.has(req.file.mimetype)) {
                    throw new BadRequestError('Only JPEG, PNG, or WEBP images are allowed');
                }

                req.catalogIconUrl = await uploadBuffer({
                    buffer: req.file.buffer,
                    folder: `catalog/${folder}`,
                    mimetype: req.file.mimetype,
                });
                return next();
            } catch (error) {
                return next(error);
            }
        });
    };
}

function coerceCatalogFields(req, _res, next) {
    if (!req.body) req.body = {};

    for (const key of ['includes', 'excludes']) {
        if (typeof req.body[key] !== 'string') continue;
        if (req.body[key] === '') {
            delete req.body[key];
            continue;
        }
        try {
            const parsed = JSON.parse(req.body[key]);
            if (!Array.isArray(parsed) || parsed.some((item) => typeof item !== 'string')) {
                throw new Error('not an array of strings');
            }
            req.body[key] = parsed;
        } catch {
            return next(new BadRequestError(`${key} must be a JSON array of strings`));
        }
    }

    if (req.body.perKgPrice === '') req.body.perKgPrice = null;
    if (req.body.per_kg_price === '') req.body.per_kg_price = null;
    if (req.body.basePrice === '') delete req.body.basePrice;
    if (req.body.base_price === '') delete req.body.base_price;

    return next();
}

module.exports = {
    catalogUpload,
    coerceCatalogFields,
};
