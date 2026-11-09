/* Canvas de análisis. El editor original conserva siempre el documento completo. */
(() => {
  const $ = id => document.getElementById(id);
  const node = (tag, text, cls) => { const n = document.createElement(tag); if (text != null) n.textContent = text; if (cls) n.className = cls; return n; };
  const button = (text, action, cls) => { const b = node('button', text, cls); b.type = 'button'; b.onclick = action; return b; };
  const clone = value => structuredClone(value);
  const colors = ['#7464d5','#408797','#bd794c','#588469','#9c638a','#6981b9','#9e8551','#5f9995','#a06d64'];
  const modes = { map: 'Mapa de módulos', module: 'Módulo', focus: 'Enfoque', path: 'Ruta', all: 'Todo el esquema', custom: 'Selección manual' };
  const actions = { 1: 'No especificado en el esquema importado', 2: 'NO ACTION', 4: 'CASCADE', 8: 'SET NULL', 16: 'SET DEFAULT', 32: 'RESTRICT' };
  const fresh = () => ({ mode: 'map', group: '', root: '', depth: 1, cross: false, direction: 'both', filterGroup: '', links: 'selection', detail: 'keys', fluid: false, spacing: 70, selected: '', relation: '', extraKeys: [], start: '', end: '', via: '', pathIndex: 0, camera: { x: 30, y: 30, z: 1 } });
  class WorkerClient {
    constructor() { this.next = 0; this.pending = new Map(); this.lanes = new Map(); this.start(); }
    start() {
      this.failure = null; this.cachedGraph = null;
      this.worker = new Worker('analysis/worker.js');
      this.worker.onmessage = ({ data }) => {
        const p=this.pending.get(data.id);if(!p)return;clearTimeout(p.timer);this.pending.delete(data.id);
        if(data.error){p.reject(new Error(data.error));return;}
        let result=data.result;
        if(p.type==='index')this.cachedGraph=result;
        if(result?.kind==='graph-metadata'){
          const graph=this.cachedGraph;if(!graph||graph.fingerprint!==result.fingerprint){p.reject(new Error('El modelo cambió durante la actualización.'));return;}
          graph.groups=result.groups;graph.modulePairs=result.modulePairs;
          for(const[key,group,origin]of result.tableGroups){const t=graph.tableMap.get(key);if(t){t.group=group;t.groupOrigin=origin;}}
          for(const[key,name]of result.names)if(graph.relationMap.has(key))graph.relationMap.get(key).name=name;
          result=graph;
        }
        p.resolve(result);
      };
      this.worker.onerror = event => this.fail(new Error(event.message || 'No se pudo abrir el motor de análisis.'));
    }
    fail(error) { this.failure = error; for (const p of this.pending.values()) { clearTimeout(p.timer); p.reject(error); } this.pending.clear(); }
    call(type, payload) { if (this.failure) return Promise.reject(this.failure); return new Promise((resolve, reject) => { const id = ++this.next; const timer = setTimeout(() => { this.pending.delete(id); reject(new Error('El cálculo tardó demasiado. Cancela o acota la vista.')); }, 60000); this.pending.set(id, { resolve, reject, timer, type }); this.worker.postMessage({ id, type, payload }); }); }
    latest(type, payload) {
      let lane = this.lanes.get(type); if (!lane) { lane = { active: false, queued: null }; this.lanes.set(type,lane); }
      return new Promise((resolve,reject) => {
        if(lane.queued)lane.queued.resolve(null);
        lane.queued={payload,resolve,reject};
        const run=()=>{ if(lane.active||!lane.queued)return; const request=lane.queued;lane.queued=null;lane.active=true;
          this.call(type,request.payload).then(request.resolve,request.reject).finally(()=>{lane.active=false;run();}); };
        run();
      });
    }
    async stop() {
      for(const lane of this.lanes.values()){lane.queued?.resolve(null);lane.queued=null;}
      await Promise.race([this.call('dispose',{}).catch(()=>{}),new Promise(resolve=>setTimeout(resolve,200))]);
      this.worker.terminate(); this.fail(new Error('Cálculo cancelado.')); this.start();
    }
  }
  class SchemaExplorer {
    constructor({ getDocument, onStatus, onEdit }) {
      this.getDocument = getDocument; this.notice = onStatus; this.onEdit = onEdit; this.worker = new WorkerClient();
      this.state = fresh(); this.layouts = {}; this.views = []; this.assignments = {}; this.hubs = []; this.history = []; this.layoutHistory = []; this.revision = 0; this.modelVersion = 0; this.renderTick = 0; this.sidebarKeys = [];
      this.viewport = $('graph-viewport'); this.world = $('graph-world'); this.nodes = $('graph-nodes'); this.edges = $('graph-edges'); this.inspector = $('table-detail');
      this.renderer = new DiagramRenderer(this); this.measureCache = new Map(); this.projectionCache = new Map(); this.geometryEpoch = 0; this.dirtyLayouts = new Set();
      document.fonts?.addEventListener('loadingdone', () => { this.geometryEpoch++; this.measureCache.clear(); if (this.graph) this.show(); });
      this.bind(); this.seedPromise = fetch('docs/MODULOS_EJEMPLO.json').then(r => r.ok ? r.json() : {}).catch(() => ({}));
      this.setInspector(false); if (innerWidth < 920) this.setNavigator(false);
      this.renderSidebar(); this.renderInspector();
    }
    async loadDocument(doc, imported = null) {
      const version = ++this.modelVersion; ++this.revision; ++this.searchToken; this.canvasReady = false;
      const seed = await this.seedPromise;
      let graph = await this.worker.call('index', { document: doc, seed });
      if (version !== this.modelVersion) return;
      this.projectionCache.clear(); this.document = doc; const changed = graph.fingerprint !== this.graph?.fingerprint;
      let packed = imported?.analysis;
      if (!packed && changed) { try { packed = await AnalysisStorage.get('analysis:' + graph.fingerprint); } catch (e) { this.notice('Las vistas no se pudieron restaurar: ' + e.message, 'warning'); } }
      if (version !== this.modelVersion) return;
      this.graph = graph;
      if (changed) this.names = imported?.names || packed?.names || {};
      else if (imported?.names) this.names = imported.names;
      if (changed) { this.state = fresh(); this.layouts = {}; this.views = []; this.history = []; this.layoutHistory = []; this.assignments = {}; this.hubs = graph.hubs; }
      if (packed) this.unpack(packed);
      if (Object.keys(this.assignments).length || Object.keys(this.names || {}).length) this.graph = graph = await this.worker.call('metadata', { groups: this.assignments, names: this.names });
      if (version !== this.modelVersion) return;
      if (!this.state.root && graph.tables[0]) this.state.root = graph.tables[0].key;
      if (!this.state.start) this.state.start = graph.tables[0]?.key || '';
      if (!this.state.end) this.state.end = graph.tables.at(-1)?.key || '';
      if (!graph.groups.has(this.state.group)) this.state.group = graph.groups.keys().next().value || '';
      this.renderSidebar(); this.renderInspector(); await this.show({ fit: changed && !packed });
    }
    stateForWorker() { return { ...this.state, ...(this.state.mode==='all'?{cross:true,links:'all',filterGroup:'',direction:'both'}:{}), hubs: this.hubs }; }
    async show({ fit = false, force = false, keepCamera = false } = {}) {
      if (!this.graph) return;
      const revision = ++this.revision;
      this.syncControls();
      try {
        const query = this.stateForWorker(); const { camera, detail, spacing, relation, selected, ...filters } = query;
        const projectionKey = JSON.stringify([this.graph.fingerprint, filters, query.mode === 'map' ? selected : '']);
        let projection = this.projectionCache.get(projectionKey);
        if (!projection) { projection = await this.worker.latest('project', query); if (projection && revision === this.revision) { this.projectionCache.set(projectionKey, projection);
          const weight=p=>p.nodes.length+p.relations.length+p.bundles.length+p.boundary.reduce((n,b)=>n+b.relations.length,0);
          while(this.projectionCache.size>1&&(this.projectionCache.size>20||[...this.projectionCache.values()].reduce((n,p)=>n+weight(p),0)>100000))this.projectionCache.delete(this.projectionCache.keys().next().value); } }
        if (!projection || revision !== this.revision) return;
        const requestedDetail = this.effectiveDetail();
        const specs = await this.measure(projection, revision, requestedDetail);
        if (revision !== this.revision) return;
        const id = this.viewKey(requestedDetail); const old = this.layouts[id];
        const geometrySignature = JSON.stringify([specs.map(s => [s.key, s.signature]), projection.bundles.map(b => [b.key,b.relations])]);
        let layout = old || (keepCamera && this.layout ? clone(this.layout) : null);
        if (force || !layout) {
          this.progress(true);
          if (this.state.mode === 'map') layout = this.mapLayout(specs);
          else layout = await this.worker.call('layout', { nodes: specs, bundles: this.withPorts(projection.bundles, specs), spacing: this.state.spacing });
          if (revision !== this.revision) return;
          layout.pins = old?.pins || []; layout.routesValid = true;
          if (old?.pins?.length) { for (const key of old.pins) if (old.positions[key]) layout.positions[key] = old.positions[key]; layout.routesValid = false; }
        } else {
          layout = clone(layout);
          // Los filtros nunca recolocan nodos ya conocidos. Los nuevos ocupan un área libre.
          const right = Math.max(0, ...Object.values(layout.positions).map(p => p.x)) + 380;
          const rowHeight = Math.max(420, ...specs.map(s => s.height + 70));
          let index = 0;
          for (const spec of specs) if (!layout.positions[spec.key]) { layout.positions[spec.key] = { x: right + (index % 3) * 360, y: 40 + Math.floor(index++ / 3) * rowHeight }; layout.routesValid = false; }
        }
        if (old && layout.geometrySignature !== geometrySignature) layout.routesValid = false;
        layout.geometrySignature = geometrySignature;
        if (revision !== this.revision) return;
        this.committedState = clone(this.state); this.canvasMode = this.state.mode; this.canvasFingerprint = this.graph.fingerprint; this.canvasReady = true;
        delete this.layouts[id]; this.layouts[id] = layout; this.dirtyLayouts.add(id);
        const protectedKeys = new Set(this.views.map(v => v.layoutKey || this.viewKey(v.state.detail === 'auto' ? (v.state.camera.z < .45 ? 'names' : 'keys') : v.state.detail, v.state)));
        while (Object.keys(this.layouts).length > 30) { const expired = Object.keys(this.layouts).find(key => key !== id && !protectedKeys.has(key)); if (!expired) break; delete this.layouts[expired]; this.dirtyLayouts.delete(expired); }
        this.projection = projection; this.specs = specs; this.specMap = new Map(specs.map(s => [s.key, s])); this.layout = layout;
        this.progress(false); this.renderInspector(); this.renderBoundaryCount();
        this.renderedDetail = requestedDetail; this.renderer.scene();
        if (fit || !old && !this.restoring && !keepCamera) this.fit(); else this.transform();
        this.restoring = false; this.scheduleSave('layout');
        await this.renderer.ready();
      } catch (error) { if (revision === this.revision) { this.progress(false); this.notice(error.message, 'error'); } }
    }
    progress(active) { $('layout-progress').hidden = !active; $('relayout').disabled = active; this.layoutBusy = active; }
    async cancel() {
      ++this.revision; await this.worker.stop(); this.progress(false);
      if (this.committedState) { this.state = { ...clone(this.committedState), camera: clone(this.state.camera) }; this.syncControls(); }
      if (this.document) { const g = await this.worker.call('index', { document: this.document, seed: await this.seedPromise, metadata: { groups: this.assignments, names: this.names } }); this.graph = g; }
      this.renderCanvas(); this.transform();
      this.notice('Cálculo cancelado. La vista anterior y el esquema completo se conservan.', 'ok');
    }
    viewKey(detail = this.effectiveDetail(), s = this.state) { if(s.mode==='map')detail='names'; return JSON.stringify([s.mode, s.mode === 'map' ? '' : s.group, s.root, s.start, s.end, s.via, s.pathIndex, s.manualKeys || [], detail]); }
    effectiveDetail() { if (this.state.mode === 'map') return 'names'; if (this.state.detail !== 'auto') return this.state.detail; this.autoDetail = this.state.autoLevel || this.autoDetail || (this.state.camera.z < .45 ? 'names' : 'keys'); if (this.autoDetail === 'names' && this.state.camera.z > .52) this.autoDetail = 'keys'; else if (this.autoDetail === 'keys' && this.state.camera.z < .38) this.autoDetail = 'names'; this.state.autoLevel = this.autoDetail; return this.autoDetail; }
    mapLayout(specs) {
      const columns = Math.max(1, Math.min(4, Math.round((this.viewport.clientWidth || 900) / 300)));
      const positions = Object.fromEntries(specs.map((s, i) => [s.key, { x: 35 + (i % columns) * 290, y: 35 + Math.floor(i / columns) * 175 }]));
      return { positions, routes: {}, pins: [], routesValid: false };
    }
    async measure(projection, revision, detail = this.effectiveDetail()) {
      const host = $('measure-node'), specs = new Map(), misses = [];
      for (const key of projection.nodes) {
        const t = this.graph.tableMap.get(key), g = this.graph.groups.get(key);
        const content = this.state.mode === 'map' ? [g.name, g.tables.length, g.internal] : [t.name,t.group,[...this.graph.groups.keys()].indexOf(t.group),t.columns.map(c=>[c.name,c.type,c.options]),[...t.keyColumns],t.incoming.length,t.outgoing.length];
        const signature = JSON.stringify([this.geometryEpoch, this.state.mode === 'map', key, detail, content]);
        const cached = this.measureCache.get(signature);
        if (cached) { this.measureCache.delete(signature); this.measureCache.set(signature,cached); specs.set(key,{...cached}); }
        else misses.push({key,signature});
      }
      // Escribir un lote completo antes de leer tamaños evita insertar/medir por fila.
      try {
        for (let i=0; i<misses.length; i+=12) {
          if (revision !== this.revision) return [];
          const batch = misses.slice(i,i+12).map(item=>({...item,card:this.card(item.key,true,detail)}));
          host.replaceChildren(...batch.map(item=>item.card));
          for (const {key,signature,card} of batch) {
            const rows=[...card.querySelectorAll('[data-column]')].map(row=>({name:row.dataset.column,y:row.offsetTop+row.offsetHeight/2}));
            const spec={key,signature,detail,width:card.offsetWidth,height:card.offsetHeight,rows};
            this.measureCache.set(signature,spec); specs.set(key,{...spec}); this.renderer.stats.measurements++;
          }
          if(i+12<misses.length) await new Promise(resolve=>setTimeout(resolve,0));
        }
      } finally { host.replaceChildren(); }
      while(this.measureCache.size>6000)this.measureCache.delete(this.measureCache.keys().next().value);
      return projection.nodes.map(key=>specs.get(key));
    }
    withPorts(bundles, specs) {
      const map = new Map(specs.map(s => [s.key, s]));
      for (const s of specs) s.ports = [];
      return bundles.map((b, i) => {
        const r = b.relations.length === 1 ? this.graph.relationMap.get(b.relations[0]) : null;
        const sourceRow = r?.childCols.length === 1 ? map.get(b.a)?.rows.find(row => row.name === r.childCols[0]) : null;
        const targetRow = r?.parentCols.length === 1 ? map.get(b.b)?.rows.find(row => row.name === r.parentCols[0]) : null;
        const sourcePort = `s${i}`, targetPort = `t${i}`;
        if (map.has(b.a)) map.get(b.a).ports.push({ id: sourcePort, x: map.get(b.a).width, y: sourceRow?.y || (b.lanes>1?15+b.lane*Math.min(8,24/(b.lanes-1)):25), side: 'EAST' });
        if (map.has(b.b)) map.get(b.b).ports.push({ id: targetPort, x: 0, y: targetRow?.y || (b.lanes>1?15+b.lane*Math.min(8,24/(b.lanes-1)):25), side: 'WEST' });
        return { ...b, sourcePort, targetPort };
      });
    }
    card(key, measuring = false, requestedDetail = this.renderedDetail || this.effectiveDetail()) {
      const isMap = this.state.mode === 'map'; const table = this.graph.tableMap.get(key), group = isMap ? this.graph.groups.get(key) : this.graph.groups.get(table?.group);
      const card = node('article', null, 'graph-node' + (isMap ? ' module-node' : '')); card.dataset.key = key;
      const color = colors[[...this.graph.groups.keys()].indexOf(group?.name) % colors.length] || colors[0]; card.style.setProperty('--module-color', color);
      if (this.state.selected === key) card.classList.add('selected');
      const head = node('div', null, 'node-head'); head.dataset.drag = key;
      const title = button(isMap ? key : table.name, () => this.select(key), 'node-title'); title.setAttribute('aria-label', (isMap ? 'Seleccionar módulo ' : 'Seleccionar tabla ') + key); head.append(title);
      { const pin = button('⌖', () => this.pin(key), 'node-pin'); pin.setAttribute('aria-label', 'Fijar posición de ' + key); pin.setAttribute('aria-pressed', String(this.layout?.pins?.includes(key) || false)); head.append(pin); }
      card.append(head);
      if (isMap) {
        card.append(node('div', `${group.tables.length} tablas · ${group.internal} FK internas`, 'node-meta'));
        card.append(button('Abrir módulo →', () => this.requestModule(key), 'module-open'));
      } else {
        const detail = requestedDetail, columns = detail === 'names' ? [] : table.columns.filter(c => detail === 'columns' || table.keyColumns.has(c.name));
        for (const col of columns) {
          const row = node('div', null, 'node-row'); row.dataset.column = col.name;
          row.append(node('span', col.options & 2 ? 'PK' : table.keyColumns.has(col.name) ? 'FK/AK' : '', 'key-badge'), node('span', col.name, 'column-name'), node('code', col.type));
          card.append(row);
        }
        const self = table.outgoing.filter(id => this.graph.relationMap.get(id).parent === key).length;
        card.append(node('div', `${table.columns.length} columnas · ${table.incoming.length} recibidas · ${table.outgoing.length} referencias${self ? ' · ↻ ' + self : ''}`, 'node-tail'));
      }
      return card;
    }
    navigate(mode, patch = {}, options = {}) {
      if (!this.graph) return;
      this.history.push(clone(this.state)); if (this.history.length > 50) this.history.shift();
      Object.assign(this.state, { mode, relation: '', manualKeys: null, extraKeys: [] }, patch);
      if (mode === 'map') { this.setInspector(false); this.state.selected = ''; }
      return this.show({ fit: options.fit !== false });
    }
    async requestModule(name) {
      const keys = this.graph.groups.get(name)?.tables || [];
      if (keys.length > 50) {
        const choice = await this.chooseExpansion(keys, `El módulo ${name} contiene ${keys.length} tablas. Elige un contexto o ábrelo completo.`);
        if (choice === null) return;
        if (choice !== 'all') return this.navigate('custom', { group: name, manualKeys: choice, links: 'context', selected: '' });
      }
      this.state.links = 'context'; this.setInspector(false);
      return this.navigate('module', { group: name, selected: '', relation: '' });
    }
    async requestFocus(root, depth = Number(this.state.depth), overrides = {}) {
      const next = { ...this.stateForWorker(), ...overrides, mode: 'focus', root, depth, manualKeys: null, extraKeys: [], selected: root, relation: '' };
      const revision = this.revision;
      const preview = await this.worker.call('project', next);
      if (revision !== this.revision) return;
      if (preview.nodes.length > 25) {
        const selected = await this.chooseExpansion(preview.nodes, `Este contexto contiene ${preview.nodes.length} tablas y ${preview.relations.length} FK. Puedes elegir tablas o abrirlo completo.`);
        if (selected === null) { this.syncControls(); return; }
        if (selected !== 'all') next.manualKeys = [...new Set([root, ...selected])];
      }
      this.setInspector(true); return this.navigate('focus', next);
    }
    chooseExpansion(keys, description) {
      return new Promise(resolve => {
        const dialog = $('expand-dialog'); $('expand-description').textContent = description; $('expand-search').value = '';
        const chosen = new Set();
        const render = () => { $('expand-list').replaceChildren(); for (const key of keys.filter(k => k.toLowerCase().includes($('expand-search').value.toLowerCase())).slice(0, 250)) { const label = node('label'); const box = document.createElement('input'); box.type = 'checkbox'; box.checked = chosen.has(key); box.onchange = () => box.checked ? chosen.add(key) : chosen.delete(key); label.append(box, document.createTextNode(key)); $('expand-list').append(label); } if (keys.length > 250) $('expand-list').append(node('p', 'Se muestran hasta 250 coincidencias. Usa la búsqueda; “Mostrar todas” incluye el contexto completo.')); };
        $('expand-search').oninput = render; render(); dialog.returnValue = 'cancel';
        dialog.onclose = () => resolve(dialog.returnValue === 'all' ? 'all' : dialog.returnValue === 'selected' ? [...chosen] : null); dialog.showModal();
      });
    }
    select(key) {
      this.state.selected = key; this.state.relation = ''; this.setInspector(true); this.renderInspector();
      if (this.state.mode === 'map') { this.state.group = key; this.show(); }
      else { this.renderCanvas(); this.renderSidebarSelection(); this.scheduleSave(); }
    }
    centerTable(key) {
      const p=this.layout?.positions[key],s=this.specMap?.get(key);if(!p||!s)return;
      const z=Math.max(.9,this.state.camera.z),w=this.viewport.clientWidth,h=this.viewport.clientHeight;
      this.state.camera={z,x:w/2-(p.x+s.width/2)*z,y:s.height*z>h-80?40-p.y*z:h/2-(p.y+s.height/2)*z};
      this.transform();this.scheduleSave('camera');
    }
    selectRelation(id) {
      this.state.relation = id; this.setInspector(true); this.renderInspector(); this.renderCanvas(); this.scheduleSave();
    }
    renderCanvas() { if(this.renderer.valid())this.committedState=clone(this.state); this.renderer.request({ selection: true }); }
    edgeShown(bundle) {
      if (this.state.mode === 'all') return true;
      if (this.state.links === 'none') return false;
      if (this.state.links !== 'selection' || this.state.mode === 'path' || this.state.relation) return true;
      return bundle.a === this.state.selected || bundle.b === this.state.selected;
    }
    drawEdges() { this.renderer.request({ selection: true }); }
    selectBundle(bundle) {
      if (bundle.relations.length === 1) this.selectRelation(bundle.relations[0]);
      else { this.setInspector(true); this.inspector.replaceChildren(node('h3', `${bundle.relations.length} relaciones`), node('p', `${bundle.a} → ${bundle.b}`, 'subtle')); this.relationList(bundle.relations); }
    }
    renderBoundaryCount() {
      const p = this.projection;
      if(this.state.mode==='all'){ $('view-counts').textContent=`${p.nodes.length} de ${p.total} tablas · ${p.relations.length} de ${this.graph.relations.length} FK · todas las conexiones · flecha hacia la tabla referenciada`; $('canvas-summary').textContent='Acerca para leer cada relación y su cardinalidad'; return; }
      $('view-counts').textContent = this.state.mode === 'map' ? `${p.nodes.length} módulos · ${p.bundles.length} conexiones agregadas · el documento completo no cambia` : `${p.nodes.length} de ${p.total} tablas · ${p.relations.length} FK del contexto · ${p.hidden} referencias resumidas o filtradas · FK → tabla referenciada`;
      $('canvas-summary').textContent = this.state.mode === 'map' ? 'Selecciona un módulo para ver sus conexiones' : 'Arrastra las tablas · Control + rueda para acercar';
    }
    syncControls() {
      const view=this.stateForWorker(),all=this.state.mode==='all';
      $('cardinality-legend').hidden=!all;
      for(const id of ['cross-filter','link-mode','direction-filter','scope-filter']) {$(id).disabled=all;$(id).title=all?'Todo el esquema incluye todas las conexiones. Usa Enfoque o Módulo para filtrar.':'';}
      $('scope-filter').value=view.filterGroup;
      for (const b of document.querySelectorAll('[data-mode]')) b.setAttribute('aria-pressed', String(b.dataset.mode === this.state.mode));
      $('fluid-mode').checked=!!this.state.fluid; $('detail-mode').value = this.state.detail; $('cross-filter').checked = view.cross; $('link-mode').value = view.links; $('direction-filter').value = view.direction; $('focus-depth').value = String(this.state.depth); $('depth-control').hidden = this.state.mode !== 'focus'; $('path-controls').hidden = this.state.mode !== 'path';
      $('path-start').value = this.state.start; $('path-end').value = this.state.end; $('path-via').value = this.state.via;
      $('breadcrumb').textContent = 'Esquema / ' + (this.state.mode === 'module' ? this.state.group : this.state.mode === 'focus' ? 'Enfoque / ' + this.state.root : this.state.mode === 'path' ? `${this.state.start} → ${this.state.end}` : modes[this.state.mode]);
      $('history-back').disabled = !this.history.length; $('layout-spacing').value = this.state.spacing;
    }
    renderSidebar() {
      if (!this.graph) { $('module-list').replaceChildren(); $('saved-views').replaceChildren(node('p', 'Guarda un contexto para volver a él.', 'subtle')); return; }
      $('group-total').textContent = this.graph.groups.size;
      $('module-list').replaceChildren(); $('scope-filter').replaceChildren(new Option('Todos', '')); $('group-options').replaceChildren(); $('table-options').replaceChildren();
      for (const [i, g] of [...this.graph.groups.values()].entries()) {
        const b = button('', () => this.requestModule(g.name), 'module-button'); b.style.setProperty('--module-color', colors[i % colors.length]); b.append(node('span', '', 'module-dot'), node('span', g.name, 'module-label'), node('b', String(g.tables.length))); b.setAttribute('aria-pressed', String(this.state.mode === 'module' && this.state.group === g.name)); $('module-list').append(b); $('scope-filter').append(new Option(g.name, g.name)); $('group-options').append(new Option(g.name, g.name));
      }
      for (const t of this.graph.tables) $('table-options').append(new Option(t.name, t.key));
      $('scope-filter').value = this.state.filterGroup;
      this.runSearch(); this.renderViews();
    }
    async runSearch() {
      if (!this.graph) return;
      const token = ++this.searchToken || (this.searchToken = 1);
      const keys = await this.worker.latest('search', $('table-search').value).catch(error => { if(error.message !== 'Cálculo cancelado.')this.notice(error.message,'warning'); return null; });
      if (!keys || token !== this.searchToken) return;
      this.sidebarKeys = keys; $('table-total').textContent = `${keys.length} de ${this.graph.tables.length} tablas`; $('table-list').scrollTop = 0; this.renderSearchWindow();
    }
    renderSearchWindow() {
      const container = $('table-list'), scrollTop = container.scrollTop; container.replaceChildren();
      const spacer = node('div', null, 'search-spacer'); spacer.style.height = this.sidebarKeys.length * 39 + 'px';
      const start = Math.max(0, Math.floor(scrollTop / 39) - 2), end = Math.min(this.sidebarKeys.length, start + 10);
      for (const key of this.sidebarKeys.slice(start, end)) {
        const t = this.graph?.tableMap.get(key); if (!t) continue; const row = node('div', null, 'search-row'); row.style.cssText = `position:absolute;top:${this.sidebarKeys.indexOf(key)}px`;
        row.style.top = this.sidebarKeys.indexOf(key) * 39 + 'px'; row.style.width = '100%';
        const b = button(t.name, () => { if(this.state.mode==='all'){this.select(key);this.centerTable(key);}else{this.state.selected = key; this.renderInspector(); this.requestFocus(key, 1);} }, 'table-item' + (key === this.state.selected ? ' selected' : '')); b.title = t.name + ' · ' + t.group; b.setAttribute('aria-label', 'Enfocar ' + t.name);
        const add = button('+', () => this.addTable(key), 'add-table'); add.setAttribute('aria-label', 'Añadir ' + t.name + ' a la vista'); row.append(b, add); spacer.append(row);
      }
      container.append(spacer); container.scrollTop = scrollTop;
    }
    renderSidebarSelection() { this.renderSearchWindow(); }
    addTable(key) { if (!this.graph.tableMap.has(key)) return; this.history.push(clone(this.state)); if (this.state.mode === 'map') Object.assign(this.state, { mode: 'custom', manualKeys: [key], extraKeys: [] }); else this.state.extraKeys = [...new Set([...this.state.extraKeys, key])]; this.state.selected = key; this.show({ fit: true }); }
    renderInspector() {
      this.inspector.replaceChildren(); if (!this.graph) { this.inspector.append(node('h3', 'Tu esquema, en contexto'), node('p', 'Importa un esquema para explorar sus módulos y relaciones.', 'subtle')); return; }
      const r = this.graph.relationMap.get(this.state.relation);
      if (r) { this.relationDetail(r); return; }
      if (this.state.mode === 'map') {
        const g = this.graph.groups.get(this.state.selected);
        this.inspector.append(node('h3', g?.name || 'Mapa del esquema'), node('p', g ? `${g.tables.length} tablas · ${g.internal} FK internas · ${g.external} externas` : `${this.graph.tables.length} tablas en ${this.graph.groups.size} módulos. Los grupos se pueden revisar.`, 'subtle'));
        if (g) { this.inspector.append(button('Abrir módulo', () => this.requestModule(g.name))); for (const b of this.projection?.bundles || []) this.inspector.append(button(`${b.a === g.name ? b.b : b.a} · ${b.relations.length} FK`, () => this.selectBundle(b), 'boundary-card')); }
      } else {
        const t = this.graph.tableMap.get(this.state.selected);
        if (t) this.tableDetail(t);
        else { this.inspector.append(node('h3', modes[this.state.mode]), node('p', 'Selecciona una tabla o una conexión para inspeccionar sus detalles.', 'subtle')); this.boundaries(); }
      }
      if (this.graph.warnings.length) this.inspector.append(node('p', this.graph.warnings.slice(0, 3).join(' '), 'info-callout'));
      this.renderRouteChoices();
    }
    tableDetail(t) {
      this.inspector.append(node('h3', t.name), node('p', t.group + ' · ' + t.groupOrigin, 'subtle'));
      const row = node('div', null, 'action-row'); row.append(button('Enfocar tabla', () => this.requestFocus(t.key, 1)), button('Añadir a vista', () => this.addTable(t.key)), button('Organizar', () => this.editGroup(t)), button('Editar', () => this.onEdit(t.id))); this.inspector.append(row);
      if(this.projection?.nodes.includes(t.key))row.append(button('Centrar en esta vista',()=>this.centerTable(t.key)));
      if (t.comment) this.inspector.append(node('p', t.comment, 'subtle'));
      const grid = node('table', null, 'column-details'), head = node('thead'), hr = node('tr'); hr.append(node('th', 'Columna / tipo'), node('th', 'Reglas')); head.append(hr); grid.append(head);
      const body = node('tbody');
      for (const col of t.columns) { const tr = node('tr'), name = node('td'); name.append(node('strong', col.name), node('code', col.type)); if (col.comment) name.append(node('small', col.comment)); const rules = []; if (col.options & 2) rules.push('PK'); if (t.outgoing.some(id => this.graph.relationMap.get(id).childCols.includes(col.name))) rules.push('FK'); if (col.options & 4) rules.push('UNIQUE'); rules.push(col.options & 8 ? 'NOT NULL' : 'NULL'); if (col.options & 1) rules.push('AUTO'); if (col.default) rules.push('DEFAULT ' + col.default); tr.append(name, node('td', rules.join(' · '))); body.append(tr); }
      grid.append(body); this.inspector.append(grid, node('h4', `Referencia a · ${t.outgoing.length}`)); this.relationList(t.outgoing); this.inspector.append(node('h4', `Es referenciada por · ${t.incoming.length}`)); this.relationList(t.incoming);
      this.inspector.append(node('h4', `Índices importados · ${t.indexes.length}`)); for (const i of t.indexes) this.inspector.append(node('p', `${i.unique ? 'UNIQUE ' : ''}${i.name} (${i.columns.join(', ')})`, 'subtle'));
      this.boundaries();
    }
    relationList(ids) {
      // Lista paginada, independiente del canvas: incluso las FK ocultas son accesibles.
      const chunk = (offset = 0) => { for (const id of ids.slice(offset, offset + 30)) { const r = this.graph.relationMap.get(id); const b = button(`${r.child} → ${r.parent}`, () => this.selectRelation(id), 'relation-button'); b.append(node('small', r.childCols.join(', ') + ' → ' + r.parentCols.join(', '))); this.inspector.append(b); } if (ids.length > offset + 30) { const more = button(`Mostrar más (${ids.length - offset - 30})`, () => { more.remove(); chunk(offset + 30); }); this.inspector.append(more); } }; chunk();
    }
    relationDetail(r) {
      this.inspector.append(node('h3', r.name || 'Relación de clave foránea'), node('p', 'La flecha parte de la tabla que declara la FK y apunta a la tabla referenciada.', 'subtle'));
      const grid = node('table', null, 'relation-mapping'), head = node('tr'); head.append(node('th', 'Origen · ' + r.child), node('th', 'Destino · ' + r.parent)); grid.append(head);
      r.childCols.forEach((name, i) => { const tr = node('tr'); tr.append(node('td', name), node('td', r.parentCols[i] || '(ausente)')); grid.append(tr); }); this.inspector.append(grid);
      const cardinality=SchemaGraph.cardinality(this.graph,r);
      this.inspector.append(node('h4','Cardinalidad'),node('p',`${r.child} [${cardinality.child}] → [${cardinality.parent}] ${r.parent}`,'info-callout'));
      this.inspector.append(node('p',`Por cada fila de ${r.child}: ${cardinality.parent} filas de ${r.parent}. Por cada fila de ${r.parent}: ${cardinality.child} filas de ${r.child}.`,'subtle'));
      this.inspector.append(node('p','Según PK, UNIQUE, nulabilidad y relaciones importadas. Una FK no obliga a que cada fila referenciada tenga filas hijas.','subtle'));
      this.inspector.append(node('h4', 'Acciones referenciales'), node('p', `ON DELETE: ${actions[r.onDelete] || 'Desconocido'}\nON UPDATE: ${actions[r.onUpdate] || 'Desconocido'}`, 'subtle'));
      const goTo = key => { this.state.selected=key;if(this.state.mode==='all'){this.centerTable(key);this.renderCanvas();this.renderSidebarSelection();}else this.requestFocus(key,0); };
      const row = node('div', null, 'action-row'); row.append(button('Ir al origen', () => goTo(r.child)), button('Ir al destino', () => goTo(r.parent)), button('Aislar relación', () => this.navigate('custom', { manualKeys: [...new Set([r.child, r.parent])], selected: r.child, relation: r.key, links: 'context', cross: true })));
      this.inspector.append(row);
      if (!this.projection?.relations.includes(r.key)) this.inspector.append(node('p', 'Esta relación está fuera de la vista o de sus filtros actuales. Sigue formando parte del modelo.', 'info-callout'));
    }
    boundaries() {
      const list = this.projection?.boundary || []; if (!list.length) return;
      this.inspector.append(node('h4', 'Referencias fuera de esta vista'));
      for (const item of list) this.inspector.append(button(`${item.group} · ${item.relations.length} FK`, async () => { if (this.graph.groups.has(item.group)) { this.state.links = 'context'; this.navigate('module', { group: item.group, selected: '' }); } else { this.state.cross = true; await this.show(); } }, 'boundary-card'));
    }
    renderRouteChoices() {
      const options = this.projection?.routeOptions || []; $('path-choice').replaceChildren(); options.forEach((p, i) => $('path-choice').append(new Option(`${i + 1}: ${p.nodes.join(' → ')}`, i))); $('path-choice').value = String(this.state.pathIndex || 0); $('path-choice').hidden = options.length < 2;
    }
    async editGroup(t) {
      $('group-table-name').textContent = t.name; $('group-name').value = t.group; $('group-hub').checked = this.hubs.includes(t.key); const dialog = $('group-dialog'); dialog.returnValue = 'cancel'; dialog.showModal();
      dialog.onclose = async () => { if (dialog.returnValue !== 'save') return; const name = $('group-name').value.trim(); if (!name) return; this.assignments = { ...this.assignments, [t.key]: name }; this.hubs = $('group-hub').checked ? [...new Set([...this.hubs, t.key])] : this.hubs.filter(key => key !== t.key); this.graph = await this.worker.call('groups', this.assignments); this.projectionCache.clear(); this.layouts = {}; this.state.group = name; this.renderSidebar(); this.show({ fit: true }); };
    }
    transform() { this.renderer.request({ camera: true }); }
    interact() {
      if(!this.state.fluid)return; this.viewport.classList.add('fluid-interaction');
      clearTimeout(this.fluidTimer); this.fluidTimer=setTimeout(()=>{this.viewport.classList.remove('fluid-interaction');},180);
    }
    fit() {
      if (!this.specs?.length) return;
      const boxes = this.specs.map(s => ({ ...this.layout.positions[s.key], ...s })); const left = Math.min(...boxes.map(b => b.x)), top = Math.min(...boxes.map(b => b.y)), right = Math.max(...boxes.map(b => b.x + b.width)), bottom = Math.max(...boxes.map(b => b.y + b.height));
      const w = this.viewport.clientWidth || 800, h = this.viewport.clientHeight || 500; const z = Math.max(.03, Math.min(1.1, (w - 70) / Math.max(1, right - left), (h - 100) / Math.max(1, bottom - top)));
      this.state.camera = { z, x: w / 2 - (left + right) / 2 * z, y: h / 2 - (top + bottom) / 2 * z - 15 }; this.transform(); this.scheduleSave('camera');
    }
    zoom(factor, x = this.viewport.clientWidth / 2, y = this.viewport.clientHeight / 2) {
      this.interact(); const c = this.state.camera, old = c.z; c.z = Math.max(.03, Math.min(2, c.z * factor)); c.x = x - (x - c.x) * c.z / old; c.y = y - (y - c.y) * c.z / old; this.transform(); this.scheduleSave('camera');
      if (this.state.detail === 'auto') { clearTimeout(this.autoTimer); this.autoTimer = setTimeout(() => { if (this.effectiveDetail() !== this.renderedDetail) this.show({keepCamera:true}); }, 180); }
    }
    pin(key) { if (!this.layout) return; const pins = new Set(this.layout.pins); pins.has(key) ? pins.delete(key) : pins.add(key); this.layout.pins = [...pins]; this.renderCanvas(); this.scheduleSave(); }
    async relayout() { if (!this.layout) return; this.layoutHistory.push({ key: this.viewKey(), layout: clone(this.layout), camera: clone(this.state.camera), state: clone(this.state) }); while(this.layoutHistory.length>1&&(this.layoutHistory.length>20||this.layoutHistory.reduce((n,item)=>n+Object.keys(item.layout.positions).length+Object.keys(item.layout.routes||{}).length*6,0)>100000))this.layoutHistory.shift(); await this.show({ fit: true, force: true }); }
    undoLayout() { const previous = this.layoutHistory.pop(); if (!previous) return; this.layouts[previous.key] = previous.layout; this.state = previous.state; this.state.camera = previous.camera; this.show(); }
    drawMinimap() { this.renderer.request({ camera: true }); }
    setNavigator(open) { $('table-panel').hidden = !open; $('btn-tables').setAttribute('aria-expanded', String(open)); }
    setInspector(open) { $('inspector').hidden = !open; $('toggle-inspector').setAttribute('aria-expanded', String(open)); }
    async getName(title, value = '') { return await new Promise(resolve => { const dialog = $('name-dialog'); $('name-title').textContent = title; $('name-value').value = value; dialog.returnValue = 'cancel'; dialog.onclose = () => resolve(dialog.returnValue === 'save' ? $('name-value').value.trim() : null); dialog.showModal(); $('name-value').focus(); }); }
    async saveView(name) { name ||= await this.getName('Guardar esta vista'); if (!name) return; if(this.views.length>=100){this.notice('Ya hay 100 vistas guardadas. Quita una antes de crear otra.','warning');return;} this.views.push({ id: crypto.randomUUID(), name: name.slice(0, 100), state: clone(this.state), layoutKey: this.viewKey(this.renderedDetail || this.effectiveDetail()) }); this.renderViews(); await this.save(); }
    renderViews() { $('saved-views').replaceChildren(); if (!this.views.length) $('saved-views').append(node('p', 'Guarda un contexto para volver a él.', 'subtle')); for (const view of this.views) { const row = node('div', null, 'saved-row'); row.append(button(view.name, () => { this.history.push(clone(this.state)); this.state = this.sanitize(view.state); this.restoring = true; this.show(); }), button('×', () => { this.views = this.views.filter(v => v.id !== view.id); this.renderViews(); this.scheduleSave(); })); row.lastChild.setAttribute('aria-label', 'Quitar vista ' + view.name); $('saved-views').append(row); } }
    sanitize(input) {
      const s = { ...fresh(), ...input }; if (!modes[s.mode]) s.mode = 'map';
      for (const key of ['root', 'selected', 'start', 'end', 'via']) if (!this.graph.tableMap.has(s[key]) && !(key === 'selected' && this.graph.groups.has(s[key]))) s[key] = '';
      s.extraKeys = (Array.isArray(s.extraKeys) ? s.extraKeys : []).filter(k => this.graph.tableMap.has(k)); if (s.manualKeys) s.manualKeys = (Array.isArray(s.manualKeys) ? s.manualKeys : []).filter(k => this.graph.tableMap.has(k));
      if (!['names','keys','columns','auto'].includes(s.detail)) s.detail = 'keys'; if (!['context','selection','none','all'].includes(s.links)) s.links = 'selection'; if (!['both','in','out'].includes(s.direction)) s.direction = 'both';
      s.fluid = s.fluid === true; if(!['names','keys'].includes(s.autoLevel))delete s.autoLevel;
      s.depth = Math.min(2, Math.max(0, Number(s.depth) || 0)); s.spacing = Math.min(180, Math.max(30, Number(s.spacing) || 70)); s.pathIndex = Math.min(2, Math.max(0, Number(s.pathIndex) || 0));
      const c = s.camera || {}; s.camera = { x: Number.isFinite(c.x) ? c.x : 30, y: Number.isFinite(c.y) ? c.y : 30, z: Number.isFinite(c.z) ? Math.min(2, Math.max(.03, c.z)) : 1 }; return s;
    }
    pack() { return { version: 1, fingerprint: this.graph?.fingerprint, state: clone(this.state), views: clone(this.views), names: this.names || {}, assignments: this.assignments, hubs: this.hubs, layouts: this.layouts }; }
    unpack(pack) {
      if (!pack || pack.version !== 1) return;
      if (pack.names && typeof pack.names === 'object') this.names = pack.names;
      this.assignments = Object.fromEntries(Object.entries(pack.assignments || {}).filter(([k,v]) => this.graph.tableMap.has(k) && typeof v === 'string' && v.trim()).map(([k,v]) => [k,v.slice(0,100)]));
      this.hubs = Array.isArray(pack.hubs) ? pack.hubs.filter(k => this.graph.tableMap.has(k)) : this.graph.hubs;
      this.state = this.sanitize(pack.state || {}); this.views = (Array.isArray(pack.views) ? pack.views : []).slice(0,100).filter(v => typeof v.name === 'string' && v.state).map(v => ({ id: String(v.id || crypto.randomUUID()), name: v.name.slice(0,100), state: this.sanitize(v.state), layoutKey: typeof v.layoutKey === 'string' ? v.layoutKey : undefined }));
      let missing = 0; for (const view of [...(Array.isArray(pack.views) ? pack.views : []), { state: pack.state }]) for (const key of [...(view.state?.extraKeys || []), ...(view.state?.manualKeys || []), ...['root','start','end','via'].map(k => view.state?.[k]).filter(Boolean)]) if (!this.graph.tableMap.has(key)) missing++;
      if (missing) this.notice(`${missing} referencias de vistas no existen en el esquema actual. Se omitieron; revisa las vistas.`, 'warning');
      this.layouts = {};
      const protectedKeys = new Set(this.views.map(v=>v.layoutKey||this.viewKey(v.state.detail==='auto'?(v.state.camera.z<.45?'names':'keys'):v.state.detail,v.state)));
      const entries=Object.entries(pack.layouts||{}), recent=new Set(entries.slice(-30).map(([key])=>key));
      if (pack.fingerprint === this.graph.fingerprint) for (const [key, layout] of entries.filter(([key])=>recent.has(key)||protectedKeys.has(key))) {
        const positions = Object.fromEntries(Object.entries(layout.positions || {}).filter(([,p]) => Number.isFinite(p?.x) && Number.isFinite(p?.y) && Math.abs(p.x) < 1e8 && Math.abs(p.y) < 1e8));
        this.layouts[key] = { positions, routes: {}, pins: (layout.pins || []).filter(k => positions[k]), routesValid: false };
      }
      this.dirtyLayouts = new Set(Object.keys(this.layouts)); this.restoring = true;
    }
    scheduleSave(kind = 'metadata') {
      if(kind !== 'camera')this.dirtyLayouts.add(this.viewKey());
      this.saveKind = this.saveKind && this.saveKind !== 'camera' ? this.saveKind : kind;
      clearTimeout(this.saveTimer); this.saveTimer=setTimeout(()=>this.save(this.saveKind),500);
      this.maxSaveTimer ||= setTimeout(()=>this.save(this.saveKind),5000);
    }
    async save(kind = 'metadata') {
      if(!this.graph)return;
      clearTimeout(this.saveTimer);clearTimeout(this.maxSaveTimer);this.maxSaveTimer=null;this.saveKind=null;
      const fp=this.graph.fingerprint,cameraOnly=kind==='camera'&&this.persistedFingerprint===fp&&this.dirtyLayouts.size===0;
      const metadata={version:1,fingerprint:fp,state:clone(this.state)};
      const updates={};
      if(!cameraOnly){Object.assign(metadata,{views:clone(this.views),names:clone(this.names||{}),assignments:{...this.assignments},hubs:[...this.hubs],layoutRefs:Object.keys(this.layouts)});for(const key of this.dirtyLayouts)if(this.layouts[key])updates[key]=clone(this.layouts[key]);this.dirtyLayouts.clear();}
      // Orden de escritura determinista incluso si una vista cambia mientras se guarda otra.
      this.saveQueue=(this.saveQueue||Promise.resolve()).then(()=>AnalysisStorage.saveAnalysis(metadata,updates,cameraOnly)).then(()=>{if(!cameraOnly)this.persistedFingerprint=fp;}).catch(e=>{if(this.graph?.fingerprint===fp){this.persistedFingerprint=null;for(const key of Object.keys(this.layouts))this.dirtyLayouts.add(key);}this.notice('No se pudieron guardar las vistas. Exporta una copia: '+e.message,'warning');});
      await this.saveQueue;
    }
    exportDocument(doc) { return { ...doc, erdApp: { version: 1, analysis: this.pack() } }; }
    download(value, name, type = 'application/json') { const url = URL.createObjectURL(new Blob([typeof value === 'string' ? value : JSON.stringify(value, null, 2)], { type })); const a = document.createElement('a'); a.href = url; a.download = name; a.click(); setTimeout(() => URL.revokeObjectURL(url), 1000); }
    async exportSVG() {
      await this.renderer.ready();
      if (!this.projection?.nodes.length) return;
      // Solo la proyección, con nombres y enlaces; nunca representa una exportación del modelo.
      const NS = 'http://www.w3.org/2000/svg', svg = document.createElementNS(NS,'svg'); const w = Math.max(...this.specs.map(s => this.layout.positions[s.key].x+s.width))+40, h = Math.max(...this.specs.map(s => this.layout.positions[s.key].y+s.height))+40; svg.setAttribute('width',w);svg.setAttribute('height',h);svg.setAttribute('viewBox',`0 0 ${w} ${h}`);
      const style=document.createElementNS(NS,'style');style.textContent='text{font:12px system-ui;fill:#1d2840}.edge-line{fill:none;stroke:#9aa6bc;stroke-width:1.5}.edge-label{font:11px system-ui}.edge-hit{display:none}';svg.append(style);svg.append(this.renderer.exportEdges());
      for(const spec of this.specs){const p=this.layout.positions[spec.key],r=document.createElementNS(NS,'rect');for(const [k,v]of Object.entries({x:p.x,y:p.y,width:spec.width,height:spec.height,rx:8,fill:'#fff',stroke:'#cbd5e1'}))r.setAttribute(k,v);svg.append(r);const text=document.createElementNS(NS,'text');text.setAttribute('x',p.x+12);text.setAttribute('y',p.y+24);text.textContent=spec.key;svg.append(text);for(const [i,row]of spec.rows.entries()){const text=document.createElementNS(NS,'text');text.setAttribute('x',p.x+12);text.setAttribute('y',p.y+row.y+4);text.textContent=row.name;svg.append(text);}}
      this.download(new XMLSerializer().serializeToString(svg),'vista-esquema.svg','image/svg+xml');
    }
    bind() {
      this.searchToken = 0;
      document.addEventListener('visibilitychange',()=>{if(document.hidden&&this.graph)this.save(this.saveKind||'camera');});
      document.querySelectorAll('[data-mode]').forEach(b => b.onclick = async () => {
        const mode = b.dataset.mode; if (!this.graph) return;
        if (mode === 'focus') return this.requestFocus(this.graph.tableMap.has(this.state.selected) ? this.state.selected : this.state.root);
        if (mode === 'all' && this.graph.tables.length > 50) { const selected = await this.chooseExpansion(this.graph.tables.map(t=>t.key), `${this.graph.tables.length} tablas y ${this.graph.relations.length} FK. La vista completa puede ser densa. Elige un subconjunto o muestra todo.`); if(selected===null)return;if(selected!=='all')return this.navigate('custom',{manualKeys:selected,links:'context'}); }
        if (mode === 'module' && !this.state.group) this.state.group = this.graph.groups.keys().next().value;
        if (mode === 'module') return this.requestModule(this.state.group); this.navigate(mode, { selected:'', relation:'' });
      });
      $('table-search').addEventListener('input', () => { clearTimeout(this.searchTimer); this.searchTimer=setTimeout(()=>this.runSearch(),120); }); $('table-list').addEventListener('scroll',()=>this.renderSearchWindow());
      $('fluid-mode').onchange=()=>{this.state.fluid=$('fluid-mode').checked;if(!this.state.fluid){clearTimeout(this.fluidTimer);this.viewport.classList.remove('fluid-interaction');}this.scheduleSave();};
      $('detail-mode').onchange=()=>{this.state.detail=$('detail-mode').value;this.show({fit:true});};
      for(const [id,field] of [['cross-filter','cross'],['link-mode','links'],['direction-filter','direction'],['scope-filter','filterGroup']]) $(id).onchange=()=>{const value=$(id).type==='checkbox'?$(id).checked:$(id).value;if(this.state.mode==='focus')this.requestFocus(this.state.root,this.state.depth,{[field]:value});else{this.state[field]=value;this.state.pathIndex=0;this.show();}};
      $('focus-depth').onchange=()=>this.requestFocus(this.state.root,Number($('focus-depth').value));
      $('path-controls').onsubmit=e=>{e.preventDefault();this.navigate('path',{start:$('path-start').value,end:$('path-end').value,via:$('path-via').value,pathIndex:0,selected:'',links:'context'});};$('path-choice').onchange=()=>{this.state.pathIndex=Number($('path-choice').value);this.show({fit:true});};
      $('history-back').onclick=()=>{const s=this.history.pop();if(s){this.state=this.sanitize(s);this.restoring=true;this.show();}};
      $('save-view').onclick=()=>this.saveView();$('export-view').onclick=()=>this.download({type:'erd-analysis-views',...this.pack()},'vistas-esquema.json');$('export-svg').onclick=()=>this.exportSVG();$('import-views').onclick=()=>$('views-input').click();
      $('views-input').onchange=async()=>{const f=$('views-input').files[0];$('views-input').value='';if(!f||!this.graph)return;try{const pack=JSON.parse(await f.text());if(pack.type!=='erd-analysis-views'||pack.version!==1)throw new Error('Archivo de vistas no válido.');this.unpack(pack);this.graph=await this.worker.call('groups',this.assignments);this.projectionCache.clear();this.renderSidebar();await this.show({fit:pack.fingerprint!==this.graph.fingerprint});this.notice('Vistas importadas. Las referencias se comprobaron contra el esquema actual.','ok');}catch(e){this.notice(e.message,'error');}};
      $('name-cancel').onclick=()=>$('name-dialog').close('cancel');$('group-cancel').onclick=()=>$('group-dialog').close('cancel');
      $('toggle-inspector').onclick=()=>this.setInspector($('inspector').hidden);$('close-inspector').onclick=()=>this.setInspector(false);$('btn-tables').onclick=()=>this.setNavigator($('table-panel').hidden);
      $('theme-button').onclick=()=>{const next=document.body.dataset.theme==='dark'?'light':'dark';document.body.dataset.theme=next;try{localStorage.setItem('erd.theme',next);}catch{}};try{document.body.dataset.theme=localStorage.getItem('erd.theme')||'light';}catch{}
      $('zoom-in').onclick=()=>this.zoom(1.25);$('zoom-out').onclick=()=>this.zoom(.8);$('btn-overview').onclick=()=>this.fit();$('relayout').onclick=()=>this.relayout();$('undo-layout').onclick=()=>this.undoLayout();$('layout-spacing').onchange=()=>{this.state.spacing=Number($('layout-spacing').value);this.relayout();};$('cancel-layout').onclick=()=>this.cancel();
      $('minimap').onclick=e=>{if(!this.miniBounds)return;const p=$('minimap').getBoundingClientRect(),scale=Math.min(p.width/this.miniBounds.width,p.height/this.miniBounds.height),ox=(p.width-this.miniBounds.width*scale)/2,oy=(p.height-this.miniBounds.height*scale)/2;this.state.camera.x=this.viewport.clientWidth/2-(this.miniBounds.x+(e.clientX-p.left-ox)/scale)*this.state.camera.z;this.state.camera.y=this.viewport.clientHeight/2-(this.miniBounds.y+(e.clientY-p.top-oy)/scale)*this.state.camera.z;this.transform();this.scheduleSave('camera');};
      this.viewport.addEventListener('wheel',e=>{e.preventDefault();this.interact();if(e.ctrlKey||e.metaKey){const b=this.viewport.getBoundingClientRect();this.zoom(Math.exp(-e.deltaY*.002),e.clientX-b.left,e.clientY-b.top);}else{this.state.camera.x-=e.shiftKey?e.deltaY:e.deltaX;this.state.camera.y-=e.shiftKey?e.deltaX:e.deltaY;this.transform();this.scheduleSave('camera');}},{passive:false});
      this.viewport.addEventListener('keydown',e=>{if(e.target!==this.viewport)return;const c=this.state.camera;if(e.key==='+'||e.key==='=')this.zoom(1.25);else if(e.key==='-')this.zoom(.8);else if(e.key==='Home')this.fit();else if(e.key.startsWith('Arrow')){e.preventDefault();c.x+=e.key==='ArrowLeft'?60:e.key==='ArrowRight'?-60:0;c.y+=e.key==='ArrowUp'?60:e.key==='ArrowDown'?-60:0;this.transform();this.scheduleSave('camera');}});
      this.viewport.addEventListener('pointerdown',e=>{
        if(e.button!==0&&e.button!==1)return;const head=e.target.closest('[data-drag]'), interactive=e.target.closest('button,input,select');if(interactive&&!head)return;if(e.target.closest('.edge-hit'))return;if(!head&&e.target.closest('.graph-node'))return;
        const key=head?.dataset.drag;if(key&&this.layout?.pins?.includes(key))return;
        this.gesture={key,x:e.clientX,y:e.clientY,position:key?clone(this.layout.positions[key]):clone(this.state.camera),moved:false};
      });
      this.viewport.addEventListener('pointermove', e => {
        const g=this.gesture;if(!g)return;const dx=e.clientX-g.x,dy=e.clientY-g.y;
        if(Math.abs(dx)+Math.abs(dy)<4&&!g.moved)return;
        this.interact();if(!g.moved){this.viewport.setPointerCapture(e.pointerId);this.viewport.classList.add('dragging');}g.moved=true;
        if(g.key){this.layout.positions[g.key]={x:g.position.x+dx/this.state.camera.z,y:g.position.y+dy/this.state.camera.z};this.renderer.move(g.key);this.dirtyLayouts.add(this.viewKey());}
        else{this.state.camera.x=g.position.x+dx;this.state.camera.y=g.position.y+dy;this.transform();}
      });
      const end=e=>{const g=this.gesture;if(!g)return;this.gesture=null;this.viewport.classList.remove('dragging');if(this.viewport.hasPointerCapture(e.pointerId))this.viewport.releasePointerCapture(e.pointerId);if(g.moved){if(g.key)this.renderer.settleNode(g.key);if(e.type==='pointerup')this.viewport.addEventListener('click',e=>{e.preventDefault();e.stopPropagation();},{once:true,capture:true});this.renderCanvas();this.scheduleSave(g.key?'layout':'camera');}};this.viewport.addEventListener('pointerup',end);this.viewport.addEventListener('pointercancel',end);
      this.viewport.addEventListener('focusout',()=>this.renderer.request({visibility:true}));
      new ResizeObserver(()=>{if(this.layout)this.renderer.request({camera:true,visibility:true,resize:true});}).observe(this.viewport);
    }
    status() { return { mode:this.state.mode, group:this.state.group, root:this.state.root, selected:this.state.selected, relation:this.state.relation, visibleTables:this.state.mode==='map'?0:this.projection?.nodes.length||0, modules:this.graph?.groups.size||0, visibleRelationships:this.projection?.relations.length||0, summarized:this.projection?.hidden||0, modelTables:this.graph?.tables.length||0, modelRelationships:this.graph?.relations.length||0, fingerprint:this.graph?.fingerprint, busy:this.layoutBusy||false, views:this.views.length }; }
  }
  window.SchemaExplorer = SchemaExplorer;
})();
