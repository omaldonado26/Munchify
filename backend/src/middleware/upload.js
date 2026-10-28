// QUÉ HACE ESTE ARCHIVO
// Recibe las fotos de evidencia que suben los clientes y las guarda en la carpeta
// uploads del servidor, con un nombre único. Solo acepta imágenes de hasta 8 MB.

const path = require('path');
const crypto = require('crypto');
const multer = require('multer');
const { HttpError } = require('../utils');

const UPLOAD_DIR = path.join(__dirname, '..', '..', 'uploads');

const storage = multer.diskStorage({
  destination: UPLOAD_DIR,
  filename: (_req, file, cb) => {
    const ext = (path.extname(file.originalname) || '.jpg').toLowerCase();
    cb(null, `${Date.now()}-${crypto.randomBytes(6).toString('hex')}${ext}`);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 8 * 1024 * 1024 }, // 8 MB
  fileFilter: (_req, file, cb) => {
    const okMime = /^image\//.test(file.mimetype) || file.mimetype === 'application/octet-stream';
    const okExt = /\.(jpe?g|png|webp|heic|gif)$/i.test(file.originalname);
    if (okMime && okExt) cb(null, true);
    else cb(new HttpError(400, 'Solo se permiten imágenes (jpg, png, webp, heic, gif)'));
  },
});

module.exports = { upload, UPLOAD_DIR };
