let clientesData = [];
let clientePage = 1;
let clienteTotalPages = 1;

async function initClientes() {
  clientePage = 1;
  await loadClientes();
}

async function loadClientes() {
  const busqueda = document.getElementById('busqueda-cliente')?.value.trim() ?? '';
  const qs = new URLSearchParams({ page: clientePage });
  if (busqueda) qs.append('busqueda', busqueda);

  const res = await apiGet('/backoffice/clientes?' + qs.toString());
  if (!res.success) {
    toast(res.message || 'Error al cargar clientes', 'error');
    return;
  }

  clientesData = res.data?.data ?? [];
  const meta = res.data?.meta ?? { page: 1, total: 0, pages: 1 };
  clientePage = meta.page;
  clienteTotalPages = meta.pages;
  renderTablaClientes(meta);
}

function renderTablaClientes(meta) {
  const tbody = document.getElementById('clientes-body');
  const cardContainer = document.getElementById('clientes-mobile-list');
  if (!tbody) return;

  if (clientesData.length === 0) {
    tbody.innerHTML = `<tr><td colspan="7" class="text-muted" style="text-align:center;padding:24px;">No hay clientes registrados</td></tr>`;
    if (cardContainer) cardContainer.innerHTML = '';
    document.getElementById('clientes-paginacion').innerHTML = '';
    return;
  }

  // Desktop table
  tbody.innerHTML = clientesData.map(c => `
    <tr>
      <td>#${c.id}</td>
      <td><strong>${escapeHtml(c.nombre)} ${escapeHtml(c.apellidos ?? '')}</strong></td>
      <td>${escapeHtml(c.telefono ?? '-')}</td>
      <td>${escapeHtml(c.telefono_alterno ?? '-')}</td>
      <td>${escapeHtml(c.email ?? '-')}</td>
      <td>${c.total_direcciones || 0}</td>
      <td style="text-align:right;white-space:nowrap">
        <button class="btn btn-sm btn-secondary" onclick="verCliente(${c.id})">Ver</button>
        <button class="btn btn-sm btn-secondary" onclick="editarCliente(${c.id})">Editar</button>
        <button class="btn btn-sm btn-danger" onclick="eliminarCliente(${c.id})">Eliminar</button>
      </td>
    </tr>
  `).join('');

  // Mobile cards
  if (cardContainer) {
    cardContainer.innerHTML = clientesData.map(c => `
      <div class="m-card">
        <div class="m-header">
          <strong>${escapeHtml(c.nombre)} ${escapeHtml(c.apellidos ?? '')}</strong>
        </div>
        <div class="m-row"><span class="m-label">Telefono</span><span class="m-value">${escapeHtml(c.telefono ?? '-')}</span></div>
        <div class="m-row"><span class="m-label">Email</span><span class="m-value">${escapeHtml(c.email ?? '-')}</span></div>
        <div class="m-row"><span class="m-label">Direcciones</span><span class="m-value">${c.total_direcciones || 0}</span></div>
        <div class="m-actions">
          <button class="btn btn-sm btn-secondary" onclick="verCliente(${c.id})">Ver</button>
          <button class="btn btn-sm btn-secondary" onclick="editarCliente(${c.id})">Editar</button>
          <button class="btn btn-sm btn-danger" onclick="eliminarCliente(${c.id})">Eliminar</button>
        </div>
      </div>
    `).join('');
  }

  const pag = document.getElementById('clientes-paginacion');
  if (pag) {
    let html = `<span style="color:var(--text-secondary);font-size:13px">Pagina ${meta.page} de ${meta.pages} (${meta.total} total)</span>`;
    if (meta.pages > 1) {
      html += `<div style="display:flex;gap:6px;margin-top:8px">`;
      if (meta.page > 1) html += `<button class="btn btn-sm btn-secondary" onclick="clientePage--; loadClientes()">Anterior</button>`;
      if (meta.page < meta.pages) html += `<button class="btn btn-sm btn-secondary" onclick="clientePage++; loadClientes()">Siguiente</button>`;
      html += `</div>`;
    }
    pag.innerHTML = html;
  }
}

