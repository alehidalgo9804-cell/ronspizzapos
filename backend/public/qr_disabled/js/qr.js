/* === Config === */
const API_BASE = '../api/v1';
const urlParams = new URLSearchParams(window.location.search);
const MESA = urlParams.get('mesa') || '1';
const BRANCH_ID = parseInt(urlParams.get('branch') || urlParams.get('sucursal_id') || '1');

/* === Mapeo de mesas QR → mesas POS === */
const MESA_LABEL = MESA;

/* === Catalogos hardcodeados (igual que el POS) === */
const PIZZA_CATALOG = {
  specialties: ['Pepperoni','Hawaiana','Suprema','Surtida','Española','Mexicana','Italiana','Ranchera','Sonorense','Vegetariana'],
  specialtyIngredients: {
    'Pepperoni': ['Pepperoni','Queso','Salsa de tomate'],
    'Hawaiana': ['Jamón','Piña','Morrón'],
    'Suprema': ['Pepperoni','Salami','Champiñón','Aceituna','Morrón'],
    'Surtida': ['Pepperoni','Salami','Jamón','Salchicha','Tocino','Chorizo'],
    'Española': ['Pepperoni','Champiñón','Jalapeño','Carne'],
    'Mexicana': ['Frijol','Cebolla','Jalapeño','Chorizo'],
    'Italiana': ['Pepperoni','Salami','Champiñón','Aceituna','Tocino'],
    'Ranchera': ['Jamón','Jalapeño','Tocino','Chorizo'],
    'Sonorense': ['Machaca','Tomate','Cebolla','Jalapeño'],
    'Vegetariana': ['Champiñón','Tomate','Cebolla','Morrón','Aceituna','Piña'],
  },
  allIngredients: ['Pepperoni','Salami','Champiñón','Aceituna','Tocino','Morrón','Frijol','Cebolla','Jalapeño','Chorizo','Carne','Jamón','Salchicha','Machaca','Tomate','Piña','Queso','Salsa de tomate'],
  sizes: [
    {name:'Mini', price:89},
    {name:'Chica', price:119},
    {name:'Mediana', price:159},
    {name:'Grande', price:199},
    {name:'Familiar', price:249},
    {name:'Mega', price:279},
  ],
  crustEdges: ['Regular','Queso crema','Queso mozzarella','Orilla Mitad y Mitad'],
  splitCrustOptions: ['Queso crema','Queso mozzarella'],
  breadTypes: ['Regular','Delgado','Grueso'],
  crustPriceBySize: {Mini:35, Chica:45, Mediana:55, Grande:65, Familiar:75, Mega:85},
  extraIngredientPriceBySize: {Mini:10, Chica:10, Mediana:15, Grande:15, Familiar:20, Mega:20},
  extraQuesoPriceBySize: {Mini:30, Chica:35, Mediana:40, Grande:45, Familiar:50, Mega:55},
  promoGarlicBreadPrice: 39,
};

const WINGS_CATALOG = {
  sizes: [
    {label:'1/2 orden', price:149, key:'mediaOrden'},
    {label:'Orden', price:189, key:'orden'},
    {label:'Mega orden', price:699, key:'megaOrden'},
  ],
  sauces: ['Salsa ligera','Salsa mediana','Salsa caliente','Salsa terrible','Salsa BBQ','Salsa tamarindo','Salsa mango habanero'],
};

const SPAG_CATALOG = {
  types: [
    {name:'A la boloñesa', price:139, ingredients:['Salsa','Carne']},
    {name:'Jamón y champiñón', price:139, ingredients:['Salsa','Jamón','Champiñón']},
    {name:'Supremo', price:169, ingredients:['Salsa','Carne','Jamón','Champiñón','Morrón']},
  ],
  accompaniments: ['Panes de ajo','Papas'],
  garlicBreadTypes: [
    {name:'Normales', price:0},
    {name:'Queso crema', price:35},
    {name:'Queso mozzarella', price:35},
  ],
  extras: [
    {name:'Tocino', price:10},
    {name:'Salchicha', price:10},
  ],
};

const HAM_CATALOG = {
  types: [
    {name:'Clásica', price:139},
    {name:'Jamón y tocino', price:159},
    {name:'Doble carne', price:169},
    {name:'Megaburguer', price:189},
    {name:'Especial de hamburguesas', price:190},
  ],
  sides: [
    {name:'conPapas', label:'Con papas', adjustment:0},
    {name:'sinPapas', label:'Sin papas', adjustment:-39},
    {name:'conAros', label:'Con aros de cebolla', adjustment:20},
  ],
  extras: ['Extra tocino','Extra queso','Extra jamón'],
  extraPrice: 1.50,
};

const COMPLEMENTOS = [
  { id:'comp_papas', nombre:'Papas', precio_base:69 },
  { id:'comp_aros', nombre:'Aros', precio_base:69 },
  { id:'comp_quesitos', nombre:'Quesitos', precio_base:69 },
  { id:'comp_panes_ajo', nombre:'Panes de ajo', precio_base:69 },
  { id:'comp_ensalada', nombre:'Ensalada', precio_base:69 },
];

const BEBIDAS = [
  { id:'beb_soda_botella', nombre:'Soda botella', precio_base:40, sabores:['Coca Cola','Coca Cola Zero','Coca Cola Light','Sidral Mundet','Sangría','Sprite','Fresca'] },
  { id:'beb_soda_vidrio', nombre:'Soda vidrio', precio_base:35, sabores:['Coca Cola','Fresa','Sprite','Sangría','Naranja','Fresca'] },
  { id:'beb_soda_bote', nombre:'Soda bote', precio_base:35, sabores:['Coca Cola'] },
  { id:'beb_frutijugos', nombre:'Frutijugos', precio_base:40, sabores:['Limonada','Pepino limón y chía','Limonada cherry','Jamaica','Cebada','Mango','Horchata'] },
  { id:'beb_te_jazmin', nombre:'Té jazmín', precio_base:40 },
  { id:'beb_brisk', nombre:'Brisk', precio_base:35 },
  { id:'beb_fuze_tea', nombre:'Fuze Tea', precio_base:40 },
  { id:'beb_agua', nombre:'Agua', precio_base:20, sabores:['Mineral','Natural'] },
  { id:'beb_jarra', nombre:'Jarra', precio_base:99, sabores:['Ponche','Té'] },
  { id:'beb_vaso_32', nombre:'Vaso 32 oz', precio_base:50, sabores:['Ponche','Té'] },
  { id:'beb_vaso_16', nombre:'Vaso 16 oz', precio_base:35, sabores:['Ponche','Té'] },
];

/* === State === */
let catalogo = null;
let carrito = [];
let productoConfigurando = null;

/* === Init === */
document.addEventListener('DOMContentLoaded', init);

async function init() {
  try {
    const res = await fetch(`${API_BASE}/qr/catalogo?sucursal_id=${BRANCH_ID}`);
    const data = await res.json();
    if (!data.success) throw new Error(data.message || 'Error cargando menu');
    catalogo = data.data;
    if (!catalogo.categorias) catalogo.categorias = {};
    catalogo.categorias['Complementos'] = COMPLEMENTOS.map(p => ({...p, categoria_nombre:'Complementos', virtual:true}));
    catalogo.categorias['Bebidas'] = BEBIDAS.map(p => ({...p, categoria_nombre:'Bebidas', virtual:true}));
    renderMenuPrincipal();
  } catch (e) {
    document.getElementById('app').innerHTML = `
      <div class="loading">
        <p style="color:var(--danger);font-weight:600">Error cargando el menu</p>
        <p style="font-size:13px;margin-top:8px">${escapeHtml(e.message)}</p>
      </div>`;
  }
}

