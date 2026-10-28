const router = require('express').Router();
const { query, transaction } = require('../db/pool');
const { auth, role } = require('../middleware/auth');
const { HttpError, requerir, entero } = require('../utils');
const { aprobarEvidencia } = require('../services/cupones');
const { notificar } = require('../services/notificaciones');

router.use(auth, role('comercio'));

router.get('/perfil', async (req, res) => {
  const [co] = await query(
    `SELECT co.*, cat.nombre AS categoria_nombre FROM comercios co
     LEFT JOIN categorias cat ON cat.id = co.categoria_id WHERE co.id=?`,
    [req.user.comercio_id]
  );
  res.json(co);
});

router.put('/perfil', async (req, res) => {
  const b = req.body || {};
  await query(
    `UPDATE comercios SET nombre=COALESCE(?,nombre), descripcion=COALESCE(?,descripcion),
       direccion=COALESCE(?,direccion), telefono=COALESCE(?,telefono), instagram=COALESCE(?,instagram),
       categoria_id=COALESCE(?,categoria_id) WHERE id=?`,
    [b.nombre || null, b.descripcion || null, b.direccion || null, b.telefono || null,
     b.instagram || null, b.categoria_id || null, req.user.comercio_id]
  );
  const [co] = await query('SELECT * FROM comercios WHERE id=?', [req.user.comercio_id]);
  res.json(co);
});

router.get('/campanas', async (req, res) => {
  const rows = await query(
    `SELECT c.*, (c.cantidad_disponible - c.cupones_emitidos) AS cupones_restantes,
            cat.nombre AS categoria_nombre,
            (SELECT COUNT(*) FROM evidencias e WHERE e.campana_id=c.id) AS participantes,
            (SELECT COUNT(*) FROM evidencias e WHERE e.campana_id=c.id AND e.estado='pendiente') AS pendientes,
            (SELECT COUNT(*) FROM cupones cu WHERE cu.campana_id=c.id AND cu.estado='canjeado') AS cupones_canjeados
       FROM campanas c LEFT JOIN categorias cat ON cat.id=c.categoria_id
      WHERE c.comercio_id=? ORDER BY c.creado_en DESC`,
    [req.user.comercio_id]
  );
  res.json(rows);
});

router.get('/evidencias', async (req, res) => {
  const where = ['c.comercio_id = ?'];
  const params = [req.user.comercio_id];
  if (req.query.estado) { where.push('e.estado = ?'); params.push(req.query.estado); }
  if (req.query.campana_id) { where.push('e.campana_id = ?'); params.push(entero(req.query.campana_id, 0)); }
  const rows = await query(
    `SELECT e.*, c.titulo AS campana_titulo, c.tipo_accion, c.red_social,
            u.nombre AS usuario_nombre, u.usuario_instagram
       FROM evidencias e
       JOIN campanas c ON c.id = e.campana_id
       JOIN usuarios u ON u.id = e.usuario_id
      WHERE ${where.join(' AND ')}
      ORDER BY e.estado='pendiente' DESC, e.creado_en DESC`,
    params
  );
  res.json(rows);
});

async function evidenciaPropia(req) {
  const [ev] = await query(
    'SELECT e.*, c.comercio_id, c.titulo FROM evidencias e JOIN campanas c ON c.id=e.campana_id WHERE e.id=?',
    [req.params.id]
  );
  if (!ev) throw new HttpError(404, 'Evidencia no encontrada');
  if (ev.comercio_id !== req.user.comercio_id) throw new HttpError(403, 'La evidencia no pertenece a tu comercio');
  return ev;
}

router.post('/evidencias/:id/aprobar', async (req, res) => {
  const ev = await evidenciaPropia(req);
  const cupon = await transaction((conn) => aprobarEvidencia(conn, ev.id, req.user.id));
  res.json({ evidencia_id: ev.id, estado: 'aprobada', cupon });
});

