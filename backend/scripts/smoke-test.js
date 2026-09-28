// Prueba de extremo a extremo del flujo principal de Munchify.
// Requiere la API corriendo (npm start) con los datos demo (npm run db:seed).
// Uso: npm run test:smoke   (o API_URL=http://host:3000/api npm run test:smoke)
const API = process.env.API_URL || 'http://localhost:3000/api';
let ok = 0;

function check(cond, msg) {
  if (!cond) throw new Error(`FALLÓ: ${msg}`);
  ok++;
  console.log(`  ✔ ${msg}`);
}

async function api(method, path, { token, body, form } = {}) {
  const headers = {};
  if (token) headers.Authorization = `Bearer ${token}`;
  if (body) headers['Content-Type'] = 'application/json';
  const res = await fetch(API + path, { method, headers, body: form || (body ? JSON.stringify(body) : undefined) });
  const data = await res.json().catch(() => ({}));
  return { status: res.status, data };
}

// PNG de 1x1 para simular una captura
const PNG = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==', 'base64');

(async () => {
  const sufijo = Date.now();
  console.log('Munchify smoke test →', API);

  const salud = await api('GET', '/salud');
  check(salud.status === 200, 'API responde');

  // 1. Registro de cliente y comercio
  const cli = await api('POST', '/auth/registro', {
    body: { nombre: 'Cliente Prueba', email: `cli${sufijo}@test.hn`, password: '123456', usuario_instagram: '@cli' },
  });
  check(cli.status === 201 && cli.data.token, 'registro de cliente');
  const tCli = cli.data.token;

  const com = await api('POST', '/auth/registro', {
    body: { nombre: 'Dueño', email: `com${sufijo}@test.hn`, password: '123456', rol: 'comercio',
            comercio: { nombre: 'Pizzería Prueba', categoria_id: 1 } },
  });
  check(com.status === 201 && com.data.usuario.comercio_id, 'registro de comercio con perfil');
  const tCom = com.data.token;

  const dup = await api('POST', '/auth/registro', { body: { nombre: 'x', email: `cli${sufijo}@test.hn`, password: '123456' } });
  check(dup.status === 409, 'rechaza correo duplicado');

  const login = await api('POST', '/auth/login', { body: { email: `cli${sufijo}@test.hn`, password: '123456' } });
  check(login.status === 200, 'login');
  const badLogin = await api('POST', '/auth/login', { body: { email: `cli${sufijo}@test.hn`, password: 'mala' } });
  check(badLogin.status === 401, 'login con contraseña incorrecta falla');

  // 2. Roles
  const noPermiso = await api('POST', '/campanas', { token: tCli, body: {} });
  check(noPermiso.status === 403, 'un cliente no puede crear campañas');

  // 3. Comercio crea campaña (manual, 2 cupones)
  const hoy = new Date().toISOString().slice(0, 10);
  const fin = new Date(Date.now() + 10 * 864e5).toISOString().slice(0, 10);
  const camp = await api('POST', '/campanas', {
    token: tCom,
    body: { titulo: '2x1 Pizza', beneficio: '2x1 en pizza mediana', condiciones: 'Sube historia', tipo_accion: 'historia',
            red_social: 'instagram', tipo_evidencia: 'captura', fecha_inicio: hoy, fecha_fin: fin,
            cantidad_disponible: 1, puntos_otorgados: 40 },
  });
  check(camp.status === 201 && camp.data.id, 'comercio crea campaña');
  const campId = camp.data.id;

  const lista = await api('GET', '/campanas', { token: tCli });
  check(lista.data.some((c) => c.id === campId), 'cliente ve la campaña vigente');

  const notifs = await api('GET', '/notificaciones', { token: tCli });
  check(notifs.data.items.some((n) => n.tipo === 'promocion'), 'cliente recibe notificación de nueva promoción');

  // 4. Evidencia
  const sinArchivo = await api('POST', `/campanas/${campId}/evidencias`, { token: tCli, form: (() => { const f = new FormData(); f.append('enlace', 'https://ig.com/x'); return f; })() });
  check(sinArchivo.status === 400, 'exige captura cuando la campaña lo requiere');

  const f = new FormData();
  f.append('captura', new Blob([PNG], { type: 'image/png' }), 'historia.png');
  f.append('comentario', 'Mi historia');
  const ev = await api('POST', `/campanas/${campId}/evidencias`, { token: tCli, form: f });
  check(ev.status === 201 && ev.data.estado === 'pendiente', 'cliente sube evidencia (pendiente)');

  const f2 = new FormData();
  f2.append('captura', new Blob([PNG], { type: 'image/png' }), 'otra.png');
  const ev2 = await api('POST', `/campanas/${campId}/evidencias`, { token: tCli, form: f2 });
  check(ev2.status === 409, 'no permite participar dos veces');

  // 5. Comercio valida
  const pend = await api('GET', '/comercio/evidencias?estado=pendiente', { token: tCom });
  check(pend.data.length === 1 && pend.data[0].archivo, 'comercio ve la evidencia pendiente con captura');

  const img = await fetch(API.replace(/\/api$/, '') + pend.data[0].archivo);
  check(img.status === 200, 'la captura es accesible');

  const apr = await api('POST', `/comercio/evidencias/${ev.data.evidencia_id}/aprobar`, { token: tCom });
  check(apr.status === 200 && /^MCH-[A-Z0-9]{4}-[A-Z0-9]{4}$/.test(apr.data.cupon.codigo), 'aprobación emite cupón con código único');
  const codigo = apr.data.cupon.codigo;

  const apr2 = await api('POST', `/comercio/evidencias/${ev.data.evidencia_id}/aprobar`, { token: tCom });
  check(apr2.status === 409, 'no se aprueba dos veces');

  const me = await api('GET', '/auth/me', { token: tCli });
  check(me.data.puntos === 40, 'cliente recibe los puntos');

  const lista2 = await api('GET', '/campanas', { token: tCli });
  check(!lista2.data.some((c) => c.id === campId), 'campaña agotada ya no aparece');

  // 6. Canje
  const misCupones = await api('GET', '/cupones', { token: tCli });
  check(misCupones.data.some((c) => c.codigo === codigo && c.estado === 'activo'), 'cupón aparece en "mis cupones"');

  const ver = await api('GET', `/comercio/cupones/${codigo.toLowerCase()}`, { token: tCom });
  check(ver.status === 200 && ver.data.canjeable === true, 'comercio verifica cupón (insensible a mayúsculas)');

  const otro = await api('POST', '/comercio/cupones/canjear', { token: (await api('POST', '/auth/login', { body: { email: 'burger@munchify.hn', password: '123456' } })).data.token, body: { codigo } });
  check(otro.status === 403, 'otro comercio no puede canjear el cupón');

  const canje = await api('POST', '/comercio/cupones/canjear', { token: tCom, body: { codigo } });
  check(canje.status === 200, 'comercio canjea cupón');
  const canje2 = await api('POST', '/comercio/cupones/canjear', { token: tCom, body: { codigo } });
  check(canje2.status === 409, 'evita reutilización del cupón');

  // 7. Métricas
  const met = await api('GET', '/comercio/metricas', { token: tCom });
  check(met.data.resumen.cupones_emitidos === 1 && met.data.resumen.cupones_canjeados === 1 && met.data.resumen.tasa_canje === 100,
    'métricas del comercio correctas');

  // 8. Recompensas con puntos
  const rec = await api('POST', '/comercio/recompensas', { token: tCom, body: { nombre: 'Refresco gratis', costo_puntos: 30, stock: 1 } });
  check(rec.status === 201, 'comercio crea recompensa');
  const canjeRec = await api('POST', `/recompensas/${rec.data.id}/canjear`, { token: tCli });
  check(canjeRec.status === 201 && canjeRec.data.puntos_restantes === 10, 'cliente canjea puntos por recompensa');
  const canjeRec2 = await api('POST', `/recompensas/${rec.data.id}/canjear`, { token: tCli });
  check(canjeRec2.status === 409, 'no permite canjear sin stock/puntos');

  // 9. Historial
  const hist = await api('GET', '/historial', { token: tCli });
  check(hist.data.resumen.cupones_obtenidos === 2 && hist.data.resumen.cupones_utilizados === 1 && hist.data.puntos.length === 2,
    'historial con participaciones, cupones y puntos');

  // 10. Validación automática (campaña demo "Café gratis por tu reseña")
  const auto = lista.data.find((c) => c.validacion_automatica === 1);
  if (auto) {
    const fa = new FormData();
    fa.append('enlace', 'https://maps.app.goo.gl/abc');
    const ea = await api('POST', `/campanas/${auto.id}/evidencias`, { token: tCli, form: fa });
    check(ea.status === 201 && ea.data.estado === 'aprobada' && ea.data.cupon, 'validación automática emite cupón al instante');
  }

  console.log(`\n✅ ${ok} verificaciones correctas`);
})().catch((e) => {
  console.error(`\n❌ ${e.message}`);
  process.exit(1);
});