/* === Render Menu Principal === */
function renderMenuPrincipal() {
  const sucursalNombre = catalogo.sucursal?.nombre || 'Rons Pizza';
  const app = document.getElementById('app');
  const cats = Object.keys(catalogo.categorias);
  const mainCats = ['Pizzas','Hamburguesas','Alitas','Boneless'];
  const secCats = cats.filter(c => !mainCats.includes(c));

  app.innerHTML = `
    <header class="qr-header">
      <div class="brand">Rons <span>Pizza</span></div>
      <div class="mesa-info">
        <span>${escapeHtml(sucursalNombre)}</span>
        <strong>Mesa ${escapeHtml(MESA)}</strong>
      </div>
    </header>
    <div style="padding:20px 16px 8px">
      <h1 style="font-size:22px;font-weight:800">Que se te antoja?</h1>
      <p style="color:var(--text-secondary);font-size:14px;margin-top:4px">Toca para ordenar</p>
    </div>
    <div class="menu-grid">
      ${mainCats.map(cat => catalogo.categorias[cat]?.length ? renderMenuCard(cat) : '').join('')}
    </div>
    ${secCats.length ? `<div class="menu-row">${secCats.map(cat => renderMenuCard(cat)).join('')}</div>` : ''}
  `;
  renderCartFab();
}

function renderProductImg(p, cls) {
  if (p && p.imagen_url) {
    return `<div class="${cls}"><img src="${escapeHtml(p.imagen_url)}" alt="${escapeHtml(p.nombre)}" loading="lazy"></div>`;
  }
  return `<div class="${cls}"><div class="img-placeholder">🖼️</div></div>`;
}

function renderMenuCard(categoria) {
  const prods = catalogo.categorias[categoria] || [];
  const soloUno = prods.length === 1;
  const img = prods.length > 0 ? renderProductImg(prods[0], 'menu-img') : '';
  return `
    <div class="menu-card" onclick="${soloUno ? `abrirConfigurador(findProduct('${escapeJs(prods[0].id)}'))` : `abrirCategoria('${escapeJs(categoria)}')`}">
      ${img}
      <div class="label">${escapeHtml(categoria)}</div>
      <div class="count">${prods.length} opcion${prods.length !== 1 ? 'es' : ''}</div>
    </div>
  `;
}

function abrirCategoria(categoria) {
  const prods = catalogo.categorias[categoria] || [];
  if (prods.length === 1) { abrirConfigurador(prods[0]); return; }
  const app = document.getElementById('app');
  app.innerHTML = `
    <header class="qr-header">
      <div style="display:flex;align-items:center">
        <button class="back-btn" onclick="renderMenuPrincipal()">&#8592;</button>
        <span class="cat-title">${escapeHtml(categoria)}</span>
      </div>
    </header>
    <div class="product-list">
      ${prods.map(p => renderProductItem(p)).join('')}
    </div>
  `;
  renderCartFab();
}

function renderProductItem(p) {
  const img = renderProductImg(p, 'product-item-img');
  return `
    <div class="product-item" onclick="abrirConfigurador(findProduct('${escapeJs(p.id)}'))">
      ${img}
      <div class="product-item-info">
        <div class="product-item-name">${escapeHtml(p.nombre)}</div>
        <div class="product-item-desc">Personaliza a tu gusto</div>
      </div>
      <div class="product-item-price">$${Number(p.precio_base).toFixed(0)}</div>
      <div class="product-item-add">+</div>
    </div>
  `;
}

function getEmoji(nombre) {
  const n = (nombre || '').toLowerCase();
  if (n.includes('pizza')) return '🍕';
  if (n.includes('alita') || n.includes('wing')) return '🍗';
  if (n.includes('boneless')) return '🍖';
  if (n.includes('hamburguesa')) return '🍔';
  if (n.includes('espagueti') || n.includes('spaghetti')) return '🍝';
  if (n.includes('refresco') || n.includes('bebida') || n.includes('soda') || n.includes('coca') || n.includes('agua') || n.includes('té') || n.includes('cafeter')) return '🥤';
  if (n.includes('papas') || n.includes('aros') || n.includes('quesitos') || n.includes('panes de ajo') || n.includes('ensalada')) return '🍟';
  return '🍽️';
}

function findProduct(id) {
  for (const cat of Object.values(catalogo.categorias)) {
    for (const p of cat) { if (p.id == id) return p; }
  }
  return null;
}

/* === Configuradores === */
function abrirConfigurador(p) {
  if (!p) return;
  productoConfigurando = p;
  if (p.virtual && p.sabores) { abrirConfigBebida(p); return; }
  if (p.virtual) { agregarAlCarrito({ producto: p, cantidad: 1, config: null, precio: p.precio_base }); return; }
  const nombre = p.nombre.toLowerCase();
  if (nombre.includes('pizza')) abrirConfigPizza(p);
  else if (nombre.includes('alita')) abrirConfigAlitas(p);
  else if (nombre.includes('boneless')) abrirConfigBoneless(p);
  else if (nombre.includes('espagueti')) abrirConfigEspagueti(p);
  else if (nombre.includes('hamburguesa')) abrirConfigHamburguesa(p);
  else agregarAlCarrito({ producto: p, cantidad: 1, config: null, precio: p.precio_base });
}

function openConfigModal(title, bodyHtml, footerHtml) {
  document.getElementById('config-title').textContent = title;
  document.getElementById('config-body').innerHTML = bodyHtml;
  document.getElementById('config-footer').innerHTML = footerHtml;
  document.getElementById('config-overlay').classList.add('open');
}

function closeConfig() {
  document.getElementById('config-overlay').classList.remove('open');
  productoConfigurando = null;
}

/* --- Bebida Config --- */
let bebidaState = {};
function abrirConfigBebida(p) {
  bebidaState = { sabor: p.sabores[0] };
  renderConfigBebida(p);
}
function renderConfigBebida(p) {
  const s = bebidaState;
  const body = p.sabores.length === 1
    ? `<div class="opt-group"><span class="opt-label">Sabor</span><p style="color:var(--text-secondary)">${escapeHtml(p.sabores[0])}</p></div>`
    : `
      <div class="opt-group">
        <span class="opt-label">Sabor</span>
        <div style="display:flex;flex-wrap:wrap;gap:8px">
          ${p.sabores.map(sab => `<button class="btn-chip ${s.sabor === sab ? 'active' : ''}" onclick="setBebidaSabor('${escapeJs(sab)}')">${escapeHtml(sab)}</button>`).join('')}
        </div>
      </div>
    `;
  const footer = `<button class="btn-primary" onclick="confirmarBebida('${escapeJs(p.id)}')">Agregar — $${p.precio_base.toFixed(0)}</button>`;
  openConfigModal(escapeHtml(p.nombre), body, footer);
}
function setBebidaSabor(v) { bebidaState.sabor = v; renderConfigBebida(productoConfigurando); }
function confirmarBebida(id) {
  const p = findProduct(id);
  const s = bebidaState;
  const lines = p.sabores.length > 1 ? [`Sabor: ${s.sabor}`] : [];
  agregarAlCarrito({ producto: p, cantidad: 1, config: { builder: null, json: { sabor: s.sabor }, lines }, precio: p.precio_base });
  closeConfig();
}

/* --- Pizza Config (igual al POS) --- */
let pizzaState = {};
function abrirConfigPizza(p) {
  pizzaState = {
    specialty: 'Pepperoni',
    size: 'Mediana',
    crustEdge: 'Regular',
    breadType: 'Regular',
    dorada: false,
    ingredients: PIZZA_CATALOG.specialtyIngredients['Pepperoni'],
    extraIngredients: [],
    selectionMode: 'specialty',
    includePromoGarlicBread: false,
    half1Specialty: 'Pepperoni',
    half2Specialty: 'Hawaiana',
    half1Mode: 'specialty',
    half2Mode: 'specialty',
    half1CustomIngredients: [],
    half2CustomIngredients: [],
    crustHalf1: 'Queso crema',
    crustHalf2: 'Queso mozzarella',
  };
  renderConfigPizza(p);
}

