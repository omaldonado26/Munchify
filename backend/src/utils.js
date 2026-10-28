// QUÉ HACE ESTE ARCHIVO
// Funciones pequeñas que usan varias rutas: el error con código HTTP (HttpError),
// el generador de códigos de cupón (MCH-XXXX-XXXX), la validación de campos
// obligatorios y la conversión segura de textos a números enteros.

const crypto = require('crypto');

class HttpError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

// Sin caracteres ambiguos (0/O, 1/I/L) para facilitar el ingreso manual.
const ALFABETO = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

/** Genera un código de cupón tipo MCH-7K2P-QX9A. */
function generarCodigo() {
  const bytes = crypto.randomBytes(8);
  let s = '';
  for (let i = 0; i < 8; i++) s += ALFABETO[bytes[i] % ALFABETO.length];
  return `MCH-${s.slice(0, 4)}-${s.slice(4)}`;
}

/** Valida que existan los campos requeridos en un objeto. */
function requerir(obj, campos) {
  const faltan = campos.filter((c) => obj[c] === undefined || obj[c] === null || obj[c] === '');
  if (faltan.length) throw new HttpError(400, `Campos requeridos: ${faltan.join(', ')}`);
}

function entero(valor, porDefecto) {
  const n = parseInt(valor, 10);
  return Number.isNaN(n) ? porDefecto : n;
}

module.exports = { HttpError, generarCodigo, requerir, entero };
