const jwt = require('jsonwebtoken');
const config = require('../config');
const { query } = require('../db/pool');
const { HttpError } = require('../utils');

async function auth(req, _res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) throw new HttpError(401, 'Token requerido');

  let payload;
  try {
    payload = jwt.verify(token, config.jwt.secret);
  } catch {
    throw new HttpError(401, 'Token inválido o expirado');
  }

  const [user] = await query(
    `SELECT u.id, u.nombre, u.email, u.rol, u.puntos, u.activo, c.id AS comercio_id
       FROM usuarios u LEFT JOIN comercios c ON c.usuario_id = u.id
      WHERE u.id = ?`,
    [payload.id]
  );
  if (!user || !user.activo) throw new HttpError(401, 'Usuario no válido');
  req.user = user;
  next();
}

function role(...roles) {
  return (req, _res, next) => {
    if (!roles.includes(req.user.rol)) throw new HttpError(403, 'No tienes permiso para esta acción');
    if (req.user.rol === 'comercio' && !req.user.comercio_id) {
      throw new HttpError(403, 'Tu usuario no tiene un comercio asociado');
    }
    next();
  };
}

module.exports = { auth, role };
