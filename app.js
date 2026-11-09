/** Visualizador local: importación verificada y diagrama de erd-editor (MIT). */
const STORAGE_KEY = 'erd-app.current-model';
const LEGACY_STORAGE_KEY = 'urbanizadoras.erd.app';
const EXAMPLE_URL = 'examples/demo-150-mysql.sql';
const editor = document.getElementById('editor');
const statusEl = document.getElementById('status');
const countsEl = document.getElementById('counts');
const fileInput = document.getElementById('file-input');
const jsonInput = document.getElementById('json-input');
const dropOverlay = document.getElementById('drop-overlay');
const canvasWrap = document.getElementById('canvas-wrap');
const pasteDialog = document.getElementById('paste-dialog');
const pasteText = document.getElementById('paste-text');
const pasteFormat = document.getElementById('paste-format');
const databaseInput = document.getElementById('database');
const reportEl = document.getElementById('import-report');
const tableList = document.getElementById('table-list');
const tableSearch = document.getElementById('table-search');
const detailEl = document.getElementById('table-detail');
const FORMAT_BY_EXT = { sql: 'sql', dbml: 'dbml', json: 'json', graphql: 'graphql', gql: 'graphql', graphqls: 'graphql', aml: 'aml' };
const FORMAT_LABEL = { sql: 'SQL', dbml: 'DBML', json: 'JSON', graphql: 'GraphQL', aml: 'AML' };
// Valores de Database y ColumnOption del bundle local 4.2.0.
const DATABASES = { MariaDB: 1, MSSQL: 2, MySQL: 4, Oracle: 8, PostgreSQL: 16, SQLite: 32 };
let busy = false, saveTimer = null, selectedTable = null;
let documentName = 'diagrama', lastImport = null;
let editorStore;
const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));

const editorReady = (async () => {
  let timer;
  try {
    await Promise.race([
      customElements.whenDefined('erd-editor'),
      new Promise((_, reject) => { timer = setTimeout(() => reject(new Error('No se pudo cargar erd-editor. Sirve la aplicación por HTTP y revisa vendor/.')), 6000); }),
    ]);
  } finally { clearTimeout(timer); }
  await sleep(80);
})();

function setStatus(text, kind = '') {
  statusEl.textContent = text;
  statusEl.className = kind;
}

function readDocument() { return editor.value ? JSON.parse(editor.value) : {}; }
// Acciones del SharedStore del editor 4.2.0: cambian vista y motor sin recargar
// el documento ni perder el historial de edición.
function dispatchSettings(actions) {
  editorStore ||= editor.getSharedStore({ mouseTracker: false, focusTracker: false });
  editorStore.dispatchSync(actions);
}
function positionView(zoom, x, y) {
  dispatchSettings([
    { type: 'settings.changeLockSettings', payload: { lockSettingType: 1, value: false, values: {} } },
    { type: 'settings.changeCanvasType', payload: { value: 'ERD' } },
    { type: 'settings.changeZoomLevel', payload: { value: zoom } },
    { type: 'settings.scrollTo', payload: { originX: x, originY: y } },
  ]);
}
function focusTable(id) {
  const table = readDocument().collections?.tableEntities?.[id];
  if (!table) return;
  positionView(0.85, Math.max(20, canvasWrap.clientWidth / 2 - 180) - table.ui.x * 0.85, 80 - table.ui.y * 0.85);
}
function showOverview() {
  const doc = readDocument(), c = doc.collections || {};
  const tables = Object.values(c.tableEntities || {});
  if (!tables.length) return;
  const left = Math.min(...tables.map(t => t.ui.x));
  const top = Math.min(...tables.map(t => t.ui.y));
  const right = Math.max(...tables.map(t => {
    const cols = t.columnIds.map(id => c.tableColumnEntities[id]);
    const width = Math.max(260, t.name.length * 8, ...cols.map(col => ((col?.name?.length || 0) + (col?.dataType?.length || 0)) * 8 + 130));
    return t.ui.x + width;
  }));
  const bottom = Math.max(...tables.map(t => t.ui.y + (t.columnIds.length + 2) * 32));
  const width = Math.max(1, canvasWrap.clientWidth - 80), height = Math.max(1, canvasWrap.clientHeight - 120);
  const zoom = Math.max(0.1, Math.min(1, width / (right - left), height / (bottom - top)));
  positionView(zoom, canvasWrap.clientWidth / 2 - (left + right) / 2 * zoom, canvasWrap.clientHeight / 2 - (top + bottom) / 2 * zoom);
}
function ensureVisibleTables() {
  const doc = readDocument(), s = doc.settings || {};
  const visible = Object.values(doc.collections?.tableEntities || {}).some(t => {
    const x = t.ui.x * s.zoomLevel + s.originX, y = t.ui.y * s.zoomLevel + s.originY;
    return x >= 0 && x < canvasWrap.clientWidth - 40 && y >= 30 && y < canvasWrap.clientHeight - 60;
  });
  if (!visible) showOverview();
}
function counts(doc = readDocument()) {
  const c = doc.collections || {};
  return {
    tables: Object.keys(c.tableEntities || {}).length,
    columns: Object.keys(c.tableColumnEntities || {}).length,
    relationships: Object.keys(c.relationshipEntities || {}).length,
    indexes: Object.keys(c.indexEntities || {}).length,
  };
}
function renderCounts(value = counts()) {
  countsEl.textContent = `${value.tables} tablas · ${value.columns} columnas · ${value.relationships} relaciones`;
  for (const key of ['tables', 'columns', 'relationships']) countsEl.dataset[key] = String(value[key]);
  return value;
}
async function persist() {
  let stored = false;
  try { await AnalysisStorage.set('current-model', { value: editor.value }); stored = true; } catch (error) { console.warn('Almacenamiento del modelo no disponible', error); }
  try { localStorage.setItem(STORAGE_KEY, editor.value); stored = true; } catch (error) { console.warn('Copia de compatibilidad no disponible', error); }
  if (!stored) setStatus('Diagrama disponible, pero no se pudo autoguardar. Usa Guardar modelo completo.', 'warning');
  return stored;
}

