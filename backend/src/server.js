// QUÉ HACE ESTE ARCHIVO
// Es el punto de arranque del servidor (lo que corre con "npm start").
// Comprueba que MySQL responda, enciende la tarea automática de vencimientos
// y deja el servidor escuchando peticiones en el puerto configurado.

const app = require('./app');
const config = require('./config');
const { pool } = require('./db/pool');
const { iniciarTareaVencimientos } = require('./services/vencimientos');

async function main() {
  try {
    await pool.query('SELECT 1');
  } catch (e) {
    console.error('✖ No se pudo conectar a MySQL:', e.message);
    console.error('  Revisa las variables DB_* en el archivo .env y ejecuta "npm run db:init".');
    process.exit(1);
  }
  iniciarTareaVencimientos();
  app.listen(config.port, '0.0.0.0', () => {
    console.log(` Munchify API escuchando en http://localhost:${config.port}/api`);
  });
}

main();
