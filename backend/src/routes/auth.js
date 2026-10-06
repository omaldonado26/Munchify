const router = require('express').Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const config = require('../config');
const { query, transaction } = require('../db/pool');
const { auth } = require('../middleware/auth');
const { HttpError, requerir } = require('../utils');
const crypto = require('crypto');
const { notificar } = require('../services/notificaciones');
const { firebaseAuth } = require('../services/firebase');

function firmar(usuario) {
  return jwt.sign({ id: usuario.id, rol: usuario.rol }, config.jwt.secret, { expiresIn: config.jwt.expires });
}

async function perfil(id) {
  const [u] = await query(
    `SELECT u.id, u.nombre, u.email, u.rol, u.telefono, u.usuario_instagram, u.puntos, u.creado_en,
            c.id AS comercio_id, c.nombre AS comercio_nombre, c.direccion AS comercio_direccion,
            c.categoria_id AS comercio_categoria_id, c.instagram AS comercio_instagram
       FROM usuarios u LEFT JOIN comercios c ON c.usuario_id = u.id WHERE u.id = ?`,
    [id]
  );
  return u;
}

/**
 * POST /api/auth/registro
 * Body cliente:  { nombre, email, password, telefono?, usuario_instagram? }
 * Body comercio: { ..., rol: 'comercio', comercio: { nombre, categoria_id, direccion?, telefono?, instagram? } }
 */
router.post('/registro', async (req, res) => {
  const b = req.body || {};
  requerir(b, ['nombre', 'email', 'password']);
  const rol = b.rol === 'comercio' ? 'comercio' : 'cliente';
  const email = String(b.email).trim().toLowerCase();
  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) throw new HttpError(400, 'Correo no válido');
  if (String(b.password).length < 6) throw new HttpError(400, 'La contraseña debe tener al menos 6 caracteres');
  if (rol === 'comercio') requerir(b.comercio || {}, ['nombre']);

  const [existe] = await query('SELECT id FROM usuarios WHERE email = ?', [email]);
  if (existe) throw new HttpError(409, 'Ya existe una cuenta con ese correo');

  const hash = await bcrypt.hash(String(b.password), 10);
  const id = await transaction(async (conn) => {
    const [r] = await conn.query(
      'INSERT INTO usuarios (nombre, email, password_hash, rol, telefono, usuario_instagram) VALUES (?,?,?,?,?,?)',
      [b.nombre.trim(), email, hash, rol, b.telefono || null, b.usuario_instagram || null]
    );
    if (rol === 'comercio') {
      const c = b.comercio;
      await conn.query(
        `INSERT INTO comercios (usuario_id, nombre, descripcion, direccion, telefono, instagram, categoria_id)
         VALUES (?,?,?,?,?,?,?)`,
        [r.insertId, c.nombre, c.descripcion || null, c.direccion || null, c.telefono || null,
         c.instagram || null, c.categoria_id || null]
      );
    }
    await notificar(r.insertId, '¡Bienvenido a Munchify!',
      rol === 'comercio'
        ? 'Crea tu primera campaña y convierte tus seguidores en clientes.'
        : 'Explora promociones, participa en redes y gana cupones y puntos.',
      'sistema', conn);
    return r.insertId;
  });

  const usuario = await perfil(id);
  res.status(201).json({ token: firmar(usuario), usuario });
});

/** POST /api/auth/login { email, password } */
router.post('/login', async (req, res) => {
  const b = req.body || {};
  requerir(b, ['email', 'password']);
  const [u] = await query('SELECT id, rol, password_hash, activo FROM usuarios WHERE email = ?', [
    String(b.email).trim().toLowerCase(),
  ]);
  if (!u || !(await bcrypt.compare(String(b.password), u.password_hash))) {
    throw new HttpError(401, 'Correo o contraseña incorrectos');
  }
  if (!u.activo) throw new HttpError(403, 'Cuenta desactivada');
  const usuario = await perfil(u.id);
  res.json({ token: firmar(usuario), usuario });
});

/**
 * POST /api/auth/google { idToken }
 * Inicia sesión con una cuenta de Google autenticada en Firebase (la app envía el ID token de Firebase).
 * Si el correo ya existe se entra a esa cuenta (cliente o comercio); si no, se crea una cuenta de cliente.
 * Devuelve el mismo JWT que el login con contraseña.
 */
router.post('/google', async (req, res) => {
  if (!firebaseAuth) throw new HttpError(503, 'El inicio de sesión con Google no está configurado en el servidor');
  requerir(req.body || {}, ['idToken']);

  let datos;
  try {
    datos = await firebaseAuth.verifyIdToken(String(req.body.idToken));
  } catch {
    throw new HttpError(401, 'No se pudo verificar tu cuenta de Google. Intenta de nuevo.');
  }
  if (datos.firebase?.sign_in_provider !== 'google.com') throw new HttpError(401, 'El token no proviene de Google');
  if (!datos.email || !datos.email_verified) throw new HttpError(401, 'Tu cuenta de Google no tiene un correo verificado');

  const email = datos.email.toLowerCase();
  let [u] = await query('SELECT id, activo FROM usuarios WHERE email = ?', [email]);
  let nuevo = false;

  if (!u) {
    // Cuenta nueva de cliente. La contraseña es aleatoria: esta persona entra siempre con Google.
    const hash = await bcrypt.hash(crypto.randomBytes(32).toString('hex'), 10);
    const nombre = (datos.name || email.split('@')[0]).slice(0, 120);
    const id = await transaction(async (conn) => {
      const [r] = await conn.query(
        'INSERT INTO usuarios (nombre, email, password_hash, rol) VALUES (?,?,?,?)',
        [nombre, email, hash, 'cliente']
      );
      await notificar(r.insertId, '¡Bienvenido a Munchify!',
        'Explora promociones, participa en redes y gana cupones y puntos.', 'sistema', conn);
      return r.insertId;
    });
    u = { id, activo: 1 };
    nuevo = true;
  }
  if (!u.activo) throw new HttpError(403, 'Cuenta desactivada');

  const usuario = await perfil(u.id);
  res.status(nuevo ? 201 : 200).json({ token: firmar(usuario), usuario });
});

/** GET /api/auth/me */
router.get('/me', auth, async (req, res) => {
  res.json(await perfil(req.user.id));
});

/** PUT /api/auth/me { nombre?, telefono?, usuario_instagram? } */
router.put('/me', auth, async (req, res) => {
  const b = req.body || {};
  await query(
    `UPDATE usuarios SET nombre = COALESCE(?, nombre), telefono = COALESCE(?, telefono),
            usuario_instagram = COALESCE(?, usuario_instagram) WHERE id = ?`,
    [b.nombre || null, b.telefono || null, b.usuario_instagram || null, req.user.id]
  );
  res.json(await perfil(req.user.id));
});

/** PUT /api/auth/fcm-token { token } — registra el token de Firebase del dispositivo */
router.put('/fcm-token', auth, async (req, res) => {
  await query('UPDATE usuarios SET fcm_token = ? WHERE id = ?', [req.body?.token || null, req.user.id]);
  res.json({ ok: true });
});

module.exports = router;
