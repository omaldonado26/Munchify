const router = require('express').Router();
const { query, transaction } = require('../db/pool');
const { auth, role } = require('../middleware/auth');
const { upload } = require('../middleware/upload');
const { HttpError, requerir, entero } = require('../utils');
const { aprobarEvidencia } = require('../services/cupones');
const { notificar, notificarAClientes } = require('../services/notificaciones');

const CAMPOS_CAMPANA = `
  c.id, c.comercio_id, c.categoria_id, c.titulo, c.descripcion, c.beneficio, c.condiciones,
  c.tipo_accion, c.red_social, c.tipo_evidencia, c.validacion_automatica, c.fecha_inicio, c.fecha_fin,
  c.vigencia_cupon_dias, c.cantidad_disponible, c.cupones_emitidos,
  (c.cantidad_disponible - c.cupones_emitidos) AS cupones_restantes,
  c.puntos_otorgados, c.imagen_url, c.estado, c.creado_en,
  co.nombre AS comercio_nombre, co.direccion AS comercio_direccion, co.instagram AS comercio_instagram,
  cat.nombre AS categoria_nombre`;

const JOINS = `FROM campanas c
  JOIN comercios co ON co.id = c.comercio_id
  LEFT JOIN categorias cat ON cat.id = c.categoria_id`;

const VIGENTE = `c.estado='activa' AND CURDATE() BETWEEN c.fecha_inicio AND c.fecha_fin
                 AND c.cupones_emitidos < c.cantidad_disponible`;

router.use(auth);

/**
 * GET /api/campanas?categoria_id=&q=
 * Promociones vigentes (para clientes). Incluye el estado de participación del usuario.
 */
router.get('/', async (req, res) => {
  const where = [VIGENTE];
  const params = [req.user.id];
  if (req.query.categoria_id) {
    where.push('c.categoria_id = ?');
    params.push(entero(req.query.categoria_id, 0));
  }
  if (req.query.q) {
    where.push('(c.titulo LIKE ? OR c.beneficio LIKE ? OR co.nombre LIKE ?)');
    const q = `%${req.query.q}%`;
    params.push(q, q, q);
  }
  const rows = await query(
    `SELECT ${CAMPOS_CAMPANA}, e.estado AS mi_participacion
     ${JOINS}
     LEFT JOIN evidencias e ON e.campana_id = c.id AND e.usuario_id = ?
     WHERE ${where.join(' AND ')}
     ORDER BY c.fecha_fin ASC, c.id DESC`,
    params
  );
  res.json(rows);
});

/** GET /api/campanas/:id — detalle + mi evidencia/cupón (si soy cliente) */
router.get('/:id', async (req, res) => {
  const [camp] = await query(`SELECT ${CAMPOS_CAMPANA} ${JOINS} WHERE c.id = ?`, [req.params.id]);
  if (!camp) throw new HttpError(404, 'Campaña no encontrada');
  const [evidencia] = await query(
    'SELECT id, estado, enlace, archivo, comentario, motivo_rechazo, creado_en FROM evidencias WHERE campana_id=? AND usuario_id=?',
    [camp.id, req.user.id]
  );
  const [cupon] = await query(
    "SELECT id, codigo, estado, fecha_vencimiento FROM cupones WHERE campana_id=? AND usuario_id=? AND origen='campana'",
    [camp.id, req.user.id]
  );
  res.json({ ...camp, mi_evidencia: evidencia || null, mi_cupon: cupon || null });
});

function datosCampana(b) {
  return [
    b.categoria_id || null, b.titulo, b.descripcion || null, b.beneficio, b.condiciones || null,
    b.tipo_accion || 'historia', b.red_social || 'instagram', b.tipo_evidencia || 'cualquiera',
    b.validacion_automatica ? 1 : 0, b.fecha_inicio, b.fecha_fin, entero(b.vigencia_cupon_dias, 7),
    entero(b.cantidad_disponible, 100), entero(b.puntos_otorgados, 10), b.imagen_url || null,
  ];
}

function validarCampana(b) {
  requerir(b, ['titulo', 'beneficio', 'fecha_inicio', 'fecha_fin']);
  if (b.fecha_fin < b.fecha_inicio) throw new HttpError(400, 'La fecha fin debe ser posterior a la de inicio');
  if (b.cantidad_disponible !== undefined && entero(b.cantidad_disponible, 0) < 1) {
    throw new HttpError(400, 'La cantidad disponible debe ser mayor a 0');
  }
}

/** POST /api/campanas — crea una campaña (comercio) y avisa a los clientes */
router.post('/', role('comercio'), async (req, res) => {
  const b = req.body || {};
  validarCampana(b);
  const [co] = await query('SELECT nombre, categoria_id FROM comercios WHERE id=?', [req.user.comercio_id]);
  if (!b.categoria_id) b.categoria_id = co.categoria_id;

  const r = await query(
    `INSERT INTO campanas (categoria_id, titulo, descripcion, beneficio, condiciones, tipo_accion, red_social,
       tipo_evidencia, validacion_automatica, fecha_inicio, fecha_fin, vigencia_cupon_dias, cantidad_disponible,
       puntos_otorgados, imagen_url, comercio_id)
     VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)`,
    [...datosCampana(b), req.user.comercio_id]
  );

  // Notificación masiva de nueva promoción a los clientes (in-app + push)
  await notificarAClientes(`Nueva promo en ${co.nombre}`, `${b.titulo}: ${b.beneficio}`);

  const [camp] = await query(`SELECT ${CAMPOS_CAMPANA} ${JOINS} WHERE c.id=?`, [r.insertId]);
  res.status(201).json(camp);
});