function setBusy(value) {
  busy = value;
  editor.inert = value;
  for (const region of ['analysis-canvas', 'table-panel', 'inspector']) document.getElementById(region).inert = value;
  document.querySelector('.analysis-nav').inert = value;
  canvasWrap.setAttribute('aria-busy', String(value));
  for (const control of document.querySelectorAll('[data-import-lock]')) control.disabled = value;
  document.getElementById('loading-overlay').hidden = !value;
}
function detectFormat(filename = '') {
  const path = filename.split(/[?#]/)[0].toLowerCase();
  const format = FORMAT_BY_EXT[path.split('.').pop()];
  if (!format) throw new Error('Formato no admitido. Usa SQL, DBML, GraphQL, AML o un documento .erd.json. Las bases binarias requieren exportar su DDL SQL.');
  return format;
}
function validateJson(text) {
  let doc;
  try { doc = JSON.parse(text); } catch { throw new Error('El JSON no es válido.'); }
  if (!doc || typeof doc !== 'object' || !doc.collections || !doc.collections.tableEntities ||
      typeof doc.collections.tableEntities !== 'object' || !doc.settings || !doc.doc) {
    throw new Error('Este JSON no es un documento de erd-editor (.erd.json). Exporta el esquema como SQL o DBML.');
  }
  return doc;
}
function normalizeSqlPrimaryKeys() {
  const doc = readDocument();
  let changed = false;
  for (const col of Object.values(doc.collections?.tableColumnEntities || {})) {
    // MySQL, PostgreSQL, MSSQL y Oracle hacen NOT NULL implícito en PK.
    // En SQLite las excepciones dependen de la forma exacta de la declaración;
    // conservamos la nulabilidad entregada por su parser.
    const implicitNotNull = doc.settings.database !== DATABASES.SQLite;
    if ((col.options & 2) && implicitNotNull && !(col.options & 8)) {
      col.options |= 8; changed = true;
    }
  }
  if (changed) editor.setInitialValue(JSON.stringify(doc));
}
async function applyText(text, format) {
  // La vista de análisis calcula su propio layout; no ordenar el documento entero al importar.
  const options = { placement: 'grid', mode: 'replace' };
  switch (format) {
    case 'sql': return await editor.setSchemaSQL(text, options);
    case 'dbml': return await editor.setSchemaDBML(text, options);
    case 'graphql': return await editor.setSchemaGraphQL(text, options);
    case 'aml': return await editor.setSchemaAML(text, options);
    case 'json': return editor.setInitialValue(text);
    default: throw new Error(`Formato no soportado: ${format}`);
  }
}

function renderReport() {
  reportEl.replaceChildren();
  if (!lastImport) return;
  const summary = document.createElement('strong');
  summary.textContent = lastImport.error ? 'No se reemplazó el diagrama' : lastImport.name;
  reportEl.append(summary);
  const text = document.createElement('p');
  text.textContent = lastImport.error ||
    (lastImport.verified ? 'SQL contrastado: nombres de tablas, columnas declaradas y cantidad de relaciones.' : 'Documento cargado. Revisa los detalles en el panel de tablas.');
  reportEl.append(text);
  for (const warning of lastImport.warnings || []) {
    const p = document.createElement('p'); p.className = 'report-warning'; p.textContent = warning; reportEl.append(p);
  }
}

// Un único bloqueo cubre lectura, conversión, distribución y validación.
async function runImport(load, options = {}) {
  if (busy) return null;
  setBusy(true);
  clearTimeout(saveTimer);
  let previous = null;
  const previousAnalysis = window.analysis?.pack();
  try {
    await editorReady;
    previous = editor.value;
    setStatus('Leyendo esquema…');
    const input = await load();
    const { format, name = 'esquema' } = input;
    const text = input.text?.replace(/^\uFEFF/, '').trim();
    if (!text) throw new Error('El archivo o texto está vacío.');
    if (text.includes('\0')) throw new Error('El archivo parece binario. Exporta la estructura de la base como SQL DDL.');
    if (!FORMAT_LABEL[format]) throw new Error(`Formato no soportado: ${format}`);
    const expected = format === 'sql' ? SchemaAudit.inspect(text) : null;
    const importedMetadata = format === 'json' ? validateJson(text).erdApp : null;
    setStatus(`Importando ${name}… distribuyendo tablas y comprobando el resultado.`);
    await sleep(30);
    if (format === 'sql') {
      const database = options.database || databaseInput.value;
      if (!DATABASES[database]) throw new Error(`Motor SQL no admitido: ${database}`);
      dispatchSettings({ type: 'settings.changeDatabase', payload: { value: DATABASES[database] } });
    }
    await applyText(text, format);
    if (format === 'sql') normalizeSqlPrimaryKeys();
    const doc = readDocument(), value = counts(doc);
    if (!value.tables) throw new Error('No se detectaron tablas. Revisa el esquema y el formato. El diagrama anterior se conserva.');
    const warnings = expected ? SchemaAudit.compare(expected, doc) : [];
    const metadata = importedMetadata || (expected ? { names: Object.fromEntries((expected.foreignKeys || []).filter(r => r.name).map(r => [JSON.stringify([r.child, r.childCols, r.parent, r.parentCols]), r.name])) } : null);
    await renderExplorer(doc, metadata);
    toggleNative(false);
    document.getElementById('document-name').textContent = name;
    documentName = name;
    databaseInput.value = Object.keys(DATABASES).find(key => DATABASES[key] === doc.settings?.database) || 'MySQL';
    lastImport = { name, format, verified: !!expected, warnings, ...value };
    renderCounts(value); renderReport();
    setStatus(`${name}: ${value.tables} tablas disponibles${warnings.length ? ' · revisa los avisos' : ''}.`, warnings.length ? 'warning' : 'ok');
    await persist();
    console.info('[erd-app] Importación completada', lastImport);
    return value;
  } catch (error) {
    console.error('No se pudo importar el esquema', error);
    if (previous !== null && editor.value !== previous) {
      editor.setInitialValue(previous);
      try { await renderExplorer(readDocument(), { analysis: previousAnalysis }); } catch (restoreError) { console.warn(restoreError); }
    }
    lastImport = { error: error.message || String(error), warnings: [] };
    renderCounts(); renderReport();
    setStatus(`No se pudo importar: ${lastImport.error}`, 'error');
    return null;
  } finally {
    clearTimeout(saveTimer);
    setBusy(false);
  }
}

function importText(text, format = 'sql', name = 'esquema pegado', options = {}) {
  return runImport(async () => ({ text, format, name }), options);
}
async function readFile(file) {
  const bytes = new Uint8Array(await file.arrayBuffer());
  let encoding = 'utf-8';
  if (bytes[0] === 0xFF && bytes[1] === 0xFE) encoding = 'utf-16le';
  else if (bytes[0] === 0xFE && bytes[1] === 0xFF) encoding = 'utf-16be';
  try { return new TextDecoder(encoding, { fatal: true }).decode(bytes); }
  catch { throw new Error(`${file.name}: codificación no reconocida. Guarda el archivo como UTF-8 o UTF-16 con BOM.`); }
}
function importFiles(files, options = {}) {
  const list = Array.from(files || []);
  if (!list.length) return Promise.resolve(null);
  return runImport(async () => {
    const formats = list.map(file => detectFormat(file.name));
    if (list.length > 1 && formats.some(format => format !== 'sql')) throw new Error('Para combinar varios archivos, selecciona solo SQL del mismo motor y modelo. Los otros formatos se abren de uno en uno.');
    const parts = [];
    for (const file of list) {
      const text = await readFile(file);
      if (!text.trim()) throw new Error(`${file.name}: el archivo está vacío.`);
      parts.push(text);
    }
    return { text: parts.join('\n;\n'), format: formats[0], name: list.map(file => file.name).join(' + ') };
  }, options);
}
function importUrl(url, options = {}) {
  return runImport(async () => {
    const resolved = new URL(url, location.href);
    if (resolved.origin !== location.origin) throw new Error('Usa una URL del servidor local o carga el archivo con Subir esquema.');
    const format = detectFormat(resolved.pathname);
    const response = await fetch(resolved, { cache: 'no-store' });
    if (!response.ok) throw new Error(`No se pudo leer ${resolved.pathname}: HTTP ${response.status}.`);
    const file = new File([await response.arrayBuffer()], decodeURIComponent(resolved.pathname.split('/').pop()));
    return { text: await readFile(file), format, name: file.name };
  }, options);
}
async function restoreSaved() {
  try {
    let saved;
    try { saved = (await AnalysisStorage.get('current-model'))?.value; } catch (error) { console.warn(error); }
    saved ||= localStorage.getItem(STORAGE_KEY) || localStorage.getItem(LEGACY_STORAGE_KEY);
    if (saved) {
      validateJson(saved);
      editor.setInitialValue(saved);
      renderCounts(); await renderExplorer();
      databaseInput.value = Object.keys(DATABASES).find(key => DATABASES[key] === readDocument().settings?.database) || 'MySQL';
      setStatus('Diagrama anterior restaurado. Puedes cargar otro esquema.', 'ok');
      return;
    }
    renderCounts(); await renderExplorer();
    setStatus('Listo. Sube un esquema, pega código o carga el ejemplo de 150 tablas.', 'ok');
  } catch (error) {
    setStatus(`No se pudo restaurar el guardado: ${error.message}. Puedes cargar un esquema.`, 'error');
    renderCounts(); await renderExplorer();
  }
}
function saveJson() {
  if (busy) return;
  const blob = new Blob([JSON.stringify(window.analysis?.exportDocument(readDocument()) || readDocument(), null, 2)], { type: 'application/json;charset=utf-8' });
  const url = URL.createObjectURL(blob), link = document.createElement('a');
  const name = documentName.replace(/\.(erd\.)?(sql|dbml|json|graphql|gql|aml)$/i, '').replace(/[^\p{L}\p{N}_.-]+/gu, '_').slice(0, 100) || 'diagrama';
  link.href = url; link.download = `${name}.erd.json`;
  link.click(); setTimeout(() => URL.revokeObjectURL(url), 1000);
  setStatus(`Diagrama descargado como ${name}.erd.json`, 'ok');
}
function clearDiagram() {
  if (busy || !window.confirm('¿Vaciar el diagrama actual? Guarda una copia si la necesitas.')) return;
  clearTimeout(saveTimer);
  editor.clear(); lastImport = null; documentName = 'diagrama'; selectedTable = null;
  renderCounts(); renderExplorer().catch(error => setStatus(error.message, 'error')); renderReport();
  setStatus('Diagrama vacío. Sube o pega un esquema.', 'ok');
  persist();
}

function element(tag, text, className) {
  const el = document.createElement(tag); el.textContent = text;
  if (className) el.className = className;
  return el;
}
async function renderExplorer(doc = readDocument(), metadata = null) {
  if (window.analysis) await window.analysis.loadDocument(doc, metadata);
}
function toggleNative(force, tableId) {
  const show = typeof force === 'boolean' ? force : document.getElementById('native-editor').hidden;
  document.getElementById('native-editor').hidden = !show;
  document.getElementById('analysis-canvas').hidden = show;
  document.getElementById('toggle-editor').textContent = show ? 'Volver al análisis' : 'Editar esquema';
  if (show && tableId) requestAnimationFrame(() => focusTable(tableId));
  if (!show && typeof force !== 'boolean' && window.analysis) renderExplorer().catch(error => setStatus(error.message, 'error'));
}

function wireUi() {
  document.getElementById('btn-upload').addEventListener('click', () => fileInput.click());
  fileInput.addEventListener('change', () => {
    const files = Array.from(fileInput.files || []); fileInput.value = ''; importFiles(files);
  });
  document.getElementById('btn-open').addEventListener('click', () => jsonInput.click());
  jsonInput.addEventListener('change', () => {
    const files = Array.from(jsonInput.files || []); jsonInput.value = ''; importFiles(files);
  });
  document.getElementById('btn-example').addEventListener('click', () => importUrl(EXAMPLE_URL, { database: 'MySQL' }));
  document.getElementById('btn-save').addEventListener('click', saveJson);
  document.getElementById('btn-new').addEventListener('click', clearDiagram);
  document.getElementById('toggle-editor').addEventListener('click', () => toggleNative());
  document.getElementById('empty-example').addEventListener('click', () => importUrl(EXAMPLE_URL, { database: 'MySQL' }));
  document.getElementById('btn-paste').addEventListener('click', () => { pasteDialog.showModal(); pasteText.focus(); });
  document.getElementById('btn-close-paste').addEventListener('click', () => pasteDialog.close());
  document.getElementById('paste-form').addEventListener('submit', async event => {
    event.preventDefault(); pasteDialog.close();
    await importText(pasteText.value, pasteFormat.value, `texto pegado (${FORMAT_LABEL[pasteFormat.value]})`);
  });
  let dragDepth = 0;
  const hideOverlay = () => { dragDepth = 0; dropOverlay.hidden = true; };
  canvasWrap.addEventListener('dragenter', event => { event.preventDefault(); if (!busy) { dragDepth++; dropOverlay.hidden = false; } });
  canvasWrap.addEventListener('dragover', event => { event.preventDefault(); event.dataTransfer.dropEffect = busy ? 'none' : 'copy'; });
  canvasWrap.addEventListener('dragleave', event => { event.preventDefault(); if (--dragDepth <= 0) hideOverlay(); });
  canvasWrap.addEventListener('drop', async event => {
    event.preventDefault(); event.stopPropagation(); hideOverlay();
    if (!busy) await importFiles(event.dataTransfer.files);
  }, true);
  editor.addEventListener('change', () => {
    clearTimeout(saveTimer);
    if (busy) return;
    saveTimer = setTimeout(async () => { if (!busy) { renderCounts(); try { await renderExplorer(); await persist(); } catch (error) { setStatus(error.message, 'error'); } } }, 600);
  });
}
async function boot() {
  await editorReady;
  window.analysis = new SchemaExplorer({ getDocument: readDocument, onStatus: setStatus, onEdit: id => toggleNative(true, id) });
  wireUi();
  const params = new URLSearchParams(location.search);
  if (params.has('autoload')) {
    const param = params.get('autoload');
    const loaded = await importUrl(!param || param === '1' ? EXAMPLE_URL : param);
    if (!loaded) {
      const failure = lastImport;
      await restoreSaved();
      lastImport = failure; renderReport();
      setStatus(`No se pudo cargar el archivo solicitado: ${failure.error}`, 'error');
    }
  } else await restoreSaved();
}
window.__erdApp = {
  editor, counts, importText, importFiles, importUrl,
  getStatus: () => ({ status: statusEl.textContent, kind: statusEl.className, counts: countsEl.textContent, busy, lastImport, ...counts() }),
};
window.__erdApp.ready = boot().catch(error => { setStatus(`Error al iniciar: ${error.message}`, 'error'); console.error(error); });