function calcPizzaPrice() {
  const c = PIZZA_CATALOG;
  const s = pizzaState;
  let price = c.sizes.find(sz => sz.name === s.size)?.price || 159;
  const crustPrice = s.crustEdge === 'Regular' ? 0 : (c.crustPriceBySize[s.size] || 0);
  price += crustPrice;
  // Extras
  s.extraIngredients.forEach(ing => {
    price += ing === 'Queso' ? (c.extraQuesoPriceBySize[s.size] || 0) : (c.extraIngredientPriceBySize[s.size] || 0);
  });
  if (s.includePromoGarlicBread) price += c.promoGarlicBreadPrice;
  return price;
}

function renderConfigPizza(p) {
  const c = PIZZA_CATALOG;
  const s = pizzaState;
  const price = calcPizzaPrice();
  const crustPrice = s.crustEdge === 'Regular' ? 0 : (c.crustPriceBySize[s.size] || 0);

  // Tabs de modo
  const modeTabs = `
    <div style="display:flex;gap:8px;margin-bottom:16px">
      <button class="btn-mode ${s.selectionMode === 'specialty' ? 'active' : ''}" onclick="setPizzaMode('specialty')">Especialidad</button>
      <button class="btn-mode ${s.selectionMode === 'ingredients' ? 'active' : ''}" onclick="setPizzaMode('ingredients')">Ingredientes</button>
      <button class="btn-mode ${s.selectionMode === 'halfHalf' ? 'active' : ''}" onclick="setPizzaMode('halfHalf')">Mitad y Mitad</button>
    </div>
  `;

  // Ingredientes actuales según modo
  function halfIngredients(half) {
    const mode = half === 1 ? s.half1Mode : s.half2Mode;
    if (mode === 'specialty') {
      const sp = half === 1 ? s.half1Specialty : s.half2Specialty;
      return PIZZA_CATALOG.specialtyIngredients[sp] || [];
    }
    return half === 1 ? s.half1CustomIngredients : s.half2CustomIngredients;
  }
  const currentIngredients = s.selectionMode === 'specialty' ? (PIZZA_CATALOG.specialtyIngredients[s.specialty] || []) : (s.selectionMode === 'halfHalf' ? [...halfIngredients(1), ...halfIngredients(2)] : s.ingredients);

  // Resumen
  let summaryRows = '';
  if (s.selectionMode === 'halfHalf') {
    const h1Label = s.half1Mode === 'specialty' ? `Especialidad - ${s.half1Specialty}` : `Ingredientes (${halfIngredients(1).length})`;
    const h2Label = s.half2Mode === 'specialty' ? `Especialidad - ${s.half2Specialty}` : `Ingredientes (${halfIngredients(2).length})`;
    summaryRows += `<div style="display:flex;justify-content:space-between;font-size:13px;padding:2px 0"><span style="color:#6b7280">Mitad 1:</span><span style="font-weight:700">${escapeHtml(h1Label)}</span></div>`;
    summaryRows += `<div style="display:flex;justify-content:space-between;font-size:13px;padding:2px 0"><span style="color:#6b7280">Mitad 2:</span><span style="font-weight:700">${escapeHtml(h2Label)}</span></div>`;
  } else {
    summaryRows += `<div style="display:flex;justify-content:space-between;font-size:13px;padding:2px 0"><span style="color:#6b7280">Especialidad:</span><span style="font-weight:700">${escapeHtml(s.specialty)}</span></div>`;
  }
  if (s.crustEdge === 'Orilla Mitad y Mitad') {
    summaryRows += `<div style="display:flex;justify-content:space-between;font-size:13px;padding:2px 0"><span style="color:#6b7280">Orilla:</span><span style="font-weight:700">Mitad y Mitad</span></div>`;
    summaryRows += `<div style="display:flex;justify-content:space-between;font-size:13px;padding:2px 0"><span style="color:#6b7280">Orilla Mitad 1:</span><span style="font-weight:700">${escapeHtml(s.crustHalf1)}</span></div>`;
    summaryRows += `<div style="display:flex;justify-content:space-between;font-size:13px;padding:2px 0"><span style="color:#6b7280">Orilla Mitad 2:</span><span style="font-weight:700">${escapeHtml(s.crustHalf2)}</span></div>`;
  } else {
    summaryRows += `<div style="display:flex;justify-content:space-between;font-size:13px;padding:2px 0"><span style="color:#6b7280">Orilla:</span><span style="font-weight:700">${escapeHtml(s.crustEdge)}</span></div>`;
  }
  summaryRows += `<div style="display:flex;justify-content:space-between;font-size:13px;padding:2px 0"><span style="color:#6b7280">Tipo de Pan:</span><span style="font-weight:700">${escapeHtml(s.breadType)}</span></div>`;
  summaryRows += `<div style="display:flex;justify-content:space-between;font-size:13px;padding:2px 0"><span style="color:#6b7280">Dorada:</span><span style="font-weight:700">${s.dorada ? 'Si' : 'No'}</span></div>`;
  summaryRows += `<div style="display:flex;justify-content:space-between;font-size:13px;padding:2px 0"><span style="color:#6b7280">Complemento:</span><span style="font-weight:700">${s.includePromoGarlicBread ? 'Panes de ajo promo' : 'Ninguno'}</span></div>`;

  let ingSummary = '';
  if (s.selectionMode === 'halfHalf') {
    const h1Ing = halfIngredients(1);
    const h2Ing = halfIngredients(2);
    ingSummary += `<div style="font-size:12px;color:#6b7280;font-weight:600;margin-bottom:4px">Mitad 1 (${s.half1Mode === 'specialty' ? escapeHtml(s.half1Specialty) : 'Ingredientes'}):</div>`;
    ingSummary += `<div style="display:flex;flex-wrap:wrap;gap:4px;margin-bottom:8px">${h1Ing.map(i => `<span style="background:#fff;border:1px solid #fed7aa;border-radius:999px;padding:2px 10px;font-size:12px">${escapeHtml(i)}</span>`).join('')}</div>`;
    ingSummary += `<div style="font-size:12px;color:#6b7280;font-weight:600;margin-bottom:4px">Mitad 2 (${s.half2Mode === 'specialty' ? escapeHtml(s.half2Specialty) : 'Ingredientes'}):</div>`;
    ingSummary += `<div style="display:flex;flex-wrap:wrap;gap:4px">${h2Ing.map(i => `<span style="background:#fff;border:1px solid #fed7aa;border-radius:999px;padding:2px 10px;font-size:12px">${escapeHtml(i)}</span>`).join('')}</div>`;
  } else {
    ingSummary += `<div style="display:flex;flex-wrap:wrap;gap:4px">${currentIngredients.map(i => `<span style="background:#fff;border:1px solid #fed7aa;border-radius:999px;padding:2px 10px;font-size:12px">${escapeHtml(i)}</span>`).join('')}</div>`;
  }

  const summary = `
    <div style="background:linear-gradient(135deg,#fff7ed,#fef2f2);border:2px solid #fed7aa;border-radius:12px;padding:14px;margin-bottom:16px">
      <div style="font-size:13px;font-weight:600;color:#4b5563;margin-bottom:8px">Tu Pizza</div>
      ${summaryRows}
      <hr style="border:none;border-top:1px solid #fed7aa;margin:8px 0">
      <div style="font-size:12px;color:#6b7280;font-weight:600;margin-bottom:4px">Ingredientes:</div>
      ${ingSummary}
      ${s.extraIngredients.length ? `<div style="font-size:12px;color:#6b7280;font-weight:600;margin:8px 0 4px">Ingredientes Extra:</div><div style="display:flex;flex-wrap:wrap;gap:4px">${s.extraIngredients.map(i => `<span style="background:#fff;border:1px solid #fed7aa;border-radius:999px;padding:2px 10px;font-size:12px">${escapeHtml(i)}</span>`).join('')}</div>` : ''}
    </div>
  `;

  // Precio
  const priceBox = `
    <div style="background:#2563eb;border-radius:12px;padding:16px;text-align:center;margin-bottom:16px">
      <div style="font-size:12px;color:#ffffffb0">Precio Total</div>
      <div style="font-size:36px;color:#fff;font-weight:800">$${price.toFixed(2)}</div>
    </div>
  `;

  // Seleccion de modo
  let modeContent = '';
  if (s.selectionMode === 'specialty') {
    modeContent = `
      <div class="opt-group">
        <span class="opt-label">Selecciona una Especialidad</span>
        <div style="display:flex;flex-wrap:wrap;gap:8px">
          ${c.specialties.map(sp => `
            <button class="btn-chip ${s.specialty === sp ? 'active' : ''}" onclick="setPizzaSpecialty('${escapeJs(sp)}')">${escapeHtml(sp)}</button>
          `).join('')}
        </div>
      </div>
    `;
  } else if (s.selectionMode === 'ingredients') {
    modeContent = `
      <div class="opt-group">
        <span class="opt-label">Selecciona Ingredientes</span>
        <div style="display:flex;flex-wrap:wrap;gap:8px">
          ${c.allIngredients.map(ing => `
            <button class="btn-chip ${s.ingredients.includes(ing) ? 'active' : ''}" onclick="togglePizzaIngredient('${escapeJs(ing)}')">${escapeHtml(ing)}</button>
          `).join('')}
        </div>
      </div>
    `;
  } else {
    // halfHalf - full implementation matching POS
    const half1Ing = s.half1Mode === 'specialty' ? (c.specialtyIngredients[s.half1Specialty] || []) : s.half1CustomIngredients;
    const half2Ing = s.half2Mode === 'specialty' ? (c.specialtyIngredients[s.half2Specialty] || []) : s.half2CustomIngredients;
    modeContent = `
      <div class="opt-group">
        <span class="opt-label">Mitad 1</span>
        <div style="display:flex;gap:8px;margin-bottom:8px">
          <button class="btn-mode ${s.half1Mode === 'specialty' ? 'active' : ''}" onclick="setHalfMode(1,'specialty')">Especialidad</button>
          <button class="btn-mode ${s.half1Mode === 'ingredients' ? 'active' : ''}" onclick="setHalfMode(1,'ingredients')">Ingredientes</button>
        </div>
        <div style="display:flex;flex-wrap:wrap;gap:8px">
          ${(s.half1Mode === 'specialty' ? c.specialties : c.allIngredients).map(item => `
            <button class="btn-chip ${(s.half1Mode === 'specialty' ? s.half1Specialty === item : s.half1CustomIngredients.includes(item)) ? 'active' : ''}" onclick="${s.half1Mode === 'specialty' ? `setHalfSpecialty(1,'${escapeJs(item)}')` : `toggleHalfIngredient(1,'${escapeJs(item)}')`}">${escapeHtml(item)}</button>
          `).join('')}
        </div>
      </div>
      <div class="opt-group">
        <span class="opt-label">Mitad 2</span>
        <div style="display:flex;gap:8px;margin-bottom:8px">
          <button class="btn-mode ${s.half2Mode === 'specialty' ? 'active' : ''}" onclick="setHalfMode(2,'specialty')">Especialidad</button>
          <button class="btn-mode ${s.half2Mode === 'ingredients' ? 'active' : ''}" onclick="setHalfMode(2,'ingredients')">Ingredientes</button>
        </div>
        <div style="display:flex;flex-wrap:wrap;gap:8px">
          ${(s.half2Mode === 'specialty' ? c.specialties : c.allIngredients).map(item => `
            <button class="btn-chip ${(s.half2Mode === 'specialty' ? s.half2Specialty === item : s.half2CustomIngredients.includes(item)) ? 'active' : ''}" onclick="${s.half2Mode === 'specialty' ? `setHalfSpecialty(2,'${escapeJs(item)}')` : `toggleHalfIngredient(2,'${escapeJs(item)}')`}">${escapeHtml(item)}</button>
          `).join('')}
        </div>
      </div>
    `;
  }

  // Tamaño
  const sizeSection = `
    <div class="opt-group">
      <span class="opt-label">Tamaño</span>
      <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:8px">
        ${c.sizes.map(sz => `
          <div class="price-btn ${s.size === sz.name ? 'active' : ''}" onclick="setPizzaSize('${escapeJs(sz.name)}')">
            <div style="font-weight:700;font-size:14px">${escapeHtml(sz.name)}</div>
            <div style="font-size:11px;color:var(--text-secondary)">+$${sz.price.toFixed(0)}</div>
          </div>
        `).join('')}
      </div>
    </div>
  `;

  // Orilla
  const crustSection = `
    <div class="opt-group">
      <span class="opt-label">Orilla</span>
      <div style="display:grid;grid-template-columns:repeat(2,1fr);gap:8px">
        ${c.crustEdges.map(ce => {
          const isSelected = s.crustEdge === ce;
          const priceLabel = ce === 'Regular' ? '' : `+$${crustPrice.toFixed(0)}`;
          return `<div class="price-btn ${isSelected ? 'active' : ''}" onclick="setPizzaCrust('${escapeJs(ce)}')">
            <div style="font-weight:700;font-size:14px">${escapeHtml(ce)}</div>
            <div style="font-size:11px;color:var(--text-secondary)">${priceLabel}</div>
          </div>`;
        }).join('')}
      </div>
    </div>
  `;

  // Orilla Mitad y Mitad
  const splitCrustSection = s.crustEdge === 'Orilla Mitad y Mitad' ? `
    <div class="opt-group">
      <span class="opt-label">Orilla Mitad y Mitad</span>
      <div style="margin-bottom:10px">
        <div style="font-size:13px;font-weight:700;color:#4b5563;margin-bottom:6px">Orilla Mitad 1</div>
        <div style="display:flex;flex-wrap:wrap;gap:8px">
          ${c.splitCrustOptions.map(opt => `<button class="btn-chip ${s.crustHalf1 === opt ? 'active' : ''}" onclick="setSplitCrustHalf(1,'${escapeJs(opt)}')">${escapeHtml(opt)}</button>`).join('')}
        </div>
      </div>
      <div>
        <div style="font-size:13px;font-weight:700;color:#4b5563;margin-bottom:6px">Orilla Mitad 2</div>
        <div style="display:flex;flex-wrap:wrap;gap:8px">
          ${c.splitCrustOptions.map(opt => `<button class="btn-chip ${s.crustHalf2 === opt ? 'active' : ''}" onclick="setSplitCrustHalf(2,'${escapeJs(opt)}')">${escapeHtml(opt)}</button>`).join('')}
        </div>
      </div>
    </div>
  ` : '';

  // Tipo de pan
  const breadSection = `
    <div class="opt-group">
      <span class="opt-label">Tipo de Pan</span>
      <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:8px">
        ${c.breadTypes.map(bt => `<div class="price-btn ${s.breadType === bt ? 'active' : ''}" onclick="setPizzaBread('${escapeJs(bt)}')"><div style="font-weight:700;font-size:14px">${escapeHtml(bt)}</div></div>`).join('')}
      </div>
    </div>
  `;

  // Coccion
  const cookSection = `
    <div class="opt-group">
      <span class="opt-label">Coccion</span>
      <div style="display:grid;grid-template-columns:repeat(2,1fr);gap:8px">
        <div class="price-btn ${!s.dorada ? 'active' : ''}" onclick="setPizzaDorada(false)"><div style="font-weight:700;font-size:14px">Normal</div></div>
        <div class="price-btn ${s.dorada ? 'active' : ''}" onclick="setPizzaDorada(true)"><div style="font-weight:700;font-size:14px">Dorada</div></div>
      </div>
    </div>
  `;

  // Ingredientes extra
  const extraIngSection = `
    <div class="opt-group">
      <span class="opt-label">Ingredientes Extra</span>
      <div style="font-size:12px;color:var(--text-secondary);margin-bottom:8px">Extra: $${(c.extraIngredientPriceBySize[s.size] || 0).toFixed(0)} · Queso extra: $${(c.extraQuesoPriceBySize[s.size] || 0).toFixed(0)}</div>
      <div style="display:flex;flex-wrap:wrap;gap:8px">
        ${c.allIngredients.map(ing => `
          <button class="btn-chip ${s.extraIngredients.includes(ing) ? 'active-red' : ''}" onclick="togglePizzaExtra('${escapeJs(ing)}')">${escapeHtml(ing)}</button>
        `).join('')}
      </div>
    </div>
  `;

  // Complemento
  const promoSection = `
    <div class="opt-group">
      <span class="opt-label">Complemento de pizza</span>
      <div style="display:grid;grid-template-columns:repeat(2,1fr);gap:8px">
        <div class="price-btn ${!s.includePromoGarlicBread ? 'active' : ''}" onclick="setPizzaPromo(false)"><div style="font-weight:700;font-size:14px">Ninguno</div></div>
        <div class="price-btn ${s.includePromoGarlicBread ? 'active' : ''}" onclick="setPizzaPromo(true)"><div style="font-weight:700;font-size:14px">Panes de ajo promo</div><div style="font-size:11px;color:var(--text-secondary)">+$${c.promoGarlicBreadPrice.toFixed(0)}</div></div>
      </div>
    </div>
  `;

  const body = summary + priceBox + modeTabs + modeContent + sizeSection + crustSection + splitCrustSection + breadSection + cookSection + extraIngSection + promoSection;
  const footer = `<button class="btn-primary" onclick="confirmarPizza(${p.id})">Agregar Pizza a la Orden</button>`;
  openConfigModal('Constructor de Pizza', body, footer);
}

