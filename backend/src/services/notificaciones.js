// QUÉ HACE ESTE ARCHIVO
// Envía avisos a los usuarios: guarda la notificación que se ve dentro de la app y,
// si Firebase está activo, manda además el push al teléfono. Puede avisar a una
// persona (notificar) o a todos los clientes a la vez (notificarAClientes).

const { query } = require('../db/pool');
const { messaging } = require('./firebase');

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
        await messaging.send({
          token: u.fcm_token,
          notification: { title: titulo, body: mensaje },
          data: { tipo },
          android: { priority: 'high', notification: { channelId: 'munchify_avisos' } },
        });
      }
    } catch (e) {
      console.warn('Push no enviado:', e.message);
    }
  }
}

/**
 * Avisa a todos los clientes activos (p. ej. al publicarse una promoción nueva):
 * guarda la notificación in-app de cada uno y envía un push a los que tienen dispositivo registrado.
 */
async function notificarAClientes(titulo, mensaje, tipo = 'promocion') {
  await query(
    `INSERT INTO notificaciones (usuario_id, titulo, mensaje, tipo)
     SELECT id, ?, ?, ? FROM usuarios WHERE rol='cliente' AND activo=1`,
    [titulo, mensaje, tipo]
  );

  if (!messaging) return;
  try {
    const filas = await query(
      "SELECT fcm_token FROM usuarios WHERE rol='cliente' AND activo=1 AND fcm_token IS NOT NULL"
    );
    const tokens = filas.map((f) => f.fcm_token);
    // FCM admite hasta 500 destinatarios por envío.
    for (let i = 0; i < tokens.length; i += 500) {
      const r = await messaging.sendEachForMulticast({
        tokens: tokens.slice(i, i + 500),
        notification: { title: titulo, body: mensaje },
        data: { tipo },
        android: { priority: 'high', notification: { channelId: 'munchify_avisos' } },
      });
      if (r.failureCount) console.warn(`Push masivo: ${r.failureCount} de ${r.responses.length} no entregados`);
    }
  } catch (e) {
    console.warn('Push masivo no enviado:', e.message);
  }
}

module.exports = { notificar, notificarAClientes };