async function verCliente(id) {
  const res = await apiGet('/backoffice/clientes/' + id);
  if (!res.success) {
    toast(res.message || 'Error al cargar cliente', 'error');
    return;
  }
  const c = res.data;
  const direcciones = (c.direcciones ?? []).map(d => `
    <div style="padding:10px;border:1px solid var(--border);border-radius:8px;margin-bottom:8px">
      <strong>${escapeHtml(d.alias ?? 'Direccion')}</strong>
      <p class="text-muted" style="margin:4px 0 0">${escapeHtml(d.calle ?? '')} ${escapeHtml(d.numero_exterior ?? '')}, ${escapeHtml(d.colonia ?? '')}, ${escapeHtml(d.ciudad ?? '')}</p>
    </div>
  `).join('') || '<p class="text-muted">Sin direcciones</p>';

  document.getElementById('modal-cliente-title').textContent = 'Detalle de Cliente';
  document.getElementById('modal-cliente-body').innerHTML = `
    <p><strong>Nombre:</strong> ${escapeHtml(c.nombre)} ${escapeHtml(c.apellidos ?? '')}</p>
    <p><strong>Telefono:</strong> ${escapeHtml(c.telefono ?? '-')}</p>
    <p><strong>Telefono alt:</strong> ${escapeHtml(c.telefono_alterno ?? '-')}</p>
    <p><strong>Email:</strong> ${escapeHtml(c.email ?? '-')}</p>
    <p><strong>Notas:</strong> ${escapeHtml(c.notas ?? '-')}</p>
    <hr style="margin:16px 0;border:none;border-top:1px solid var(--border)">
    <h4 style="margin-bottom:10px">Direcciones</h4>
    ${direcciones}
  `;
  document.getElementById('modal-cliente-footer').innerHTML = `<button class="btn btn-secondary" onclick="hideModal('modal-cliente')">Cerrar</button>`;
  showModal('modal-cliente');
}

function abrirModalCrearCliente() {
  document.getElementById('modal-cliente-title').textContent = 'Nuevo Cliente';
  document.getElementById('modal-cliente-body').innerHTML = `
    <form id="form-cliente" onsubmit="event.preventDefault(); guardarCliente();">
      <div class="form-group"><label>Nombre *</label><input type="text" id="cli-nombre" class="form-control" required></div>
      <div class="form-group"><label>Apellidos</label><input type="text" id="cli-apellidos" class="form-control"></div>
      <div class="form-group"><label>Telefono *</label><input type="text" id="cli-telefono" class="form-control" required></div>
      <div class="form-group"><label>Telefono alterno</label><input type="text" id="cli-telefono-alt" class="form-control"></div>
      <div class="form-group"><label>Email</label><input type="email" id="cli-email" class="form-control"></div>
      <div class="form-group"><label>Notas</label><textarea id="cli-notas" class="form-control" rows="2"></textarea></div>
      <hr style="margin:16px 0;border:none;border-top:1px solid var(--border)">
      <h4 style="margin-bottom:10px">Direccion principal</h4>
      <div class="form-group"><label>Alias</label><input type="text" id="dir-alias" class="form-control" value="Principal"></div>
      <div class="form-group"><label>Calle</label><input type="text" id="dir-calle" class="form-control"></div>
      <div class="form-group"><label>Numero exterior</label><input type="text" id="dir-num-ext" class="form-control"></div>
      <div class="form-group"><label>Numero interior</label><input type="text" id="dir-num-int" class="form-control"></div>
      <div class="form-group"><label>Colonia</label><input type="text" id="dir-colonia" class="form-control"></div>
      <div class="form-group"><label>Ciudad</label><input type="text" id="dir-ciudad" class="form-control"></div>
      <div class="form-group"><label>Estado</label><input type="text" id="dir-estado" class="form-control"></div>
      <div class="form-group"><label>Codigo postal</label><input type="text" id="dir-cp" class="form-control"></div>
      <div class="form-group"><label>Referencia</label><input type="text" id="dir-referencia" class="form-control"></div>
      <div class="form-group"><label>Instrucciones</label><input type="text" id="dir-instrucciones" class="form-control"></div>
    </form>
  `;
  document.getElementById('modal-cliente-footer').innerHTML = `
    <button type="button" class="btn btn-secondary" onclick="hideModal('modal-cliente')">Cancelar</button>
    <button type="button" class="btn btn-primary" onclick="guardarCliente()">Guardar</button>
  `;
  showModal('modal-cliente');
}

