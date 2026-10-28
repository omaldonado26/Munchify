const fs = require('fs');
const config = require('../config');

let app = null;
if (config.firebaseServiceAccount && fs.existsSync(config.firebaseServiceAccount)) {
  try {
    const { initializeApp, cert } = require('firebase-admin/app');
    app = initializeApp({ credential: cert(require(config.firebaseServiceAccount)) });
    console.log('✔ Firebase habilitado');
  } catch (e) {
    console.warn('⚠ No se pudo iniciar Firebase:', e.message);
  }
}

const messaging = app ? require('firebase-admin/messaging').getMessaging(app) : null;

const firebaseAuth = app ? require('firebase-admin/auth').getAuth(app) : null;

module.exports = { messaging, firebaseAuth };
