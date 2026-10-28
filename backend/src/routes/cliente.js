const router = require('express').Router();
const { query, transaction } = require('../db/pool');
const { auth, role } = require('../middleware/auth');
const { HttpError } = require('../utils');
const { insertarCupon, moverPuntos } = require('../services/cupones');
const { notificar } = require('../services/notificaciones');

router.use(auth);

router.get('/cupones', role('cliente'), async (req, res) => {
  const params = [req.user.id];
  let filtro = '';
  if (req.query.estado) { filtro = 'AND cu.estado = ?'; params.push(req.query.estado); }
  const rows = await query(
    `SELECT cu.id, cu.codigo, cu.origen, cu.beneficio, cu.estado, cu.fecha_emision, cu.fecha_vencimiento,
            cu.fecha_canje, co.nombre AS comercio_nombre, co.direccion AS comercio_direccion,
            c.titulo AS campana_titulo, r.nombre AS recompensa_nombre
       FROM cupones cu
       JOIN comercios co ON co.id = cu.comercio_id
       LEFT JOIN campanas c ON c.id = cu.campana_id
       LEFT JOIN recompensas r ON r.id = cu.recompensa_id
      WHERE cu.usuario_id = ? ${filtro}
      ORDER BY cu.estado='activo' DESC, cu.fecha_emision DESC`,
    params
  );
  res.json(rows);
});

router.get('/historial', role('cliente'), async (req, res) => {
  const [participaciones, cupones, puntos, [resumen]] = await Promise.all([
    query(
      `SELECT e.id, e.estado, e.motivo_rechazo, e.creado_en, e.revisado_en,
              c.id AS campana_id, c.titulo AS campana_titulo, c.beneficio, co.nombre AS comercio_nombre
         FROM evidencias e JOIN campanas c ON c.id=e.campana_id JOIN comercios co ON co.id=c.comercio_id
        WHERE e.usuario_id=? ORDER BY e.creado_en DESC`,
      [req.user.id]
    ),
    query(
      `SELECT cu.id, cu.codigo, cu.beneficio, cu.estado, cu.origen, cu.fecha_emision, cu.fecha_vencimiento,
              cu.fecha_canje, co.nombre AS comercio_nombre
         FROM cupones cu JOIN comercios co ON co.id=cu.comercio_id
        WHERE cu.usuario_id=? ORDER BY cu.fecha_emision DESC`,
      [req.user.id]
    ),
    query('SELECT id, puntos, concepto, creado_en FROM movimientos_puntos WHERE usuario_id=? ORDER BY creado_en DESC, id DESC', [req.user.id]),
    query(
      `SELECT u.puntos,
              (SELECT COUNT(*) FROM evidencias WHERE usuario_id=u.id) AS participaciones,
              (SELECT COUNT(*) FROM cupones WHERE usuario_id=u.id) AS cupones_obtenidos,
              (SELECT COUNT(*) FROM cupones WHERE usuario_id=u.id AND estado='canjeado') AS cupones_utilizados,
              (SELECT COUNT(*) FROM cupones WHERE usuario_id=u.id AND estado='vencido') AS cupones_vencidos
         FROM usuarios u WHERE u.id=?`,
      [req.user.id]
    ),
  ]);
  res.json({ resumen, participaciones, cupones, puntos });
});

router.get('/recompensas', async (_req, res) => {
  const rows = await query(
    `SELECT r.id, r.nombre, r.descripcion, r.costo_puntos, r.stock, r.vigencia_dias,
            co.id AS comercio_id, co.nombre AS comercio_nombre
       FROM recompensas r JOIN comercios co ON co.id=r.comercio_id
      WHERE r.activa=1 AND r.stock > 0 ORDER BY r.costo_puntos`
  );
  res.json(rows);
});

router.post('/recompensas/:id/canjear', role('cliente'), async (req, res) => {
  const resultado = await transaction(async (conn) => {
    const [[rec]] = await conn.query('SELECT * FROM recompensas WHERE id=? AND activa=1 FOR UPDATE', [req.params.id]);
    if (!rec) throw new HttpError(404, 'Recompensa no disponible');
    if (rec.stock < 1) throw new HttpError(409, 'Recompensa agotada');
    const [[u]] = await conn.query('SELECT puntos FROM usuarios WHERE id=? FOR UPDATE', [req.user.id]);
    if (u.puntos < rec.costo_puntos) {
      throw new HttpError(409, `Puntos insuficientes: tienes ${u.puntos} y necesitas ${rec.costo_puntos}`);
    }

    const cupon = await insertarCupon(conn, {
      origen: 'recompensa',
      recompensa_id: rec.id,
      comercio_id: rec.comercio_id,
      usuario_id: req.user.id,
      beneficio: rec.nombre,
      dias: rec.vigencia_dias,
    });
    await conn.query('UPDATE recompensas SET stock = stock - 1 WHERE id=?', [rec.id]);
    await moverPuntos(conn, req.user.id, -rec.costo_puntos, `Canje de recompensa: ${rec.nombre}`, cupon.id);
    await notificar(req.user.id, 'Recompensa canjeada',
      `Cambiaste ${rec.costo_puntos} puntos por "${rec.nombre}". Cupón ${cupon.codigo}.`, 'puntos', conn);
    return { cupon, puntos_restantes: u.puntos - rec.costo_puntos };
  });
  res.status(201).json(resultado);
});

router.get('/notificaciones', async (req, res) => {
  const rows = await query(
    'SELECT id, titulo, mensaje, tipo, leida, creado_en FROM notificaciones WHERE usuario_id=? ORDER BY creado_en DESC, id DESC LIMIT 100',
    [req.user.id]
  );
  const noLeidas = rows.filter((n) => !n.leida).length;
  res.json({ no_leidas: noLeidas, items: rows });
});

router.patch('/notificaciones/leer-todas', async (req, res) => {
  await query('UPDATE notificaciones SET leida=1 WHERE usuario_id=?', [req.user.id]);
  res.json({ ok: true });
});

router.patch('/notificaciones/:id/leida', async (req, res) => {
  await query('UPDATE notificaciones SET leida=1 WHERE id=? AND usuario_id=?', [req.params.id, req.user.id]);
  res.json({ ok: true });
});

module.exports = router;
