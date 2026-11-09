/* Render incremental. La cámara no invalida la geometría del documento. */
(() => {
  const NS = 'http://www.w3.org/2000/svg';
  const svg = (tag, attrs = {}) => { const el = document.createElementNS(NS, tag); for (const [k, v] of Object.entries(attrs)) el.setAttribute(k, v); return el; };
  const intersects = (a, b) => a.x <= b.x + b.width && a.x + a.width >= b.x && a.y <= b.y + b.height && a.y + a.height >= b.y;
  const contains = (a, b) => a && b.x >= a.x && b.y >= a.y && b.x + b.width <= a.x + a.width && b.y + b.height <= a.y + a.height;
  // Las cajas de rutas muy largas quedan en un conjunto aparte: no llenan miles de celdas.
  class SpatialIndex {
    constructor() { this.cells = new Map(); this.entries = new Map(); this.wide = new Set(); this.size = 1024; }
    keys(box) {
      const x0 = Math.floor(box.x / this.size), x1 = Math.floor((box.x + box.width) / this.size), y0 = Math.floor(box.y / this.size), y1 = Math.floor((box.y + box.height) / this.size);
      if ((x1 - x0 + 1) * (y1 - y0 + 1) > 128) return null;
      const keys = []; for (let x = x0; x <= x1; x++) for (let y = y0; y <= y1; y++) keys.push(x + ':' + y); return keys;
    }
    set(key, box) { this.delete(key); const cells = this.keys(box); this.entries.set(key, { box, cells }); if (!cells) this.wide.add(key); else for (const cell of cells) { if (!this.cells.has(cell)) this.cells.set(cell, new Set()); this.cells.get(cell).add(key); } }
    delete(key) { const entry = this.entries.get(key); if (!entry) return; for (const cell of entry.cells || []) { const set = this.cells.get(cell); set.delete(key); if (!set.size) this.cells.delete(cell); } this.wide.delete(key); this.entries.delete(key); }
    query(box) { const keys = this.keys(box); if (!keys) return [...this.entries].filter(([, e]) => intersects(e.box, box)).map(([k]) => k); const found = new Set(this.wide); for (const cell of keys) for (const key of this.cells.get(cell) || []) found.add(key); return [...found].filter(k => intersects(this.entries.get(k).box, box)); }
  }
  class DiagramRenderer {
    constructor(app) {
      this.app = app; this.cards = new Map(); this.links = new Map(); this.geometry = new Map(); this.incident = new Map(); this.waiters = []; this.dirty = {}; this.changedCards = new Set(); this.moved = new Set(); this.settled = new Set(); this.bases = new WeakMap(); this.stats = { frames: 0, cardsCreated: 0, cardsRemoved: 0, pathsCreated: 0, geometryUpdates: 0, measurements: 0, miniBuilds: 0, frameMs: [] };
      this.metricsEnabled = new URLSearchParams(location.search).has('performance');
      this.defs = svg('defs'); const marker = svg('marker', { id: 'fk-arrow', viewBox: '0 0 10 10', refX: 10, refY: 5, markerWidth: 6, markerHeight: 6, orient: 'auto-start-reverse' }); marker.append(svg('path', { d: 'M0 0 L10 5 L0 10 z', fill: 'context-stroke' })); this.defs.append(marker); app.edges.replaceChildren(this.defs);
      document.addEventListener('visibilitychange', () => { if (!document.hidden && Object.keys(this.dirty).length) this.request(); });
    }
    valid() { const a = this.app; return a.canvasReady && a.layout && a.projection && a.canvasMode === a.state.mode && a.canvasFingerprint === a.graph?.fingerprint; }
    request(flags = {}) { Object.assign(this.dirty, flags); if (!this.frame) this.frame = requestAnimationFrame(() => this.commit()); }
    ready() { if (!this.frame) return Promise.resolve(); return new Promise(resolve => { this.waiters.push(resolve); if (document.hidden) this.commit(); }); }
    scene() {
      const a = this.app; this.safety = null; this.nodeIndex = new SpatialIndex(); this.edgeIndex = new SpatialIndex(); this.geometry.clear(); this.incident.clear();
      for (const s of a.specs) { const p = a.layout.positions[s.key]; this.nodeIndex.set(s.key, { ...p, width: s.width, height: s.height }); }
      this.bundleMap = new Map(a.projection.bundles.map(b => [b.key, b]));
      this.invalidRoutes = new Set(a.layout.invalidRoutes || []);
      for (const b of a.projection.bundles) { for (const key of new Set([b.a, b.b])) { if (!this.incident.has(key)) this.incident.set(key, new Set()); this.incident.get(key).add(b.key); } this.updateGeometry(b); }
      this.request({ scene: true, selection: true, camera: true, mini: true });
    }
    settleNode(key) { this.settled.add(key); this.request({ movement: true }); }
    move(key) { this.moved.add(key); this.request({ movement: true, camera: true }); }
    updateGeometry(b) {
      const a = this.app, p = a.layout.positions[b.a], q = a.layout.positions[b.b], s = a.specMap.get(b.a), t = a.specMap.get(b.b); if (!p || !q || !s || !t) return;
      let points; const route = a.layout.routesValid && !this.invalidRoutes.has(b.key) && a.layout.routes?.[b.key]?.[0];
      if (route) points = [route.startPoint, ...(route.bendPoints || []), route.endPoint];
      else {
        const r = b.relations.length === 1 ? a.graph.relationMap.get(b.relations[0]) : null;
        const header = b.lanes>1 ? 15+b.lane*Math.min(8,24/(b.lanes-1)) : 25;
        const y1 = p.y + (r?.childCols.length === 1 ? s.rows.find(v => v.name === r.childCols[0])?.y || header : header), y2 = q.y + (r?.parentCols.length === 1 ? t.rows.find(v => v.name === r.parentCols[0])?.y || header : header), x1 = p.x + s.width, x2 = q.x;
        if (b.a === b.b) points = [{ x:x1,y:y1 },{ x:x1+28+(b.lane||0)*14,y:y1 },{ x:x1+28+(b.lane||0)*14,y:p.y-30-(b.lane||0)*16 },{ x:p.x-20,y:p.y-30-(b.lane||0)*16 },{ x:p.x-20,y:y2 },{ x:p.x,y:y2 }];
        else if (x2 > x1 + 30) { const x = (x1+x2)/2 + ((b.lane||0)-((b.lanes||1)-1)/2)*Math.min(14,(x2-x1)/(2*(b.lanes||1))); points = [{x:x1,y:y1},{x,y:y1},{x,y:y2},{x:x2,y:y2}]; }
        else { const y = Math.min(p.y,q.y)-35-(b.lane||0)*16; points = [{x:x1,y:y1},{x:x1+20,y:y1},{x:x1+20,y},{x:x2-20,y},{x:x2-20,y:y2},{x:x2,y:y2}]; }
      }
      const xs = points.map(p => p.x), ys = points.map(p => p.y), x = Math.min(...xs), y = Math.min(...ys), mid = points[Math.floor(points.length/2)];
      const record = { d: points.map((p,i)=>(i?'L':'M')+p.x+','+p.y).join(' '), points, startLabel:this.endLabel(points), endLabel:this.endLabel([...points].reverse()), x:mid.x+4, y:mid.y-8, box:{ x:x-50,y:y-35,width:Math.max(...xs)-x+100,height:Math.max(...ys)-y+70 } };
      this.geometry.set(b.key, record); this.edgeIndex.set(b.key, record.box); this.stats.geometryUpdates++;
    }
    endLabel(points) {
      let total=0;for(let i=1;i<points.length;i++)total+=Math.hypot(points[i].x-points[i-1].x,points[i].y-points[i-1].y);
      let remaining=Math.min(30,total/4);
      for(let i=1;i<points.length;i++){const p=points[i-1],q=points[i],dx=q.x-p.x,dy=q.y-p.y,length=Math.hypot(dx,dy);if(!length)continue;if(remaining<=length){return{x:p.x+dx*remaining/length+dy/length*11,y:p.y+dy*remaining/length-dx/length*11};}remaining-=length;}
      return points[0]||{x:0,y:0};
    }
    routeIntersects(record, box) {
      if (!intersects(record.box,box)) return false;
      for (let i=1;i<record.points.length;i++) { const p=record.points[i-1],q=record.points[i]; if (intersects({x:Math.min(p.x,q.x)-12,y:Math.min(p.y,q.y)-12,width:Math.abs(p.x-q.x)+24,height:Math.abs(p.y-q.y)+24},box)) return true; } return false;
    }
    commit() {
      if (this.frame) cancelAnimationFrame(this.frame); this.frame = 0;
      const flags=this.dirty; this.dirty={}; const started=this.metricsEnabled?performance.now():0;
      try {
        if (!this.valid()) return;
        const a=this.app,c=a.state.camera;
        if (!this.viewportSize || flags.resize) {this.viewportSize={width:a.viewport.clientWidth,height:a.viewport.clientHeight};this.viewportRect=a.viewport.getBoundingClientRect();}
        const {width:w,height:h}=this.viewportSize;
        a.world.style.transform=`translate(${c.x}px,${c.y}px) scale(${c.z})`; const label=Math.round(c.z*100)+'%'; if(this.zoomLabel!==label){document.getElementById('zoom-label').textContent=label;this.zoomLabel=label;}
        for (const key of this.moved) {
          const p=a.layout.positions[key],s=a.specMap.get(key); if (!p || !s) continue;
          this.nodeIndex.set(key,{...p,width:s.width,height:s.height});
          const mounted=this.cards.get(key); if (mounted) this.position(mounted.el,p, a.gesture?.key === key);
          for (const id of this.incident.get(key)||[]) { this.invalidRoutes.add(id); this.updateGeometry(this.bundleMap.get(id)); const entry=this.links.get(id); if(entry)this.pathGeometry(entry,this.geometry.get(id)); }
          const mini=this.miniNodes?.get(key); if(mini){mini.setAttribute('x',p.x);mini.setAttribute('y',p.y);}
        }
        if (this.moved.size) { a.layout.invalidRoutes=[...this.invalidRoutes]; this.safety=null; this.moved.clear(); this.updateMiniBounds(); }
        for(const key of this.settled){const mounted=this.cards.get(key);if(mounted)this.position(mounted.el,a.layout.positions[key]);}this.settled.clear();
        const view={x:-c.x/c.z,y:-c.y/c.z,width:w/c.z,height:h/c.z};
        if (flags.scene || flags.visibility || !contains(this.safety,view)) {
          const margin=240/c.z,box={x:view.x-margin,y:view.y-margin,width:view.width+margin*2,height:view.height+margin*2};
          this.safety={x:view.x-margin/2,y:view.y-margin/2,width:view.width+margin,height:view.height+margin};
          this.visibleNodes=new Set(this.nodeIndex.query(box)); this.visibleEdges=new Set(this.edgeIndex.query(box).filter(k=>this.routeIntersects(this.geometry.get(k),box)));
          this.syncNodes(this.visibleNodes); this.syncEdges(this.visibleEdges); flags.selection = true;
        } else if (flags.selection) this.syncEdges(this.visibleEdges);
        if (flags.selection || flags.scene) this.styleSelection();
        if (flags.mini) this.buildMinimap();
        this.cameraMinimap(view);
        document.getElementById('undo-layout').disabled=!a.layoutHistory.length;
        this.stats.frames++;
      } finally {
        if (this.metricsEnabled) { this.stats.frameMs.push(performance.now()-started); if(this.stats.frameMs.length>1200)this.stats.frameMs.shift(); }
        for(const resolve of this.waiters.splice(0))resolve();
      }
    }
    position(el,p,drag=false) { const base=this.bases.get(el);if(drag&&base){el.style.transform=`translate(${p.x-base.x}px,${p.y-base.y}px)`;}else{el.style.left=p.x+'px';el.style.top=p.y+'px';el.style.transform='';this.bases.set(el,{...p});} }
    syncNodes(keys) {
      const a=this.app,active=document.activeElement?.closest('.graph-node')?.dataset.key;
      for(const key of [active,a.gesture?.key]) if(key&&a.specMap.has(key))keys.add(key);
      for(const [key,entry] of this.cards) if(!keys.has(key)){entry.el.remove();this.cards.delete(key);this.stats.cardsRemoved++;}
      for(const key of keys){const spec=a.specMap.get(key);if(!spec)continue;let entry=this.cards.get(key);
        if(entry?.signature!==spec.signature){const el=a.card(key);if(entry)entry.el.replaceWith(el);else a.nodes.append(el);entry={el,signature:spec.signature,rows:[...el.querySelectorAll('[data-column]')]};this.cards.set(key,entry);this.changedCards.add(key);this.stats.cardsCreated++;}
        entry.el.style.height=spec.height+'px'; this.position(entry.el,a.layout.positions[key]);
      }
      document.getElementById('canvas-empty').hidden=a.projection.nodes.length>0;
      if(!a.projection.nodes.length&&a.graph.tables.length){const empty=document.getElementById('canvas-empty');empty.textContent=a.state.mode==='path'?'Sin ruta bajo los filtros actuales. Cambia los filtros o vuelve al mapa.':'No hay tablas en este contexto. El modelo completo sigue disponible.';}
    }
    pathGeometry(entry,g) { if(entry.geometry===g)return;entry.geometry=g;entry.path.setAttribute('d',g.d);entry.hit.setAttribute('d',g.d);entry.text.setAttribute('x',g.x);entry.text.setAttribute('y',g.y);for(const[el,position]of [[entry.childCardinality,g.startLabel],[entry.parentCardinality,g.endLabel]]){el.setAttribute('x',position.x);el.setAttribute('y',position.y);}}
    syncEdges(keys = new Set()) {
      const a=this.app,active=document.activeElement?.dataset.bundle;
      const shown=new Set([...keys].filter(k=>this.bundleMap.has(k)&&a.edgeShown(this.bundleMap.get(k))));
      if(active&&this.bundleMap.has(active)&&a.edgeShown(this.bundleMap.get(active)))shown.add(active);
      for(const [key,entry] of this.links)if(!shown.has(key)){entry.group.remove();this.links.delete(key);}
      for(const key of shown){const b=this.bundleMap.get(key),g=this.geometry.get(key);let entry=this.links.get(key);if(!g)continue;
        if(!entry){const group=svg('g'),path=svg('path',{class:'edge-line'}),hit=svg('path',{class:'edge-hit',role:'button',tabindex:0,'data-bundle':key}),text=svg('text',{class:'edge-label'}),childCardinality=svg('text',{class:'edge-label edge-cardinality','text-anchor':'middle','data-cardinality':'child'}),parentCardinality=svg('text',{class:'edge-label edge-cardinality','text-anchor':'middle','data-cardinality':'parent'}),title=svg('title');hit.onclick=()=>a.selectBundle(this.bundleMap.get(key));hit.onkeydown=e=>{if(e.key==='Enter'||e.key===' '){e.preventDefault();a.selectBundle(this.bundleMap.get(key));}};group.append(title,path,hit,text,childCardinality,parentCardinality);a.edges.append(group);entry={group,path,hit,text,childCardinality,parentCardinality,title};this.links.set(key,entry);this.stats.pathsCreated++;}
        this.pathGeometry(entry,g);entry.hit.setAttribute('aria-label',b.cardinality?`${a.graph.relationMap.get(b.relations[0])?.name||b.key} · ${b.a} [${b.cardinality.child}] → ${b.b} [${b.cardinality.parent}]`:`${b.a} → ${b.b}: ${b.relations.length} relaciones`);entry.path.setAttribute('marker-end',a.state.mode==='map'?'':'url(#fk-arrow)');
        this.styleEdge(entry,b);
      }
    }
    styleEdge(entry,b) { const a=this.app,selected=b.relations.includes(a.state.relation);entry.path.setAttribute('class','edge-line'+(selected?' selected':''));const label=b.relations.length>1?b.relations.length+' FK':'FK';if(entry.text.textContent!==label)entry.text.textContent=label;entry.text.style.display=b.relations.length>1||selected||a.state.mode==='map'?'':'none';
      entry.group.classList.toggle('selected',selected);
      const card=b.cardinality;entry.childCardinality.style.display=entry.parentCardinality.style.display=card?'':'none';
      if(card){if(entry.childCardinality.textContent!==card.child)entry.childCardinality.textContent=card.child;if(entry.parentCardinality.textContent!==card.parent)entry.parentCardinality.textContent=card.parent;const r=a.graph.relationMap.get(b.relations[0]);const description=`${r.name||'FK'}: por cada ${r.child}, ${card.parent} ${r.parent}; por cada ${r.parent}, ${card.child} ${r.child}. ${r.childCols.join(', ')} → ${r.parentCols.join(', ')}`;if(entry.title.textContent!==description)entry.title.textContent=description;} }
    styleSelection() {
      const a=this.app,r=a.graph.relationMap.get(a.state.relation),previous=this.lastRelation;
      const pins=new Set(a.layout.pins||[]),keys=new Set([...this.changedCards,this.lastSelected,a.state.selected,r?.child,r?.parent,previous?.child,previous?.parent]);
      for(const key of pins)if(!this.lastPins?.has(key))keys.add(key);
      for(const key of this.lastPins||[])if(!pins.has(key))keys.add(key);
      for(const key of keys){const mounted=this.cards.get(key);if(!mounted)continue;const {el,rows}=mounted;el.classList.toggle('selected',a.state.selected===key);el.querySelector('.node-pin')?.setAttribute('aria-pressed',String(pins.has(key)));for(const row of rows)row.classList.toggle('highlight',!!r&&(key===r.child&&r.childCols.includes(row.dataset.column)||key===r.parent&&r.parentCols.includes(row.dataset.column)));}
      a.edges.classList.toggle('has-selection',!!a.state.relation);
      for(const [key,entry]of this.links){const b=this.bundleMap.get(key);if(b.relations.includes(a.state.relation)||b.relations.includes(this.lastRelation?.key))this.styleEdge(entry,b);}
      for(const key of [this.lastSelected,a.state.selected])this.miniNodes?.get(key)?.setAttribute('fill',key===a.state.selected?'var(--accent)':'var(--line)');
      this.lastSelected=a.state.selected;this.lastRelation=r;this.lastPins=pins;this.changedCards.clear();
    }
    updateMiniBounds() {
      const a=this.app,boxes=a.specs.map(s=>({...a.layout.positions[s.key],width:s.width,height:s.height}));
      if(!boxes.length){a.miniBounds=null;return;}const x=Math.min(...boxes.map(b=>b.x))-40,y=Math.min(...boxes.map(b=>b.y))-40,right=Math.max(...boxes.map(b=>b.x+b.width))+40,bottom=Math.max(...boxes.map(b=>b.y+b.height))+40;
      a.miniBounds={x,y,width:right-x,height:bottom-y};document.getElementById('minimap').setAttribute('viewBox',`${x} ${y} ${right-x} ${bottom-y}`);
    }
    buildMinimap() {
      const a=this.app,host=document.getElementById('minimap');host.replaceChildren();this.miniNodes=new Map();this.updateMiniBounds();
      const fragment=document.createDocumentFragment();for(const spec of a.specs){const p=a.layout.positions[spec.key],el=svg('rect',{x:p.x,y:p.y,width:spec.width,height:spec.height,fill:spec.key===a.state.selected?'var(--accent)':'var(--line)'});fragment.append(el);this.miniNodes.set(spec.key,el);}
      this.miniCamera=svg('rect',{fill:'none',stroke:'var(--accent)','stroke-width':2,'vector-effect':'non-scaling-stroke'});fragment.append(this.miniCamera);host.append(fragment);this.stats.miniBuilds++;
    }
    cameraMinimap(view) {if(this.miniCamera)for(const[k,v]of Object.entries(view))if(this.miniCamera.getAttribute(k)!==String(v))this.miniCamera.setAttribute(k,v);}
    exportEdges() {const fragment=document.createDocumentFragment();fragment.append(this.defs.cloneNode(true));for(const [key,g]of this.geometry){const b=this.bundleMap.get(key);if(!this.app.edgeShown(b))continue;const path=svg('path',{d:g.d,class:'edge-line'});if(this.app.state.mode!=='map')path.setAttribute('marker-end','url(#fk-arrow)');fragment.append(path);if(b.cardinality)for(const[value,p]of [[b.cardinality.child,g.startLabel],[b.cardinality.parent,g.endLabel]]){const label=svg('text',{x:p.x,y:p.y,class:'edge-label edge-cardinality','text-anchor':'middle'});label.textContent=value;fragment.append(label);}if(b.relations.length>1){const text=svg('text',{x:g.x,y:g.y,class:'edge-label'});text.textContent=b.relations.length+' FK';fragment.append(text);}}return fragment;}
  }
  window.DiagramRenderer=DiagramRenderer;
})();
