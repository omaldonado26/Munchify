const fs = require('fs');
const config = require('../config');

// Firebase es opcional: se activa solo si hay credenciales configuradas
// (FIREBASE_SERVICE_ACCOUNT en .env) y el paquete `firebase-admin` está instalado.
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

/** Cliente de Firebase Cloud Messaging, o null si Firebase no está configurado. */
const messaging = app ? require('firebase-admin/messaging').getMessaging(app) : null;

/** Cliente de Firebase Authentication, o null si Firebase no está configurado. */
const firebaseAuth = app ? require('firebase-admin/auth').getAuth(app) : null;

module.exports = { messaging, firebaseAuth };
