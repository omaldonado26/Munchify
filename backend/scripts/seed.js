// QUÉ HACE ESTE ARCHIVO
// Carga datos de demostración (comercios, clientes, campañas y recompensas) para
// poder probar la app sin crear todo a mano (npm run db:seed).

// Carga datos de demostración: 3 comercios, 2 clientes, campañas, recompensas y actividad.
// Contraseña de todos los usuarios demo: 123456
const bcrypt = require('bcryptjs');
const { pool, transaction } = require('../src/db/pool');
const { aprobarEvidencia } = require('../src/services/cupones');

const hoy = new Date();
const fecha = (dias) => {
  const d = new Date(hoy);
  d.setDate(d.getDate() + dias);
  return d.toISOString().slice(0, 10);
};

(async () => {
  const hash = await bcrypt.hash('123456', 10);

  await transaction(async (conn) => {
    const [[{ n }]] = await conn.query('SELECT COUNT(*) AS n FROM usuarios');
    if (n > 0) throw new Error('La base ya tiene datos. Ejecuta "npm run db:init" para reiniciarla.');

    const usuario = async (nombre, email, rol, ig = null) => {
      const [r] = await conn.query(
        'INSERT INTO usuarios (nombre, email, password_hash, rol, usuario_instagram) VALUES (?,?,?,?,?)',
        [nombre, email, hash, rol, ig]
      );
      return r.insertId;
    };
    const comercio = async (uid, nombre, cat, dir, ig, desc) => {
      const [r] = await conn.query(
        'INSERT INTO comercios (usuario_id, nombre, categoria_id, direccion, instagram, descripcion) VALUES (?,?,?,?,?,?)',
        [uid, nombre, cat, dir, ig, desc]
      );
      return r.insertId;
    };
    const campana = async (c) => {
      const [r] = await conn.query(
        `INSERT INTO campanas (comercio_id, categoria_id, titulo, descripcion, beneficio, condiciones, tipo_accion,
           red_social, tipo_evidencia, validacion_automatica, fecha_inicio, fecha_fin, vigencia_cupon_dias,
           cantidad_disponible, puntos_otorgados) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)`,
        [c.comercio, c.cat, c.titulo, c.desc, c.beneficio, c.cond, c.accion, c.red, c.evid, c.auto ? 1 : 0,
         fecha(c.inicio ?? -3), fecha(c.fin ?? 20), c.vig ?? 7, c.cant ?? 100, c.pts ?? 10]
      );
      return r.insertId;
    };

    await usuario('Administrador Munchify', 'admin@munchify.hn', 'admin');

    const uBurger = await usuario('Carlos Reyes', 'burger@munchify.hn', 'comercio');
    const uCafe = await usuario('María López', 'cafe@munchify.hn', 'comercio');
    const uModa = await usuario('Andrea Paz', 'moda@munchify.hn', 'comercio');

    const burger = await comercio(uBurger, 'Burger Station SPS', 1, 'Barrio Río de Piedras, San Pedro Sula', '@burgerstation.sps', 'Hamburguesas artesanales a la parrilla.');
    const cafe = await comercio(uCafe, 'Café Aroma', 2, 'Col. Trejo, San Pedro Sula', '@cafearoma.hn', 'Café de altura hondureño.');
    const moda = await comercio(uModa, 'Urban Style', 3, 'City Mall, San Pedro Sula', '@urbanstyle.hn', 'Ropa urbana para toda ocasión.');

    const c1 = await campana({ comercio: burger, cat: 1, titulo: '2x1 en hamburguesas clásicas',
      desc: 'Comparte tu experiencia en Burger Station y llévate otra hamburguesa gratis.',
      beneficio: '2x1 en hamburguesa clásica', cond: 'Sube una historia en Instagram mencionando a @burgerstation.sps',
      accion: 'historia', red: 'instagram', evid: 'captura', pts: 20, cant: 50 });
    const c2 = await campana({ comercio: cafe, cat: 2, titulo: 'Café gratis por tu reseña',
      desc: 'Déjanos una reseña en Google Maps.', beneficio: 'Café americano gratis',
      cond: 'Publica una reseña de Café Aroma en Google Maps y comparte el enlace.', accion: 'resena',
      red: 'google', evid: 'enlace', auto: true, pts: 15 });
    await campana({ comercio: moda, cat: 3, titulo: '15% de descuento por seguirnos',
      desc: 'Síguenos en TikTok y obtén descuento en tu próxima compra.', beneficio: '15% de descuento en toda la tienda',
      cond: 'Sigue a @urbanstyle.hn en TikTok y envía captura de pantalla.', accion: 'seguir', red: 'tiktok',
      evid: 'captura', pts: 10, vig: 14 });
    await campana({ comercio: burger, cat: 1, titulo: 'Papas gratis con tu post',
      desc: 'Publica una foto de tu combo en tu feed.', beneficio: 'Papas medianas gratis',
      cond: 'Publica una foto en tu feed de Instagram etiquetando a @burgerstation.sps.', accion: 'publicacion',
      red: 'instagram', evid: 'cualquiera', pts: 25, cant: 30 });

    await conn.query(
      `INSERT INTO recompensas (comercio_id, nombre, descripcion, costo_puntos, stock) VALUES
        (?, 'Postre gratis', 'Brownie con helado', 30, 20),
        (?, 'Capuccino grande', 'Cualquier sabor', 25, 40),
        (?, 'Gorra Urban Style', 'Edición limitada', 80, 10)`,
      [burger, cafe, moda]
    );

    // Clientes demo con algo de actividad
    const ana = await usuario('Ana Martínez', 'ana@munchify.hn', 'cliente', '@ana.mtz');
    await usuario('Luis Castillo', 'luis@munchify.hn', 'cliente', '@luisc');

    const [e1] = await conn.query(
      "INSERT INTO evidencias (campana_id, usuario_id, enlace, comentario) VALUES (?,?,?,?)",
      [c1, ana, 'https://instagram.com/stories/ana.mtz/123', '¡Deliciosa!']
    );
    await aprobarEvidencia(conn, e1.insertId, uBurger);
    const [e2] = await conn.query(
      'INSERT INTO evidencias (campana_id, usuario_id, enlace) VALUES (?,?,?)',
      [c2, ana, 'https://maps.app.goo.gl/resena-demo']
    );
    await aprobarEvidencia(conn, e2.insertId, null);
  });

  console.log('✔ Datos de demostración cargados. Contraseña de todos: 123456');
  console.log('  Comercios: burger@munchify.hn · cafe@munchify.hn · moda@munchify.hn');
  console.log('  Clientes:  ana@munchify.hn · luis@munchify.hn');
  await pool.end();
})().catch(async (e) => {
  console.error('✖', e.message);
  await pool.end();
  process.exit(1);
});