router.post('/evidencias/:id/rechazar', async (req, res) => {
  const ev = await evidenciaPropia(req);
  if (ev.estado !== 'pendiente') throw new HttpError(409, `La evidencia ya fue ${ev.estado}`);
  const motivo = req.body?.motivo || 'La evidencia no cumple las condiciones de la campaña';
  await query(
    "UPDATE evidencias SET estado='rechazada', motivo_rechazo=?, revisado_por=?, revisado_en=NOW() WHERE id=?",
    [motivo, req.user.id, ev.id]
  );
  await notificar(ev.usuario_id, 'Evidencia rechazada', `Tu participación en "${ev.titulo}" fue rechazada: ${motivo}`, 'evidencia');
  res.json({ evidencia_id: ev.id, estado: 'rechazada', motivo });
});

async function buscarCupon(codigo, comercioId, conn = null, lock = false) {
  const sql = `SELECT cu.*, u.nombre AS usuario_nombre, c.titulo AS campana_titulo, r.nombre AS recompensa_nombre
                 FROM cupones cu
                 JOIN usuarios u ON u.id = cu.usuario_id
                 LEFT JOIN campanas c ON c.id = cu.campana_id
                 LEFT JOIN recompensas r ON r.id = cu.recompensa_id
                WHERE cu.codigo = ? ${lock ? 'FOR UPDATE' : ''}`;
  const params = [String(codigo).trim().toUpperCase()];
  const rows = conn ? (await conn.query(sql, params))[0] : await query(sql, params);
  const cupon = rows[0];
  if (!cupon) throw new HttpError(404, 'Cupón no encontrado');
  if (cupon.comercio_id !== comercioId) throw new HttpError(403, 'Este cupón pertenece a otro comercio');
  return cupon;
}

router.get('/cupones/:codigo', async (req, res) => {
  const cupon = await buscarCupon(req.params.codigo, req.user.comercio_id);
  const vencido = cupon.estado === 'activo' && new Date(cupon.fecha_vencimiento.replace(' ', 'T')) < new Date();
  res.json({ ...cupon, estado: vencido ? 'vencido' : cupon.estado, canjeable: cupon.estado === 'activo' && !vencido });
});

router.post('/cupones/canjear', async (req, res) => {
  requerir(req.body || {}, ['codigo']);
  const cupon = await transaction(async (conn) => {
    const cu = await buscarCupon(req.body.codigo, req.user.comercio_id, conn, true);
    if (cu.estado === 'canjeado') throw new HttpError(409, `El cupón ya fue canjeado el ${cu.fecha_canje}`);
    if (cu.estado !== 'activo') throw new HttpError(409, `El cupón está ${cu.estado}`);
    const [[{ vencido }]] = await conn.query('SELECT CAST(? AS DATETIME) < NOW() AS vencido', [cu.fecha_vencimiento]);
    if (vencido) {
      await conn.query("UPDATE cupones SET estado='vencido' WHERE id=?", [cu.id]);
      throw new HttpError(409, 'El cupón está vencido');
    }
    await conn.query("UPDATE cupones SET estado='canjeado', fecha_canje=NOW(), canjeado_por=? WHERE id=?", [req.user.id, cu.id]);
    await notificar(cu.usuario_id, 'Cupón canjeado', `Usaste tu cupón ${cu.codigo}: ${cu.beneficio}. ¡Gracias!`, 'cupon', conn);
    return { ...cu, estado: 'canjeado' };
  });
  res.json({ ok: true, mensaje: 'Cupón canjeado correctamente', cupon });
});

router.get('/canjes', async (req, res) => {
  const rows = await query(
    `SELECT cu.id, cu.codigo, cu.beneficio, cu.origen, cu.fecha_canje, u.nombre AS usuario_nombre
       FROM cupones cu JOIN usuarios u ON u.id=cu.usuario_id
      WHERE cu.comercio_id=? AND cu.estado='canjeado' ORDER BY cu.fecha_canje DESC LIMIT 50`,
    [req.user.comercio_id]
  );
  res.json(rows);
});

