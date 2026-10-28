const fs = require('fs');
const path = require('path');
const mysql = require('mysql2/promise');
const config = require('../src/config');

(async () => {
  const sql = fs.readFileSync(path.join(__dirname, '..', 'src', 'db', 'schema.sql'), 'utf8')
    .replace(/\bmunchify\b(?=[\s;])/g, config.db.database);
  const { database, ...sinBD } = config.db;
  const conn = await mysql.createConnection({ ...sinBD, multipleStatements: true });
  await conn.query(sql);
  await conn.end();
  console.log(`✔ Base de datos "${database}" creada.`);
})().catch((e) => {
  console.error('✖ Error creando la base de datos:', e.message);
  process.exit(1);
});
