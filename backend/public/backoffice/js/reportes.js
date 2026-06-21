async function initReportes() {
  await loadSucursalesSelect('reporte-sucursal');
  const hoy = new Date().toISOString().split('T')[0];
  document.getElementById('fecha-inicio').value = hoy;
  document.getElementById('fecha-fin').value = hoy;
}

async function loadSucursalesSelect(id) {
  const res = await apiGet('/backoffice/sucursales');
  const el = document.getElementById(id);
  if (!el) return;
  const list = res.success && Array.isArray(res.data) ? res.data : [];
  el.innerHTML = '<option value="">Todas</option>' +
    list.map(x => `<option value="${x.id}">${escapeHtml(x.nombre)}</option>`).join('');
}

async function cargarReporte() {
  const btn = document.getElementById('btn-cargar-reporte');
  setLoading(btn, true);

  const fi = document.getElementById('fecha-inicio').value;
  const ff = document.getElementById('fecha-fin').value;
  const suc = document.getElementById('reporte-sucursal').value;

  if (!fi || !ff) {
    toast('Selecciona fecha inicio y fin', 'error');
    setLoading(btn, false);
    return;
  }

  const qs = new URLSearchParams({ fecha_inicio: fi, fecha_fin: ff });
  if (suc) qs.append('sucursal_id', suc);

  const res = await apiGet('/backoffice/reportes/modificadores?' + qs.toString());
  setLoading(btn, false);

  if (!res.success) {
    toast(res.message || 'Error al cargar reporte', 'error');
    return;
  }

  renderReporte(res.data);
}

function renderReporte(data) {
  const container = document.getElementById('reporte-resultados');
  const total = data.total_tickets || 0;

  if (total === 0) {
    container.innerHTML = `<div class="card"><p class="text-muted" style="text-align:center;padding:40px">No hay tickets en el periodo seleccionado</p></div>`;
    return;
  }

  const comp = data.complementos || {};

  const makeCard = (key, compData) => {
    if (!compData || compData.tickets_con_complemento === 0) return '';
    const pct = compData.porcentaje || 0;
    const con = compData.tickets_con_complemento;
    const tipos = compData.por_tipo || {};
    const tipoRows = Object.entries(tipos).map(([k, v]) => `
      <div class="m-row" style="padding:2px 0;font-size:12px">
        <span class="m-label">${escapeHtml(k)}</span>
        <span class="m-value">${v} ticket${v !== 1 ? 's' : ''}</span>
      </div>
    `).join('');

    return `
      <div class="card mb-4" style="flex:1;min-width:260px">
        <div class="card-header">
          <h3>${escapeHtml(compData.label)}</h3>
          <span style="font-size:24px;font-weight:700;color:var(--primary)">${pct}%</span>
        </div>
        <div style="padding:0 24px 16px">
          <p style="font-size:14px;color:var(--text-secondary);margin-bottom:12px">
            <strong style="color:var(--text);font-size:20px">${con}</strong> de <strong>${total}</strong> tickets
          </p>
          ${tipoRows ? `<div style="border-top:1px solid var(--border);padding-top:8px;margin-top:8px">${tipoRows}</div>` : ''}
        </div>
      </div>
    `;
  };

  const cards = Object.entries(comp)
    .filter(([_, c]) => c.tickets_con_complemento > 0)
    .map(([k, c]) => makeCard(k, c))
    .join('');

  const emptyState = !cards ? `<div class="card"><p class="text-muted" style="text-align:center;padding:40px">No se encontraron complementos en este periodo</p></div>` : '';

  container.innerHTML = `
    <div class="card mb-4" style="background:var(--primary);color:#fff">
      <div style="display:flex;justify-content:space-between;align-items:center;padding:20px 24px">
        <div>
          <h3 style="color:#fff;font-size:14px;font-weight:500;opacity:0.9">Total de Tickets</h3>
          <p style="font-size:32px;font-weight:700;margin-top:4px">${total.toLocaleString('es-MX')}</p>
        </div>
        <div style="text-align:right;opacity:0.9;font-size:13px">
          <p>${data.periodo.inicio || ''} - ${data.periodo.fin || ''}</p>
        </div>
      </div>
    </div>
    <div style="display:flex;gap:20px;flex-wrap:wrap">
      ${cards}
    </div>
    ${emptyState}
  `;
}
