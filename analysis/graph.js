/* Modelo de lectura independiente: ninguna operación escribe en el documento ERD. */
(function (root) {
  'use strict';
  const values = x => Object.values(x || {});
  const ordered = x => JSON.stringify(x);
  function hash(text) { let h = 2166136261; for (let i = 0; i < text.length; i++) h = Math.imul(h ^ text.charCodeAt(i), 16777619); return (h >>> 0).toString(36); }
  function build(doc, seed = {}, metadata = {}) {
    const c = doc.collections || {}, bySource = new Map(), tables = [], tableMap = new Map(), relations = [], adjacency = new Map();
    const seedNames = new Map((seed.groups || []).flatMap(g => g.tables.map(name => [name, g.name])));
    const originals = values(c.tableEntities).sort((a, b) => a.name.localeCompare(b.name));
    const useSeed = originals.length >= 50 && originals.filter(t => seedNames.has(t.name)).length / Math.max(1, originals.length) >= .8;
    const seen = new Map(), warnings = [], indexesByTable = new Map();
    for (const index of values(c.indexEntities)) { if (!indexesByTable.has(index.tableId)) indexesByTable.set(index.tableId, []); indexesByTable.get(index.tableId).push({ name: index.name, unique: index.unique, columns: (index.indexColumnIds || []).map(id => c.tableColumnEntities?.[c.indexColumnEntities?.[id]?.columnId]?.name).filter(Boolean) }); }
    for (const t of originals) {
      const name = t.name || '(sin nombre)', n = seen.get(name) || 0; seen.set(name, n + 1);
      const key = name + (n ? `#duplicado-${n}` : '');
      if (n) warnings.push(`Nombre ambiguo: ${name}. Revisa sus vistas tras reimportar.`);
      const cols = (t.columnIds || []).map(id => c.tableColumnEntities?.[id]).filter(Boolean).map(col => ({ id: col.id, name: col.name || '', type: col.dataType || '', comment: col.comment || '', default: col.default || '', options: col.options || 0 }));
      const indexes = indexesByTable.get(t.id) || [];
      const groupName = c.tableGroupEntities?.[t.groupId]?.name;
      const schema = name.includes('.') ? name.slice(0, name.lastIndexOf('.')) : '';
      const group = groupName || (useSeed && seedNames.get(name)) || schema || '';
      const table = { key, id: t.id, name, comment: t.comment || '', columns: cols, indexes, group, baseGroup: group, groupOrigin: groupName ? 'Declarado' : useSeed && seedNames.has(name) ? 'Propuesta revisable' : schema ? 'Esquema' : 'Sugerido', keyColumns: new Set(cols.filter(col => col.options & 2).map(col => col.name)), incoming: [], outgoing: [] };
      tables.push(table); tableMap.set(key, table); bySource.set(t.id, table); adjacency.set(key, []);
    }
    const signatureCounts = new Map();
    for (const r of values(c.relationshipEntities)) {
      const parent = bySource.get(r.start?.tableId), child = bySource.get(r.end?.tableId);
      if (!parent || !child) { warnings.push('Relación con una tabla ausente en el documento.'); continue; }
      const childCols = (r.end.columnIds || []).map(id => c.tableColumnEntities?.[id]?.name || '?');
      const parentCols = (r.start.columnIds || []).map(id => c.tableColumnEntities?.[id]?.name || '?');
      const signature = ordered([child.key, childCols, parent.key, parentCols]);
      const ordinal = signatureCounts.get(signature) || 0; signatureCounts.set(signature, ordinal + 1);
      const relation = { order: relations.length, key: signature + (ordinal ? `#${ordinal}` : ''), id: r.id, child: child.key, parent: parent.key, childCols, parentCols, name: r.name || metadata.names?.[signature] || '', onDelete: r.onDelete, onUpdate: r.onUpdate, type: r.relationshipType };
      relations.push(relation); child.outgoing.push(relation.key); parent.incoming.push(relation.key);
      childCols.forEach(name => child.keyColumns.add(name)); parentCols.forEach(name => parent.keyColumns.add(name));
      adjacency.get(child.key).push({ node: parent.key, relation: relation.key, direction: 'out' });
      adjacency.get(parent.key).push({ node: child.key, relation: relation.key, direction: 'in' });
    }
    const hubThreshold = Math.max(12, tables.length * .25);
    const hubs = tables.filter(t => t.incoming.length >= hubThreshold).map(t => t.key);
    const prefixes = new Map();
    for (const t of tables.filter(t => !t.group)) { const p = t.name.split('_')[0]; prefixes.set(p, (prefixes.get(p) || 0) + 1); }
    for (const t of tables.filter(t => !t.group)) {
      const p = t.name.split('_')[0]; t.group = prefixes.get(p) >= 2 ? p : 'Sin clasificar';
    }
    for(const t of tables) { t.baseGroup = t.group; t.baseGroupOrigin=t.groupOrigin; t.searchText = `${t.name} ${t.comment} ${t.columns.map(c=>`${c.name} ${c.comment}`).join(' ')}`.toLocaleLowerCase(); }
    const fingerprint = hash(ordered(tables.map(t => [t.key, t.columns.map(c => [c.name, c.type, c.options])])) + ordered(relations.map(r => r.key).sort()));
    const graph = { tables, tableMap, relations, relationMap: new Map(relations.map(r => [r.key, r])), adjacency, hubs, fingerprint, warnings, useSeed };
    regroup(graph, metadata.groups || {});
    return graph;
  }
  function regroup(graph, assignments = {}) {
    for (const t of graph.tables) { t.group = typeof assignments[t.key] === 'string' && assignments[t.key].trim() ? assignments[t.key].trim().slice(0,100) : t.baseGroup; t.groupOrigin = t.group !== t.baseGroup ? 'Asignado' : t.baseGroupOrigin; }
    const groups = new Map();
    for (const t of graph.tables) {
      if (!groups.has(t.group)) groups.set(t.group, { name: t.group, tables: [], internal: 0, external: 0 });
      groups.get(t.group).tables.push(t.key);
    }
    for (const r of graph.relations) { const a = graph.tableMap.get(r.child).group, b = graph.tableMap.get(r.parent).group; if (a === b) groups.get(a).internal++; else { groups.get(a).external++; groups.get(b).external++; } }
    graph.groups = groups;
    const pairs=new Map();
    for(const r of graph.relations){const a=graph.tableMap.get(r.child).group,b=graph.tableMap.get(r.parent).group;if(a===b)continue;const key=ordered([a,b].sort());if(!pairs.has(key))pairs.set(key,{key,a,b,relations:[]});pairs.get(key).relations.push(r.key);}
    graph.modulePairs=[...pairs.values()];
  }
  // Extremos en el sentido de la flecha: tabla que declara FK → tabla referenciada.
  // NOT NULL exige un padre por hijo; no exige hijos para cada padre.
  function cardinality(g, r) {
    const table=g.tableMap.get(r.child),names=new Set(r.childCols),columns=table?.columns.filter(c=>names.has(c.name))||[];
    const known=names.size>0&&columns.length===names.size;
    const pk=table?.columns.filter(c=>c.options&2).map(c=>c.name)||[];
    const unique=known&&((pk.length>0&&pk.every(name=>names.has(name)))||columns.some(c=>c.options&4)||table.indexes.some(i=>i.unique&&i.columns.length>0&&i.columns.every(name=>names.has(name)))||[2,8].includes(r.type));
    return { child:known?(unique?'0..1':'0..N'):'?', parent:known?(columns.every(c=>c.options&8)?'1':'0..1'):'?', unique:!!unique, known };
  }
  function allowed(g, r, s = {}) {
    const hubs = new Set(s.hubs || g.hubs);
    return (s.cross || (!hubs.has(r.parent) && !hubs.has(r.child))) &&
      (!s.filterGroup || g.tableMap.get(r.child).group === s.filterGroup || g.tableMap.get(r.parent).group === s.filterGroup);
  }
  function neighbors(g, source, depth = 1, s = {}) {
    if (!g.tableMap.has(source)) return [];
    const found = new Set([source]); let frontier = [source];
    for (let d = 0; d < Math.min(2, depth); d++) {
      const next = [];
      for (const key of frontier) for (const item of g.adjacency.get(key) || []) {
        if (s.direction === 'out' && item.direction !== 'out' || s.direction === 'in' && item.direction !== 'in') continue;
        if (!allowed(g, g.relationMap.get(item.relation), s) || found.has(item.node)) continue;
        found.add(item.node); next.push(item.node);
      }
      frontier = next;
    }
    return [...found];
  }
  function shortest(g, start, end, s = {}, banned = new Set()) {
    if (!g.tableMap.has(start) || !g.tableMap.has(end)) return null;
    const queue = [start], previous = new Map([[start, null]]); let cursor = 0;
    while (cursor < queue.length) {
      const key = queue[cursor++]; if (key === end) break;
      for (const item of g.adjacency.get(key) || []) {
        if (banned.has(item.relation) || previous.has(item.node) || !allowed(g, g.relationMap.get(item.relation), s)) continue;
        if (s.direction === 'out' && item.direction !== 'out' || s.direction === 'in' && item.direction !== 'in') continue;
        previous.set(item.node, { key, relation: item.relation }); queue.push(item.node);
      }
    }
    if (!previous.has(end)) return null;
    const nodes = [end], edges = []; let key = end;
    while (previous.get(key)) { const p = previous.get(key); edges.unshift(p.relation); nodes.unshift(p.key); key = p.key; }
    return { nodes, edges };
  }
  function paths(g, start, end, s = {}) {
    const first = shortest(g, start, s.via || end, s); if (!first) return [];
    if (s.via) { const tail = shortest(g, s.via, end, s); return tail ? [{ nodes: [...first.nodes, ...tail.nodes.slice(1)], edges: [...first.edges, ...tail.edges] }] : []; }
    const result = [first], signatures = new Set([ordered(first.nodes)]);
    for (const edge of first.edges.slice(0, 12)) {
      const alt = shortest(g, start, end, s, new Set([edge]));
      if (alt && !signatures.has(ordered(alt.nodes))) { result.push(alt); signatures.add(ordered(alt.nodes)); }
      if (result.length === 3) break;
    }
    return result.sort((a, b) => a.edges.length - b.edges.length);
  }
  function project(g, s) {
    if (s.mode === 'map') {
      const selectedGroup = g.groups.has(s.selected) ? s.selected : null;
      const bundles = g.modulePairs.filter(p => s.links === 'all' || selectedGroup && (p.a === selectedGroup || p.b === selectedGroup));
      return { nodes: [...g.groups.keys()], relations: [], bundles, boundary: [], hidden: g.relations.length, total: g.tables.length };
    }
    let keys = [], routeOptions = [];
    if (s.mode === 'module') keys = g.groups.get(s.group)?.tables || [];
    else if (s.mode === 'focus') keys = s.manualKeys || neighbors(g, s.root, Number(s.depth ?? 1), s);
    else if (s.mode === 'path') { routeOptions = paths(g, s.start, s.end, s); keys = routeOptions[s.pathIndex || 0]?.nodes || []; }
    else if (s.mode === 'all') keys = g.tables.map(t => t.key);
    else keys = s.manualKeys || [];
    keys = [...new Set([...keys, ...(s.extraKeys || [])])].filter(key => g.tableMap.has(key));
    const visible = new Set(keys), pathEdges = new Set(routeOptions[s.pathIndex || 0]?.edges || []);
    const relations = [], boundary = new Map(); let hidden = 0;
    const candidates = new Set();
    for(const key of keys) for(const item of g.adjacency.get(key)||[])candidates.add(item.relation);
    for (const id of [...candidates].sort((a,b)=>g.relationMap.get(a).order-g.relationMap.get(b).order)) {
      const r = g.relationMap.get(id);
      const both = visible.has(r.child) && visible.has(r.parent), either = visible.has(r.child) || visible.has(r.parent);
      if (both && (s.mode === 'all' || allowed(g, r, s)) && (s.mode !== 'path' || pathEdges.has(r.key))) relations.push(r.key);
      else if (either) {
        hidden++;
        const remote = !visible.has(r.parent) ? r.parent : !visible.has(r.child) ? r.child : null;
        const label = remote ? g.tableMap.get(remote).group : 'Referencias transversales / filtradas';
        if (!boundary.has(label)) boundary.set(label, { group: label, relations: [], tables: new Set() });
        const item = boundary.get(label); item.relations.push(r.key); if (remote) item.tables.add(remote);
      }
    }
    if (s.mode === 'all') {
      const pairs=new Map();
      for(const id of relations){const r=g.relationMap.get(id),pair=ordered([r.child,r.parent]);if(!pairs.has(pair))pairs.set(pair,[]);pairs.get(pair).push(id);}
      const bundles=[];
      for(const ids of pairs.values())ids.forEach((id,lane)=>{const r=g.relationMap.get(id);bundles.push({key:r.key,a:r.child,b:r.parent,relations:[id],lane,lanes:ids.length,cardinality:cardinality(g,r)});});
      return {nodes:keys,relations,bundles,boundary:[],hidden:0,total:g.tables.length,routeOptions};
    }
    const grouped = new Map();
    for (const id of relations) { const r = g.relationMap.get(id), key = ordered([r.child, r.parent]); if (!grouped.has(key)) grouped.set(key, { key, a: r.child, b: r.parent, relations: [] }); grouped.get(key).relations.push(id); }
    return { nodes: keys, relations, bundles: [...grouped.values()], boundary: [...boundary.values()].map(b => ({ ...b, tables: [...b.tables] })), hidden, total: g.tables.length, routeOptions };
  }
  function search(g, query) {
    const words = query.trim().toLocaleLowerCase().split(/\s+/).filter(Boolean);
    return g.tables.filter(t => words.every(w => t.searchText.includes(w))).map(t => t.key);
  }
  const api = { build, regroup, project, neighbors, paths, shortest, search, hash, cardinality };
  if (typeof module !== 'undefined' && module.exports) module.exports = api; else root.SchemaGraph = api;
})(globalThis);