function setPizzaMode(mode) {
  pizzaState.selectionMode = mode;
  if (mode === 'specialty') {
    pizzaState.ingredients = PIZZA_CATALOG.specialtyIngredients[pizzaState.specialty] || [];
  } else if (mode === 'ingredients') {
    pizzaState.specialty = 'Pizza personalizada';
  } else {
    pizzaState.specialty = 'Pizza mitad y mitad';
  }
  renderConfigPizza(productoConfigurando);
}

function setHalfMode(half, mode) {
  if (half === 1) pizzaState.half1Mode = mode;
  else pizzaState.half2Mode = mode;
  renderConfigPizza(productoConfigurando);
}

function setHalfSpecialty(half, sp) {
  if (half === 1) pizzaState.half1Specialty = sp;
  else pizzaState.half2Specialty = sp;
  renderConfigPizza(productoConfigurando);
}

function toggleHalfIngredient(half, ing) {
  const arr = half === 1 ? pizzaState.half1CustomIngredients : pizzaState.half2CustomIngredients;
  const idx = arr.indexOf(ing);
  if (idx >= 0) arr.splice(idx, 1);
  else arr.push(ing);
  renderConfigPizza(productoConfigurando);
}

function setSplitCrustHalf(half, val) {
  if (half === 1) pizzaState.crustHalf1 = val;
  else pizzaState.crustHalf2 = val;
  renderConfigPizza(productoConfigurando);
}

