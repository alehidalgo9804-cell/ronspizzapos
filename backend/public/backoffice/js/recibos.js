let reciboPage = 1;
let reciboPerPage = 50;

async function initRecibos() {
  await loadSucursalesSelect('recibo-sucursal');
  await loadMeserosSelect('recibo-mesero');
  const hoy = new Date().toISOString().split('T')[0];
  document.getElementById('recibo-fecha-inicio').value = hoy;
  document.getElementById('recibo-fecha-fin').value = hoy;
  loadRecibos();
}

async function loadMeserosSelect(id) {
  const res = await apiGet('/backoffice/usuarios');
  const el = document.getElementById(id);
  if (!el) return;
  const list = res.success && Array.isArray(res.data) ? res.data : [];
  el.innerHTML = '<option value="">Todos los meseros</option>' +
    list.map(x => `<option value="${x.id}">${escapeHtml(x.nombre || x.usuario)}</option>`).join('');
}

async function loadRecibos() {
  const btn = document.getElementById('btn-cargar-recibos');
  if (btn) setLoading(btn, true);

  const fi = document.getElementById('recibo-fecha-inicio').value;
  const ff = document.getElementById('recibo-fecha-fin').value;
  const suc = document.getElementById('recibo-sucursal').value;
  const mes = document.getElementById('recibo-mesero').value;
  const est = document.getElementById('recibo-estado').value;
  const search = document.getElementById('recibo-busqueda').value;

  const qs = new URLSearchParams({ page: String(reciboPage), per_page: String(reciboPerPage) });
  if (fi) qs.append('fecha_inicio', fi);
  if (ff) qs.append('fecha_fin', ff);
  if (suc) qs.append('sucursal_id', suc);
  if (mes) qs.append('usuario_id', mes);
  if (est) qs.append('estado', est);
  if (search) qs.append('search', search);

  const res = await apiGet('/backoffice/recibos?' + qs.toString());
  if (btn) setLoading(btn, false);

  if (!res.success) {
    toast(res.message || 'Error al cargar recibos', 'error');
    return;
  }

  renderRecibos(res.data.data || [], res.data.meta || {});
}