router.get('/metricas', async (req, res) => {
  const id = req.user.comercio_id;
  const [resumen] = await query(
    `SELECT
       (SELECT COUNT(*) FROM campanas WHERE comercio_id=?) AS campanas_total,
       (SELECT COUNT(*) FROM campanas WHERE comercio_id=? AND estado='activa') AS campanas_activas,
       (SELECT COUNT(DISTINCT e.usuario_id) FROM evidencias e JOIN campanas c ON c.id=e.campana_id WHERE c.comercio_id=?) AS participantes,
       (SELECT COUNT(*) FROM evidencias e JOIN campanas c ON c.id=e.campana_id WHERE c.comercio_id=?) AS evidencias_total,
       (SELECT COUNT(*) FROM evidencias e JOIN campanas c ON c.id=e.campana_id WHERE c.comercio_id=? AND e.estado='pendiente') AS evidencias_pendientes,
       (SELECT COUNT(*) FROM cupones WHERE comercio_id=?) AS cupones_emitidos,
       (SELECT COUNT(*) FROM cupones WHERE comercio_id=? AND estado='canjeado') AS cupones_canjeados,
       (SELECT COUNT(*) FROM cupones WHERE comercio_id=? AND estado='vencido') AS cupones_vencidos`,
    [id, id, id, id, id, id, id, id]
  );
  resumen.tasa_canje = resumen.cupones_emitidos
    ? Math.round((resumen.cupones_canjeados / resumen.cupones_emitidos) * 1000) / 10
    : 0;

  const porCampana = await query(
    `SELECT c.id, c.titulo, c.estado, c.cantidad_disponible, c.cupones_emitidos,
            (SELECT COUNT(*) FROM evidencias e WHERE e.campana_id=c.id) AS participantes,
            (SELECT COUNT(*) FROM cupones cu WHERE cu.campana_id=c.id AND cu.estado='canjeado') AS canjeados
       FROM campanas c WHERE c.comercio_id=? ORDER BY c.creado_en DESC`,
    [id]
  );

  const ultimos7dias = await query(
    `SELECT DATE(fecha_canje) AS dia, COUNT(*) AS canjes FROM cupones
      WHERE comercio_id=? AND estado='canjeado' AND fecha_canje >= DATE_SUB(CURDATE(), INTERVAL 6 DAY)
      GROUP BY DATE(fecha_canje) ORDER BY dia`,
    [id]
  );

  res.json({ resumen, por_campana: porCampana, canjes_ultimos_7_dias: ultimos7dias });
});

router.get('/recompensas', async (req, res) => {
  res.json(await query('SELECT * FROM recompensas WHERE comercio_id=? ORDER BY creado_en DESC', [req.user.comercio_id]));
});

router.post('/recompensas', async (req, res) => {
  const b = req.body || {};
  requerir(b, ['nombre', 'costo_puntos']);
  if (entero(b.costo_puntos, 0) < 1) throw new HttpError(400, 'El costo en puntos debe ser mayor a 0');
  const r = await query(
    'INSERT INTO recompensas (comercio_id, nombre, descripcion, costo_puntos, stock, vigencia_dias) VALUES (?,?,?,?,?,?)',
    [req.user.comercio_id, b.nombre, b.descripcion || null, entero(b.costo_puntos, 0),
     entero(b.stock, 50), entero(b.vigencia_dias, 15)]
  );
  const [rec] = await query('SELECT * FROM recompensas WHERE id=?', [r.insertId]);
  res.status(201).json(rec);
});

router.put('/recompensas/:id', async (req, res) => {
  const [rec] = await query('SELECT * FROM recompensas WHERE id=? AND comercio_id=?', [req.params.id, req.user.comercio_id]);
  if (!rec) throw new HttpError(404, 'Recompensa no encontrada');
  const b = { ...rec, ...req.body };
  await query(
    'UPDATE recompensas SET nombre=?, descripcion=?, costo_puntos=?, stock=?, vigencia_dias=?, activa=? WHERE id=?',
    [b.nombre, b.descripcion, entero(b.costo_puntos, rec.costo_puntos), entero(b.stock, rec.stock),
     entero(b.vigencia_dias, rec.vigencia_dias), b.activa ? 1 : 0, rec.id]
  );
  const [act] = await query('SELECT * FROM recompensas WHERE id=?', [rec.id]);
  res.json(act);
});

module.exports = router;