function setPizzaSpecialty(sp) {
  pizzaState.specialty = sp;
  pizzaState.ingredients = PIZZA_CATALOG.specialtyIngredients[sp] || [];
  pizzaState.selectionMode = 'specialty';
  renderConfigPizza(productoConfigurando);
}

function togglePizzaIngredient(ing) {
  const idx = pizzaState.ingredients.indexOf(ing);
  if (idx >= 0) pizzaState.ingredients.splice(idx, 1);
  else pizzaState.ingredients.push(ing);
  pizzaState.specialty = 'Pizza personalizada';
  renderConfigPizza(productoConfigurando);
}

function setPizzaSize(sz) { pizzaState.size = sz; renderConfigPizza(productoConfigurando); }
function setPizzaCrust(ce) { pizzaState.crustEdge = ce; renderConfigPizza(productoConfigurando); }
function setPizzaBread(bt) { pizzaState.breadType = bt; renderConfigPizza(productoConfigurando); }
function setPizzaDorada(d) { pizzaState.dorada = d; renderConfigPizza(productoConfigurando); }
function togglePizzaExtra(ing) {
  const idx = pizzaState.extraIngredients.indexOf(ing);
  if (idx >= 0) pizzaState.extraIngredients.splice(idx, 1);
  else pizzaState.extraIngredients.push(ing);
  renderConfigPizza(productoConfigurando);
}
function setPizzaPromo(v) { pizzaState.includePromoGarlicBread = v; renderConfigPizza(productoConfigurando); }

function confirmarPizza(productId) {
  const p = findProduct(productId);
  const price = calcPizzaPrice();
  const s = pizzaState;

  function halfIngredients(half) {
    const mode = half === 1 ? s.half1Mode : s.half2Mode;
    if (mode === 'specialty') {
      const sp = half === 1 ? s.half1Specialty : s.half2Specialty;
      return PIZZA_CATALOG.specialtyIngredients[sp] || [];
    }
    return half === 1 ? [...s.half1CustomIngredients] : [...s.half2CustomIngredients];
  }

  const json = {
    specialty: s.specialty,
    size: s.size,
    crustEdge: s.crustEdge,
    breadType: s.breadType,
    dorada: s.dorada,
    ingredients: s.selectionMode === 'specialty' ? (PIZZA_CATALOG.specialtyIngredients[s.specialty] || []) : (s.selectionMode === 'halfHalf' ? [...halfIngredients(1), ...halfIngredients(2)] : [...s.ingredients]),
    extraIngredients: [...s.extraIngredients],
    selectionMode: s.selectionMode,
    half1: s.selectionMode === 'halfHalf' ? (s.half1Mode === 'specialty' ? s.half1Specialty : 'Ingredientes') : null,
    half2: s.selectionMode === 'halfHalf' ? (s.half2Mode === 'specialty' ? s.half2Specialty : 'Ingredientes') : null,
    half1Mode: s.selectionMode === 'halfHalf' ? s.half1Mode : null,
    half2Mode: s.selectionMode === 'halfHalf' ? s.half2Mode : null,
    half1Specialty: s.selectionMode === 'halfHalf' ? s.half1Specialty : null,
    half2Specialty: s.selectionMode === 'halfHalf' ? s.half2Specialty : null,
    half1Ingredients: s.selectionMode === 'halfHalf' ? halfIngredients(1) : [],
    half2Ingredients: s.selectionMode === 'halfHalf' ? halfIngredients(2) : [],
    crustHalf1: s.crustEdge === 'Orilla Mitad y Mitad' ? s.crustHalf1 : null,
    crustHalf2: s.crustEdge === 'Orilla Mitad y Mitad' ? s.crustHalf2 : null,
    includePromoGarlicBread: s.includePromoGarlicBread,
  };

  const lines = [];
  if (s.selectionMode === 'halfHalf') {
    lines.push(`${s.size} · Pizza mitad y mitad`);
    lines.push(`Mitad 1: ${s.half1Mode === 'specialty' ? s.half1Specialty : 'Ingredientes personalizados'}`);
    lines.push(`Mitad 2: ${s.half2Mode === 'specialty' ? s.half2Specialty : 'Ingredientes personalizados'}`);
  } else {
    lines.push(`${s.size} · ${s.specialty}`);
  }
  if (s.crustEdge === 'Orilla Mitad y Mitad') {
    lines.push(`Orilla: Mitad y Mitad (${s.crustHalf1} / ${s.crustHalf2})`);
  } else {
    lines.push(`Orilla: ${s.crustEdge}`);
  }
  lines.push(`Pan: ${s.breadType} · ${s.dorada ? 'Dorada' : 'Normal'}`);
  if (s.extraIngredients.length) lines.push(`Extras: ${s.extraIngredients.join(', ')}`);
  if (s.includePromoGarlicBread) lines.push('Panes de ajo promo');

  agregarAlCarrito({ producto: p, cantidad: 1, config: { builder: 'pizza_builder', json, lines }, precio: price });
  closeConfig();
}

