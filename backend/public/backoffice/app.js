(() => {
  'use strict';

  const STORAGE_KEY = 'rons_backoffice_session_v1';
  const DEFAULT_ROUTE_ID = 'reportes-ventas';
  const DEFAULT_ROUTE_PATH = '/reportes/ventas';

  const state = {
    apiBase: resolveApiBase(),
    backofficeBasePath: resolveBackofficeBasePath(),
    session: null,
    currentModule: DEFAULT_ROUTE_ID,
    expandedGroups: {
      reports: true,
    },
    realtimeTimer: null,
    realtimeModule: null,
    reportFilters: {
      from: '',
      to: '',
      categoria: '',
      meseroId: '',
    },
    reportLookups: null,
    salesView: {
      seriesMode: 'day',
      top: 10,
      preset: 'this_month',
    },
    receiptsView: {
      preset: 'this_month',
      from: '',
      to: '',
      search: '',
      meseroId: '',
      paymentType: '',
      status: '',
      channel: '',
      page: 1,
      perPage: 20,
      sort: 'opened_at',
      dir: 'desc',
    },
    customersView: {
      preset: 'this_month',
      from: '',
      to: '',
      search: '',
      page: 1,
      perPage: 20,
    },
  };

  const REALTIME_MODULES = {
    'reportes-ventas': 300000,
    'reportes-recibos': 300000,
    'reportes-clientes': 300000,
    'reportes-analisis-abc': 300000,
  };

  const refs = {
    loginScreen: document.getElementById('login-screen'),
    appScreen: document.getElementById('app-screen'),
    loginForm: document.getElementById('login-form'),
    loginStatus: document.getElementById('login-status'),
    moduleNav: document.getElementById('module-nav'),
    moduleTitle: document.getElementById('module-title'),
    moduleSubtitle: document.getElementById('module-subtitle'),
    moduleContent: document.getElementById('module-content'),
    sessionBadge: document.getElementById('session-badge'),
    logoutBtn: document.getElementById('logout-btn'),
  };

  const MODULES = [
    {
      id: 'reportes-ventas',
      path: '/reportes/ventas',
      label: 'Ventas',
      title: 'Reportes',
      subtitle: 'Ventas',
      parentId: 'reports',
      permission: 'reportes.ventas',
      render: renderReportsSales,
    },
    {
      id: 'reportes-recibos',
      path: '/reportes/recibos',
      label: 'Recibos',
      title: 'Reportes',
      subtitle: 'Recibos',
      parentId: 'reports',
      permission: 'reportes.recibos',
      render: renderReportsReceipts,
    },
    {
      id: 'reportes-clientes',
      path: '/reportes/clientes',
      label: 'Clientes',
      title: 'Reportes',
      subtitle: 'Clientes',
      parentId: 'reports',
      permission: 'reportes.clientes',
      render: renderReportsCustomers,
    },
    {
      id: 'reportes-analisis-abc',
      path: '/reportes/analisis-abc',
      label: 'Análisis ABC',
      title: 'Reportes',
      subtitle: 'Análisis ABC',
      parentId: 'reports',
      permission: 'reportes.analisis_abc',
      render: renderReportsAnalysisAbc,
    },
    {
      id: 'branches',
      path: '/administracion/sucursales',
      label: 'Sucursales',
      title: 'Administración',
      subtitle: 'Sucursales',
      parentId: 'admin',
      permission: 'admin.sucursales',
      render: () => renderCrud(CRUD.branches),
    },
    {
      id: 'employees',
      path: '/administracion/empleados',
      label: 'Empleados',
      title: 'Administración',
      subtitle: 'Empleados',
      parentId: 'admin',
      permission: 'admin.empleados',
      render: () => renderCrud(CRUD.employees),
    },
    {
      id: 'users',
      path: '/administracion/usuarios',
      label: 'Usuarios',
      title: 'Administración',
      subtitle: 'Usuarios',
      parentId: 'admin',
      permission: 'admin.usuarios',
      render: () => renderCrud(CRUD.users),
    },
    {
      id: 'roles',
      path: '/administracion/roles',
      label: 'Roles y permisos',
      title: 'Administración',
      subtitle: 'Roles y permisos',
      parentId: 'admin',
      permission: 'admin.roles',
      render: renderRoles,
    },
    {
      id: 'customers',
      path: '/clientes/clientes',
      label: 'Clientes',
      title: 'Clientes',
      subtitle: 'Gestión de clientes',
      parentId: 'customers-group',
      permission: 'clientes.listado',
      render: renderReportsCustomers,
    },
    {
      id: 'customer-groups',
      path: '/clientes/grupo-clientes',
      label: 'Grupo de clientes',
      title: 'Clientes',
      subtitle: 'Grupo de clientes',
      parentId: 'customers-group',
      permission: 'clientes.grupos',
      render: renderCustomerGroups,
    },
    {
      id: 'customer-rewards',
      path: '/clientes/recompensas',
      label: 'Recompensas',
      title: 'Clientes',
      subtitle: 'Recompensas',
      parentId: 'customers-group',
      permission: 'clientes.recompensas',
      render: renderCustomerRewards,
    },
    {
      id: 'categories',
      path: '/productos/categorias',
      label: 'Categorías',
      title: 'Productos',
      subtitle: 'Categorías de productos',
      parentId: 'products-group',
      permission: 'productos.categorias',
      render: () => renderCrud(CRUD.categories),
    },
    {
      id: 'products',
      path: '/productos/listado',
      label: 'Productos',
      title: 'Productos',
      subtitle: 'Productos del menú',
      parentId: 'products-group',
      permission: 'productos.listado',
      render: () => renderCrud(CRUD.products),
    },
    {
      id: 'ingredients',
      path: '/productos/ingredientes',
      label: 'Ingredientes',
      title: 'Productos',
      subtitle: 'Ingredientes del sistema',
      parentId: 'products-group',
      permission: 'productos.ingredientes',
      render: () => renderCrud(CRUD.ingredients),
    },
    {
      id: 'promotions',
      path: '/promociones',
      label: 'Promociones',
      title: 'Productos',
      subtitle: 'Promociones activas',
      parentId: 'products-group',
      permission: 'productos.promociones',
      render: () => renderCrud(CRUD.promotions),
    },
    {
      id: 'settings-general',
      path: '/configuracion/general',
      label: 'General',
      title: 'Configuración',
      subtitle: 'General',
      parentId: 'settings-group',
      permission: 'configuracion.general',
      render: renderSettings,
    },
    {
      id: 'settings-receipt',
      path: '/configuracion/recibo',
      label: 'Recibo',
      title: 'Configuración',
      subtitle: 'Recibo',
      parentId: 'settings-group',
      permission: 'configuracion.recibo',
      render: renderSettingsReceipt,
    },
    {
      id: 'settings-security',
      path: '/configuracion/seguridad',
      label: 'Seguridad',
      title: 'Configuración',
      subtitle: 'Seguridad',
      parentId: 'settings-group',
      permission: 'configuracion.seguridad',
      render: renderSettingsSecurity,
    },
    {
      id: 'settings-tables',
      path: '/configuracion/mesas',
      label: 'Mesas',
      title: 'Configuración',
      subtitle: 'Mesas',
      parentId: 'settings-group',
      permission: 'configuracion.mesas',
      render: renderSettingsTables,
    },
  ];
  const MODULES_BY_ID = new Map(MODULES.map((m) => [m.id, m]));
  const MODULES_BY_PATH = new Map(MODULES.map((m) => [m.path, m]));
  const SIDEBAR_ITEMS = [
    {
      id: 'reports',
      label: 'REPORTES',
      children: ['reportes-ventas', 'reportes-recibos', 'reportes-clientes', 'reportes-analisis-abc'],
    },
    {
      id: 'admin',
      label: 'ADMINISTRACIÓN',
      children: ['branches', 'employees', 'users', 'roles'],
    },
    {
      id: 'products-group',
      label: 'PRODUCTOS',
      children: ['categories', 'products', 'ingredients', 'promotions'],
    },
    {
      id: 'customers-group',
      label: 'CLIENTES',
      children: ['customers', 'customer-groups', 'customer-rewards'],
    },
    {
      id: 'settings-group',
      label: 'CONFIGURACIÓN',
      children: ['settings-general', 'settings-receipt', 'settings-security', 'settings-tables'],
    },
  ];

  init();

  function init() {
    refs.loginForm.addEventListener('submit', onLoginSubmit);
    refs.logoutBtn.addEventListener('click', onLogout);
    window.addEventListener('popstate', onPopState);
    ensureDefaultRouteUrl();

    const restored = loadSession();
    if (restored) {
      state.session = restored;
      showApp();
      selectModule(resolveModuleIdFromLocation(), { replaceHistory: true });
    } else {
      showLogin();
    }
  }

  function resolveApiBase() {
    const p = window.location.pathname;
    const i = p.indexOf('/backoffice');
    const root = i >= 0 ? p.slice(0, i) : p.replace(/\/[^/]*$/, '');
    return `${window.location.origin}${root}/api/v1`;
  }

  function resolveBackofficeBasePath() {
    const cleanPath = window.location.pathname.replace(/\/index\.html$/, '');
    const marker = '/backoffice';
    const i = cleanPath.indexOf(marker);
    if (i < 0) return marker;
    return cleanPath.slice(0, i + marker.length);
  }

  function onPopState() {
    if (!state.session) return;
    selectModule(resolveModuleIdFromLocation(), { skipHistory: true });
  }

  function ensureDefaultRouteUrl() {
    const currentPath = window.location.pathname.replace(/\/index\.html$/, '');
    const isRootPath = currentPath === state.backofficeBasePath || currentPath === `${state.backofficeBasePath}/`;
    if (!isRootPath) return;
    window.history.replaceState({}, '', `${state.backofficeBasePath}${DEFAULT_ROUTE_PATH}`);
  }

  function showLogin() {
    stopRealtimeRefresh();
    refs.loginScreen.classList.remove('hidden');
    refs.appScreen.classList.add('hidden');
  }

  function showApp() {
    refs.loginScreen.classList.add('hidden');
    refs.appScreen.classList.remove('hidden');
    renderNav();
    renderSessionBadge();
  }

  function renderNav() {
    refs.moduleNav.innerHTML = '';
    SIDEBAR_ITEMS.forEach((item) => {
      if (Array.isArray(item.children) && item.children.length) {
        const groupNode = renderNavGroup(item);
        if (groupNode) refs.moduleNav.appendChild(groupNode);
      } else if (MODULES_BY_ID.has(item.id)) {
        const module = MODULES_BY_ID.get(item.id);
        if (canAccessModule(module)) {
          refs.moduleNav.appendChild(createNavButton(item.id));
        }
      }
    });
  }

  function renderNavGroup(group) {
    const visibleChildren = group.children.filter((childId) => {
      if (!MODULES_BY_ID.has(childId)) return false;
      return canAccessModule(MODULES_BY_ID.get(childId));
    });
    if (!visibleChildren.length) return null;

    const wrapper = document.createElement('div');
    wrapper.className = 'nav-group';

    const activeChildId = visibleChildren.find((childId) => childId === state.currentModule);
    const hasStoredState = Object.prototype.hasOwnProperty.call(state.expandedGroups, group.id);
    if (!hasStoredState) {
      state.expandedGroups[group.id] = Boolean(activeChildId);
    }

    const expanded = Boolean(state.expandedGroups[group.id]);

    const toggle = document.createElement('button');
    toggle.type = 'button';
    toggle.className = `group-toggle${expanded ? ' expanded' : ''}${activeChildId ? ' active' : ''}`;
    toggle.innerHTML = `<span>${escapeHtml(group.label)}</span><span class="chevron">&#9662;</span>`;
    toggle.addEventListener('click', () => {
      state.expandedGroups[group.id] = !Boolean(state.expandedGroups[group.id]);
      renderNav();
    });

    const submenu = document.createElement('div');
    submenu.className = `nav-submenu${expanded ? ' expanded' : ''}`;
    submenu.style.display = expanded ? 'flex' : 'none';
    visibleChildren.forEach((childId) => {
      if (MODULES_BY_ID.has(childId)) {
        submenu.appendChild(createNavButton(childId, { child: true }));
      }
    });

    wrapper.appendChild(toggle);
    wrapper.appendChild(submenu);
    return wrapper;
  }

  function createNavButton(moduleId, options = {}) {
    const m = MODULES_BY_ID.get(moduleId);
    const btn = document.createElement('button');
    btn.type = 'button';
    btn.className = `nav-item${options.child ? ' child' : ''}${moduleId === state.currentModule ? ' active' : ''}`;
    btn.textContent = m.label;
    btn.addEventListener('click', () => selectModule(moduleId));
    return btn;
  }

  function canAccessModule(module) {
    if (!module) return false;
    if (!module.permission) return true;
    const permissionSource = state.session?.user?.permissions || state.session?.user?.permisos || [];
    if (!Array.isArray(permissionSource) || !permissionSource.length) return true;
    return permissionSource.includes('*')
      || permissionSource.includes(module.permission)
      || permissionSource.includes('reportes.*');
  }

  function renderSessionBadge() {
    const u = state.session?.user || {};
    refs.sessionBadge.textContent = `${safe(u.nombre)} ${safe(u.apellido)} · ${safe(u.rol)} · Sucursal ${state.session?.branchId || ''}`;
  }

  function resolveModuleIdFromLocation() {
    const routePath = resolveRoutePathFromLocation();
    const m = MODULES_BY_PATH.get(routePath);
    const preferredId = m?.id || DEFAULT_ROUTE_ID;
    const preferredModule = MODULES_BY_ID.get(preferredId);
    if (preferredModule && canAccessModule(preferredModule)) {
      return preferredId;
    }
    const fallback = MODULES.find((module) => canAccessModule(module));
    return fallback?.id || DEFAULT_ROUTE_ID;
  }

  function resolveRoutePathFromLocation() {
    const currentPath = window.location.pathname.replace(/\/index\.html$/, '');
    let routePath = currentPath.startsWith(state.backofficeBasePath)
      ? currentPath.slice(state.backofficeBasePath.length)
      : currentPath;

    if (!routePath || routePath === '/') {
      return DEFAULT_ROUTE_PATH;
    }

    if (!routePath.startsWith('/')) {
      routePath = `/${routePath}`;
    }

    routePath = routePath.replace(/\/+$/, '');
    return routePath || DEFAULT_ROUTE_PATH;
  }

  function syncHistory(m, replaceHistory = false) {
    const targetPath = `${state.backofficeBasePath}${m.path}`;
    const currentPath = window.location.pathname.replace(/\/index\.html$/, '');
    if (currentPath === targetPath) return;
    const method = replaceHistory ? 'replaceState' : 'pushState';
    window.history[method]({ routeId: m.id }, '', targetPath);
  }

  async function selectModule(id, options = {}) {
    const m = MODULES_BY_ID.get(id);
    if (!m) return;
    if (!canAccessModule(m)) {
      refs.moduleContent.innerHTML = '<div class="error-box">No tienes permiso para acceder a este módulo.</div>';
      return;
    }
    stopRealtimeRefresh();
    state.currentModule = id;
    if (m.parentId) {
      state.expandedGroups[m.parentId] = true;
    }
    if (!options.skipHistory) {
      syncHistory(m, Boolean(options.replaceHistory));
    }
    renderNav();
    refs.moduleTitle.textContent = m.title;
    refs.moduleSubtitle.textContent = m.subtitle;
    refs.moduleContent.innerHTML = '<div class="loading">Cargando...</div>';
    try {
      await m.render();
      startRealtimeRefresh(id);
    } catch (error) {
      refs.moduleContent.innerHTML = `<div class="error-box">${escapeHtml(error.message || 'Error cargando módulo')}</div>`;
    }
  }

  async function onLoginSubmit(event) {
    event.preventDefault();
    refs.loginStatus.className = 'status';
    refs.loginStatus.textContent = 'Validando...';

    const fd = new FormData(refs.loginForm);
    try {
      const data = await api('/auth/login', {
        method: 'POST',
        auth: false,
        body: {
          pin: String(fd.get('pin') || '').trim(),
          sucursal_id: Number(fd.get('sucursal_id') || 0),
          plataforma: 'backoffice',
        },
      });

      state.session = { token: data.token, user: data.user, branchId: data.user.sucursal_id };
      saveSession(state.session);
      refs.loginStatus.className = 'status success';
      refs.loginStatus.textContent = 'Sesión iniciada';
      showApp();
      selectModule(resolveModuleIdFromLocation(), { replaceHistory: true });
    } catch (error) {
      refs.loginStatus.className = 'status error';
      refs.loginStatus.textContent = error.message || 'No se pudo iniciar sesión';
    }
  }

  function onLogout() {
    if (state.session?.token) api('/auth/logout', { method: 'POST' }).catch(() => null);
    stopRealtimeRefresh();
    state.session = null;
    state.reportLookups = null;
    state.reportFilters = {
      from: '',
      to: '',
      categoria: '',
      meseroId: '',
    };
    state.salesView = {
      seriesMode: 'day',
      top: 10,
      preset: 'this_month',
    };
    state.receiptsView = {
      preset: 'this_month',
      from: '',
      to: '',
      search: '',
      meseroId: '',
      paymentType: '',
      status: '',
      channel: '',
      page: 1,
      perPage: 20,
      sort: 'opened_at',
      dir: 'desc',
    };
    state.customersView = {
      preset: 'this_month',
      from: '',
      to: '',
      search: '',
      page: 1,
      perPage: 20,
    };
    localStorage.removeItem(STORAGE_KEY);
    showLogin();
  }

  function stopRealtimeRefresh() {
    if (state.realtimeTimer !== null) {
      clearInterval(state.realtimeTimer);
      state.realtimeTimer = null;
      state.realtimeModule = null;
    }
  }

  function startRealtimeRefresh(moduleId) {
    const interval = REALTIME_MODULES[moduleId];
    if (!interval) return;

    state.realtimeModule = moduleId;
    state.realtimeTimer = setInterval(async () => {
      if (state.currentModule !== moduleId) {
        stopRealtimeRefresh();
        return;
      }

      const module = MODULES_BY_ID.get(moduleId);
      if (!module) return;

      try {
        await module.render();
      } catch (_error) {
        // Mantiene el último estado exitoso en pantalla.
      }
    }, interval);
  }

  function loadSession() {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (!raw) return null;
      const parsed = JSON.parse(raw);
      return parsed?.token ? parsed : null;
    } catch (_error) {
      return null;
    }
  }

  function saveSession(session) {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(session));
  }

  async function api(path, options = {}) {
    const headers = { Accept: 'application/json' };
    if (options.body !== undefined) headers['Content-Type'] = 'application/json';
    if (options.auth !== false && state.session?.token) headers.Authorization = `Bearer ${state.session.token}`;
    if (options.branch !== false && state.session?.branchId) headers['X-Branch-Id'] = String(state.session.branchId);

    const res = await fetch(`${state.apiBase}${path}`, {
      method: options.method || 'GET',
      headers,
      body: options.body !== undefined ? JSON.stringify(options.body) : undefined,
    });

    const payload = await res.json().catch(() => null);
    if (!res.ok || !payload || payload.success !== true) {
      throw new Error(payload?.message || `HTTP ${res.status}`);
    }
    return payload.data;
  }

  async function safeApi(path, options = {}) {
    try {
      return await api(path, options);
    } catch (_error) {
      return null;
    }
  }

  function card(title, subtitle = '') {
    const el = document.createElement('div');
    el.className = 'card';
    if (title) {
      const h = document.createElement('h3');
      h.textContent = title;
      el.appendChild(h);
    }
    if (subtitle) {
      const p = document.createElement('p');
      p.className = 'muted small';
      p.textContent = subtitle;
      el.appendChild(p);
    }
    return el;
  }

  function safe(v) {
    return v === null || v === undefined ? '' : String(v);
  }

  function escapeHtml(v) {
    return safe(v)
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
  }

  function money(v) {
    return Number(v || 0).toLocaleString('es-MX', {
      style: 'currency',
      currency: 'MXN',
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    });
  }

  function dateTime(v) {
    if (!v) return '';
    const d = new Date(String(v).replace(' ', 'T'));
    if (Number.isNaN(d.getTime())) return String(v);
    return d.toLocaleString('es-MX');
  }

  const CRUD = {
    branches: {
      endpoint: '/branches',
      query: '',
      columns: [
        { key: 'id', label: 'ID' },
        { key: 'nombre', label: 'Nombre' },
        { key: 'clave', label: 'Clave' },
        { key: 'telefono', label: 'Teléfono' },
        { key: 'ciudad', label: 'Ciudad' },
        { key: 'activa', label: 'Activa' },
      ],
      fields: [
        { key: 'nombre', label: 'Nombre', type: 'text' },
        { key: 'clave', label: 'Clave', type: 'text' },
        { key: 'telefono', label: 'Teléfono', type: 'text', nullable: true },
        { key: 'email', label: 'Email', type: 'text', nullable: true },
        { key: 'ciudad', label: 'Ciudad', type: 'text', nullable: true },
        { key: 'estado', label: 'Estado', type: 'text', nullable: true },
        { key: 'activa', label: 'Activa', type: 'checkbox', defaultValue: 1 },
      ],
    },
    users: {
      endpoint: '/users',
      query: '?limit=500',
      columns: [
        { key: 'id', label: 'ID' },
        { key: 'nombre', label: 'Nombre' },
        { key: 'apellido', label: 'Apellido' },
        { key: 'email', label: 'Email' },
        { key: 'rol_id', label: 'Rol' },
        { key: 'sucursal_id', label: 'Sucursal' },
      ],
      fields: [
        { key: 'nombre', label: 'Nombre', type: 'text' },
        { key: 'apellido', label: 'Apellido', type: 'text', nullable: true },
        { key: 'telefono', label: 'Teléfono', type: 'text', nullable: true },
        { key: 'email', label: 'Email', type: 'text', nullable: true },
        { key: 'pin', label: 'PIN', type: 'text' },
        { key: 'rol_id', label: 'Rol ID', type: 'number' },
        { key: 'sucursal_id', label: 'Sucursal ID', type: 'number' },
        { key: 'activo', label: 'Activo', type: 'checkbox', defaultValue: 1 },
      ],
    },
    employees: {
      endpoint: '/employees',
      query: '?limit=500',
      columns: [
        { key: 'id', label: 'ID' },
        { key: 'nombre', label: 'Nombre' },
        { key: 'apellidos', label: 'Apellidos' },
        { key: 'numero_empleado', label: '# empleado' },
        { key: 'rol_operativo', label: 'Rol operativo' },
      ],
      fields: [
        { key: 'nombre', label: 'Nombre', type: 'text' },
        { key: 'apellidos', label: 'Apellidos', type: 'text', nullable: true },
        { key: 'telefono', label: 'Teléfono', type: 'text', nullable: true },
        { key: 'numero_empleado', label: 'Número empleado', type: 'text', nullable: true },
        { key: 'sucursal_id', label: 'Sucursal ID', type: 'number', nullable: true },
        { key: 'usuario_id', label: 'Usuario ID', type: 'number', nullable: true },
        { key: 'rol_operativo', label: 'Rol operativo', type: 'text', nullable: true },
        { key: 'pin_caja', label: 'PIN caja', type: 'text', nullable: true },
        { key: 'activo', label: 'Activo', type: 'checkbox', defaultValue: 1 },
      ],
    },
    customers: {
      endpoint: '/customers',
      query: '?limit=500',
      columns: [
        { key: 'id', label: 'ID' },
        { key: 'nombre', label: 'Nombre' },
        { key: 'apellidos', label: 'Apellidos' },
        { key: 'telefono', label: 'Teléfono' },
        { key: 'activo', label: 'Activo' },
      ],
      fields: [
        { key: 'nombre', label: 'Nombre', type: 'text' },
        { key: 'apellidos', label: 'Apellidos', type: 'text', nullable: true },
        { key: 'telefono', label: 'Teléfono', type: 'text' },
        { key: 'telefono_alterno', label: 'Teléfono alterno', type: 'text', nullable: true },
        { key: 'email', label: 'Email', type: 'text', nullable: true },
        { key: 'notas', label: 'Notas', type: 'textarea', full: true, nullable: true },
        { key: 'activo', label: 'Activo', type: 'checkbox', defaultValue: 1 },
      ],
    },
    categories: {
      endpoint: '/categories',
      query: '?active=0&limit=500',
      columns: [
        { key: 'id', label: 'ID' },
        { key: 'nombre', label: 'Nombre' },
        { key: 'slug', label: 'Slug' },
        { key: 'orden_visual', label: 'Orden' },
        { key: 'activa', label: 'Activa' },
      ],
      fields: [
        { key: 'nombre', label: 'Nombre', type: 'text' },
        { key: 'slug', label: 'Slug', type: 'text', nullable: true },
        { key: 'descripcion', label: 'Descripción', type: 'textarea', full: true, nullable: true },
        { key: 'imagen_url', label: 'Imagen URL', type: 'text', full: true, nullable: true },
        { key: 'orden_visual', label: 'Orden visual', type: 'number', defaultValue: 0 },
        { key: 'activa', label: 'Activa', type: 'checkbox', defaultValue: 1 },
      ],
    },
    products: {
      endpoint: '/products',
      query: '?active=0&limit=1000',
      columns: [
        { key: 'id', label: 'ID' },
        { key: 'nombre', label: 'Nombre' },
        { key: 'categoria_nombre', label: 'Categoría' },
        { key: 'tipo_producto', label: 'Tipo' },
        { key: 'precio_base', label: 'Precio', formatter: (v) => money(v) },
      ],
      fields: [
        { key: 'categoria_id', label: 'Categoría ID', type: 'number' },
        { key: 'nombre', label: 'Nombre', type: 'text' },
        { key: 'slug', label: 'Slug', type: 'text', nullable: true },
        { key: 'tipo_producto', label: 'Tipo', type: 'text', defaultValue: 'alimento' },
        { key: 'sku', label: 'SKU', type: 'text', nullable: true },
        { key: 'precio_base', label: 'Precio base', type: 'number', step: '0.01' },
        { key: 'descripcion', label: 'Descripción', type: 'textarea', full: true, nullable: true },
        { key: 'imagen_url', label: 'Imagen URL', type: 'text', full: true, nullable: true },
        { key: 'activo', label: 'Activo', type: 'checkbox', defaultValue: 1 },
        { key: 'visible_pos', label: 'Visible POS', type: 'checkbox', defaultValue: 1 },
      ],
    },
    ingredients: {
      endpoint: '/ingredients',
      query: '?limit=500',
      columns: [
        { key: 'id', label: 'ID' },
        { key: 'nombre', label: 'Nombre' },
        { key: 'clave', label: 'Clave' },
        { key: 'unidad_medida_id', label: 'Unidad ID' },
        { key: 'costo_unitario', label: 'Costo', formatter: (v) => money(v) },
      ],
      fields: [
        { key: 'nombre', label: 'Nombre', type: 'text' },
        { key: 'clave', label: 'Clave', type: 'text' },
        { key: 'unidad_medida_id', label: 'Unidad ID', type: 'number', defaultValue: 1 },
        { key: 'costo_unitario', label: 'Costo unitario', type: 'number', step: '0.01', defaultValue: 0 },
        { key: 'activo', label: 'Activo', type: 'checkbox', defaultValue: 1 },
      ],
    },
    promotions: {
      endpoint: '/promotions',
      query: '?limit=300',
      columns: [
        { key: 'id', label: 'ID' },
        { key: 'nombre', label: 'Nombre' },
        { key: 'codigo', label: 'Código' },
        { key: 'valor', label: 'Valor', formatter: (v) => money(v) },
        { key: 'activa', label: 'Activa' },
      ],
      fields: [
        { key: 'nombre', label: 'Nombre', type: 'text' },
        { key: 'codigo', label: 'Código', type: 'text', nullable: true },
        { key: 'tipo_promocion', label: 'Tipo promoción', type: 'text', defaultValue: 'precio_fijo' },
        { key: 'motor_reglas', label: 'Motor reglas', type: 'text', defaultValue: 'rules_v1' },
        { key: 'valor', label: 'Valor', type: 'number', step: '0.01' },
        { key: 'prioridad', label: 'Prioridad', type: 'number', defaultValue: 1 },
        { key: 'activa', label: 'Activa', type: 'checkbox', defaultValue: 1 },
        { key: 'fecha_inicio', label: 'Fecha inicio', type: 'date' },
        { key: 'fecha_fin', label: 'Fecha fin', type: 'date' },
        { key: 'config_json', label: 'Config JSON', type: 'textarea', full: true, nullable: true },
      ],
    },
  };

  async function renderCrud(config) {
    const container = refs.moduleContent;
    const split = document.createElement('div');
    split.className = 'split';

    const formCard = card('Crear / editar registro');
    const formStatus = document.createElement('div');
    formCard.appendChild(formStatus);

    const form = document.createElement('form');
    form.className = 'form-grid';

    const inputs = {};
    config.fields.forEach((f) => {
      const wrap = document.createElement('div');
      if (f.full) wrap.className = 'full';

      if (f.type === 'checkbox') {
        const lbl = document.createElement('label');
        lbl.className = 'checkbox';
        const inp = document.createElement('input');
        inp.type = 'checkbox';
        inp.checked = Number(f.defaultValue || 0) === 1;
        const span = document.createElement('span');
        span.textContent = f.label;
        lbl.appendChild(inp);
        lbl.appendChild(span);
        wrap.appendChild(lbl);
        inputs[f.key] = inp;
      } else {
        const lbl = document.createElement('label');
        lbl.textContent = f.label;
        wrap.appendChild(lbl);
        const inp = f.type === 'textarea' ? document.createElement('textarea') : document.createElement('input');
        if (f.type && f.type !== 'textarea') inp.type = f.type;
        if (f.step) inp.step = f.step;
        if (f.defaultValue !== undefined) inp.value = String(f.defaultValue);
        wrap.appendChild(inp);
        inputs[f.key] = inp;
      }
      form.appendChild(wrap);
    });

    const actions = document.createElement('div');
    actions.className = 'form-actions full';
    actions.innerHTML = '<button class="primary" type="submit">Guardar</button><button class="secondary" type="button" id="new-btn">Nuevo</button>';
    form.appendChild(actions);
    formCard.appendChild(form);

    const listCard = card('Listado');
    const search = document.createElement('input');
    search.placeholder = 'Buscar...';
    search.style.maxWidth = '320px';
    listCard.appendChild(search);
    const tableWrap = document.createElement('div');
    tableWrap.className = 'table-wrap';
    listCard.appendChild(tableWrap);

    split.appendChild(formCard);
    split.appendChild(listCard);
    container.innerHTML = '';
    container.appendChild(split);

    let rows = await api(config.endpoint + config.query);
    let selectedId = null;

    function setValues(row) {
      config.fields.forEach((f) => {
        const inp = inputs[f.key];
        if (f.type === 'checkbox') {
          inp.checked = Number(row?.[f.key] || 0) === 1;
        } else {
          inp.value = row?.[f.key] !== null && row?.[f.key] !== undefined ? String(row[f.key]) : (f.defaultValue !== undefined ? String(f.defaultValue) : '');
        }
      });
    }

    function collect() {
      const payload = {};
      config.fields.forEach((f) => {
        const inp = inputs[f.key];
        if (f.type === 'checkbox') payload[f.key] = inp.checked ? 1 : 0;
        else if (f.type === 'number') payload[f.key] = inp.value === '' ? (f.nullable ? null : 0) : Number(inp.value);
        else if (f.key === 'config_json') payload[f.key] = inp.value.trim() === '' ? null : inp.value;
        else payload[f.key] = inp.value === '' ? (f.nullable ? null : '') : inp.value;
      });
      return payload;
    }

    function filteredRows() {
      const q = search.value.trim().toLowerCase();
      if (!q) return rows;
      return rows.filter((r) => config.columns.some((c) => String(c.key in r ? r[c.key] : '').toLowerCase().includes(q)));
    }

    function renderTable() {
      const data = filteredRows();
      if (!data.length) {
        tableWrap.innerHTML = '<div class="empty-state">Sin registros.</div>';
        return;
      }

      const table = document.createElement('table');
      const head = document.createElement('thead');
      const hr = document.createElement('tr');
      config.columns.forEach((c) => {
        const th = document.createElement('th');
        th.textContent = c.label;
        hr.appendChild(th);
      });
      const thA = document.createElement('th');
      thA.textContent = 'Acciones';
      hr.appendChild(thA);
      head.appendChild(hr);
      table.appendChild(head);

      const body = document.createElement('tbody');
      data.forEach((r) => {
        const tr = document.createElement('tr');
        tr.className = 'clickable-row';
        if (selectedId === r.id) tr.style.background = '#eff6ff';
        config.columns.forEach((c) => {
          const td = document.createElement('td');
          const raw = r[c.key];
          td.textContent = c.formatter ? c.formatter(raw) : safe(raw);
          tr.appendChild(td);
        });

        const action = document.createElement('td');
        const editBtn = document.createElement('button');
        editBtn.type = 'button';
        editBtn.className = 'secondary';
        editBtn.textContent = 'Editar';
        editBtn.addEventListener('click', () => {
          selectedId = r.id;
          setValues(r);
          formStatus.className = 'success-box';
          formStatus.textContent = `Editando ID ${r.id}`;
          renderTable();
        });
        action.appendChild(editBtn);
        tr.appendChild(action);
        body.appendChild(tr);
      });

      table.appendChild(body);
      tableWrap.innerHTML = '';
      tableWrap.appendChild(table);
    }

    search.addEventListener('input', renderTable);

    form.querySelector('#new-btn').addEventListener('click', () => {
      selectedId = null;
      formStatus.className = '';
      formStatus.textContent = '';
      setValues(null);
      renderTable();
    });

    form.addEventListener('submit', async (event) => {
      event.preventDefault();
      try {
        const payload = collect();
        if (selectedId) {
          await api(`${config.endpoint}/${selectedId}`, { method: 'PUT', body: payload });
          formStatus.className = 'success-box';
          formStatus.textContent = 'Registro actualizado';
        } else {
          await api(config.endpoint, { method: 'POST', body: payload });
          formStatus.className = 'success-box';
          formStatus.textContent = 'Registro creado';
        }

        rows = await api(config.endpoint + config.query);
        renderTable();
      } catch (error) {
        formStatus.className = 'error-box';
        formStatus.textContent = error.message || 'Error guardando';
      }
    });

    setValues(null);
    renderTable();
  }

  async function renderRoles() {
    const container = refs.moduleContent;
    const roles = await api('/roles');
    if (!Array.isArray(roles) || !roles.length) {
      container.innerHTML = '<div class="empty-state">Sin roles.</div>';
      return;
    }

    let roleId = roles[0].id;
    const split = document.createElement('div');
    split.className = 'split';
    const left = card('Roles');
    const right = card('Permisos');
    const status = document.createElement('div');
    right.appendChild(status);
    const permWrap = document.createElement('div');
    permWrap.className = 'permissions-grid';
    right.appendChild(permWrap);
    const saveBtn = document.createElement('button');
    saveBtn.className = 'primary';
    saveBtn.type = 'button';
    saveBtn.textContent = 'Guardar permisos';
    right.appendChild(saveBtn);

    const t = document.createElement('table');
    t.innerHTML = '<thead><tr><th>ID</th><th>Rol</th></tr></thead>';
    const b = document.createElement('tbody');
    roles.forEach((r) => {
      const tr = document.createElement('tr');
      tr.className = 'clickable-row';
      tr.innerHTML = `<td>${r.id}</td><td>${escapeHtml(r.nombre)}</td>`;
      tr.addEventListener('click', async () => {
        roleId = r.id;
        await loadPerms();
      });
      b.appendChild(tr);
    });
    t.appendChild(b);
    left.appendChild(t);

    split.appendChild(left);
    split.appendChild(right);
    container.innerHTML = '';
    container.appendChild(split);

    let selected = [];

    async function loadPerms() {
      const payload = await api(`/roles/${roleId}/permissions`);
      const perms = payload.permissions || [];
      selected = perms.filter((p) => Number(p.permitido) === 1).map((p) => Number(p.id));
      const groups = {};
      perms.forEach((p) => {
        const m = p.modulo || 'general';
        if (!groups[m]) groups[m] = [];
        groups[m].push(p);
      });
      permWrap.innerHTML = '';
      Object.keys(groups).forEach((m) => {
        const box = document.createElement('div');
        box.className = 'permission-group';
        box.innerHTML = `<h4>${escapeHtml(m)}</h4>`;
        groups[m].forEach((p) => {
          const row = document.createElement('label');
          row.className = 'checkbox';
          const cb = document.createElement('input');
          cb.type = 'checkbox';
          cb.checked = selected.includes(Number(p.id));
          cb.addEventListener('change', () => {
            const id = Number(p.id);
            if (cb.checked && !selected.includes(id)) selected.push(id);
            if (!cb.checked) selected = selected.filter((x) => x !== id);
          });
          const sp = document.createElement('span');
          sp.textContent = `${p.clave}`;
          row.appendChild(cb);
          row.appendChild(sp);
          box.appendChild(row);
        });
        permWrap.appendChild(box);
      });
    }

    saveBtn.addEventListener('click', async () => {
      try {
        await api(`/roles/${roleId}/permissions`, { method: 'PUT', body: { permission_ids: selected } });
        status.className = 'success-box';
        status.textContent = 'Permisos actualizados';
      } catch (error) {
        status.className = 'error-box';
        status.textContent = error.message || 'No se pudo guardar';
      }
    });

    await loadPerms();
  }

  async function renderSettings() {
    const container = refs.moduleContent;
    const [globals, rates] = await Promise.all([
      api('/settings/global'),
      api('/settings/exchange-rates?from=USD&to=MXN'),
    ]);

    const stack = document.createElement('div');
    stack.className = 'panel-stack';

    const globalCard = card('Configuración global');
    const status = document.createElement('div');
    globalCard.appendChild(status);
    const table = document.createElement('table');
    table.innerHTML = '<thead><tr><th>Clave</th><th>Valor</th><th>Tipo</th><th>Acción</th></tr></thead>';
    const body = document.createElement('tbody');

    (globals || []).forEach((g) => {
      const tr = document.createElement('tr');
      tr.innerHTML = `<td class="code">${escapeHtml(g.clave)}</td><td></td><td>${escapeHtml(g.tipo || 'string')}</td>`;
      const input = document.createElement('input');
      input.value = g.valor ?? '';
      tr.children[1].appendChild(input);
      const action = document.createElement('td');
      const btn = document.createElement('button');
      btn.type = 'button';
      btn.className = 'primary';
      btn.textContent = 'Guardar';
      btn.addEventListener('click', async () => {
        try {
          await api(`/settings/global/${encodeURIComponent(g.clave)}`, { method: 'PUT', body: { value: input.value, type: g.tipo || 'string' } });
          status.className = 'success-box';
          status.textContent = `Guardado: ${g.clave}`;
        } catch (error) {
          status.className = 'error-box';
          status.textContent = error.message || 'No se pudo guardar';
        }
      });
      action.appendChild(btn);
      tr.appendChild(action);
      body.appendChild(tr);
    });

    table.appendChild(body);
    globalCard.appendChild(table);

    const rateCard = card('Tipo de cambio USD');
    const current = (rates || []).find((r) => Number(r.activa) === 1);
    const p = document.createElement('p');
    p.className = 'muted';
    p.textContent = current ? `Vigente: ${Number(current.tipo_cambio).toFixed(4)} desde ${dateTime(current.vigente_desde)}` : 'Sin tipo de cambio activo';
    rateCard.appendChild(p);

    const f = document.createElement('form');
    f.className = 'toolbar';
    f.innerHTML = '<input id="new-rate" type="number" step="0.0001" min="0.0001" placeholder="Nuevo tipo de cambio"><button type="submit">Actualizar</button>';
    const fs = document.createElement('div');
    rateCard.appendChild(f);
    rateCard.appendChild(fs);

    f.addEventListener('submit', async (event) => {
      event.preventDefault();
      const val = Number(f.querySelector('#new-rate').value || 0);
      try {
        await api('/settings/exchange-rates', { method: 'POST', body: { from: 'USD', to: 'MXN', rate: val } });
        fs.className = 'success-box';
        fs.textContent = 'Tipo de cambio actualizado';
        await renderSettings();
      } catch (error) {
        fs.className = 'error-box';
        fs.textContent = error.message || 'No se pudo actualizar';
      }
    });

    stack.appendChild(globalCard);
    stack.appendChild(rateCard);
    container.innerHTML = '';
    container.appendChild(stack);
  }

  async function renderCustomerGroups() {
    const container = refs.moduleContent;
    const shell = buildModuleShell({
      title: 'Grupo de clientes',
      description: 'Configura segmentos para campañas, reportes y reglas comerciales.',
      filters: [
        { label: 'Buscar grupo', placeholder: 'Nombre del grupo...' },
        { label: 'Estado', type: 'select', options: ['Todos', 'Activo', 'Inactivo'] },
      ],
      columns: ['Grupo', 'Clientes', 'Descuento', 'Estado', 'Actualizado'],
      empty: 'Aún no hay grupos de clientes configurados.',
    });
    container.innerHTML = '';
    container.appendChild(shell);
  }

  async function renderCustomerRewards() {
    const container = refs.moduleContent;
    const shell = buildModuleShell({
      title: 'Recompensas',
      description: 'Gestiona programas de lealtad y recompensas por compras.',
      filters: [
        { label: 'Buscar recompensa', placeholder: 'Nombre de recompensa...' },
        { label: 'Tipo', type: 'select', options: ['Todos', 'Puntos', 'Cupón', 'Descuento'] },
      ],
      columns: ['Recompensa', 'Tipo', 'Condición', 'Estado', 'Vigencia'],
      empty: 'No hay recompensas registradas todavía.',
    });
    container.innerHTML = '';
    container.appendChild(shell);
  }

  async function renderSettingsReceipt() {
    const container = refs.moduleContent;
    const shell = buildModuleShell({
      title: 'Configuración de recibo',
      description: 'Define encabezado, pie de ticket y formato de impresión.',
      filters: [
        { label: 'Buscar parámetro', placeholder: 'Ej. pie de ticket' },
      ],
      columns: ['Parámetro', 'Valor actual', 'Tipo', 'Actualizado'],
      empty: 'Sin parámetros específicos de recibo para mostrar.',
    });
    container.innerHTML = '';
    container.appendChild(shell);
  }

  async function renderSettingsSecurity() {
    const container = refs.moduleContent;
    const shell = buildModuleShell({
      title: 'Configuración de seguridad',
      description: 'Administra políticas de acceso, PIN y seguridad operativa.',
      filters: [
        { label: 'Buscar regla', placeholder: 'Ej. intentos máximos' },
        { label: 'Severidad', type: 'select', options: ['Todas', 'Alta', 'Media', 'Baja'] },
      ],
      columns: ['Regla', 'Valor', 'Aplicación', 'Estado', 'Actualizado'],
      empty: 'No hay reglas de seguridad configuradas en esta vista.',
    });
    container.innerHTML = '';
    container.appendChild(shell);
  }

  async function renderSettingsTables() {
    const container = refs.moduleContent;
    const shell = buildModuleShell({
      title: 'Configuración de mesas',
      description: 'Controla zonas, mesas y comportamiento del plano de mesas.',
      filters: [
        { label: 'Buscar mesa', placeholder: 'Ej. Mesa 7' },
        { label: 'Zona', type: 'select', options: ['Todas', 'Principal', 'Terraza', 'Privada'] },
      ],
      columns: ['Mesa/Zona', 'Tipo', 'Capacidad', 'Estado', 'Configuración'],
      empty: 'No hay configuración de mesas disponible en esta vista.',
    });
    container.innerHTML = '';
    container.appendChild(shell);
  }

  function buildModuleShell(config) {
    const wrapper = document.createElement('div');
    wrapper.className = 'panel-stack';

    const filtersCard = card('Filtros');
    const toolbar = document.createElement('div');
    toolbar.className = 'toolbar';
    (config.filters || []).forEach((filter) => {
      if (filter.type === 'select') {
        const select = document.createElement('select');
        (filter.options || []).forEach((label) => {
          const option = document.createElement('option');
          option.value = label;
          option.textContent = label;
          select.appendChild(option);
        });
        toolbar.appendChild(select);
      } else {
        const input = document.createElement('input');
        input.type = 'text';
        input.placeholder = filter.placeholder || '';
        toolbar.appendChild(input);
      }
    });
    const applyButton = document.createElement('button');
    applyButton.type = 'button';
    applyButton.textContent = 'Filtrar';
    toolbar.appendChild(applyButton);
    filtersCard.appendChild(toolbar);

    const contentCard = card(config.title, config.description);
    const table = document.createElement('table');
    table.innerHTML = `<thead><tr>${(config.columns || []).map((column) => `<th>${escapeHtml(column)}</th>`).join('')}</tr></thead><tbody></tbody>`;
    contentCard.appendChild(table);
    contentCard.innerHTML += `<div class="empty-state">${escapeHtml(config.empty || 'Sin registros.')}</div>`;

    wrapper.appendChild(filtersCard);
    wrapper.appendChild(contentCard);
    return wrapper;
  }

  async function renderReportsSales() {
    const container = refs.moduleContent;
    ensureSalesDateRange();
    const filtersCard = buildSalesFiltersCard();

    container.innerHTML = '';
    container.appendChild(filtersCard);
    const loadingCard = card('Cargando reporte de ventas');
    loadingCard.innerHTML += '<div class="loading">Consultando datos del periodo seleccionado...</div>';
    container.appendChild(loadingCard);

    let sales;
    try {
      sales = await api(`/reportes/ventas${buildSalesReportQuery()}`);
    } catch (error) {
      container.innerHTML = '';
      container.appendChild(filtersCard);
      const errorCard = card('Reporte de ventas');
      errorCard.innerHTML += `<div class="error-box">${escapeHtml(error.message || 'No se pudo cargar el reporte')}</div>`;
      container.appendChild(errorCard);
      return;
    }

    const summary = sales?.summary || {};
    const comparison = sales?.comparison || {};
    const seriesMode = state.salesView.seriesMode || 'day';
    const seriesRows = Array.isArray(sales?.time_series?.[seriesMode]) ? sales.time_series[seriesMode] : [];
    const hourlyRows = Array.isArray(sales?.hourly_sales) ? sales.hourly_sales : [];
    const weekdayRows = Array.isArray(sales?.weekday_sales) ? sales.weekday_sales : [];
    const paymentRows = Array.isArray(sales?.payment_methods) ? sales.payment_methods : [];
    const channelRows = Array.isArray(sales?.channels) ? sales.channels : [];
    const topRows = Array.isArray(sales?.top_products) ? sales.top_products : [];
    const pizzaStats = sales?.pizza_modifiers || null;

    const headerCard = card('Reporte de ventas');
    const refreshLabel = formatRealtimeInterval(REALTIME_MODULES['reportes-ventas'] || 0);
    headerCard.innerHTML += `<p class="muted small">Actualización automática cada ${escapeHtml(refreshLabel)} · Última actualización: ${dateTime(new Date().toISOString())}</p>`;
    headerCard.appendChild(buildSalesSummaryBand(summary));

    const chartCard = card('Ingresos');
    chartCard.appendChild(buildSeriesModeSelector(seriesMode));
    chartCard.appendChild(buildLineChart(seriesRows, seriesMode));

    const secondaryKpis = card('Consolidado del periodo');
    secondaryKpis.innerHTML += `<div class="kpi-grid">
      <div class="kpi"><div class="label">Ingresos acumulados</div><div class="value">${money(summary.total_ventas || 0)}</div></div>
      <div class="kpi"><div class="label">Ganancias acumuladas</div><div class="value">${money(summary.ganancias || 0)}</div></div>
      <div class="kpi"><div class="label">Órdenes</div><div class="value">${safe(summary.total_pedidos || 0)}</div></div>
      <div class="kpi"><div class="label">Ticket promedio</div><div class="value">${money(summary.ticket_promedio || 0)}</div></div>
    </div>`;

    const comparisonCard = buildComparisonCard(comparison);
    const paymentCard = buildPaymentMethodsCard(paymentRows);
    const channelsCard = buildChannelsCard(channelRows);
    const hourlyCard = buildVerticalBarsCard('Por hora', hourlyRows, 'hour');
    const weekdayCard = buildVerticalBarsCard('Por día', weekdayRows, 'weekday');
    const topProductsCard = buildTopProductsCard(topRows);
    const pizzaModifiersCard = buildPizzaModifiersCard(pizzaStats);

    const paymentChannelGrid = document.createElement('div');
    paymentChannelGrid.className = 'report-grid-2';
    paymentChannelGrid.appendChild(paymentCard);
    paymentChannelGrid.appendChild(channelsCard);

    const timeGrid = document.createElement('div');
    timeGrid.className = 'report-grid-2';
    timeGrid.appendChild(hourlyCard);
    timeGrid.appendChild(weekdayCard);

    container.innerHTML = '';
    container.appendChild(filtersCard);
    container.appendChild(headerCard);
    container.appendChild(chartCard);
    container.appendChild(secondaryKpis);
    container.appendChild(comparisonCard);
    container.appendChild(paymentChannelGrid);
    container.appendChild(timeGrid);
    container.appendChild(topProductsCard);
    container.appendChild(pizzaModifiersCard);
  }

  function ensureSalesDateRange() {
    if (state.reportFilters.from && state.reportFilters.to) return;
    const range = getPresetRange(state.salesView.preset || 'this_month');
    state.reportFilters = {
      ...state.reportFilters,
      from: range.from,
      to: range.to,
      categoria: '',
      meseroId: '',
    };
  }

  function buildSalesFiltersCard() {
    const wrapper = document.createElement('div');
    wrapper.className = 'card report-filter-card';

    const row = document.createElement('div');
    row.className = 'report-filter-row';

    const details = document.createElement('details');
    details.className = 'date-filter-details';

    const summary = document.createElement('summary');
    summary.className = 'date-range-trigger';
    summary.textContent = formatDateRangeButtonLabel(state.reportFilters.from, state.reportFilters.to);
    details.appendChild(summary);

    const panel = document.createElement('div');
    panel.className = 'date-filter-popover';

    const presetSelect = document.createElement('select');
    presetSelect.innerHTML = `
      <option value="today">Hoy</option>
      <option value="yesterday">Ayer</option>
      <option value="this_week">Esta semana</option>
      <option value="this_month">Este mes</option>
      <option value="custom">Rango personalizado</option>
    `;
    presetSelect.value = state.salesView.preset || 'this_month';

    const fromInput = document.createElement('input');
    fromInput.type = 'date';
    fromInput.value = dateOnly(state.reportFilters.from);

    const toInput = document.createElement('input');
    toInput.type = 'date';
    toInput.value = dateOnly(state.reportFilters.to);

    const fields = document.createElement('div');
    fields.className = 'date-filter-grid';
    fields.appendChild(presetSelect);
    fields.appendChild(fromInput);
    fields.appendChild(toInput);

    const actions = document.createElement('div');
    actions.className = 'date-filter-actions';

    const clearButton = document.createElement('button');
    clearButton.type = 'button';
    clearButton.className = 'secondary';
    clearButton.textContent = 'Restablecer';

    const applyButton = document.createElement('button');
    applyButton.type = 'button';
    applyButton.className = 'primary';
    applyButton.textContent = 'Mostrar';

    actions.appendChild(clearButton);
    actions.appendChild(applyButton);

    panel.appendChild(fields);
    panel.appendChild(actions);
    details.appendChild(panel);
    row.appendChild(details);
    wrapper.appendChild(row);

    presetSelect.addEventListener('change', () => {
      const preset = presetSelect.value;
      state.salesView.preset = preset;
      if (preset !== 'custom') {
        const range = getPresetRange(preset);
        fromInput.value = range.from;
        toInput.value = range.to;
      }
    });

    applyButton.addEventListener('click', async () => {
      state.reportFilters = {
        ...state.reportFilters,
        from: fromInput.value || '',
        to: toInput.value || '',
        categoria: '',
        meseroId: '',
      };
      details.open = false;
      await selectModule(state.currentModule, { skipHistory: true });
    });

    clearButton.addEventListener('click', async () => {
      const range = getPresetRange('this_month');
      state.salesView.preset = 'this_month';
      presetSelect.value = 'this_month';
      fromInput.value = range.from;
      toInput.value = range.to;
      state.reportFilters = {
        ...state.reportFilters,
        from: range.from,
        to: range.to,
        categoria: '',
        meseroId: '',
      };
      details.open = false;
      await selectModule(state.currentModule, { skipHistory: true });
    });

    return wrapper;
  }

  function buildSalesReportQuery() {
    const params = new URLSearchParams();
    if (state.reportFilters.from) params.set('from', state.reportFilters.from);
    if (state.reportFilters.to) params.set('to', state.reportFilters.to);
    params.set('top', String(state.salesView.top || 10));
    const query = params.toString();
    return query ? `?${query}` : '';
  }

  function dateOnly(value) {
    const text = String(value || '').trim();
    if (!text) return '';
    return text.replace('T', ' ').slice(0, 10);
  }

  function getPresetRange(preset) {
    const now = new Date();
    const end = formatDateInput(now);

    if (preset === 'today') {
      return { from: end, to: end };
    }

    if (preset === 'yesterday') {
      const y = new Date(now);
      y.setDate(now.getDate() - 1);
      const value = formatDateInput(y);
      return { from: value, to: value };
    }

    if (preset === 'this_week') {
      const monday = new Date(now);
      const day = (now.getDay() + 6) % 7;
      monday.setDate(now.getDate() - day);
      return { from: formatDateInput(monday), to: end };
    }

    const firstDay = new Date(now.getFullYear(), now.getMonth(), 1);
    return { from: formatDateInput(firstDay), to: end };
  }

  function formatDateInput(value) {
    const year = value.getFullYear();
    const month = String(value.getMonth() + 1).padStart(2, '0');
    const day = String(value.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  function buildSalesSummaryBand(summary) {
    const periodLabel = formatSalesPeriodLabel(state.reportFilters.from, state.reportFilters.to);
    const row = document.createElement('div');
    row.className = 'report-band';
    row.innerHTML = `
      <div class="band-item period">
        <div class="label">${escapeHtml(periodLabel.title)}</div>
        <div class="value">${escapeHtml(periodLabel.subtitle)}</div>
      </div>
      <div class="band-item">
        <div class="label">Ingresos</div>
        <div class="value">${money(summary.total_ventas || 0)}</div>
      </div>
      <div class="band-item">
        <div class="label">Ganancias</div>
        <div class="value">${money(summary.ganancias || 0)}</div>
      </div>
      <div class="band-item">
        <div class="label">Recibos / órdenes</div>
        <div class="value">${safe(summary.total_pedidos || 0)}</div>
      </div>
      <div class="band-item">
        <div class="label">Ticket promedio</div>
        <div class="value">${money(summary.ticket_promedio || 0)}</div>
      </div>
    `;
    return row;
  }

  function formatSalesPeriodLabel(from, to) {
    const fromText = dateOnly(from);
    const toText = dateOnly(to);
    const today = formatDateInput(new Date());
    const yesterdayDate = new Date();
    yesterdayDate.setDate(yesterdayDate.getDate() - 1);
    const yesterday = formatDateInput(yesterdayDate);

    if (fromText && toText && fromText === toText) {
      if (fromText === today) {
        return { title: 'Hoy', subtitle: formatShortEsDate(fromText) };
      }
      if (fromText === yesterday) {
        return { title: 'Ayer', subtitle: formatShortEsDate(fromText) };
      }
      return { title: 'Periodo', subtitle: formatShortEsDate(fromText) };
    }

    if (fromText && toText) {
      return {
        title: 'Periodo',
        subtitle: `${formatShortEsDate(fromText)} - ${formatShortEsDate(toText)}`,
      };
    }

    return { title: 'Periodo', subtitle: 'Sin rango' };
  }

  function formatShortEsDate(dateText) {
    const d = new Date(`${dateText}T00:00:00`);
    if (Number.isNaN(d.getTime())) return dateText;
    return d.toLocaleDateString('es-MX', { day: 'numeric', month: 'long' });
  }

  function formatDateRangeButtonLabel(from, to) {
    const fromText = dateOnly(from);
    const toText = dateOnly(to);
    if (!fromText || !toText) return 'Seleccionar fechas';
    return `${formatShortEsDate(fromText)} - ${formatShortEsDate(toText)}`;
  }

  function formatRealtimeInterval(ms) {
    const totalSeconds = Math.max(0, Math.round(Number(ms || 0) / 1000));
    if (totalSeconds < 60) {
      return `${totalSeconds} segundos`;
    }
    const totalMinutes = Math.round(totalSeconds / 60);
    if (totalMinutes === 1) {
      return '1 minuto';
    }
    return `${totalMinutes} minutos`;
  }

  function buildSeriesModeSelector(mode) {
    const wrap = document.createElement('div');
    wrap.className = 'report-mode-selector';
    [
      ['day', 'Día'],
      ['week', 'Semana'],
      ['month', 'Mes'],
    ].forEach(([key, label]) => {
      const button = document.createElement('button');
      button.type = 'button';
      button.className = `${key === mode ? 'primary' : 'secondary'} report-mode-button`;
      button.textContent = label;
      button.addEventListener('click', async () => {
        state.salesView.seriesMode = key;
        await selectModule(state.currentModule, { skipHistory: true });
      });
      wrap.appendChild(button);
    });
    return wrap;
  }

  function buildLineChart(rows, mode) {
    if (!rows.length) {
      const empty = document.createElement('div');
      empty.className = 'empty-state';
      empty.textContent = 'Sin datos de ingresos para este periodo.';
      return empty;
    }

    const chart = document.createElement('div');
    chart.className = 'line-chart';

    const values = rows.map((row) => Number(row.total || 0));
    const max = Math.max(...values, 1);
    const width = 960;
    const height = 260;
    const paddingX = 42;
    const paddingY = 26;
    const chartWidth = width - (paddingX * 2);
    const chartHeight = height - (paddingY * 2);
    const stepX = rows.length > 1 ? chartWidth / (rows.length - 1) : chartWidth;

    const points = rows.map((row, index) => {
      const x = paddingX + (index * stepX);
      const y = height - paddingY - ((Number(row.total || 0) / max) * chartHeight);
      return { x, y, value: Number(row.total || 0), label: formatSeriesLabel(mode, row.bucket || row.label || '') };
    });

    const polylinePoints = points.map((point) => `${point.x},${point.y}`).join(' ');
    const fillPoints = `${paddingX},${height - paddingY} ${polylinePoints} ${paddingX + chartWidth},${height - paddingY}`;

    const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
    svg.setAttribute('viewBox', `0 0 ${width} ${height}`);
    svg.setAttribute('class', 'chart-svg');

    const area = document.createElementNS('http://www.w3.org/2000/svg', 'polygon');
    area.setAttribute('points', fillPoints);
    area.setAttribute('class', 'line-area');
    svg.appendChild(area);

    const line = document.createElementNS('http://www.w3.org/2000/svg', 'polyline');
    line.setAttribute('points', polylinePoints);
    line.setAttribute('class', 'line-stroke');
    svg.appendChild(line);

    points.forEach((point) => {
      const circle = document.createElementNS('http://www.w3.org/2000/svg', 'circle');
      circle.setAttribute('cx', String(point.x));
      circle.setAttribute('cy', String(point.y));
      circle.setAttribute('r', '3.8');
      circle.setAttribute('class', 'line-dot');

      const title = document.createElementNS('http://www.w3.org/2000/svg', 'title');
      title.textContent = `${point.label}: ${money(point.value)}`;
      circle.appendChild(title);
      svg.appendChild(circle);
    });

    chart.appendChild(svg);

    const labels = document.createElement('div');
    labels.className = 'chart-label-row';
    rows.forEach((row) => {
      const item = document.createElement('span');
      item.textContent = formatSeriesLabel(mode, row.bucket || row.label || '');
      labels.appendChild(item);
    });
    chart.appendChild(labels);

    return chart;
  }

  function formatSeriesLabel(mode, value) {
    const text = String(value || '');
    if (!text) return '-';

    if (mode === 'month') {
      const [year, month] = text.split('-');
      if (year && month) {
        return `${month}/${year}`;
      }
      return text;
    }

    const date = new Date(text.replace(' ', 'T'));
    if (Number.isNaN(date.getTime())) return text;
    return date.toLocaleDateString('es-MX', { day: '2-digit', month: 'short' });
  }

  function buildComparisonCard(comparison) {
    const cardEl = card('Comparativo contra periodo anterior');
    const rows = [
      ['Ventas', comparison.ventas],
      ['Ganancias', comparison.ganancias],
      ['Órdenes', comparison.ordenes, true],
      ['Ticket promedio', comparison.ticket_promedio],
    ];
    const grid = document.createElement('div');
    grid.className = 'comparison-grid';

    rows.forEach(([label, payload, integerValue = false]) => {
      const item = document.createElement('div');
      item.className = 'comparison-item';
      const data = payload || {};
      const trend = data.trend || 'flat';
      const trendClass = trend === 'up' ? 'up' : (trend === 'down' ? 'down' : 'flat');
      const currentValue = integerValue ? Math.round(Number(data.current || 0)) : money(data.current || 0);
      const previousValue = integerValue ? Math.round(Number(data.previous || 0)) : money(data.previous || 0);
      const deltaValue = integerValue
        ? `${Number(data.delta || 0) > 0 ? '+' : ''}${Math.round(Number(data.delta || 0))}`
        : `${Number(data.delta || 0) > 0 ? '+' : ''}${money(data.delta || 0)}`;

      item.innerHTML = `
        <div class="label">${escapeHtml(label)}</div>
        <div class="value">${escapeHtml(String(currentValue))}</div>
        <div class="muted small">Anterior: ${escapeHtml(String(previousValue))}</div>
        <div class="delta ${trendClass}">${escapeHtml(deltaValue)} (${escapeHtml(String(Number(data.delta_pct || 0).toFixed(2)))}%)</div>
      `;
      grid.appendChild(item);
    });

    cardEl.appendChild(grid);
    return cardEl;
  }

  function buildPaymentMethodsCard(rows) {
    const cardEl = card('Métodos de pago');
    if (!rows.length) {
      cardEl.innerHTML += '<div class="empty-state">Sin pagos registrados en el periodo.</div>';
      return cardEl;
    }

    const maxTotal = Math.max(...rows.map((row) => Number(row.total_mxn || 0)), 1);
    const stack = document.createElement('div');
    stack.className = 'metric-stack';

    rows.forEach((row) => {
      const item = document.createElement('div');
      item.className = 'metric-row';
      const width = Math.max(2, (Number(row.total_mxn || 0) / maxTotal) * 100);
      const subtitle = row.key === 'mixto'
        ? `${safe(row.orders || 0)} órdenes mixtas · ${safe(row.share_pct || 0)}% de órdenes`
        : `${money(row.total_mxn || 0)} · ${safe(row.share_pct || 0)}% · ${safe(row.orders || 0)} órdenes`;
      item.innerHTML = `
        <div class="metric-head">
          <span class="metric-title">${escapeHtml(row.name || '-')}</span>
          <span class="metric-subtitle">${escapeHtml(subtitle)}</span>
        </div>
        <div class="metric-bar"><span style="width:${width}%"></span></div>
      `;
      stack.appendChild(item);
    });

    cardEl.appendChild(stack);
    return cardEl;
  }

  function buildChannelsCard(rows) {
    const cardEl = card('Plataformas / canales de pedido');
    if (!rows.length) {
      cardEl.innerHTML += '<div class="empty-state">Sin órdenes por canal en el periodo.</div>';
      return cardEl;
    }

    const maxTotal = Math.max(...rows.map((row) => Number(row.total_mxn || 0)), 1);
    const stack = document.createElement('div');
    stack.className = 'metric-stack';

    rows.forEach((row) => {
      const item = document.createElement('div');
      item.className = 'metric-row';
      const width = Math.max(2, (Number(row.total_mxn || 0) / maxTotal) * 100);
      item.innerHTML = `
        <div class="metric-head">
          <span class="metric-title">${escapeHtml(row.name || '-')}</span>
          <span class="metric-subtitle">${money(row.total_mxn || 0)} · ${safe(row.orders || 0)} órdenes · ${safe(row.sales_share_pct || 0)}%</span>
        </div>
        <div class="metric-bar"><span style="width:${width}%"></span></div>
      `;
      stack.appendChild(item);
    });

    cardEl.appendChild(stack);
    return cardEl;
  }

  function buildVerticalBarsCard(title, rows, kind) {
    const cardEl = card(title);
    if (!rows.length) {
      cardEl.innerHTML += '<div class="empty-state">Sin datos para mostrar.</div>';
      return cardEl;
    }

    const chart = document.createElement('div');
    chart.className = 'mini-bars-chart';
    const max = Math.max(...rows.map((row) => Number(row.total || 0)), 1);

    rows.forEach((row) => {
      const column = document.createElement('div');
      column.className = 'mini-bar-col';
      const bar = document.createElement('span');
      const ratio = (Number(row.total || 0) / max) * 100;
      bar.style.height = `${Math.max(3, ratio)}%`;
      bar.title = `${money(row.total || 0)}`;
      const label = document.createElement('small');
      label.textContent = kind === 'hour'
        ? String(row.hour).padStart(2, '0')
        : String(row.label || '').slice(0, 3);
      column.appendChild(bar);
      column.appendChild(label);
      chart.appendChild(column);
    });

    cardEl.appendChild(chart);
    return cardEl;
  }

  function buildTopProductsCard(rows) {
    const cardEl = card('Productos más populares');

    const topToolbar = document.createElement('div');
    topToolbar.className = 'toolbar';
    const topSelect = document.createElement('select');
    topSelect.innerHTML = `
      <option value="5">Top 5</option>
      <option value="10">Top 10</option>
      <option value="20">Top 20</option>
    `;
    topSelect.value = String(state.salesView.top || 10);
    topSelect.addEventListener('change', async () => {
      state.salesView.top = Number(topSelect.value || 10);
      await selectModule(state.currentModule, { skipHistory: true });
    });
    topToolbar.appendChild(topSelect);
    cardEl.appendChild(topToolbar);

    if (!rows.length) {
      const empty = document.createElement('div');
      empty.className = 'empty-state';
      empty.textContent = 'Sin productos vendidos en este periodo.';
      cardEl.appendChild(empty);
      return cardEl;
    }

    const table = document.createElement('table');
    table.innerHTML = '<thead><tr><th>Producto</th><th>Unidades</th><th>Importe total</th><th>Categoría</th><th>% participación</th></tr></thead>';
    const body = document.createElement('tbody');
    rows.forEach((row) => {
      const tr = document.createElement('tr');
      tr.innerHTML = `
        <td>${escapeHtml(row.producto || '-')}</td>
        <td>${safe(row.unidades_vendidas || 0)}</td>
        <td>${money(row.importe_total || 0)}</td>
        <td>${escapeHtml(row.categoria || '-')}</td>
        <td>${safe(row.participacion_pct || 0)}%</td>`;
      body.appendChild(tr);
    });
    table.appendChild(body);
    cardEl.appendChild(table);
    return cardEl;
  }

  function buildPizzaModifiersCard(stats) {
    const cardEl = card('Modificadores de pizza');
    if (!stats) {
      cardEl.innerHTML += '<div class="empty-state">Sin datos de modificadores de pizza.</div>';
      return cardEl;
    }
    const crust = stats.orillas || {};
    cardEl.innerHTML += `<div class="kpi-grid">
      <div class="kpi"><div class="label">Total pizzas</div><div class="value">${safe(stats.total_pizzas || 0)}</div></div>
      <div class="kpi"><div class="label">Con orilla</div><div class="value">${safe(stats.con_orilla || 0)}</div></div>
      <div class="kpi"><div class="label">Sin orilla</div><div class="value">${safe(stats.sin_orilla || 0)}</div></div>
      <div class="kpi"><div class="label">Con panes de ajo promo</div><div class="value">${safe(stats.con_panes_ajo_promo || 0)}</div></div>
      <div class="kpi"><div class="label">Orilla queso crema</div><div class="value">${safe(crust.queso_crema || 0)}</div></div>
      <div class="kpi"><div class="label">Orilla queso mozzarella</div><div class="value">${safe(crust.queso_mozzarella || 0)}</div></div>
      <div class="kpi"><div class="label">Orilla mitad y mitad</div><div class="value">${safe(crust.mitad_y_mitad || 0)}</div></div>
    </div>`;
    return cardEl;
  }

  async function renderReportsReceipts() {
    ensureReceiptsDateRange();
    const container = refs.moduleContent;
    container.innerHTML = '';

    const loadingCard = card('Recibos');
    loadingCard.innerHTML += '<div class="loading">Cargando recibos...</div>';
    container.appendChild(loadingCard);

    let payload;
    try {
      payload = await api(`/reportes/recibos${buildReceiptsQuery()}`);
    } catch (error) {
      const code = String(error?.message || '').toLowerCase();
      if (code.includes('permiso') || code.includes('forbidden')) {
        container.innerHTML = '<div class="error-box">No tienes permisos para ver recibos.</div>';
        return;
      }
      container.innerHTML = `<div class="error-box">${escapeHtml(error.message || 'No se pudo cargar el reporte de recibos.')}</div>`;
      return;
    }

    const rows = Array.isArray(payload?.rows) ? payload.rows : [];
    const meta = payload?.meta || {};
    const filters = payload?.filters || {};

    const headerCard = buildReceiptsHeaderCard(meta, rows);
    const filtersCard = buildReceiptsFiltersCard(filters);
    const tableCard = buildReceiptsTableCard(rows, meta);

    container.innerHTML = '';
    container.appendChild(headerCard);
    container.appendChild(filtersCard);
    container.appendChild(tableCard);
  }

  function ensureReceiptsDateRange() {
    if (state.receiptsView.from && state.receiptsView.to) return;
    const range = getPresetRange(state.receiptsView.preset || 'this_month');
    state.receiptsView = {
      ...state.receiptsView,
      from: range.from,
      to: range.to,
      page: 1,
    };
  }

  function buildReceiptsQuery() {
    const params = new URLSearchParams();
    if (state.receiptsView.from) params.set('from', state.receiptsView.from);
    if (state.receiptsView.to) params.set('to', state.receiptsView.to);
    if (state.receiptsView.search) params.set('search', state.receiptsView.search);
    if (state.receiptsView.meseroId) params.set('mesero_id', String(state.receiptsView.meseroId));
    if (state.receiptsView.paymentType) params.set('tipo_pago', String(state.receiptsView.paymentType));
    if (state.receiptsView.status) params.set('estatus', String(state.receiptsView.status));
    if (state.receiptsView.channel) params.set('canal', String(state.receiptsView.channel));
    params.set('page', String(state.receiptsView.page || 1));
    params.set('per_page', String(state.receiptsView.perPage || 20));
    params.set('sort', String(state.receiptsView.sort || 'opened_at'));
    params.set('dir', String(state.receiptsView.dir || 'desc'));
    return `?${params.toString()}`;
  }

  function buildReceiptsHeaderCard(meta, rows) {
    const cardEl = card('Recibos');
    const headerRow = document.createElement('div');
    headerRow.className = 'receipts-header-row';

    const left = document.createElement('div');
    left.className = 'receipts-header-left';
    left.innerHTML = `
      <div class="muted">Total de recibos en el rango: <strong>${safe(meta.total || 0)}</strong></div>
    `;

    const right = document.createElement('div');
    right.className = 'receipts-header-actions';

    const exportBtn = document.createElement('button');
    exportBtn.type = 'button';
    exportBtn.className = 'secondary';
    exportBtn.textContent = 'Exportar';
    exportBtn.addEventListener('click', () => exportReceiptsRows(rows));

    const printBtn = document.createElement('button');
    printBtn.type = 'button';
    printBtn.className = 'secondary';
    printBtn.textContent = 'Imprimir';
    printBtn.addEventListener('click', () => printReceiptsRows(rows, meta));

    const details = document.createElement('details');
    details.className = 'date-filter-details';
    const summary = document.createElement('summary');
    summary.className = 'date-range-trigger';
    summary.textContent = formatDateRangeButtonLabel(state.receiptsView.from, state.receiptsView.to);
    details.appendChild(summary);

    const panel = document.createElement('div');
    panel.className = 'date-filter-popover';

    const presetSelect = document.createElement('select');
    presetSelect.innerHTML = `
      <option value="today">Hoy</option>
      <option value="yesterday">Ayer</option>
      <option value="this_week">Esta semana</option>
      <option value="this_month">Este mes</option>
      <option value="custom">Rango personalizado</option>
    `;
    presetSelect.value = state.receiptsView.preset || 'this_month';

    const fromInput = document.createElement('input');
    fromInput.type = 'date';
    fromInput.value = dateOnly(state.receiptsView.from);

    const toInput = document.createElement('input');
    toInput.type = 'date';
    toInput.value = dateOnly(state.receiptsView.to);

    const fields = document.createElement('div');
    fields.className = 'date-filter-grid';
    fields.appendChild(presetSelect);
    fields.appendChild(fromInput);
    fields.appendChild(toInput);

    const actions = document.createElement('div');
    actions.className = 'date-filter-actions';

    const clearButton = document.createElement('button');
    clearButton.type = 'button';
    clearButton.className = 'secondary';
    clearButton.textContent = 'Restablecer';

    const applyButton = document.createElement('button');
    applyButton.type = 'button';
    applyButton.className = 'primary';
    applyButton.textContent = 'Mostrar';

    actions.appendChild(clearButton);
    actions.appendChild(applyButton);
    panel.appendChild(fields);
    panel.appendChild(actions);
    details.appendChild(panel);

    presetSelect.addEventListener('change', () => {
      const preset = presetSelect.value;
      state.receiptsView.preset = preset;
      if (preset !== 'custom') {
        const range = getPresetRange(preset);
        fromInput.value = range.from;
        toInput.value = range.to;
      }
    });

    applyButton.addEventListener('click', async () => {
      state.receiptsView = {
        ...state.receiptsView,
        from: fromInput.value || '',
        to: toInput.value || '',
        page: 1,
      };
      details.open = false;
      await selectModule(state.currentModule, { skipHistory: true });
    });

    clearButton.addEventListener('click', async () => {
      const range = getPresetRange('this_month');
      state.receiptsView = {
        ...state.receiptsView,
        preset: 'this_month',
        from: range.from,
        to: range.to,
        page: 1,
      };
      presetSelect.value = 'this_month';
      fromInput.value = range.from;
      toInput.value = range.to;
      details.open = false;
      await selectModule(state.currentModule, { skipHistory: true });
    });

    right.appendChild(exportBtn);
    right.appendChild(printBtn);
    right.appendChild(details);

    headerRow.appendChild(left);
    headerRow.appendChild(right);
    cardEl.appendChild(headerRow);
    return cardEl;
  }

  function buildReceiptsFiltersCard(lookups) {
    const cardEl = card('Filtros');
    const row = document.createElement('div');
    row.className = 'toolbar receipts-toolbar';

    const searchInput = document.createElement('input');
    searchInput.type = 'text';
    searchInput.placeholder = 'Busqueda rapida por ticket, cliente, telefono o mesero';
    searchInput.value = state.receiptsView.search || '';

    const meseroSelect = document.createElement('select');
    meseroSelect.innerHTML = '<option value="">Mesero: Todos</option>';
    (Array.isArray(lookups?.meseros) ? lookups.meseros : []).forEach((mesero) => {
      const option = document.createElement('option');
      option.value = String(mesero.id);
      option.textContent = mesero.nombre || `Usuario ${mesero.id}`;
      if (String(state.receiptsView.meseroId || '') === String(mesero.id)) {
        option.selected = true;
      }
      meseroSelect.appendChild(option);
    });

    const paymentSelect = document.createElement('select');
    paymentSelect.innerHTML = '<option value="">Tipo de pago: Todos</option>';
    (Array.isArray(lookups?.payment_types) ? lookups.payment_types : []).forEach((type) => {
      if (!type?.key) return;
      const option = document.createElement('option');
      option.value = String(type.key);
      option.textContent = type.label || type.key;
      if (String(state.receiptsView.paymentType || '') === String(type.key)) {
        option.selected = true;
      }
      paymentSelect.appendChild(option);
    });

    const statusSelect = document.createElement('select');
    statusSelect.innerHTML = '<option value="">Estatus: Todos</option>';
    (Array.isArray(lookups?.statuses) ? lookups.statuses : []).forEach((status) => {
      if (!status?.key) return;
      const option = document.createElement('option');
      option.value = String(status.key);
      option.textContent = status.label || status.key;
      if (String(state.receiptsView.status || '') === String(status.key)) {
        option.selected = true;
      }
      statusSelect.appendChild(option);
    });

    const channelSelect = document.createElement('select');
    channelSelect.innerHTML = '<option value="">Canal: Todos</option>';
    const baseChannels = [
      { key: 'recoger', label: 'Recoger' },
      { key: 'domicilio', label: 'Domicilio' },
      { key: 'mesa', label: 'Mesa' },
    ];
    const normalizedSelectedChannel = normalizeChannelFilterKey(state.receiptsView.channel || '');
    const mergedChannels = new Map();
    baseChannels.forEach((channel) => {
      mergedChannels.set(channel.key, channel);
    });
    (Array.isArray(lookups?.channels) ? lookups.channels : []).forEach((channel) => {
      const channelKey = normalizeChannelFilterKey(channel?.key || channel?.label || '');
      if (!channelKey) return;
      if (!mergedChannels.has(channelKey)) {
        mergedChannels.set(channelKey, {
          key: channelKey,
          label: formatOrderType(channel?.label || channel?.key || channelKey),
        });
      }
    });
    [...mergedChannels.values()].forEach((channel) => {
      const option = document.createElement('option');
      option.value = String(channel.key);
      option.textContent = channel.label || channel.key;
      if (normalizedSelectedChannel === normalizeChannelFilterKey(channel.key)) {
        option.selected = true;
      }
      channelSelect.appendChild(option);
    });

    const perPageSelect = document.createElement('select');
    perPageSelect.innerHTML = `
      <option value="10">10 por pagina</option>
      <option value="20">20 por pagina</option>
      <option value="50">50 por pagina</option>
      <option value="100">100 por pagina</option>
    `;
    perPageSelect.value = String(state.receiptsView.perPage || 20);

    const applyBtn = document.createElement('button');
    applyBtn.type = 'button';
    applyBtn.className = 'primary';
    applyBtn.textContent = 'Aplicar';

    const clearBtn = document.createElement('button');
    clearBtn.type = 'button';
    clearBtn.className = 'secondary';
    clearBtn.textContent = 'Limpiar';

    row.appendChild(searchInput);
    row.appendChild(meseroSelect);
    row.appendChild(paymentSelect);
    row.appendChild(statusSelect);
    row.appendChild(channelSelect);
    row.appendChild(perPageSelect);
    row.appendChild(applyBtn);
    row.appendChild(clearBtn);
    cardEl.appendChild(row);

    applyBtn.addEventListener('click', async () => {
      state.receiptsView = {
        ...state.receiptsView,
        search: (searchInput.value || '').trim(),
        meseroId: meseroSelect.value || '',
        paymentType: paymentSelect.value || '',
        status: statusSelect.value || '',
        channel: channelSelect.value || '',
        perPage: Number(perPageSelect.value || 20),
        page: 1,
      };
      await selectModule(state.currentModule, { skipHistory: true });
    });

    clearBtn.addEventListener('click', async () => {
      const range = getPresetRange(state.receiptsView.preset || 'this_month');
      state.receiptsView = {
        ...state.receiptsView,
        from: range.from,
        to: range.to,
        search: '',
        meseroId: '',
        paymentType: '',
        status: '',
        channel: '',
        page: 1,
        perPage: 20,
      };
      await selectModule(state.currentModule, { skipHistory: true });
    });

    return cardEl;
  }

  function buildReceiptsTableCard(rows, meta) {
    const cardEl = card('Listado de recibos');
    const wrap = document.createElement('div');
    wrap.className = 'table-wrap';

    if (!rows.length) {
      wrap.innerHTML = '<div class="empty-state">Sin recibos para los filtros seleccionados.</div>';
      cardEl.appendChild(wrap);
      return cardEl;
    }

    const table = document.createElement('table');
    table.className = 'receipts-table';

    const sortIndicator = (key) => {
      if (String(state.receiptsView.sort || '') !== key) return '';
      return String(state.receiptsView.dir || 'desc') === 'asc' ? ' ↑' : ' ↓';
    };

    table.innerHTML = `
      <thead>
        <tr>
          <th>#Ticket</th>
          <th>Mesero</th>
          <th class="sortable" data-sort="opened_at">Fecha y hora en que se abrió${sortIndicator('opened_at')}</th>
          <th class="sortable" data-sort="closed_at">Fecha y hora en que se cerró${sortIndicator('closed_at')}</th>
          <th>Cantidad pagada</th>
          <th>Descuento</th>
          <th>Ganancias</th>
          <th>Estatus</th>
          <th>Detalles</th>
        </tr>
      </thead>
    `;

    const body = document.createElement('tbody');
    rows.forEach((row) => {
      const tr = document.createElement('tr');
      tr.innerHTML = `
        <td>${escapeHtml(row.ticket || '-')}</td>
        <td>${escapeHtml(row.mesero || '-')}</td>
        <td>${escapeHtml(dateTime(row.opened_at) || '-')}</td>
        <td>${escapeHtml(dateTime(row.closed_at) || '-')}</td>
        <td>${money(row.paid_amount || 0)}</td>
        <td>${money(row.discount_amount || 0)}</td>
        <td>${money(row.profit_amount || 0)}</td>
        <td><span class="status-pill ${statusPillClass(row.status)}">${escapeHtml(row.status_label || formatStatusLabel(row.status))}</span></td>
        <td><button type="button" class="secondary details-btn" data-id="${safe(row.id)}">Detalles</button></td>
      `;
      body.appendChild(tr);
    });
    table.appendChild(body);
    wrap.appendChild(table);
    cardEl.appendChild(wrap);
    cardEl.appendChild(buildReceiptsPagination(meta));

    table.querySelectorAll('th.sortable').forEach((th) => {
      th.addEventListener('click', async () => {
        const sortKey = th.getAttribute('data-sort') || 'opened_at';
        if (state.receiptsView.sort === sortKey) {
          state.receiptsView.dir = state.receiptsView.dir === 'asc' ? 'desc' : 'asc';
        } else {
          state.receiptsView.sort = sortKey;
          state.receiptsView.dir = 'desc';
        }
        state.receiptsView.page = 1;
        await selectModule(state.currentModule, { skipHistory: true });
      });
    });

    table.querySelectorAll('.details-btn').forEach((button) => {
      button.addEventListener('click', async () => {
        const id = Number(button.getAttribute('data-id') || 0);
        if (id <= 0) return;
        await openReceiptDetailsModal(id);
      });
    });

    return cardEl;
  }

  function buildReceiptsPagination(meta) {
    const total = Number(meta?.total || 0);
    const page = Math.max(1, Number(meta?.page || 1));
    const pages = Math.max(1, Number(meta?.pages || 1));
    const perPage = Math.max(1, Number(meta?.per_page || 20));

    const footer = document.createElement('div');
    footer.className = 'receipts-pagination';

    const info = document.createElement('div');
    const from = total === 0 ? 0 : ((page - 1) * perPage) + 1;
    const to = Math.min(page * perPage, total);
    info.className = 'muted';
    info.textContent = `Mostrando ${from} - ${to} de ${total} recibos`;

    const controls = document.createElement('div');
    controls.className = 'pagination-controls';

    const prevBtn = document.createElement('button');
    prevBtn.type = 'button';
    prevBtn.className = 'secondary';
    prevBtn.textContent = 'Anterior';
    prevBtn.disabled = page <= 1;

    const pageBadge = document.createElement('span');
    pageBadge.className = 'page-badge';
    pageBadge.textContent = `${page} / ${pages}`;

    const nextBtn = document.createElement('button');
    nextBtn.type = 'button';
    nextBtn.className = 'secondary';
    nextBtn.textContent = 'Siguiente';
    nextBtn.disabled = page >= pages;

    prevBtn.addEventListener('click', async () => {
      if (state.receiptsView.page <= 1) return;
      state.receiptsView.page -= 1;
      await selectModule(state.currentModule, { skipHistory: true });
    });

    nextBtn.addEventListener('click', async () => {
      if (state.receiptsView.page >= pages) return;
      state.receiptsView.page += 1;
      await selectModule(state.currentModule, { skipHistory: true });
    });

    controls.appendChild(prevBtn);
    controls.appendChild(pageBadge);
    controls.appendChild(nextBtn);
    footer.appendChild(info);
    footer.appendChild(controls);
    return footer;
  }

  function statusPillClass(status) {
    const key = normalizeKey(status);
    if (key === 'paid' || key === 'completed' || key === 'closed') return 'ok';
    if (key === 'closed_without_payment' || key === 'cancelado' || key === 'cancelled') return 'danger';
    if (key === 'partial' || key === 'awaiting_payment') return 'warning';
    return 'neutral';
  }

  function exportReceiptsRows(rows) {
    const headers = [
      '#Ticket',
      'Mesero',
      'Fecha apertura',
      'Fecha cierre',
      'Cantidad pagada',
      'Descuento',
      'Ganancias',
      'Estatus',
    ];
    const csvRows = [headers.join(',')];
    rows.forEach((row) => {
      const values = [
        row.ticket,
        row.mesero,
        dateTime(row.opened_at),
        dateTime(row.closed_at),
        Number(row.paid_amount || 0).toFixed(2),
        Number(row.discount_amount || 0).toFixed(2),
        Number(row.profit_amount || 0).toFixed(2),
        row.status_label || formatStatusLabel(row.status),
      ].map((value) => `"${String(value ?? '').replaceAll('"', '""')}"`);
      csvRows.push(values.join(','));
    });

    const blob = new Blob([`\uFEFF${csvRows.join('\n')}`], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `recibos_${dateOnly(state.receiptsView.from)}_${dateOnly(state.receiptsView.to)}.csv`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
  }

  function printReceiptsRows(rows, meta) {
    const printWindow = window.open('', '_blank', 'width=1000,height=700');
    if (!printWindow) return;
    const tableRows = rows.map((row) => `
      <tr>
        <td>${escapeHtml(row.ticket || '-')}</td>
        <td>${escapeHtml(row.mesero || '-')}</td>
        <td>${escapeHtml(dateTime(row.opened_at) || '-')}</td>
        <td>${escapeHtml(dateTime(row.closed_at) || '-')}</td>
        <td>${escapeHtml(money(row.paid_amount || 0))}</td>
        <td>${escapeHtml(money(row.discount_amount || 0))}</td>
        <td>${escapeHtml(money(row.profit_amount || 0))}</td>
        <td>${escapeHtml(row.status_label || formatStatusLabel(row.status))}</td>
      </tr>
    `).join('');
    printWindow.document.write(`
      <html>
      <head>
        <title>Recibos</title>
        <style>
          body{font-family:Arial,sans-serif;padding:24px;}
          h1{margin:0 0 8px 0;}
          p{margin:0 0 16px 0;color:#475569;}
          table{width:100%;border-collapse:collapse;}
          th,td{border:1px solid #e2e8f0;padding:8px;text-align:left;font-size:12px;}
          th{background:#f8fafc;}
        </style>
      </head>
      <body>
        <h1>Recibos</h1>
        <p>Rango: ${escapeHtml(formatDateRangeButtonLabel(state.receiptsView.from, state.receiptsView.to))} · Total: ${escapeHtml(String(meta?.total || 0))}</p>
        <table>
          <thead>
            <tr>
              <th>#Ticket</th><th>Mesero</th><th>Apertura</th><th>Cierre</th><th>Cantidad pagada</th><th>Descuento</th><th>Ganancias</th><th>Estatus</th>
            </tr>
          </thead>
          <tbody>${tableRows}</tbody>
        </table>
      </body>
      </html>
    `);
    printWindow.document.close();
    printWindow.focus();
    printWindow.print();
  }

  async function openReceiptDetailsModal(orderId) {
    let overlay = document.getElementById('receipt-detail-overlay');
    if (!overlay) {
      overlay = document.createElement('div');
      overlay.id = 'receipt-detail-overlay';
      overlay.className = 'receipt-overlay';
      overlay.innerHTML = `
        <div class="receipt-modal">
          <div class="receipt-modal-header">
            <h3>Detalle del recibo</h3>
            <button type="button" class="secondary" id="receipt-detail-close">Cerrar</button>
          </div>
          <div class="receipt-modal-body" id="receipt-detail-body"></div>
        </div>
      `;
      document.body.appendChild(overlay);
      overlay.querySelector('#receipt-detail-close').addEventListener('click', () => {
        overlay.classList.remove('open');
      });
      overlay.addEventListener('click', (event) => {
        if (event.target === overlay) overlay.classList.remove('open');
      });
    }

    const body = overlay.querySelector('#receipt-detail-body');
    body.innerHTML = '<div class="loading">Cargando detalle del recibo...</div>';
    overlay.classList.add('open');

    try {
      const detail = await api(`/reportes/recibos/${orderId}`);
      body.innerHTML = renderReceiptDetailContent(detail);
    } catch (error) {
      body.innerHTML = `<div class="error-box">${escapeHtml(error.message || 'No se pudo cargar el detalle del recibo.')}</div>`;
    }
  }

  function renderReceiptDetailContent(payload) {
    const order = payload?.order || {};
    const customer = payload?.customer || {};
    const address = payload?.address || null;
    const totals = payload?.totals || {};
    const items = Array.isArray(payload?.items) ? payload.items : [];
    const payments = Array.isArray(payload?.payments) ? payload.payments : [];

    const itemsHtml = items.length
      ? items.map((item) => {
          const modifierLines = buildReceiptItemModifierLines(item);
          return `
            <tr>
              <td class="qty">${formatQty(item.qty)}</td>
              <td>
                <div class="name">${escapeHtml(item.name || '-')}</div>
                ${modifierLines}
              </td>
              <td class="amount">${money(item.unit_price || 0)}</td>
              <td class="amount">${money(item.line_total || 0)}</td>
            </tr>
          `;
        }).join('')
      : '<tr><td colspan="4">Sin productos</td></tr>';

    const paymentsHtml = payments.length
      ? payments.map((payment) => {
          const currencyLabel = payment.currency === 'USD' ? 'USD' : 'MXN';
          const sourceAmount = Number(payment.amount || 0).toFixed(2);
          const exchange = payment.currency === 'USD' && payment.exchange_rate
            ? ` · TC ${Number(payment.exchange_rate).toFixed(2)}`
            : '';
          return `<li>${escapeHtml(payment.method_name || '-')}: ${sourceAmount} ${currencyLabel} (${money(payment.amount_mxn || 0)} MXN)${exchange}</li>`;
        }).join('')
      : '<li>Sin pagos aplicados</li>';

    const closeNoPay = order.close_without_payment_reason
      ? `<div class="ticket-note"><strong>Cierre sin pago:</strong> ${escapeHtml(order.close_without_payment_reason)}${order.close_without_payment_detail ? ` · ${escapeHtml(order.close_without_payment_detail)}` : ''}</div>`
      : '';

    return `
      <div class="receipt-ticket">
        <div class="ticket-head">
          <h4>${escapeHtml(order.branch || "Ron's Pizza")}</h4>
          <div>Ticket: <strong>${escapeHtml(order.ticket || '-')}</strong></div>
          <div>${escapeHtml(dateTime(order.closed_at || order.opened_at) || '')}</div>
          <div>Mesero: ${escapeHtml(order.mesero || '-')}</div>
          <div>Tipo: ${escapeHtml(formatOrderType(order.tipo_pedido) || '-')}</div>
          <div>Estatus: ${escapeHtml(order.status_label || formatStatusLabel(order.status))}</div>
        </div>
        <div class="ticket-meta">
          <div><strong>Apertura:</strong> ${escapeHtml(dateTime(order.opened_at) || '-')}</div>
          <div><strong>Cierre:</strong> ${escapeHtml(dateTime(order.closed_at) || '-')}</div>
          ${customer.name ? `<div><strong>Cliente:</strong> ${escapeHtml(customer.name)}</div>` : ''}
          ${customer.phone ? `<div><strong>Telefono:</strong> ${escapeHtml(customer.phone)}</div>` : ''}
          ${address?.full ? `<div><strong>Direccion:</strong> ${escapeHtml(address.full)}</div>` : ''}
          ${address?.reference ? `<div><strong>Referencia:</strong> ${escapeHtml(address.reference)}</div>` : ''}
          ${address?.instructions ? `<div><strong>Notas de entrega:</strong> ${escapeHtml(address.instructions)}</div>` : ''}
          ${order.notes ? `<div><strong>Notas:</strong> ${escapeHtml(order.notes)}</div>` : ''}
        </div>
        <table class="ticket-items">
          <thead>
            <tr><th>Cant.</th><th>Producto</th><th>Precio</th><th>Total</th></tr>
          </thead>
          <tbody>${itemsHtml}</tbody>
        </table>
        <div class="ticket-totals">
          <div><span>Subtotal</span><strong>${money(totals.subtotal || 0)}</strong></div>
          <div><span>Descuento</span><strong>${money(totals.discount || 0)}</strong></div>
          <div><span>Total</span><strong>${money(totals.total || 0)}</strong></div>
          <div><span>Pagado</span><strong>${money(totals.paid || 0)}</strong></div>
          ${Number(totals.change || 0) > 0 ? `<div><span>Cambio</span><strong>${money(totals.change || 0)}</strong></div>` : ''}
          ${Number(totals.pending || 0) > 0 ? `<div><span>Pendiente</span><strong>${money(totals.pending || 0)}</strong></div>` : ''}
        </div>
        <div class="ticket-payments">
          <h5>Metodos de pago</h5>
          <ul>${paymentsHtml}</ul>
        </div>
        ${closeNoPay}
      </div>
    `;
  }

  function buildReceiptItemModifierLines(item) {
    const lines = Array.isArray(item?.display_lines) ? item.display_lines : [];
    if (!lines.length) return '';
    const list = lines.map((line) => `<li>${escapeHtml(line)}</li>`).join('');
    return `<ul class="ticket-modifier-lines">${list}</ul>`;
  }

  function formatQty(value) {
    const qty = Number(value || 0);
    if (!Number.isFinite(qty)) return '0';
    if (Math.abs(qty - Math.round(qty)) < 0.001) return String(Math.round(qty));
    return qty.toFixed(2);
  }

  async function renderReportsCustomers() {
    ensureCustomersDateRange();
    const container = refs.moduleContent;
    container.innerHTML = '';

    const loadingCard = card('Clientes');
    loadingCard.innerHTML += '<div class="loading">Cargando clientes...</div>';
    container.appendChild(loadingCard);

    let payload;
    try {
      payload = await api(`/reportes/clientes${buildCustomersQuery()}`);
    } catch (error) {
      const code = String(error?.message || '').toLowerCase();
      if (code.includes('permiso') || code.includes('forbidden')) {
        container.innerHTML = '<div class="error-box">No tienes permisos para ver clientes.</div>';
        return;
      }
      container.innerHTML = `<div class="error-box">${escapeHtml(error.message || 'No se pudo cargar el reporte de clientes.')}</div>`;
      return;
    }

    const rows = Array.isArray(payload?.rows) ? payload.rows : [];
    const meta = payload?.meta || {};

    const headerCard = buildCustomersHeaderCard(meta);
    const filtersCard = buildCustomersFiltersCard();
    const tableCard = buildCustomersTableCard(rows, meta);

    container.innerHTML = '';
    container.appendChild(headerCard);
    container.appendChild(filtersCard);
    container.appendChild(tableCard);
  }

  function ensureCustomersDateRange() {
    if (state.customersView.from && state.customersView.to) return;
    const range = getPresetRange(state.customersView.preset || 'this_month');
    state.customersView = {
      ...state.customersView,
      from: range.from,
      to: range.to,
      page: 1,
    };
  }

  function buildCustomersQuery() {
    const params = new URLSearchParams();
    if (state.customersView.from) params.set('from', state.customersView.from);
    if (state.customersView.to) params.set('to', state.customersView.to);
    if (state.customersView.search) params.set('search', state.customersView.search);
    params.set('page', String(state.customersView.page || 1));
    params.set('per_page', String(state.customersView.perPage || 20));
    return `?${params.toString()}`;
  }

  function buildCustomersHeaderCard(meta) {
    const cardEl = card('Clientes');

    const topRow = document.createElement('div');
    topRow.className = 'receipts-header-row';

    const left = document.createElement('div');
    left.className = 'receipts-header-left';
    left.innerHTML = `
      <div class="muted">Total de clientes: <strong>${safe(meta.total || 0)}</strong></div>
    `;

    const right = document.createElement('div');
    right.className = 'receipts-header-actions';

    const createButton = document.createElement('button');
    createButton.type = 'button';
    createButton.className = 'primary';
    createButton.textContent = 'Nuevo cliente';
    createButton.addEventListener('click', async () => {
      await openCustomerCreateModal();
    });

    const details = document.createElement('details');
    details.className = 'date-filter-details';
    const summary = document.createElement('summary');
    summary.className = 'date-range-trigger';
    summary.textContent = formatDateRangeButtonLabel(state.customersView.from, state.customersView.to);
    details.appendChild(summary);

    const panel = document.createElement('div');
    panel.className = 'date-filter-popover';

    const presetSelect = document.createElement('select');
    presetSelect.innerHTML = `
      <option value="today">Hoy</option>
      <option value="yesterday">Ayer</option>
      <option value="this_week">Esta semana</option>
      <option value="this_month">Este mes</option>
      <option value="custom">Rango personalizado</option>
    `;
    presetSelect.value = state.customersView.preset || 'this_month';

    const fromInput = document.createElement('input');
    fromInput.type = 'date';
    fromInput.value = dateOnly(state.customersView.from);

    const toInput = document.createElement('input');
    toInput.type = 'date';
    toInput.value = dateOnly(state.customersView.to);

    const fields = document.createElement('div');
    fields.className = 'date-filter-grid';
    fields.appendChild(presetSelect);
    fields.appendChild(fromInput);
    fields.appendChild(toInput);

    const actions = document.createElement('div');
    actions.className = 'date-filter-actions';

    const clearButton = document.createElement('button');
    clearButton.type = 'button';
    clearButton.className = 'secondary';
    clearButton.textContent = 'Restablecer';

    const applyButton = document.createElement('button');
    applyButton.type = 'button';
    applyButton.className = 'primary';
    applyButton.textContent = 'Mostrar';

    actions.appendChild(clearButton);
    actions.appendChild(applyButton);
    panel.appendChild(fields);
    panel.appendChild(actions);
    details.appendChild(panel);

    presetSelect.addEventListener('change', () => {
      const preset = presetSelect.value;
      state.customersView.preset = preset;
      if (preset !== 'custom') {
        const range = getPresetRange(preset);
        fromInput.value = range.from;
        toInput.value = range.to;
      }
    });

    applyButton.addEventListener('click', async () => {
      state.customersView = {
        ...state.customersView,
        from: fromInput.value || '',
        to: toInput.value || '',
        page: 1,
      };
      details.open = false;
      await selectModule(state.currentModule, { skipHistory: true });
    });

    clearButton.addEventListener('click', async () => {
      const range = getPresetRange('this_month');
      state.customersView = {
        ...state.customersView,
        preset: 'this_month',
        from: range.from,
        to: range.to,
        page: 1,
      };
      presetSelect.value = 'this_month';
      fromInput.value = range.from;
      toInput.value = range.to;
      details.open = false;
      await selectModule(state.currentModule, { skipHistory: true });
    });

    right.appendChild(createButton);
    right.appendChild(details);
    topRow.appendChild(left);
    topRow.appendChild(right);
    cardEl.appendChild(topRow);
    return cardEl;
  }

  function buildCustomersFiltersCard() {
    const cardEl = card('Filtro');
    const row = document.createElement('div');
    row.className = 'toolbar';

    const searchInput = document.createElement('input');
    searchInput.type = 'text';
    searchInput.placeholder = 'Buscar por nombre o teléfono';
    searchInput.value = state.customersView.search || '';
    searchInput.style.maxWidth = '360px';

    const perPageSelect = document.createElement('select');
    perPageSelect.innerHTML = `
      <option value="10">10 por página</option>
      <option value="20">20 por página</option>
      <option value="50">50 por página</option>
      <option value="100">100 por página</option>
    `;
    perPageSelect.value = String(state.customersView.perPage || 20);
    perPageSelect.style.maxWidth = '160px';

    const applyBtn = document.createElement('button');
    applyBtn.type = 'button';
    applyBtn.className = 'primary';
    applyBtn.textContent = 'Aplicar';

    const clearBtn = document.createElement('button');
    clearBtn.type = 'button';
    clearBtn.className = 'secondary';
    clearBtn.textContent = 'Limpiar';

    row.appendChild(searchInput);
    row.appendChild(perPageSelect);
    row.appendChild(applyBtn);
    row.appendChild(clearBtn);
    cardEl.appendChild(row);

    const applyFilters = async () => {
      state.customersView = {
        ...state.customersView,
        search: (searchInput.value || '').trim(),
        perPage: Number(perPageSelect.value || 20),
        page: 1,
      };
      await selectModule(state.currentModule, { skipHistory: true });
    };

    applyBtn.addEventListener('click', applyFilters);
    searchInput.addEventListener('keydown', async (event) => {
      if (event.key !== 'Enter') return;
      event.preventDefault();
      await applyFilters();
    });

    clearBtn.addEventListener('click', async () => {
      const range = getPresetRange(state.customersView.preset || 'this_month');
      state.customersView = {
        ...state.customersView,
        from: range.from,
        to: range.to,
        search: '',
        page: 1,
        perPage: 20,
      };
      await selectModule(state.currentModule, { skipHistory: true });
    });

    return cardEl;
  }

  function buildCustomersTableCard(rows, meta) {
    const cardEl = card('Listado de clientes');
    const wrap = document.createElement('div');
    wrap.className = 'table-wrap';

    if (!rows.length) {
      wrap.innerHTML = '<div class="empty-state">No se encontraron clientes para el rango o filtro seleccionado.</div>';
      cardEl.appendChild(wrap);
      return cardEl;
    }

    const table = document.createElement('table');
    table.className = 'customers-table';
    table.innerHTML = `
      <thead>
        <tr>
          <th>Cliente</th>
          <th>Teléfono</th>
          <th>Dirección principal</th>
          <th>Notas / referencia</th>
          <th>Total pedidos</th>
          <th>Última compra</th>
          <th>Acciones</th>
        </tr>
      </thead>
    `;

    const body = document.createElement('tbody');
    rows.forEach((row) => {
      const tr = document.createElement('tr');
      tr.innerHTML = `
        <td>${escapeHtml(row.name || '-')}</td>
        <td>${escapeHtml(row.phone || '-')}</td>
        <td>${escapeHtml(row.main_address || '-')}</td>
        <td>${escapeHtml(row.reference || row.notes || '-')}</td>
        <td>${safe(row.orders_count || 0)}</td>
        <td>${escapeHtml(dateTime(row.last_order_at) || '-')}</td>
        <td><button type="button" class="secondary details-btn" data-id="${safe(row.id)}">Ver / editar</button></td>
      `;
      body.appendChild(tr);
    });
    table.appendChild(body);
    wrap.appendChild(table);
    cardEl.appendChild(wrap);
    cardEl.appendChild(buildCustomersPagination(meta));

    table.querySelectorAll('.details-btn').forEach((button) => {
      button.addEventListener('click', async () => {
        const customerId = Number(button.getAttribute('data-id') || 0);
        if (customerId <= 0) return;
        await openCustomerDetailsModal(customerId);
      });
    });

    return cardEl;
  }

  function buildCustomersPagination(meta) {
    const total = Number(meta?.total || 0);
    const page = Math.max(1, Number(meta?.page || 1));
    const pages = Math.max(1, Number(meta?.pages || 1));
    const perPage = Math.max(1, Number(meta?.per_page || 20));

    const footer = document.createElement('div');
    footer.className = 'receipts-pagination';

    const info = document.createElement('div');
    const from = total === 0 ? 0 : ((page - 1) * perPage) + 1;
    const to = Math.min(page * perPage, total);
    info.className = 'muted';
    info.textContent = `Mostrando ${from} - ${to} de ${total} clientes`;

    const controls = document.createElement('div');
    controls.className = 'pagination-controls';

    const prevBtn = document.createElement('button');
    prevBtn.type = 'button';
    prevBtn.className = 'secondary';
    prevBtn.textContent = 'Anterior';
    prevBtn.disabled = page <= 1;

    const pageBadge = document.createElement('span');
    pageBadge.className = 'page-badge';
    pageBadge.textContent = `${page} / ${pages}`;

    const nextBtn = document.createElement('button');
    nextBtn.type = 'button';
    nextBtn.className = 'secondary';
    nextBtn.textContent = 'Siguiente';
    nextBtn.disabled = page >= pages;

    prevBtn.addEventListener('click', async () => {
      if (state.customersView.page <= 1) return;
      state.customersView.page -= 1;
      await selectModule(state.currentModule, { skipHistory: true });
    });

    nextBtn.addEventListener('click', async () => {
      if (state.customersView.page >= pages) return;
      state.customersView.page += 1;
      await selectModule(state.currentModule, { skipHistory: true });
    });

    controls.appendChild(prevBtn);
    controls.appendChild(pageBadge);
    controls.appendChild(nextBtn);
    footer.appendChild(info);
    footer.appendChild(controls);
    return footer;
  }

  function ensureCustomerDetailOverlay() {
    let overlay = document.getElementById('customer-detail-overlay');
    if (overlay) return overlay;

    overlay = document.createElement('div');
    overlay.id = 'customer-detail-overlay';
    overlay.className = 'receipt-overlay';
    overlay.innerHTML = `
      <div class="receipt-modal customer-modal">
        <div class="receipt-modal-header">
          <h3 id="customer-detail-title">Detalle de cliente</h3>
          <button type="button" class="secondary" id="customer-detail-close">Cerrar</button>
        </div>
        <div class="receipt-modal-body" id="customer-detail-body"></div>
      </div>
    `;
    document.body.appendChild(overlay);
    overlay.querySelector('#customer-detail-close').addEventListener('click', () => {
      overlay.classList.remove('open');
    });
    overlay.addEventListener('click', (event) => {
      if (event.target === overlay) overlay.classList.remove('open');
    });
    return overlay;
  }

  async function openCustomerCreateModal() {
    const overlay = ensureCustomerDetailOverlay();
    const title = overlay.querySelector('#customer-detail-title');
    if (title) title.textContent = 'Nuevo cliente';
    const body = overlay.querySelector('#customer-detail-body');
    body.innerHTML = '<div class="loading">Cargando formulario...</div>';
    overlay.classList.add('open');

    try {
      body.innerHTML = renderCustomerCreateContent();
      bindCustomerCreateActions({
        body,
      });
    } catch (error) {
      body.innerHTML = `<div class="error-box">${escapeHtml(error.message || 'No se pudo cargar el formulario de cliente.')}</div>`;
    }
  }

  async function openCustomerDetailsModal(customerId) {
    const overlay = ensureCustomerDetailOverlay();
    const title = overlay.querySelector('#customer-detail-title');
    if (title) title.textContent = 'Detalle de cliente';
    const body = overlay.querySelector('#customer-detail-body');
    body.innerHTML = '<div class="loading">Cargando cliente...</div>';
    overlay.classList.add('open');

    try {
      const detail = await api(`/reportes/clientes/${customerId}`);
      body.innerHTML = renderCustomerDetailContent(detail);
      bindCustomerDetailActions({
        customerId,
        detail,
        body,
      });
    } catch (error) {
      body.innerHTML = `<div class="error-box">${escapeHtml(error.message || 'No se pudo cargar el detalle del cliente.')}</div>`;
    }
  }

  function renderCustomerCreateContent() {
    return `
      <div class="panel-stack">
        <div class="card">
          <h3>Alta de cliente</h3>
          <div class="form-grid customer-detail-grid">
            <div class="full">
              <label>Nombre del cliente</label>
              <input type="text" id="customer-create-name" placeholder="Nombre y apellidos" />
            </div>
            <div>
              <label>Teléfono</label>
              <input type="text" id="customer-create-phone" placeholder="Teléfono principal" />
            </div>
            <div>
              <label>Teléfono alterno</label>
              <input type="text" id="customer-create-phone-alt" placeholder="Opcional" />
            </div>
            <div class="full">
              <label>Dirección principal</label>
              <input type="text" id="customer-create-address" placeholder="Calle, número, colonia..." />
            </div>
            <div class="full">
              <label>Referencia de entrega</label>
              <input type="text" id="customer-create-reference" placeholder="Portón, color de casa, referencias..." />
            </div>
            <div class="full">
              <label>Notas</label>
              <textarea id="customer-create-notes" placeholder="Notas adicionales del cliente"></textarea>
            </div>
          </div>
          <div class="form-actions">
            <button type="button" class="primary" id="customer-create-save">Crear cliente</button>
            <button type="button" class="secondary" id="customer-create-cancel">Cancelar</button>
          </div>
          <div id="customer-create-feedback" class="status"></div>
        </div>
      </div>
    `;
  }

  function renderCustomerDetailContent(detail) {
    const customer = detail?.customer || {};
    const addresses = Array.isArray(detail?.addresses) ? detail.addresses : [];
    const orders = Array.isArray(detail?.orders) ? detail.orders : [];

    const addressRows = addresses.length
      ? addresses.map((address) => `
          <tr>
            <td>${escapeHtml(address.alias || 'Principal')}</td>
            <td>${escapeHtml(address.calle || '-')}</td>
            <td>${escapeHtml(address.referencia || address.instrucciones_entrega || '-')}</td>
            <td>${Number(address.activa || 0) === 1 ? 'Sí' : 'No'}</td>
          </tr>
        `).join('')
      : '<tr><td colspan="4">Sin direcciones registradas</td></tr>';

    const orderRows = orders.length
      ? orders.slice(0, 10).map((order) => `
          <tr>
            <td>${escapeHtml(order.folio || String(order.id || '-'))}</td>
            <td>${escapeHtml(formatOrderType(order.tipo_pedido) || '-')}</td>
            <td>${money(order.total_pagado || order.total || 0)}</td>
            <td>${escapeHtml(dateTime(order.fecha_cierre || order.fecha_pedido) || '-')}</td>
          </tr>
        `).join('')
      : '<tr><td colspan="4">Sin historial de órdenes</td></tr>';

    return `
      <div class="panel-stack">
        <div class="card">
          <h3>Datos del cliente</h3>
          <div class="form-grid customer-detail-grid">
            <div class="full">
              <label>Nombre del cliente</label>
              <input type="text" id="customer-detail-name" value="${escapeHtml([customer.nombre || '', customer.apellidos || ''].join(' ').trim())}" />
            </div>
            <div>
              <label>Teléfono</label>
              <input type="text" id="customer-detail-phone" value="${escapeHtml(customer.telefono || '')}" />
            </div>
            <div>
              <label>Teléfono alterno</label>
              <input type="text" id="customer-detail-phone-alt" value="${escapeHtml(customer.telefono_alterno || '')}" />
            </div>
            <div class="full">
              <label>Notas / referencia</label>
              <textarea id="customer-detail-notes">${escapeHtml(customer.notas || '')}</textarea>
            </div>
          </div>
          <div class="form-actions">
            <button type="button" class="primary" id="customer-detail-save">Guardar cambios</button>
          </div>
          <div id="customer-detail-feedback" class="status"></div>
        </div>

        <div class="card">
          <h3>Direcciones</h3>
          <div class="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Alias</th>
                  <th>Dirección</th>
                  <th>Referencia</th>
                  <th>Activa</th>
                </tr>
              </thead>
              <tbody>${addressRows}</tbody>
            </table>
          </div>
          <div class="form-grid customer-address-form">
            <div>
              <label>Dirección</label>
              <input type="text" id="customer-new-address" placeholder="Calle, número, colonia..." />
            </div>
            <div>
              <label>Referencia</label>
              <input type="text" id="customer-new-reference" placeholder="Portón, color de casa, referencias..." />
            </div>
          </div>
          <div class="form-actions">
            <button type="button" class="secondary" id="customer-add-address">Agregar dirección</button>
          </div>
          <div id="customer-address-feedback" class="status"></div>
        </div>

        <div class="card">
          <h3>Historial reciente</h3>
          <div class="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Ticket</th>
                  <th>Canal</th>
                  <th>Total</th>
                  <th>Fecha</th>
                </tr>
              </thead>
              <tbody>${orderRows}</tbody>
            </table>
          </div>
        </div>
      </div>
    `;
  }

  function bindCustomerDetailActions({ customerId, body }) {
    const saveBtn = body.querySelector('#customer-detail-save');
    const addAddressBtn = body.querySelector('#customer-add-address');
    const feedback = body.querySelector('#customer-detail-feedback');
    const addressFeedback = body.querySelector('#customer-address-feedback');

    saveBtn?.addEventListener('click', async () => {
      const fullName = String(body.querySelector('#customer-detail-name')?.value || '').trim();
      const phone = String(body.querySelector('#customer-detail-phone')?.value || '').trim();
      const phoneAlt = String(body.querySelector('#customer-detail-phone-alt')?.value || '').trim();
      const notes = String(body.querySelector('#customer-detail-notes')?.value || '').trim();

      if (!fullName) {
        feedback.className = 'status error';
        feedback.textContent = 'El nombre del cliente es obligatorio.';
        return;
      }
      if (!phone) {
        feedback.className = 'status error';
        feedback.textContent = 'El teléfono es obligatorio.';
        return;
      }

      const [nombre, ...rest] = fullName.split(/\s+/);
      const apellidos = rest.join(' ').trim();

      feedback.className = 'status';
      feedback.textContent = 'Guardando...';
      try {
        await api(`/customers/${customerId}`, {
          method: 'PUT',
          body: {
            nombre,
            apellidos: apellidos || null,
            telefono: phone,
            telefono_alterno: phoneAlt || null,
            notas: notes || null,
          },
        });

        feedback.className = 'status success';
        feedback.textContent = 'Cliente actualizado.';
        await selectModule('reportes-clientes', { skipHistory: true });
      } catch (error) {
        feedback.className = 'status error';
        feedback.textContent = error.message || 'No se pudo actualizar cliente.';
      }
    });

    addAddressBtn?.addEventListener('click', async () => {
      const address = String(body.querySelector('#customer-new-address')?.value || '').trim();
      const reference = String(body.querySelector('#customer-new-reference')?.value || '').trim();

      if (!address) {
        addressFeedback.className = 'status error';
        addressFeedback.textContent = 'La dirección es obligatoria.';
        return;
      }

      addressFeedback.className = 'status';
      addressFeedback.textContent = 'Guardando dirección...';
      try {
        await api(`/customers/${customerId}/addresses`, {
          method: 'POST',
          body: {
            alias: 'Dirección',
            calle: address,
            referencia: reference || null,
            activa: 1,
          },
        });

        addressFeedback.className = 'status success';
        addressFeedback.textContent = 'Dirección agregada.';
        await openCustomerDetailsModal(customerId);
      } catch (error) {
        addressFeedback.className = 'status error';
        addressFeedback.textContent = error.message || 'No se pudo agregar la dirección.';
      }
    });
  }

  function bindCustomerCreateActions({ body }) {
    const saveBtn = body.querySelector('#customer-create-save');
    const cancelBtn = body.querySelector('#customer-create-cancel');
    const feedback = body.querySelector('#customer-create-feedback');

    cancelBtn?.addEventListener('click', () => {
      const overlay = document.getElementById('customer-detail-overlay');
      if (overlay) overlay.classList.remove('open');
    });

    saveBtn?.addEventListener('click', async () => {
      const fullName = String(body.querySelector('#customer-create-name')?.value || '').trim();
      const phone = String(body.querySelector('#customer-create-phone')?.value || '').trim();
      const phoneAlt = String(body.querySelector('#customer-create-phone-alt')?.value || '').trim();
      const address = String(body.querySelector('#customer-create-address')?.value || '').trim();
      const reference = String(body.querySelector('#customer-create-reference')?.value || '').trim();
      const notes = String(body.querySelector('#customer-create-notes')?.value || '').trim();

      if (!fullName) {
        feedback.className = 'status error';
        feedback.textContent = 'El nombre del cliente es obligatorio.';
        return;
      }
      if (!phone) {
        feedback.className = 'status error';
        feedback.textContent = 'El teléfono es obligatorio.';
        return;
      }

      const [nombre, ...rest] = fullName.split(/\s+/);
      const apellidos = rest.join(' ').trim();

      feedback.className = 'status';
      feedback.textContent = 'Creando cliente...';

      try {
        const created = await api('/customers', {
          method: 'POST',
          body: {
            nombre,
            apellidos: apellidos || null,
            telefono: phone,
            telefono_alterno: phoneAlt || null,
            notas: notes || null,
            activo: 1,
          },
        });
        const customerId = Number(created?.id || 0);
        if (customerId <= 0) {
          throw new Error('No se pudo obtener el ID del cliente creado.');
        }

        if (address) {
          await api(`/customers/${customerId}/addresses`, {
            method: 'POST',
            body: {
              alias: 'Principal',
              calle: address,
              referencia: reference || null,
              activa: 1,
            },
          });
        }

        feedback.className = 'status success';
        feedback.textContent = 'Cliente creado correctamente.';
        await selectModule(state.currentModule, { skipHistory: true });
        await openCustomerDetailsModal(customerId);
      } catch (error) {
        feedback.className = 'status error';
        feedback.textContent = error.message || 'No se pudo crear el cliente.';
      }
    });
  }

  async function renderReportsEmployees() {
    const container = refs.moduleContent;
    const [filtersCard, users, allOrders] = await Promise.all([
      buildReportFiltersCard({ title: 'Filtros de empleados', includeCategory: false }),
      safeApi('/users?limit=1000'),
      safeApi('/orders?limit=1000'),
    ]);

    const paidStatuses = new Set(['paid', 'completed', 'closed']);
    const paidOrders = applyOrderFilters(
      Array.isArray(allOrders) ? allOrders.filter((order) => paidStatuses.has(normalizeKey(order.estado))) : [],
      state.reportFilters
    );

    const usersList = Array.isArray(users) ? users : [];
    const stats = new Map();
    paidOrders.forEach((order) => {
      const employeeId = Number(order.usuario_id || 0);
      if (!employeeId) return;
      const current = stats.get(employeeId) || { ordenes: 0, total: 0 };
      current.ordenes += 1;
      current.total += Number(order.total_pagado || order.total || 0);
      stats.set(employeeId, current);
    });

    const rows = usersList
      .filter((user) => stats.has(Number(user.id)))
      .map((user) => {
        const stat = stats.get(Number(user.id));
        const ordenes = Number(stat?.ordenes || 0);
        const total = Number(stat?.total || 0);
        return {
          id: Number(user.id),
          nombre: `${safe(user.nombre)} ${safe(user.apellido)}`.trim() || `Usuario ${safe(user.id)}`,
          rol: user.rol_nombre || user.rol || '-',
          ordenes,
          total,
          ticketPromedio: ordenes > 0 ? total / ordenes : 0,
        };
      })
      .sort((a, b) => b.total - a.total);

    const summaryCard = card('Empleados');
    summaryCard.innerHTML += `<div class="kpi-grid">
      <div class="kpi"><div class="label">Meseros con ventas</div><div class="value">${rows.length}</div></div>
      <div class="kpi"><div class="label">Total vendido</div><div class="value">${money(rows.reduce((acc, row) => acc + row.total, 0))}</div></div>
    </div>`;

    const tableCard = card('Desempeño por mesero');
    if (!rows.length) {
      tableCard.innerHTML += '<div class="empty-state">Sin ventas por mesero para el rango seleccionado.</div>';
    } else {
      const table = document.createElement('table');
      table.innerHTML = '<thead><tr><th>Empleado</th><th>Rol</th><th>Órdenes</th><th>Total</th><th>Ticket promedio</th></tr></thead>';
      const body = document.createElement('tbody');
      rows.forEach((row) => {
        const tr = document.createElement('tr');
        tr.innerHTML = `
          <td>${escapeHtml(row.nombre)}</td>
          <td>${escapeHtml(row.rol)}</td>
          <td>${safe(row.ordenes)}</td>
          <td>${money(row.total)}</td>
          <td>${money(row.ticketPromedio)}</td>`;
        body.appendChild(tr);
      });
      table.appendChild(body);
      tableCard.appendChild(table);
    }

    container.innerHTML = '';
    container.appendChild(filtersCard);
    container.appendChild(summaryCard);
    container.appendChild(tableCard);
  }

  async function renderReportsAnalysisAbc() {
    const container = refs.moduleContent;
    const query = buildReportQuery(state.reportFilters);
    const [filtersCard, products] = await Promise.all([
      buildReportFiltersCard({ title: 'Filtros de análisis ABC' }),
      safeApi(`/reportes/productos${query}`),
    ]);

    const rows = Array.isArray(products?.items) ? products.items : [];
    const totalVendido = rows.reduce((acc, row) => acc + Number(row.total_vendido || 0), 0);
    let acumulado = 0;
    const abcRows = rows.map((row) => {
      const total = Number(row.total_vendido || 0);
      acumulado += total;
      const acumuladoPct = totalVendido > 0 ? (acumulado / totalVendido) * 100 : 0;
      let clase = 'C';
      if (acumuladoPct <= 80) clase = 'A';
      else if (acumuladoPct <= 95) clase = 'B';
      return {
        nombre: row.nombre_snapshot || '-',
        cantidad: Number(row.cantidad_vendida || 0),
        total,
        acumuladoPct,
        clase,
      };
    });

    const summaryCard = card('Análisis ABC');
    summaryCard.innerHTML += `<div class="kpi-grid">
      <div class="kpi"><div class="label">Productos analizados</div><div class="value">${abcRows.length}</div></div>
      <div class="kpi"><div class="label">Venta total</div><div class="value">${money(totalVendido)}</div></div>
    </div>`;

    const tableCard = card('Clasificación de productos');
    if (!abcRows.length) {
      tableCard.innerHTML += '<div class="empty-state">Sin datos para análisis ABC.</div>';
    } else {
      const table = document.createElement('table');
      table.innerHTML = '<thead><tr><th>Producto</th><th>Cantidad</th><th>Total</th><th>% acumulado</th><th>Clase</th></tr></thead>';
      const body = document.createElement('tbody');
      abcRows.forEach((row) => {
        const tr = document.createElement('tr');
        tr.innerHTML = `
          <td>${escapeHtml(row.nombre)}</td>
          <td>${safe(row.cantidad)}</td>
          <td>${money(row.total)}</td>
          <td>${row.acumuladoPct.toFixed(2)}%</td>
          <td><span class="tag">${row.clase}</span></td>`;
        body.appendChild(tr);
      });
      table.appendChild(body);
      tableCard.appendChild(table);
    }

    container.innerHTML = '';
    container.appendChild(filtersCard);
    container.appendChild(summaryCard);
    container.appendChild(tableCard);
  }

  async function buildReportFiltersCard(options = {}) {
    const config = {
      title: options.title || 'Filtros',
      includeCategory: options.includeCategory !== false,
      includeMesero: options.includeMesero !== false,
    };
    const lookups = await ensureReportLookups();
    const filtersCard = card(config.title);
    const filtersBar = document.createElement('div');
    filtersBar.className = 'toolbar';
    filtersBar.innerHTML = `
      <input id="report-from" type="datetime-local" value="${escapeHtml(state.reportFilters.from || '')}" />
      <input id="report-to" type="datetime-local" value="${escapeHtml(state.reportFilters.to || '')}" />
      ${config.includeCategory ? '<select id="report-category"></select>' : ''}
      ${config.includeMesero ? '<select id="report-mesero"></select>' : ''}
      <button id="report-apply" type="button">Aplicar</button>
      <button id="report-clear" type="button" class="secondary">Limpiar</button>
    `;
    filtersCard.appendChild(filtersBar);

    if (config.includeCategory) {
      const categorySelect = filtersBar.querySelector('#report-category');
      const categories = Array.isArray(lookups?.categories) ? lookups.categories : [];
      categorySelect.innerHTML = '<option value="">Todas las categorías</option>';
      categories.forEach((c) => {
        const value = (c.categoria_snapshot || '').toString();
        if (!value) return;
        const option = document.createElement('option');
        option.value = value;
        option.textContent = value;
        if (state.reportFilters.categoria === value) option.selected = true;
        categorySelect.appendChild(option);
      });
    }

    if (config.includeMesero) {
      const meseroSelect = filtersBar.querySelector('#report-mesero');
      const meseros = Array.isArray(lookups?.meseros) ? lookups.meseros : [];
      meseroSelect.innerHTML = '<option value="">Todos los meseros</option>';
      meseros.forEach((m) => {
        const option = document.createElement('option');
        option.value = String(m.id);
        option.textContent = m.nombreCompleto;
        if (String(state.reportFilters.meseroId || '') === String(m.id)) {
          option.selected = true;
        }
        meseroSelect.appendChild(option);
      });
    }

    filtersBar.querySelector('#report-apply').addEventListener('click', async () => {
      state.reportFilters = {
        from: filtersBar.querySelector('#report-from').value || '',
        to: filtersBar.querySelector('#report-to').value || '',
        categoria: config.includeCategory ? (filtersBar.querySelector('#report-category').value || '') : state.reportFilters.categoria,
        meseroId: config.includeMesero ? (filtersBar.querySelector('#report-mesero').value || '') : state.reportFilters.meseroId,
      };
      await selectModule(state.currentModule, { skipHistory: true });
    });

    filtersBar.querySelector('#report-clear').addEventListener('click', async () => {
      state.reportFilters = {
        from: '',
        to: '',
        categoria: '',
        meseroId: '',
      };
      await selectModule(state.currentModule, { skipHistory: true });
    });

    return filtersCard;
  }

  async function ensureReportLookups() {
    if (state.reportLookups) return state.reportLookups;

    const [categoryData, usersData] = await Promise.all([
      safeApi('/reportes/productos'),
      safeApi('/users?limit=500'),
    ]);

    const categoryRows = Array.isArray(categoryData?.by_category_snapshot)
      ? categoryData.by_category_snapshot
      : [];
    const categories = categoryRows
      .map((row) => ({
        categoria_snapshot: String(row.categoria || '').trim(),
      }))
      .filter((row) => row.categoria_snapshot);

    const users = Array.isArray(usersData) ? usersData : [];
    const meseros = users
      .filter((u) => Number(u.activo) === 1)
      .map((u) => ({
        id: Number(u.id),
        nombreCompleto: `${safe(u.nombre)} ${safe(u.apellido)}`.trim() || `Usuario ${safe(u.id)}`,
      }))
      .filter((u) => Number.isFinite(u.id) && u.id > 0);

    state.reportLookups = { categories, meseros };
    return state.reportLookups;
  }

  function buildReportQuery(filters) {
    const params = new URLSearchParams();
    if (filters?.from) params.set('from', normalizeDateFilter(filters.from));
    if (filters?.to) params.set('to', normalizeDateFilter(filters.to));
    if (filters?.categoria) params.set('categoria', filters.categoria);
    if (filters?.meseroId) params.set('mesero_id', String(filters.meseroId));
    const query = params.toString();
    return query ? `?${query}` : '';
  }

  function normalizeDateFilter(value) {
    return String(value || '').replace('T', ' ');
  }

  function normalizeKey(value) {
    return String(value || '').trim().toLowerCase();
  }

  function toTimestamp(value) {
    if (!value) return 0;
    const date = new Date(String(value).replace(' ', 'T'));
    return Number.isNaN(date.getTime()) ? 0 : date.getTime();
  }

  function isWithinRange(dateValue, from, to) {
    const ts = toTimestamp(dateValue);
    if (!ts) return false;
    const fromTs = from ? toTimestamp(normalizeDateFilter(from)) : null;
    const toTs = to ? toTimestamp(normalizeDateFilter(to)) : null;
    if (fromTs && ts < fromTs) return false;
    if (toTs && ts > toTs) return false;
    return true;
  }

  function applyOrderFilters(orders, filters) {
    return orders.filter((order) => {
      const dateSource = order.fecha_cierre || order.fecha_pedido || order.created_at;
      if (filters?.from || filters?.to) {
        if (!isWithinRange(dateSource, filters.from, filters.to)) return false;
      }
      if (filters?.meseroId) {
        if (Number(order.usuario_id || 0) !== Number(filters.meseroId)) return false;
      }
      return true;
    });
  }

  function buildUserMap(users) {
    const map = new Map();
    const rows = Array.isArray(users) ? users : [];
    rows.forEach((row) => {
      map.set(Number(row.id), `${safe(row.nombre)} ${safe(row.apellido)}`.trim() || `Usuario ${safe(row.id)}`);
    });
    return map;
  }

  function formatOrderType(value) {
    const key = normalizeKey(value);
    if (key === 'mesa') return 'Mesa';
    if (key === 'recoger' || key === 'pickup' || key === 'to_go') return 'Recoger';
    if (key === 'domicilio' || key === 'delivery' || key === 'entrega') return 'Domicilio';
    return safe(value || '-');
  }

  function normalizeChannelFilterKey(value) {
    const key = normalizeKey(value);
    if (!key) return '';
    if (key === 'recoger' || key === 'pickup' || key === 'to_go' || key === 'para_llevar' || key === 'para llevar') {
      return 'recoger';
    }
    if (key === 'domicilio' || key === 'delivery' || key === 'entrega') {
      return 'domicilio';
    }
    if (key === 'mesa') {
      return 'mesa';
    }
    return key;
  }

  function formatStatusLabel(value) {
    const key = normalizeKey(value);
    if (key === 'paid') return 'Pagada';
    if (key === 'partial') return 'Pago parcial';
    if (key === 'completed') return 'Completada';
    if (key === 'closed') return 'Cerrada';
    if (key === 'closed_without_payment') return 'Cerrada sin pago';
    if (key === 'pending') return 'Pendiente';
    if (key === 'open') return 'Abierta';
    if (key === 'awaiting_payment') return 'Por cobrar';
    return safe(value || '-');
  }

  async function renderBuilders() {
    const container = refs.moduleContent;
    const builders = await api('/builders');
    if (!Array.isArray(builders) || !builders.length) {
      container.innerHTML = '<div class="empty-state">Sin configuradores.</div>';
      return;
    }

    const cardEl = card('Configuradores');
    const table = document.createElement('table');
    table.innerHTML = '<thead><tr><th>ID</th><th>Clave</th><th>Nombre</th><th>Secciones</th></tr></thead>';
    const body = document.createElement('tbody');
    for (const b of builders) {
      const payload = await api(`/builders/${b.id}/sections`);
      const count = Array.isArray(payload.sections) ? payload.sections.length : 0;
      const tr = document.createElement('tr');
      tr.innerHTML = `<td>${b.id}</td><td class="code">${escapeHtml(b.clave)}</td><td>${escapeHtml(b.nombre)}</td><td>${count}</td>`;
      body.appendChild(tr);
    }
    table.appendChild(body);
    cardEl.appendChild(table);
    container.innerHTML = '';
    container.appendChild(cardEl);
  }

  async function renderAudit() {
    const container = refs.moduleContent;
    const rows = await api('/audit/events?limit=300');
    const cardEl = card('Auditoría');
    if (!Array.isArray(rows) || !rows.length) {
      cardEl.innerHTML += '<div class="empty-state">Sin eventos.</div>';
      container.innerHTML = '';
      container.appendChild(cardEl);
      return;
    }

    const table = document.createElement('table');
    table.innerHTML = '<thead><tr><th>ID</th><th>Usuario</th><th>Entidad</th><th>Acción</th><th>Fecha</th><th>Payload</th></tr></thead>';
    const body = document.createElement('tbody');
    rows.forEach((r) => {
      const tr = document.createElement('tr');
      tr.innerHTML = `<td>${r.id}</td><td>${escapeHtml(`${r.usuario_nombre || ''} ${r.usuario_apellido || ''}`.trim() || 'N/A')}</td><td>${escapeHtml(r.entidad || '')}</td><td>${escapeHtml(r.accion || '')}</td><td>${escapeHtml(dateTime(r.created_at))}</td><td class="code">${escapeHtml(String(r.payload_json || '').slice(0, 140))}</td>`;
      body.appendChild(tr);
    });
    table.appendChild(body);
    cardEl.appendChild(table);
    container.innerHTML = '';
    container.appendChild(cardEl);
  }

  async function renderReprints() {
    const container = refs.moduleContent;
    const rows = await api('/tickets/reprints?limit=300');
    const cardEl = card('Reimpresiones');
    if (!Array.isArray(rows) || !rows.length) {
      cardEl.innerHTML += '<div class="empty-state">Sin reimpresiones.</div>';
      container.innerHTML = '';
      container.appendChild(cardEl);
      return;
    }

    const table = document.createElement('table');
    table.innerHTML = '<thead><tr><th>ID</th><th>Folio</th><th>Tipo</th><th>Impresora</th><th>Usuario</th><th>Fecha</th></tr></thead>';
    const body = document.createElement('tbody');
    rows.forEach((r) => {
      const tr = document.createElement('tr');
      tr.innerHTML = `<td>${r.id}</td><td>${escapeHtml(r.folio || '-')}</td><td>${escapeHtml(r.tipo_ticket || '-')}</td><td>${escapeHtml(r.impresora_nombre || '-')}</td><td>${escapeHtml(`${r.usuario_nombre || ''} ${r.usuario_apellido || ''}`.trim() || 'N/A')}</td><td>${escapeHtml(dateTime(r.created_at))}</td>`;
      body.appendChild(tr);
    });
    table.appendChild(body);
    cardEl.appendChild(table);
    container.innerHTML = '';
    container.appendChild(cardEl);
  }
})();
