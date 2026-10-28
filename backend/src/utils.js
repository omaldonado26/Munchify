const crypto = require('crypto');

class HttpError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

const ALFABETO = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

function generarCodigo() {
  const bytes = crypto.randomBytes(8);
  let s = '';
  for (let i = 0; i < 8; i++) s += ALFABETO[bytes[i] % ALFABETO.length];
  return `MCH-${s.slice(0, 4)}-${s.slice(4)}`;
}

function requerir(obj, campos) {
  const faltan = campos.filter((c) => obj[c] === undefined || obj[c] === null || obj[c] === '');
  if (faltan.length) throw new HttpError(400, `Campos requeridos: ${faltan.join(', ')}`);
}

function entero(valor, porDefecto) {
  const n = parseInt(valor, 10);
  return Number.isNaN(n) ? porDefecto : n;
}

module.exports = { HttpError, generarCodigo, requerir, entero };