/* --- Alitas Config --- */
let wingsState = {};
function abrirConfigAlitas(p) {
  wingsState = { size:'orden', sauceMode:'unica', sauce:'Salsa mediana', sauceHalf1:'Salsa mediana', sauceHalf2:'Salsa mango habanero', naturales:false, sauceOnSide:false, juicy:false, doradas:false, boneType:null, sinApio:false, sinZanahoria:false };
  renderConfigWings(p, 'Constructor de Alitas', 'ALITAS');
}
function abrirConfigBoneless(p) {
  wingsState = { size:'orden', sauceMode:'unica', sauce:'Salsa mediana', sauceHalf1:'Salsa mediana', sauceHalf2:'Salsa mango habanero', naturales:false, sauceOnSide:false, juicy:false, doradas:false, boneType:null, sinApio:false, sinZanahoria:false };
  renderConfigWings(p, 'Constructor de Boneless', 'BONELESS');
}

function calcWingsPrice() {
  return WINGS_CATALOG.sizes.find(s => s.key === wingsState.size)?.price || 189;
}

function renderConfigWings(p, title, prefix) {
  const c = WINGS_CATALOG;
  const s = wingsState;
  const price = calcWingsPrice();

  const sizeSection = `
    <div class="opt-group">
      <span class="opt-label">Tamaño</span>
      <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:8px">
        ${c.sizes.map(sz => `<div class="price-btn ${s.size === sz.key ? 'active' : ''}" onclick="setWingsSize('${escapeJs(sz.key)}')"><div style="font-weight:700;font-size:14px">${escapeHtml(sz.label)}</div><div style="font-size:11px;color:var(--text-secondary)">+$${sz.price.toFixed(0)}</div></div>`).join('')}
      </div>
    </div>
  `;

  const sauceModeSection = `
    <div class="opt-group">
      <span class="opt-label">Modo de salsa</span>
      <div style="display:grid;grid-template-columns:repeat(2,1fr);gap:8px">
        <div class="price-btn ${s.sauceMode === 'unica' ? 'active' : ''}" onclick="setWingsSauceMode('unica')"><div style="font-weight:700;font-size:14px">Unica</div></div>
        <div class="price-btn ${s.sauceMode === 'mitadMitad' ? 'active' : ''}" onclick="setWingsSauceMode('mitadMitad')"><div style="font-weight:700;font-size:14px">Mitad y mitad</div></div>
      </div>
    </div>
  `;

  const sauceSection = s.sauceMode === 'unica' ? `
    <div class="opt-group"><span class="opt-label">Salsa</span><div style="display:flex;flex-wrap:wrap;gap:8px">${c.sauces.map(sc => `<button class="btn-chip ${s.sauce === sc ? 'active' : ''}" onclick="setWingsSauce('${escapeJs(sc)}')">${escapeHtml(sc.replace(/^Salsa\s+/i,''))}</button>`).join('')}</div></div>
  ` : `
    <div class="opt-group"><span class="opt-label">Salsa Mitad 1</span><div style="display:flex;flex-wrap:wrap;gap:8px">${c.sauces.map(sc => `<button class="btn-chip ${s.sauceHalf1 === sc ? 'active' : ''}" onclick="setWingsSauceHalf1('${escapeJs(sc)}')">${escapeHtml(sc.replace(/^Salsa\s+/i,''))}</button>`).join('')}</div></div>
    <div class="opt-group"><span class="opt-label">Salsa Mitad 2</span><div style="display:flex;flex-wrap:wrap;gap:8px">${c.sauces.map(sc => `<button class="btn-chip ${s.sauceHalf2 === sc ? 'active' : ''}" onclick="setWingsSauceHalf2('${escapeJs(sc)}')">${escapeHtml(sc.replace(/^Salsa\s+/i,''))}</button>`).join('')}</div></div>
  `;

  const optsSection = `
    <div class="opt-group"><span class="opt-label">Opciones</span><div class="opt-list">
      ${optCheckBool('naturales', 'Naturales', s.naturales)}
      ${optCheckBool('sauceOnSide', 'Salsa aparte', s.sauceOnSide)}
      ${optCheckBool('juicy', 'Jugosas', s.juicy)}
      ${optCheckBool('doradas', 'Doradas', s.doradas)}
      ${optCheckBool('sinApio', 'Sin apio', s.sinApio)}
      ${optCheckBool('sinZanahoria', 'Sin zanahoria', s.sinZanahoria)}
    </div></div>
  `;

  const body = sizeSection + sauceModeSection + sauceSection + optsSection;
  const footer = `<button class="btn-primary" onclick="confirmarWings(${p.id},'${escapeJs(prefix)}')">Agregar ${escapeHtml(prefix)} a la Orden</button>`;
  openConfigModal(title, body, footer);
}

function setWingsSize(v) { wingsState.size = v; renderConfigWings(productoConfigurando, productoConfigurando.nombre.toLowerCase().includes('boneless') ? 'Constructor de Boneless' : 'Constructor de Alitas', productoConfigurando.nombre.toLowerCase().includes('boneless') ? 'BONELESS' : 'ALITAS'); }
function setWingsSauceMode(v) { wingsState.sauceMode = v; setWingsSize(wingsState.size); }
function setWingsSauce(v) { wingsState.sauce = v; setWingsSize(wingsState.size); }
function setWingsSauceHalf1(v) { wingsState.sauceHalf1 = v; setWingsSize(wingsState.size); }
function setWingsSauceHalf2(v) { wingsState.sauceHalf2 = v; setWingsSize(wingsState.size); }

function confirmarWings(productId, prefix) {
  const p = findProduct(productId);
  const s = wingsState;
  const lines = [];
  if (s.naturales) {
    if (s.sauceOnSide) {
      lines.push(s.sauceMode === 'mitadMitad' ? `NATURALES + MITAD ${shortSauce(s.sauceHalf1)} / ${shortSauce(s.sauceHalf2)} APARTE` : `NATURALES + SALSA ${shortSauce(s.sauce)} APARTE`);
    } else lines.push('NATURALES');
  } else {
    if (s.sauceMode === 'mitadMitad') {
      const halfLine = `1/2 ${shortSauce(s.sauceHalf1)} / 1/2 ${shortSauce(s.sauceHalf2)}`;
      lines.push(s.sauceOnSide ? `${halfLine} APARTE` : halfLine);
    } else {
      const singleLine = `SALSA ${shortSauce(s.sauce)}`;
      lines.push(s.sauceOnSide ? `${singleLine} APARTE` : singleLine);
    }
  }
  if (s.juicy) lines.push('Jugosas');
  if (s.doradas) lines.push('Doradas');
  if (s.sinApio) lines.push('Sin apio');
  if (s.sinZanahoria) lines.push('Sin zanahoria');
  const json = { size:s.size, sauceMode:s.sauceMode, sauce:s.sauceMode==='unica'?s.sauce:null, sauceHalf1:s.sauceMode==='mitadMitad'?s.sauceHalf1:null, sauceHalf2:s.sauceMode==='mitadMitad'?s.sauceHalf2:null, naturales:s.naturales, sauceOnSide:s.sauceOnSide, juicy:s.juicy, doradas:s.doradas, boneType:s.boneType, sinApio:s.sinApio, sinZanahoria:s.sinZanahoria };
  agregarAlCarrito({ producto: p, cantidad: 1, config: { builder: 'wings_builder', json, lines }, precio: calcWingsPrice() });
  closeConfig();
}

function shortSauce(v) { return (v || '').replace(/^Salsa\s+/i, '').toUpperCase(); }

/* --- Espagueti Config --- */
let spagState = {};
function abrirConfigEspagueti(p) {
  spagState = { type:'A la boloñesa', accompaniment:'Panes de ajo', garlicBreadType:'Normales', extras:[], removedIngredients:[], sinQueso:false, sinMantequilla:false, pocaSalsa:false, quesoDorado:false };
  renderConfigEspagueti(p);
}

function calcSpagPrice() {
  const c = SPAG_CATALOG;
  const s = spagState;
  let price = c.types.find(t => t.name === s.type)?.price || 139;
  const gb = c.garlicBreadTypes.find(g => g.name === s.garlicBreadType);
  if (gb) price += gb.price;
  s.extras.forEach(ex => { const ep = c.extras.find(e => e.name === ex); if (ep) price += ep.price; });
  return price;
}

