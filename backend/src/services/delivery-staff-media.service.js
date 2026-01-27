const { getSupabaseClient } = require('../config/supabase');
const logger = require('../utils/logger');
const { AppError, ValidationError } = require('../utils/errors');
const { v4: uuidv4 } = require('uuid');

const DEFAULT_BUCKET = process.env.SUPABASE_DELIVERY_STAFF_BUCKET || 'delivery-staff';

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

async function ensureBucketExists(bucket) {
  const supabase = getSupabaseClient();

  const { data: buckets, error: listError } = await supabase.storage.listBuckets();
  if (listError) {
    logger.error('Supabase listBuckets failed', { error: listError.message, bucket });
    throw new AppError('Failed to access storage buckets', 500);
  }

  const exists = Array.isArray(buckets) && buckets.some((b) => b?.name === bucket);
  if (exists) return;

  logger.warn('Supabase bucket missing; creating bucket', { bucket });
  const { error: createError } = await supabase.storage.createBucket(bucket, { public: true });

  if (createError) {
    const msg = String(createError.message || '').toLowerCase();
    if (!msg.includes('already exists')) {
      logger.error('Supabase createBucket failed', { error: createError.message, bucket });
      throw new AppError('Failed to create storage bucket', 500);
    }
  }
}

async function uploadToSupabase({ bucket, objectPath, file }) {
  const supabase = getSupabaseClient();

  const doUpload = async () => {
    return supabase.storage.from(bucket).upload(objectPath, file.buffer, {
      contentType: file.mimetype,
      upsert: true,
      cacheControl: '3600',
    });
  };

  let { error: uploadError } = await doUpload();

  if (uploadError) {
    const msg = String(uploadError.message || '').toLowerCase();
    if (msg.includes('bucket not found')) {
      await ensureBucketExists(bucket);
      ({ error: uploadError } = await doUpload());
    }
  }

  if (uploadError) {
    logger.error('Supabase upload failed', { error: uploadError.message, bucket, objectPath });
    throw new AppError('Failed to upload file', 500);
  }

  const { data: publicUrlData } = supabase.storage.from(bucket).getPublicUrl(objectPath);
  const publicUrl = publicUrlData?.publicUrl;

  if (!publicUrl) {
    logger.error('Supabase getPublicUrl returned empty url', { bucket, objectPath });
    throw new AppError('Failed to resolve file URL', 500);
  }

  return publicUrl;
}

exports.uploadDeliveryStaffProfileImage = async ({ registrationKey, file }) => {
  if (!registrationKey) throw new ValidationError('registrationKey is required');
  if (!file) throw new ValidationError('Profile image file is required');
  if (!IMAGE_MIME_TYPES.has(file.mimetype)) {
    throw new ValidationError('Profile image must be JPEG, PNG, or WEBP');
  }

  const ext = getFileExt(file.mimetype);
  if (!ext) throw new ValidationError('Unsupported profile image file type');

  const objectPath = `registrations/${registrationKey}/profile/${uuidv4()}.${ext}`;
  return uploadToSupabase({ bucket: DEFAULT_BUCKET, objectPath, file });
};

exports.uploadDeliveryStaffDocument = async ({ registrationKey, kind, file }) => {
  if (!registrationKey) throw new ValidationError('registrationKey is required');
  if (!kind) throw new ValidationError('Document kind is required');
  if (!file) throw new ValidationError('Document file is required');

  if (!DOC_MIME_TYPES.has(file.mimetype)) {
    throw new ValidationError('Document must be PDF, JPG, PNG, or WEBP');
  }

  const ext = getFileExt(file.mimetype);
  if (!ext) throw new ValidationError('Unsupported document file type');

  const safeKind = String(kind).replace(/[^a-z0-9_-]/gi, '_').toLowerCase();
  const objectPath = `registrations/${registrationKey}/documents/${safeKind}/${uuidv4()}.${ext}`;
  return uploadToSupabase({ bucket: DEFAULT_BUCKET, objectPath, file });
};

exports.uploadDeliveryProofImage = async ({ deliveryId, kind, file }) => {
  if (!deliveryId) throw new ValidationError('deliveryId is required');
  if (!kind) throw new ValidationError('kind is required');
  if (!file) throw new ValidationError('Proof image file is required');
  if (!IMAGE_MIME_TYPES.has(file.mimetype)) {
    throw new ValidationError('Proof image must be JPEG, PNG, or WEBP');
  }

  const ext = getFileExt(file.mimetype);
  if (!ext) throw new ValidationError('Unsupported proof image file type');

  const bucket = process.env.SUPABASE_DELIVERY_PROOFS_BUCKET || 'delivery-proofs';
  const safeKind = String(kind).replace(/[^a-z0-9_-]/gi, '_').toLowerCase();
  const objectPath = `deliveries/${deliveryId}/${safeKind}/${uuidv4()}.${ext}`;
  return uploadToSupabase({ bucket, objectPath, file });
};

