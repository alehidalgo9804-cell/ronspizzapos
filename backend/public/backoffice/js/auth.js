function requireAuth() {
  const token = getToken();
  if (!token) {
    window.location.href = './index.html';
    return false;
  }
  return true;
}

async function checkSession() {
  const token = getToken();
  if (!token) return false;
  const res = await apiGet('/backoffice/me');
  if (res.success) {
    setUser(res.data);
    renderUserInfo();
    return true;
  }
  clearToken();
  window.location.href = './index.html';
  return false;
}

async function login(usuario, password) {
  const res = await apiPost('/backoffice/login', { usuario, password, plataforma: 'backoffice' });
  if (res.success && res.data?.token) {
    setToken(res.data.token);
    setUser(res.data.user);
    return { success: true };
  }
  return { success: false, message: res.message || 'Credenciales invalidas' };
}

async function logout() {
  await apiPost('/backoffice/logout', {});
  clearToken();
  window.location.href = './index.html';
}

function renderUserInfo() {
  const user = getUser();
  const el = document.getElementById('user-info');
  if (el) {
    el.innerHTML = `<strong>${escapeHtml(user.nombre || '')}</strong><span>${escapeHtml(user.rol || '')}</span>`;
  }
}