function renderConfigEspagueti(p) {
  const c = SPAG_CATALOG;
  const s = spagState;
  const price = calcSpagPrice();

  const typeSection = `
    <div class="opt-group"><span class="opt-label">Tipo</span><div class="opt-list">
      ${c.types.map(t => optRadio('type', t.name, t.name, '', s.type)).join('')}
    </div></div>
  `;

  const accSection = `
    <div class="opt-group"><span class="opt-label">Acompañamiento</span><div class="opt-list">
      ${c.accompaniments.map(a => optRadio('accompaniment', a, a, '', s.accompaniment)).join('')}
    </div></div>
  `;

  const gbSection = s.accompaniment === 'Panes de ajo' ? `
    <div class="opt-group"><span class="opt-label">Tipo de pan de ajo</span><div class="opt-list">
      ${c.garlicBreadTypes.map(g => optRadio('garlicBreadType', g.name, g.name, g.price > 0 ? `+$${g.price.toFixed(0)}` : '', s.garlicBreadType)).join('')}
    </div></div>
  ` : '';

  const extraSection = `
    <div class="opt-group"><span class="opt-label">Extras</span><div class="opt-list">
      ${c.extras.map(e => optCheck('extras', e.name, `${e.name} (+$${e.price.toFixed(0)})`, '', s.extras.includes(e.name))).join('')}
    </div></div>
  `;

  const optsSection = `
    <div class="opt-group"><span class="opt-label">Opciones</span><div class="opt-list">
      ${optCheckBool('sinQueso', 'Sin queso', s.sinQueso)}
      ${optCheckBool('sinMantequilla', 'Sin mantequilla', s.sinMantequilla)}
      ${optCheckBool('pocaSalsa', 'Poca salsa', s.pocaSalsa)}
      ${optCheckBool('quesoDorado', 'Queso dorado', s.quesoDorado)}
    </div></div>
  `;

  const body = typeSection + accSection + gbSection + extraSection + optsSection;
  const footer = `<button class="btn-primary" onclick="confirmarEspagueti(${p.id})">Agregar — $${price.toFixed(0)}</button>`;
  openConfigModal('Configurar Espagueti', body, footer);
}

function setSpagType(v) { spagState.type = v; renderConfigEspagueti(productoConfigurando); }
function setSpagAcc(v) { spagState.accompaniment = v; renderConfigEspagueti(productoConfigurando); }
function setSpagGB(v) { spagState.garlicBreadType = v; renderConfigEspagueti(productoConfigurando); }

function confirmarEspagueti(productId) {
  const p = findProduct(productId);
  const s = spagState;
  const lines = [`Tipo: ${s.type}`];
  if (s.accompaniment === 'Panes de ajo') lines.push(`Pan de ajo: ${s.garlicBreadType}`);
  else lines.push('Acompañamiento: Papas');
  if (s.extras.length) lines.push(`Extras: ${s.extras.join(', ')}`);
  const json = { spaghettiType:s.type, accompaniment:s.accompaniment, garlicBreadType:s.accompaniment==='Panes de ajo'?s.garlicBreadType:null, removedIngredients:[...s.removedIngredients], sinQueso:s.sinQueso, sinMantequilla:s.sinMantequilla, pocaSalsa:s.pocaSalsa, quesoDorado:s.quesoDorado, extras:[...s.extras] };
  agregarAlCarrito({ producto: p, cantidad: 1, config: { builder: 'spaghetti_builder', json, lines }, precio: calcSpagPrice() });
  closeConfig();
}

/* --- Hamburguesa Config --- */
let hamState = {};
function abrirConfigHamburguesa(p) {
  hamState = { burgerType:'Clásica', side:'conPapas', removedIngredients:[], extraIngredients:[], usedSinVerduraQuickAction:false, cutOption:'completa', isSpecialCombo:false, combo1:{type:'Clásica',extras:[]}, combo2:{type:'Clásica',extras:[]} };
  renderConfigHamburguesa(p);
}

function calcHamPrice() {
  const c = HAM_CATALOG;
  const s = hamState;
  let price = c.types.find(t => t.name === s.burgerType)?.price || 139;
  const side = c.sides.find(sd => sd.name === s.side);
  if (side) price += side.adjustment;
  price += s.extraIngredients.length * c.extraPrice;
  return price;
}

function renderConfigHamburguesa(p) {
  const c = HAM_CATALOG;
  const s = hamState;
  const price = calcHamPrice();

  const typeSection = `
    <div class="opt-group"><span class="opt-label">Tipo</span><div class="opt-list">
      ${c.types.map(t => optRadio('burgerType', t.name, t.name, `+$${t.price.toFixed(0)}`, s.burgerType)).join('')}
    </div></div>
  `;

  const sideSection = `
    <div class="opt-group"><span class="opt-label">Papas</span><div class="opt-list">
      ${c.sides.map(sd => optRadio('side', sd.name, sd.label, sd.adjustment !== 0 ? (sd.adjustment > 0 ? `+$${sd.adjustment.toFixed(0)}` : `-$${Math.abs(sd.adjustment).toFixed(0)}`) : '', s.side)).join('')}
    </div></div>
  `;

  const extrasSection = `
    <div class="opt-group"><span class="opt-label">Extras (+$${c.extraPrice.toFixed(2)} c/u)</span><div style="display:flex;flex-wrap:wrap;gap:8px">
      ${c.extras.map(ex => `<button class="btn-chip ${s.extraIngredients.includes(ex) ? 'active-red' : ''}" onclick="toggleHamExtra('${escapeJs(ex)}')">${escapeHtml(ex)}</button>`).join('')}
    </div></div>
  `;

  const body = typeSection + sideSection + extrasSection;
  const footer = `<button class="btn-primary" onclick="confirmarHamburguesa(${p.id})">Agregar — $${price.toFixed(0)}</button>`;
  openConfigModal('Configurar Hamburguesa', body, footer);
}

function setHamType(v) { hamState.burgerType = v; renderConfigHamburguesa(productoConfigurando); }
function setHamSide(v) { hamState.side = v; renderConfigHamburguesa(productoConfigurando); }
function toggleHamExtra(ex) {
  const idx = hamState.extraIngredients.indexOf(ex);
  if (idx >= 0) hamState.extraIngredients.splice(idx, 1);
  else hamState.extraIngredients.push(ex);
  renderConfigHamburguesa(productoConfigurando);
}

function confirmarHamburguesa(productId) {
  const p = findProduct(productId);
  const s = hamState;
  const lines = [`Tipo: ${s.burgerType}`];
  const sideLabel = HAM_CATALOG.sides.find(sd => sd.name === s.side)?.label || '';
  lines.push(sideLabel);
  if (s.extraIngredients.length) lines.push(`Extras: ${s.extraIngredients.join(', ')}`);
  const json = { burgerType:s.burgerType, side:s.side, removedIngredients:[...s.removedIngredients], extraIngredients:[...s.extraIngredients], usedSinVerduraQuickAction:s.usedSinVerduraQuickAction, cutOption:s.cutOption, isSpecialCombo:s.isSpecialCombo };
  agregarAlCarrito({ producto: p, cantidad: 1, config: { builder: 'hamburger_builder', json, lines }, precio: calcHamPrice() });
  closeConfig();
}

/* === Option Helpers === */
function optRadio(group, value, label, extra, selected) {
  const sel = selected === value ? 'selected' : '';
  return `<div class="opt-item ${sel}" onclick="handleOpt('${group}', '${escapeJs(value)}')">
    <div class="opt-item-left"><div class="opt-radio"></div><div class="opt-name">${escapeHtml(label)}</div></div>
    <div class="opt-price">${extra ? escapeHtml(extra) : ''}</div>
  </div>`;
}
function optCheck(group, value, label, extra, checked) {
  const sel = checked ? 'selected' : '';
  return `<div class="chk-opt ${sel}" onclick="handleCheck('${group}', '${escapeJs(value)}')">
    <div style="display:flex;align-items:center;gap:10px"><div class="chk-box"></div><div class="opt-name">${escapeHtml(label)}</div></div>
    <div class="opt-price">${extra ? escapeHtml(extra) : ''}</div>
  </div>`;
}
function optCheckBool(key, label, checked) {
  const sel = checked ? 'selected' : '';
  return `<div class="chk-opt ${sel}" onclick="handleBool('${key}')"><div style="display:flex;align-items:center;gap:10px"><div class="chk-box"></div><div class="opt-name">${escapeHtml(label)}</div></div></div>`;
}

