let usuariosData = [];
let sucursalesList = [];
let rolesList = [];
let editingId = null;

async function initUsuarios() {
  await Promise.all([loadSucursales(), loadRoles()]);
  renderFiltros();
  await loadUsuarios();
}

async function loadSucursales() {
  const res = await apiGet('/backoffice/sucursales');
  sucursalesList = res.success && Array.isArray(res.data) ? res.data : [];
}

async function loadRoles() {
  const res = await apiGet('/backoffice/roles');
  rolesList = res.success && Array.isArray(res.data) ? res.data : [];
}

async function loadUsuarios() {
  const filtros = {};
  const s = document.getElementById('filtro-sucursal');
  const r = document.getElementById('filtro-rol');
  const b = document.getElementById('filtro-busqueda');
  if (s && s.value) filtros.sucursal_id = s.value;
  if (r && r.value) filtros.rol_id = r.value;
  if (b && b.value.trim()) filtros.busqueda = b.value.trim();

  const qs = new URLSearchParams(filtros).toString();
  const res = await apiGet('/backoffice/usuarios' + (qs ? '?' + qs : ''));
  usuariosData = res.success && Array.isArray(res.data) ? res.data : [];
  renderTabla();
}

function renderFiltros() {
  const s = document.getElementById('filtro-sucursal');
  const r = document.getElementById('filtro-rol');
  if (s) {
    s.innerHTML = '<option value="">Todas las sucursales</option>' +
      sucursalesList.map(x => `<option value="${x.id}">${escapeHtml(x.nombre)}</option>`).join('');
  }
  if (r) {
    r.innerHTML = '<option value="">Todos los roles</option>' +
      rolesList.map(x => `<option value="${x.id}">${escapeHtml(x.nombre)}</option>`).join('');
  }
}

function renderTabla() {
  const tbody = document.getElementById('usuarios-body');
  if (!tbody) return;

  if (usuariosData.length === 0) {
    tbody.innerHTML = `<tr><td colspan="7" class="text-muted" style="text-align:center;padding:24px;">No hay usuarios registrados</td></tr>`;
    return;
  }

  tbody.innerHTML = usuariosData.map(u => {
    const badgeClass = `badge-${u.rol_nombre || 'cajero'}`;
    return `
      <tr>
        <td>#${u.id}</td>
        <td>${escapeHtml(u.sucursal_nombre || '-')}</td>
        <td><strong>${escapeHtml(u.usuario)}</strong></td>
        <td>${escapeHtml(u.nombre || '')} ${escapeHtml(u.apellido || '')}</td>
        <td><span class="badge ${badgeClass}">${escapeHtml(u.rol_nombre)}</span></td>
        <td>${u.activo ? 'Activo' : 'Inactivo'}</td>
        <td style="text-align:right;white-space:nowrap;">
          <button class="btn btn-sm btn-secondary" onclick="editarUsuario(${u.id})">Editar</button>
          <button class="btn btn-sm btn-danger" onclick="eliminarUsuario(${u.id})">Eliminar</button>
        </td>
      </tr>
    `;
  }).join('');
}

function abrirModalCrear() {
  editingId = null;
  document.getElementById('modal-title').textContent = 'Nuevo Usuario';
  document.getElementById('form-usuario').reset();
  document.getElementById('password-help').textContent = '';
  renderSelectsModal();
  showModal('modal-usuario');
}

async function editarUsuario(id) {
  const res = await apiGet('/backoffice/usuarios/' + id);
  if (!res.success) {
    toast(res.message || 'Error al cargar usuario', 'error');
    return;
  }
  const u = res.data;
  editingId = u.id;
  document.getElementById('modal-title').textContent = 'Editar Usuario';
  document.getElementById('inp-usuario').value = u.usuario || '';
  document.getElementById('inp-nombre').value = u.nombre || '';
  document.getElementById('inp-apellido').value = u.apellido || '';
  document.getElementById('inp-email').value = u.email || '';
  document.getElementById('inp-rol').value = u.rol_id || '';
  document.getElementById('inp-sucursal').value = u.sucursal_id || '';
  document.getElementById('inp-activo').value = u.activo ? '1' : '0';
  document.getElementById('inp-password').value = '';
  document.getElementById('password-help').textContent = 'Dejar en blanco para mantener la contraseña actual';
  renderSelectsModal();
  showModal('modal-usuario');
}

function renderSelectsModal() {
  const s = document.getElementById('inp-sucursal');
  const r = document.getElementById('inp-rol');
  if (s) {
    s.innerHTML = '<option value="">Seleccionar...</option>' +
      sucursalesList.map(x => `<option value="${x.id}">${escapeHtml(x.nombre)}</option>`).join('');
  }
  if (r) {
    r.innerHTML = '<option value="">Seleccionar...</option>' +
      rolesList.map(x => `<option value="${x.id}">${escapeHtml(x.nombre)}</option>`).join('');
  }
}

async function guardarUsuario() {
  const payload = {
    usuario: document.getElementById('inp-usuario').value.trim(),
    nombre: document.getElementById('inp-nombre').value.trim(),
    apellido: document.getElementById('inp-apellido').value.trim(),
    email: document.getElementById('inp-email').value.trim(),
    rol_id: parseInt(document.getElementById('inp-rol').value) || 0,
    sucursal_id: parseInt(document.getElementById('inp-sucursal').value) || 0,
    activo: parseInt(document.getElementById('inp-activo').value),
  };
  const password = document.getElementById('inp-password').value;
  if (password) payload.password = password;

  if (!payload.usuario) { toast('El usuario es obligatorio', 'error'); return; }
  if (!payload.nombre) { toast('El nombre es obligatorio', 'error'); return; }
  if (!payload.rol_id) { toast('El rol es obligatorio', 'error'); return; }
  if (!payload.sucursal_id) { toast('La sucursal es obligatoria', 'error'); return; }
  if (!editingId && (!password || password.length < 6)) { toast('La contraseña debe tener al menos 6 caracteres', 'error'); return; }

  const btn = document.getElementById('btn-guardar');
  setLoading(btn, true);

  let res;
  if (editingId) {
    res = await apiPut('/backoffice/usuarios/' + editingId, payload);
  } else {
    res = await apiPost('/backoffice/usuarios', payload);
  }

  setLoading(btn, false);

  if (res.success) {
    toast(editingId ? 'Usuario actualizado' : 'Usuario creado');
    hideModal('modal-usuario');
    await loadUsuarios();
  } else {
    const msg = res.errors ? Object.values(res.errors).join(', ') : (res.message || 'Error al guardar');
    toast(msg, 'error');
  }
}

async function eliminarUsuario(id) {
  confirmDialog('¿Estas seguro? Esta accion no se puede deshacer.', async () => {
    const res = await apiDelete('/backoffice/usuarios/' + id);
    if (res.success) {
      toast('Usuario eliminado');
      await loadUsuarios();
    } else {
      toast(res.message || 'Error al eliminar', 'error');
    }
  });
}
