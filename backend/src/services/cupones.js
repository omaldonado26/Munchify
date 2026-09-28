const { HttpError, generarCodigo } = require('../utils');
const { notificar } = require('./notificaciones');

/** Inserta un cupón con un código único (reintenta si hay colisión). */
async function insertarCupon(conn, datos) {
  for (let intento = 0; intento < 5; intento++) {
    const codigo = generarCodigo();
    try {
      const [r] = await conn.query(
        `INSERT INTO cupones (codigo, origen, campana_id, recompensa_id, evidencia_id, comercio_id,
                              usuario_id, beneficio, fecha_vencimiento)
         VALUES (?,?,?,?,?,?,?,?, DATE_ADD(NOW(), INTERVAL ? DAY))`,
        [
          codigo, datos.origen, datos.campana_id || null, datos.recompensa_id || null,
          datos.evidencia_id || null, datos.comercio_id, datos.usuario_id, datos.beneficio, datos.dias,
        ]
      );
      return { id: r.insertId, codigo };
    } catch (e) {
      if (e.code !== 'ER_DUP_ENTRY' || !String(e.message).includes('codigo')) throw e;
    }
  }
  throw new HttpError(500, 'No se pudo generar un código único');
}

/** Suma (o resta) puntos al usuario y deja registro del movimiento. */
async function moverPuntos(conn, usuarioId, puntos, concepto, cuponId = null) {
  if (!puntos) return;
  await conn.query('UPDATE usuarios SET puntos = puntos + ? WHERE id = ?', [puntos, usuarioId]);
  await conn.query(
    'INSERT INTO movimientos_puntos (usuario_id, puntos, concepto, cupon_id) VALUES (?,?,?,?)',
    [usuarioId, puntos, concepto, cuponId]
  );
}

/**
 * Aprueba una evidencia: valida disponibilidad de la campaña, emite el cupón,
 * otorga puntos y notifica al cliente. Debe ejecutarse dentro de una transacción.
 */
async function aprobarEvidencia(conn, evidenciaId, revisorId) {
  const [[ev]] = await conn.query('SELECT * FROM evidencias WHERE id = ? FOR UPDATE', [evidenciaId]);
  if (!ev) throw new HttpError(404, 'Evidencia no encontrada');
  if (ev.estado !== 'pendiente') throw new HttpError(409, `La evidencia ya fue ${ev.estado}`);

  const [[camp]] = await conn.query('SELECT * FROM campanas WHERE id = ? FOR UPDATE', [ev.campana_id]);
  if (camp.cupones_emitidos >= camp.cantidad_disponible) {
    throw new HttpError(409, 'La campaña ya no tiene cupones disponibles');
  }

  const cupon = await insertarCupon(conn, {
    origen: 'campana',
    campana_id: camp.id,
    evidencia_id: ev.id,
    comercio_id: camp.comercio_id,
    usuario_id: ev.usuario_id,
    beneficio: camp.beneficio,
    dias: camp.vigencia_cupon_dias,
  });

  await conn.query('UPDATE campanas SET cupones_emitidos = cupones_emitidos + 1 WHERE id = ?', [camp.id]);
  await conn.query(
    "UPDATE evidencias SET estado='aprobada', revisado_por=?, revisado_en=NOW() WHERE id=?",
    [revisorId, ev.id]
  );
  await moverPuntos(conn, ev.usuario_id, camp.puntos_otorgados, `Participación: ${camp.titulo}`, cupon.id);

  await notificar(
    ev.usuario_id,
    '¡Tu cupón está listo! 🎉',
    `Tu participación en "${camp.titulo}" fue aprobada. Cupón ${cupon.codigo}: ${camp.beneficio}. ` +
      `Ganaste ${camp.puntos_otorgados} puntos.`,
    'cupon',
    conn
  );
  return cupon;
}

module.exports = { insertarCupon, moverPuntos, aprobarEvidencia };