function handleOpt(group, value) {
  if (productoConfigurando?.nombre.toLowerCase().includes('pizza')) {
    if (group === 'size') setPizzaSize(value);
    else if (group === 'crustEdge') setPizzaCrust(value);
    else if (group === 'breadType') setPizzaBread(value);
  } else if (productoConfigurando?.nombre.toLowerCase().includes('espagueti')) {
    if (group === 'type') setSpagType(value);
    else if (group === 'accompaniment') setSpagAcc(value);
    else if (group === 'garlicBreadType') setSpagGB(value);
  } else if (productoConfigurando?.nombre.toLowerCase().includes('hamburguesa')) {
    if (group === 'burgerType') setHamType(value);
    else if (group === 'side') setHamSide(value);
  }
}
function handleCheck(group, value) {
  if (productoConfigurando?.nombre.toLowerCase().includes('pizza') && group === 'extraIngredients') togglePizzaExtra(value);
  else if (productoConfigurando?.nombre.toLowerCase().includes('espagueti') && group === 'extras') {
    const idx = spagState.extras.indexOf(value);
    if (idx >= 0) spagState.extras.splice(idx, 1); else spagState.extras.push(value);
    renderConfigEspagueti(productoConfigurando);
  }
}
function handleBool(key) {
  if (productoConfigurando?.nombre.toLowerCase().includes('alita') || productoConfigurando?.nombre.toLowerCase().includes('boneless')) {
    wingsState[key] = !wingsState[key];
    const title = productoConfigurando.nombre.toLowerCase().includes('boneless') ? 'Constructor de Boneless' : 'Constructor de Alitas';
    const prefix = productoConfigurando.nombre.toLowerCase().includes('boneless') ? 'BONELESS' : 'ALITAS';
    renderConfigWings(productoConfigurando, title, prefix);
  } else if (productoConfigurando?.nombre.toLowerCase().includes('espagueti')) {
    spagState[key] = !spagState[key];
    renderConfigEspagueti(productoConfigurando);
  }
}

/* === Carrito === */
function agregarAlCarrito(item) {
  carrito.push(item);
  renderCartFab();
  toast(`${item.producto.nombre} agregado`, 'success');
}

function renderCartFab() {
  const total = carrito.reduce((s, i) => s + i.precio * i.cantidad, 0);
  const count = carrito.reduce((s, i) => s + i.cantidad, 0);
  let el = document.getElementById('cart-fab');
  if (!el) {
    el = document.createElement('div');
    el.id = 'cart-fab';
    el.className = 'cart-fab';
    document.body.appendChild(el);
  }
  if (count === 0) { el.style.display = 'none'; return; }
  el.style.display = 'flex';
  el.innerHTML = `
    <button class="cart-fab-btn" onclick="openCart()">
      <span>Ver pedido</span>
      <span style="display:flex;align-items:center;gap:8px">
        <span class="cart-fab-count">${count}</span>
        <span>$${total.toFixed(0)}</span>
      </span>
    </button>
  `;
}

function openCart() {
  renderCartDrawer();
  document.getElementById('cart-overlay').classList.add('open');
}
function closeCart() {
  document.getElementById('cart-overlay').classList.remove('open');
}

function renderCartDrawer() {
  const body = document.getElementById('cart-body');
  const footer = document.getElementById('cart-footer');
  if (carrito.length === 0) {
    body.innerHTML = '<p style="text-align:center;color:var(--text-secondary);padding:40px">Tu carrito esta vacio</p>';
    footer.innerHTML = '<button class="btn-secondary" onclick="closeCart()">Seguir comprando</button>';
    return;
  }
  body.innerHTML = carrito.map((item, idx) => {
    const configText = item.config?.lines?.join(' · ') || '';
    return `
      <div class="cart-item">
        <div class="cart-item-info">
          <div class="cart-item-name">${escapeHtml(item.producto.nombre)}</div>
          ${configText ? `<div class="cart-item-config">${escapeHtml(configText)}</div>` : ''}
          <div class="cart-item-price">$${(item.precio * item.cantidad).toFixed(0)}</div>
        </div>
        <div class="cart-item-actions">
          <button class="cart-item-btn" onclick="changeQty(${idx}, -1)">-</button>
          <span style="font-weight:700;font-size:15px;min-width:20px;text-align:center">${item.cantidad}</span>
          <button class="cart-item-btn" onclick="changeQty(${idx}, 1)">+</button>
        </div>
      </div>
    `;
  }).join('');
  const total = carrito.reduce((s, i) => s + i.precio * i.cantidad, 0);
  footer.innerHTML = `
    <div class="form-group" style="margin-bottom:12px">
      <label>Nombre (opcional)</label>
      <input type="text" id="client-name" class="form-control" placeholder="Como te llamamos?">
    </div>
    <div class="total-line"><span>Total</span><span>$${total.toFixed(0)}</span></div>
    <button class="btn-primary" onclick="enviarPedido()">Enviar a cocina</button>
    <button class="btn-secondary" onclick="closeCart()">Seguir comprando</button>
  `;
}

function changeQty(idx, delta) {
  carrito[idx].cantidad += delta;
  if (carrito[idx].cantidad <= 0) carrito.splice(idx, 1);
  renderCartDrawer();
  renderCartFab();
}

/* === Checkout === */
async function enviarPedido() {
  if (carrito.length === 0) { toast('Tu carrito esta vacio', 'error'); return; }
  const nombre = document.getElementById('client-name')?.value.trim() || '';

  const items = carrito.map(item => {
    const isVirtual = item.producto.virtual === true;
    const payload = {
      cantidad: item.cantidad,
      precio_unitario: item.precio,
      nombre_snapshot: item.producto.nombre,
      sku_snapshot: item.producto.sku || '',
      config_builder_tipo: item.config?.builder || null,
      config_builder_json: item.config?.json || null,
      display_lines_json: item.config?.lines || null,
      notas: item.config?.lines?.join(', ') || '',
    };
    if (!isVirtual) {
      payload.producto_id = item.producto.id;
    }
    return payload;
  });

  const payload = {
    sucursal_id: BRANCH_ID,
    mesa_id: parseInt(MESA) || null,
    mesa_label: MESA_LABEL,
    nombre_cliente: nombre,
    items,
    observaciones: nombre ? `Cliente: ${nombre}` : 'Pedido QR',
  };

  try {
    const res = await fetch(`${API_BASE}/qr/pedido`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });
    const data = await res.json();
    if (!data.success) throw new Error(data.message || 'Error al enviar pedido');
    closeCart();
    carrito = [];
    renderCartFab();
    renderSuccess(data.data);
  } catch (e) {
    toast(e.message, 'error');
  }
}

function renderSuccess(order) {
  const app = document.getElementById('app');
  app.innerHTML = `
    <div class="success-screen">
      <div class="success-icon">🍕</div>
      <h2>Pedido enviado</h2>
      <p>Tu numero de pedido es <strong>#${escapeHtml(order.folio || '')}</strong></p>
      <p>Estamos preparando tu orden. En un momento te la llevamos.</p>
      <button class="btn-primary" style="margin-top:24px;max-width:280px" onclick="location.reload()">Hacer otro pedido</button>
    </div>
  `;
}

/* === Toast === */
function toast(msg, type = 'success') {
  const container = document.getElementById('toast-container');
  const el = document.createElement('div');
  el.className = `toast-msg ${type}`;
  el.textContent = msg;
  container.appendChild(el);
  setTimeout(() => el.remove(), 3000);
}

/* === Utils === */
function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text || '';
  return div.innerHTML;
}
function escapeJs(str) {
  return String(str || '').replace(/'/g, "\\'").replace(/"/g, '\\"');
}
