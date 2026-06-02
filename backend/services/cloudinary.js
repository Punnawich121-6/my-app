const { v2: cloudinary } = require('cloudinary');

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key:    process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
  secure:     true,
});

/**
 * Upload a base64 image string to Cloudinary.
 * Returns the secure HTTPS URL or null on failure.
 */
async function uploadBase64(base64Data, folder = 'digio') {
  if (!base64Data) return null;
  try {
    const dataUri = base64Data.startsWith('data:')
      ? base64Data
      : `data:image/jpeg;base64,${base64Data}`;
    const result = await cloudinary.uploader.upload(dataUri, {
      folder,
      resource_type: 'image',
    });
    return result.secure_url;
  } catch (e) {
    console.error('[Cloudinary] uploadBase64 error:', e.message);
    return null;
  }
}

/**
 * Upload a file buffer to Cloudinary.
 * Returns the secure HTTPS URL or null on failure.
 */
function uploadBuffer(buffer, { folder = 'digio', filename, mimetype } = {}) {
  return new Promise((resolve) => {
    const stream = cloudinary.uploader.upload_stream(
      {
        folder,
        resource_type: 'image',
        public_id: filename ? filename.replace(/\.[^.]+$/, '') : undefined,
      },
      (error, result) => {
        if (error) {
          console.error('[Cloudinary] uploadBuffer error:', error.message);
          resolve(null);
        } else {
          resolve(result.secure_url);
        }
      }
    );
    stream.end(buffer);
  });
}

module.exports = { uploadBase64, uploadBuffer };
