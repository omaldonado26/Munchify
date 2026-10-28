// QUÉ HACE ESTE ARCHIVO
// Es la conexión con la base de datos MySQL. Mantiene un grupo de conexiones abiertas
// y ofrece dos funciones: query (ejecutar una consulta) y transaction (ejecutar varias
// consultas juntas, de modo que se guardan todas o ninguna).

const mysql = require('mysql2/promise');
const config = require('../config');

const pool = mysql.createPool({
  ...config.db,
  waitForConnections: true,
  connectionLimit: 10,
  dateStrings: true, // fechas como texto 'YYYY-MM-DD HH:mm:ss'
  timezone: 'local',
});

/** Ejecuta una consulta y devuelve las filas. */
async function query(sql, params = []) {
  const [rows] = await pool.query(sql, params);
  return rows;
}

/** Ejecuta `fn(conn)` dentro de una transacción. */
async function transaction(fn) {
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();
    const result = await fn(conn);
    await conn.commit();
    return result;
  } catch (err) {
    await conn.rollback();
    throw err;
  } finally {
    conn.release();
  }
}

module.exports = { pool, query, transaction };
