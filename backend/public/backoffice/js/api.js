const API_BASE = (() => {
  const path = window.location.pathname;
  const base = path.substring(0, path.indexOf('/backoffice/'));
  return (base || '') + '/api/v1';
})();

function getToken() {
  return localStorage.getItem('bo_token') || '';
}

function setToken(token) {
  localStorage.setItem('bo_token', token);
}

function clearToken() {
  localStorage.removeItem('bo_token');
  localStorage.removeItem('bo_user');
}

function getUser() {
  try {
    return JSON.parse(localStorage.getItem('bo_user') || '{}');
  } catch {
    return {};
  }
}

function setUser(user) {
  localStorage.setItem('bo_user', JSON.stringify(user));
}

async function apiPost(path, body) {
  const res = await fetch(API_BASE + path, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + getToken() },
    body: JSON.stringify(body),
  });
  return res.json().catch(() => ({ success: false, message: 'Error de red' }));
}

async function apiGet(path) {
  const res = await fetch(API_BASE + path, {
    headers: { 'Authorization': 'Bearer ' + getToken() },
  });
  return res.json().catch(() => ({ success: false, message: 'Error de red' }));
}

async function apiPut(path, body) {
  const res = await fetch(API_BASE + path, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + getToken() },
    body: JSON.stringify(body),
  });
  return res.json().catch(() => ({ success: false, message: 'Error de red' }));
}

async function apiDelete(path) {
  const res = await fetch(API_BASE + path, {
    method: 'DELETE',
    headers: { 'Authorization': 'Bearer ' + getToken() },
  });
  return res.json().catch(() => ({ success: false, message: 'Error de red' }));
}
