// QUÉ HACE ESTE ARCHIVO
// Lee la configuración del archivo .env (puerto, datos de MySQL, clave y duración
// del JWT, ruta de la cuenta de Firebase) y la deja disponible para el resto del servidor.
// Aquí no hay secretos escritos: los valores reales viven en .env, que no se sube a GitHub.

require('dotenv').config({ quiet: true });
const path = require('path');

// La ruta de la cuenta de servicio puede ser relativa a la carpeta backend/.
const cuentaFirebase = process.env.FIREBASE_SERVICE_ACCOUNT
  ? path.resolve(__dirname, '..', process.env.FIREBASE_SERVICE_ACCOUNT)
  : '';

module.exports = {
  port: Number(process.env.PORT || 3000),
  publicUrl: process.env.PUBLIC_URL || `http://localhost:${process.env.PORT || 3000}`,
  db: {
    host: process.env.DB_HOST || 'localhost',
    port: Number(process.env.DB_PORT || 3306),
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'munchify',
  },
  jwt: {
    secret: process.env.JWT_SECRET || 'munchify_dev_secret',
    expires: process.env.JWT_EXPIRES || '7d',
  },
  firebaseServiceAccount: cuentaFirebase,
};
