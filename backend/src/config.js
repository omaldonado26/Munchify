require('dotenv').config({ quiet: true });

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
  firebaseServiceAccount: process.env.FIREBASE_SERVICE_ACCOUNT || '',
};