async function campanaPropia(req) {
  const [camp] = await query('SELECT * FROM campanas WHERE id=?', [req.params.id]);
  if (!camp) throw new HttpError(404, 'Campaña no encontrada');
  if (req.user.rol !== 'admin' && camp.comercio_id !== req.user.comercio_id) {
    throw new HttpError(403, 'La campaña no pertenece a tu comercio');
  }
  return camp;
}

/** PUT /api/campanas/:id — edita la campaña */
router.put('/:id', role('comercio', 'admin'), async (req, res) => {
  const actual = await campanaPropia(req);
  const b = { ...actual, ...req.body };
  validarCampana(b);
  if (entero(b.cantidad_disponible, 0) < actual.cupones_emitidos) {
    throw new HttpError(400, `Ya se emitieron ${actual.cupones_emitidos} cupones; la cantidad no puede ser menor`);
  }
  await query(
    `UPDATE campanas SET categoria_id=?, titulo=?, descripcion=?, beneficio=?, condiciones=?, tipo_accion=?,
       red_social=?, tipo_evidencia=?, validacion_automatica=?, fecha_inicio=?, fecha_fin=?,
       vigencia_cupon_dias=?, cantidad_disponible=?, puntos_otorgados=?, imagen_url=?
     WHERE id=?`,
    [...datosCampana(b), actual.id]
  );
  const [camp] = await query(`SELECT ${CAMPOS_CAMPANA} ${JOINS} WHERE c.id=?`, [actual.id]);
  res.json(camp);
});

/** PATCH /api/campanas/:id/estado { estado: activa|pausada|finalizada } */
router.patch('/:id/estado', role('comercio', 'admin'), async (req, res) => {
  const camp = await campanaPropia(req);
  const estado = req.body?.estado;
  if (!['activa', 'pausada', 'finalizada'].includes(estado)) throw new HttpError(400, 'Estado no válido');
  await query('UPDATE campanas SET estado=? WHERE id=?', [estado, camp.id]);
  res.json({ id: camp.id, estado });
});

/**
 * POST /api/campanas/:id/evidencias  (multipart/form-data)
 * Campos: captura (archivo imagen), enlace, comentario
 * El cliente registra la evidencia de su acción en redes sociales.
 */
router.post('/:id/evidencias', role('cliente'), upload.single('captura'), async (req, res) => {
  const b = req.body || {};
  const [camp] = await query(`SELECT c.* FROM campanas c WHERE c.id=? AND ${VIGENTE}`, [req.params.id]);
  if (!camp) throw new HttpError(400, 'La campaña no está disponible (vencida, pausada o agotada)');

  const enlace = b.enlace ? String(b.enlace).trim() : null;
  const archivo = req.file ? `/uploads/${req.file.filename}` : null;
  if (enlace && !/^https?:\/\//i.test(enlace)) throw new HttpError(400, 'El enlace debe iniciar con http:// o https://');
  if (camp.tipo_evidencia === 'captura' && !archivo) throw new HttpError(400, 'Esta campaña requiere una captura de pantalla');
  if (camp.tipo_evidencia === 'enlace' && !enlace) throw new HttpError(400, 'Esta campaña requiere el enlace de la publicación');
  if (!archivo && !enlace) throw new HttpError(400, 'Adjunta una captura o el enlace de tu publicación');

  const resultado = await transaction(async (conn) => {
    let evidenciaId;
    try {
      const [r] = await conn.query(
        'INSERT INTO evidencias (campana_id, usuario_id, enlace, archivo, comentario) VALUES (?,?,?,?,?)',
        [camp.id, req.user.id, enlace, archivo, b.comentario || null]
      );
      evidenciaId = r.insertId;
    } catch (e) {
      if (e.code === 'ER_DUP_ENTRY') throw new HttpError(409, 'Ya participaste en esta campaña');
      throw e;
    }

    if (camp.validacion_automatica) {
      const cupon = await aprobarEvidencia(conn, evidenciaId, null);
      return { evidencia_id: evidenciaId, estado: 'aprobada', cupon };
    }

    const [[co]] = await conn.query('SELECT usuario_id FROM comercios WHERE id=?', [camp.comercio_id]);
    await notificar(co.usuario_id, 'Nueva evidencia por revisar',
      `${req.user.nombre} participó en "${camp.titulo}".`, 'evidencia', conn);
    return { evidencia_id: evidenciaId, estado: 'pendiente', cupon: null };
  });

  res.status(201).json(resultado);
});

module.exports = router;