function fmtMoney(n) {
  return '$' + Number(n || 0).toLocaleString('es-MX', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

function fmtDate(d) {
  if (!d) return '-';
  const dt = new Date(d.replace(' ', 'T'));
  return dt.toLocaleDateString('es-MX', { day: 'numeric', month: 'short', year: 'numeric' }) +
    ' ' + dt.toLocaleTimeString('es-MX', { hour: '2-digit', minute: '2-digit' });
}

function badgeClass(estado) {
  const map = {
    'completado': 'badge-success',
    'pagado': 'badge-success',
    'cancelado': 'badge-danger',
    'eliminado': 'badge-danger',
    'abierto': 'badge-warning',
    'pendiente': 'badge-warning',
    'en_preparacion': 'badge-info',
    'listo': 'badge-info',
  };
  return map[estado] || 'badge-secondary';
}

function renderRecibos(rows, meta) {
  const tableWrap = document.getElementById('recibos-table-wrap');
  const mobileList = document.getElementById('recibos-mobile-list');
  const pagEl = document.getElementById('recibos-paginacion');

  if (!rows.length) {
    if (tableWrap) tableWrap.innerHTML = '<div class="text-center text-muted" style="padding:40px">No hay recibos</div>';
    if (mobileList) mobileList.innerHTML = '';
    if (pagEl) pagEl.innerHTML = '';
    return;
  }

  // Desktop: table
  if (tableWrap) {
    tableWrap.innerHTML = `
      <table>
        <thead>
          <tr><th># Ticket</th><th>Mesero</th><th>Fecha</th><th style="text-align:right">Cantidad</th><th style="text-align:right">Descuento</th><th>Estatus</th><th style="text-align:right">Detalles</th></tr>
        </thead>
        <tbody id="recibos-body">
          ${rows.map(r => {
            const mesero = [r.mesero_nombre, r.mesero_apellido].filter(Boolean).join(' ');
            return `
              <tr>
                <td style="font-weight:600">${escapeHtml(r.folio)}</td>
                <td>${escapeHtml(mesero) || '-'}</td>
                <td>${fmtDate(r.fecha_pedido)}</td>
                <td style="text-align:right;font-weight:600">${fmtMoney(r.total)}</td>
                <td style="text-align:right;color:var(--danger)">${Number(r.descuento_total || 0) > 0 ? '-' + fmtMoney(r.descuento_total) : '-'}</td>
                <td><span class="badge ${badgeClass(r.estado)}">${escapeHtml(r.estado)}</span></td>
                <td style="text-align:right">
                  <button class="btn btn-sm btn-primary" onclick="verDetalleRecibo(${r.id})">Detalles</button>
                </td>
              </tr>
            `;
          }).join('')}
        </tbody>
      </table>
    `;
  }

  // Mobile: cards
  if (mobileList) {
    mobileList.innerHTML = rows.map(r => {
      const mesero = [r.mesero_nombre, r.mesero_apellido].filter(Boolean).join(' ');
      return `
        <div class="m-card">
          <div class="m-header">
            <strong>${escapeHtml(r.folio)}</strong>
            <span class="badge ${badgeClass(r.estado)}">${escapeHtml(r.estado)}</span>
          </div>
          <div class="m-row"><span class="m-label">Mesero</span><span class="m-value">${escapeHtml(mesero) || '-'}</span></div>
          <div class="m-row"><span class="m-label">Fecha</span><span class="m-value">${fmtDate(r.fecha_pedido)}</span></div>
          <div class="m-row"><span class="m-label">Total</span><span class="m-value" style="font-weight:600;font-size:14px">${fmtMoney(r.total)}</span></div>
          ${Number(r.descuento_total || 0) > 0 ? `
          <div class="m-row"><span class="m-label">Descuento</span><span class="m-value" style="color:var(--danger)">-${fmtMoney(r.descuento_total)}</span></div>` : ''}
          <div class="m-footer">
            <span class="text-muted" style="font-size:12px">${escapeHtml(r.sucursal_nombre || '')}</span>
            <button class="btn btn-sm btn-primary" onclick="verDetalleRecibo(${r.id})">Detalles</button>
          </div>
        </div>
      `;
    }).join('');
  }

  // Pagination
  const totalPages = meta.total_pages || 1;
  const start = ((meta.page || 1) - 1) * (meta.per_page || 50) + 1;
  const end = Math.min(start + rows.length - 1, meta.total || 0);
  if (pagEl) {
    pagEl.innerHTML = `
      <div style="display:flex;justify-content:space-between;align-items:center;margin-top:16px;flex-wrap:wrap;gap:8px">
        <span class="text-muted" style="font-size:13px">${start}-${end} de ${meta.total}</span>
        <div style="display:flex;gap:8px">
          <button class="btn btn-sm btn-secondary" ${meta.page <= 1 ? 'disabled' : ''} onclick="reciboPage--;loadRecibos()">Anterior</button>
          <span class="text-muted" style="align-self:center;font-size:13px">${meta.page}/${totalPages}</span>
          <button class="btn btn-sm btn-secondary" ${meta.page >= totalPages ? 'disabled' : ''} onclick="reciboPage++;loadRecibos()">Siguiente</button>
        </div>
      </div>
    `;
  }
}

async function verDetalleRecibo(id) {
  const res = await apiGet('/backoffice/recibos/' + id);
  if (!res.success) {
    toast(res.message || 'Error al cargar detalle', 'error');
    return;
  }
  renderDetalleModal(res.data);
  showModal('modal-recibo');
}

function formatConfig(tipo, jsonStr) {
  if (!jsonStr) return '';
  try {
    const c = JSON.parse(jsonStr);
    const parts = [];

    if (tipo === 'pizza_builder') {
      const halves = [];
      if (c.half1 && c.half2) {
        halves.push('1/2 ' + c.half1);
        halves.push('1/2 ' + c.half2);
      } else if (c.specialty) {
        halves.push(c.specialty);
      }
      if (halves.length) parts.push(halves.join(' / '));
      if (c.size) parts.push(c.size);
      if (c.breadType && c.breadType !== 'Regular') parts.push(c.breadType);
      if (c.crustEdge && c.crustEdge !== 'Ninguna' && c.crustEdge !== '-') parts.push('Orilla ' + c.crustEdge);
      if (Array.isArray(c.ingredients) && c.ingredients.length) parts.push(c.ingredients.join(', '));
      if (Array.isArray(c.extraIngredients) && c.extraIngredients.length) parts.push('Extra: ' + c.extraIngredients.join(', '));
      if (c.dorada) parts.push('Dorada');
    }

    else if (tipo === 'spaghetti_builder') {
      if (c.spaghettiType) parts.push(c.spaghettiType);
      if (c.accompaniment && c.accompaniment !== '-') parts.push(c.accompaniment);
      if (c.garlicBreadType && c.garlicBreadType !== 'Normales') parts.push(c.garlicBreadType);
      if (c.quesoDorado) parts.push('Queso dorado');
      if (Array.isArray(c.extras) && c.extras.length) parts.push('Extra: ' + c.extras.join(', '));
      if (c.sinQueso) parts.push('Sin queso');
      if (c.sinMantequilla) parts.push('Sin mantequilla');
      if (c.pocaSalsa) parts.push('Poca salsa');
    }

    else if (tipo === 'wings_builder') {
      if (c.size && c.size !== 'orden') parts.push(c.size);
      if (c.sauceMode === 'mitad') {
        if (c.sauceHalf1) parts.push('1/2 ' + c.sauceHalf1);
        if (c.sauceHalf2) parts.push('1/2 ' + c.sauceHalf2);
      } else if (c.sauce) {
        parts.push(c.sauce);
      }
      if (c.boneType && c.boneType !== 'naturales') parts.push(c.boneType);
      if (c.juicy) parts.push('Jugosas');
      if (c.doradas) parts.push('Doradas');
      if (c.naturales) parts.push('Naturales');
      if (c.sinApio) parts.push('Sin apio');
      if (c.sinZanahoria) parts.push('Sin zanahoria');
      if (c.sauceOnSide) parts.push('Salsa aparte');
    }

    else if (tipo === 'hamburger_builder') {
      if (c.burgerType) parts.push(c.burgerType);
      if (c.side && c.side !== 'sinPapas') parts.push(c.side);
      if (Array.isArray(c.extraIngredients) && c.extraIngredients.length) parts.push('Extra: ' + c.extraIngredients.join(', '));
      if (c.cutOption && c.cutOption !== 'completa') parts.push(c.cutOption);
      if (c.usedSinVerduraQuickAction) parts.push('Sin verdura');
    }

    if (parts.length === 0) return '';
    return '<div style="font-size:12px;color:var(--muted);margin-top:2px">' + escapeHtml(parts.join(' · ')) + '</div>';
  } catch (e) {
    return '';
  }
}

function renderDetalleModal(data) {
  const mesero = [data.mesero_nombre, data.mesero_apellido].filter(Boolean).join(' ');
  const items = data.items || [];

  const itemsHtml = items.length
    ? items.map(it => {
        const configHtml = formatConfig(it.config_builder_tipo, it.config_builder_json);
        const cleanName = (it.nombre_snapshot || '')
          .replace(/\s*configurables?\s*$/i, '')
          .replace(/\s+/g, ' ')
          .trim();
        return `
        <tr>
          <td>
            <div style="font-weight:500">${escapeHtml(cleanName)}</div>
            ${configHtml}
          </td>
          <td style="text-align:right;white-space:nowrap">${fmtMoney(it.precio_unitario)}</td>
          <td style="text-align:right">${Number(it.cantidad).toLocaleString('es-MX', {minimumFractionDigits:0,maximumFractionDigits:3})}</td>
          <td style="text-align:right;font-weight:600;white-space:nowrap">${fmtMoney(it.total_linea)}</td>
        </tr>
      `;
      }).join('')
    : '<tr><td colspan="4" class="text-center text-muted">Sin productos</td></tr>';

  let envioHtml = '';
  if (Number(data.envio_total || 0) > 0) {
    envioHtml = `
      <tr style="border-top:2px solid var(--border)">
        <td colspan="3" style="text-align:right">Envio:</td>
        <td style="text-align:right;font-weight:600">${fmtMoney(data.envio_total)}</td>
      </tr>`;
  }

  let descHtml = '';
  if (Number(data.descuento_total || 0) > 0) {
    descHtml = `
      <tr>
        <td colspan="3" style="text-align:right;color:var(--danger)">Descuento:</td>
        <td style="text-align:right;color:var(--danger);font-weight:600">-${fmtMoney(data.descuento_total)}</td>
      </tr>`;
  }

  const body = document.getElementById('modal-recibo-body');
  body.innerHTML = `
    <div style="margin-bottom:16px">
      <div style="display:flex;gap:24px;flex-wrap:wrap;font-size:14px">
        <div><strong>Ticket:</strong> ${escapeHtml(data.folio)}</div>
        <div><strong>Mesero:</strong> ${escapeHtml(mesero) || '-'}</div>
        <div><strong>Fecha:</strong> ${fmtDate(data.fecha_pedido)}</div>
        <div><strong>Tipo:</strong> ${escapeHtml(data.tipo_pedido)}</div>
        <div><span class="badge ${badgeClass(data.estado)}">${escapeHtml(data.estado)}</span></div>
      </div>
    </div>
    <div class="table-wrap">
      <table>
        <thead>
          <tr><th>Producto</th><th style="text-align:right">Precio</th><th style="text-align:right">Cantidad</th><th style="text-align:right">Subtotal</th></tr>
        </thead>
        <tbody>
          ${itemsHtml}
          ${descHtml}
          ${envioHtml}
          <tr style="border-top:2px solid var(--border)">
            <td colspan="3" style="text-align:right;font-size:16px;font-weight:700">Total:</td>
            <td style="text-align:right;font-size:16px;font-weight:700">${fmtMoney(data.total)}</td>
          </tr>
        </tbody>
      </table>
    </div>
  `;
}