async function editarCliente(id) {
  const res = await apiGet('/backoffice/clientes/' + id);
  if (!res.success) {
    toast(res.message || 'Error al cargar cliente', 'error');
    return;
  }
  const c = res.data;
  document.getElementById('modal-cliente-title').textContent = 'Editar Cliente';
  document.getElementById('modal-cliente-body').innerHTML = `
    <form id="form-cliente" data-id="${c.id}" onsubmit="event.preventDefault(); guardarCliente(${c.id});">
      <div class="form-group"><label>Nombre *</label><input type="text" id="cli-nombre" class="form-control" value="${escapeHtml(c.nombre ?? '')}" required></div>
      <div class="form-group"><label>Apellidos</label><input type="text" id="cli-apellidos" class="form-control" value="${escapeHtml(c.apellidos ?? '')}"></div>
      <div class="form-group"><label>Telefono *</label><input type="text" id="cli-telefono" class="form-control" value="${escapeHtml(c.telefono ?? '')}" required></div>
      <div class="form-group"><label>Telefono alterno</label><input type="text" id="cli-telefono-alt" class="form-control" value="${escapeHtml(c.telefono_alterno ?? '')}"></div>
      <div class="form-group"><label>Email</label><input type="email" id="cli-email" class="form-control" value="${escapeHtml(c.email ?? '')}"></div>
      <div class="form-group"><label>Notas</label><textarea id="cli-notas" class="form-control" rows="2">${escapeHtml(c.notas ?? '')}</textarea></div>
    </form>
  `;
  document.getElementById('modal-cliente-footer').innerHTML = `
    <button type="button" class="btn btn-secondary" onclick="hideModal('modal-cliente')">Cancelar</button>
    <button type="button" class="btn btn-primary" onclick="guardarCliente(${c.id})">Guardar</button>
  `;
  showModal('modal-cliente');
}

async function guardarCliente(id) {
  const payload = {
    nombre: document.getElementById('cli-nombre')?.value.trim() ?? '',
    apellidos: document.getElementById('cli-apellidos')?.value.trim() ?? '',
    telefono: document.getElementById('cli-telefono')?.value.trim() ?? '',
    telefono_alterno: document.getElementById('cli-telefono-alt')?.value.trim() ?? '',
    email: document.getElementById('cli-email')?.value.trim() ?? '',
    notas: document.getElementById('cli-notas')?.value.trim() ?? '',
  };

  if (!payload.nombre) { toast('El nombre es obligatorio', 'error'); return; }
  if (!payload.telefono) { toast('El telefono es obligatorio', 'error'); return; }

  // Si es nuevo y hay direccion
  if (!id) {
    const dir = {
      alias: document.getElementById('dir-alias')?.value.trim() || 'Principal',
      calle: document.getElementById('dir-calle')?.value.trim() ?? '',
      numero_exterior: document.getElementById('dir-num-ext')?.value.trim() ?? '',
      numero_interior: document.getElementById('dir-num-int')?.value.trim() ?? '',
      colonia: document.getElementById('dir-colonia')?.value.trim() ?? '',
      ciudad: document.getElementById('dir-ciudad')?.value.trim() ?? '',
      estado: document.getElementById('dir-estado')?.value.trim() ?? '',
      codigo_postal: document.getElementById('dir-cp')?.value.trim() ?? '',
      referencia: document.getElementById('dir-referencia')?.value.trim() ?? '',
      instrucciones_entrega: document.getElementById('dir-instrucciones')?.value.trim() ?? '',
    };
    payload.direccion = dir;
  }

  let res;
  if (id) {
    res = await apiPut('/backoffice/clientes/' + id, payload);
  } else {
    res = await apiPost('/backoffice/clientes', payload);
  }

  if (res.success) {
    toast(id ? 'Cliente actualizado' : 'Cliente creado');
    hideModal('modal-cliente');
    await loadClientes();
  } else {
    const msg = res.errors ? Object.values(res.errors).join(', ') : (res.message || 'Error al guardar');
    toast(msg, 'error');
  }
}

async function eliminarCliente(id) {
  confirmDialog('¿Estas seguro de eliminar este cliente?', async () => {
    const res = await apiDelete('/backoffice/clientes/' + id);
    if (res.success) {
      toast('Cliente eliminado');
      await loadClientes();
    } else {
      toast(res.message || 'Error al eliminar', 'error');
    }
  });
}
