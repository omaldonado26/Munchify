const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const multer = require('multer');
const { UPLOAD_DIR } = require('./middleware/upload');
const { query } = require('./db/pool');

const app = express();

app.use(cors());
app.use(express.json({ limit: '1mb' }));
if (process.env.NODE_ENV !== 'test') app.use(morgan('dev'));

// Capturas de evidencias subidas por los clientes
app.use('/uploads', express.static(UPLOAD_DIR));

app.get('/api/salud', (_req, res) => res.json({ ok: true, servicio: 'Munchify API', hora: new Date().toISOString() }));

app.get('/api/categorias', async (_req, res) => {
  res.json(await query('SELECT id, nombre, icono FROM categorias ORDER BY id'));
});

app.use('/api/auth', require('./routes/auth'));
app.use('/api/campanas', require('./routes/campanas'));
app.use('/api/comercio', require('./routes/comercio'));
app.use('/api', require('./routes/cliente'));

app.use((_req, res) => res.status(404).json({ error: 'Ruta no encontrada' }));

// Manejador central de errores (Express 5 captura también errores async)
// eslint-disable-next-line no-unused-vars
app.use((err, _req, res, _next) => {
  if (err instanceof multer.MulterError) {
    const msg = err.code === 'LIMIT_FILE_SIZE' ? 'La imagen supera el máximo de 8 MB' : err.message;
    return res.status(400).json({ error: msg });
  }
  if (err.type === 'entity.parse.failed') return res.status(400).json({ error: 'JSON inválido' });
  const status = err.status || 500;
  if (status >= 500) console.error(err);
  res.status(status).json({ error: status >= 500 ? 'Error interno del servidor' : err.message });
});

module.exports = app;
