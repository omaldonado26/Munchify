const { query } = require('../db/pool');
const { notificar } = require('./notificaciones');

async function procesarVencimientos() {
  const vencidos = await query(
    "SELECT id, usuario_id, codigo, beneficio FROM cupones WHERE estado='activo' AND fecha_vencimiento < NOW()"
  );
  if (vencidos.length) {
    await query('UPDATE cupones SET estado=\'vencido\' WHERE id IN (?)', [vencidos.map((c) => c.id)]);
    for (const c of vencidos) {
      await notificar(c.usuario_id, 'Cupón vencido', `Tu cupón ${c.codigo} (${c.beneficio}) ha vencido.`, 'cupon');
    }
  }

  await query(
    `UPDATE campanas SET estado='finalizada'
      WHERE estado <> 'finalizada' AND (fecha_fin < CURDATE() OR cupones_emitidos >= cantidad_disponible)`
  );

  const porVencer = await query(
    `SELECT c.id, c.usuario_id, c.codigo, c.beneficio FROM cupones c
      WHERE c.estado='activo' AND c.fecha_vencimiento BETWEEN NOW() AND DATE_ADD(NOW(), INTERVAL 1 DAY)
        AND NOT EXISTS (SELECT 1 FROM notificaciones n
                         WHERE n.usuario_id=c.usuario_id AND n.titulo='Tu cupón vence pronto'
                           AND n.mensaje LIKE CONCAT('%', c.codigo, '%'))`
  );
  for (const c of porVencer) {
    await notificar(c.usuario_id, 'Tu cupón vence pronto', `El cupón ${c.codigo} (${c.beneficio}) vence en menos de 24 horas.`, 'cupon');
  }

  return { vencidos: vencidos.length, recordatorios: porVencer.length };
}

function iniciarTareaVencimientos(intervaloMs = 60 * 60 * 1000) {
  const run = () => procesarVencimientos().catch((e) => console.error('Vencimientos:', e.message));
  run();
  return setInterval(run, intervaloMs);
}

module.exports = { procesarVencimientos, iniciarTareaVencimientos };
