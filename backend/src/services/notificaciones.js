const fs = require('fs');
const config = require('../config');
const { query } = require('../db/pool');

// Firebase Cloud Messaging es opcional: solo se activa si hay credenciales configuradas
// y el paquete `firebase-admin` está instalado (npm i firebase-admin).
let messaging = null;
if (config.firebaseServiceAccount && fs.existsSync(config.firebaseServiceAccount)) {
  try {
    const admin = require('firebase-admin');
    admin.initializeApp({ credential: admin.credential.cert(require(config.firebaseServiceAccount)) });
    messaging = admin.messaging();
    console.log('✔ Firebase Cloud Messaging habilitado');
  } catch (e) {
    console.warn('⚠ No se pudo iniciar Firebase:', e.message);
  }
}

/**
 * Registra una notificación in-app y, si Firebase está habilitado, envía un push.
 * `db` puede ser una conexión de transacción o el helper `query`.
 */
async function notificar(usuarioId, titulo, mensaje, tipo = 'sistema', db = null) {
  const sql = 'INSERT INTO notificaciones (usuario_id, titulo, mensaje, tipo) VALUES (?,?,?,?)';
  if (db) await db.query(sql, [usuarioId, titulo, mensaje, tipo]);
  else await query(sql, [usuarioId, titulo, mensaje, tipo]);

  if (messaging) {
    try {
      const [u] = await query('SELECT fcm_token FROM usuarios WHERE id = ?', [usuarioId]);
      if (u && u.fcm_token) {
        await messaging.send({ token: u.fcm_token, notification: { title: titulo, body: mensaje } });
      }
    } catch (e) {
      console.warn('Push no enviado:', e.message);
    }
  }
}

module.exports = { notificar };
