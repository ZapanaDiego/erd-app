/* Ensayo del índice de lectura, sin DOM ni promesa de rendimiento del layout. */
const assert = require('node:assert/strict');
const G = require('../analysis/graph.js');
for (const size of [1000, 5000]) {
  const c = { tableEntities: {}, tableColumnEntities: {}, relationshipEntities: {} };
  for (let i = 0; i < size; i++) {
    const id = 't' + i, columnId = id + 'id';
    c.tableEntities[id] = { id, name: `area${i % 20}_table${i}`, columnIds: [columnId] };
    c.tableColumnEntities[columnId] = { id: columnId, name: 'id', dataType: 'INT', options: 2 };
    for (let j = 1; j <= 5; j++) {
      const parent = 't' + ((i + j) % size), rid = `${id}r${j}`;
      c.relationshipEntities[rid] = { id: rid, start: { tableId: parent, columnIds: [parent + 'id'] }, end: { tableId: id, columnIds: [columnId] } };
    }
  }
  const doc = { collections: c }, before = JSON.stringify(doc);
  const start = performance.now(), g = G.build(doc), indexed = performance.now();
  const map = G.project(g, { mode: 'map', links: 'selection', selected: '' });
  const focus = G.project(g, { mode: 'focus', root: g.tables[0].key, depth: 1, cross: true, direction: 'both', links: 'context', hubs: [] });
  const found = G.search(g, 'id'), end = performance.now();
  assert.equal(g.tables.length, size); assert.equal(g.relations.length, size * 5);
  assert.equal(map.nodes.length, 20); assert.equal(map.bundles.length, 0);
  assert.equal(focus.nodes.length, 11); assert.equal(found.length, size);
  assert.equal(JSON.stringify(doc), before);
  console.log(JSON.stringify({ tables: size, foreignKeys: g.relations.length, indexMs: Math.round(indexed - start), projectAndSearchMs: Math.round(end - indexed), mapNodes: map.nodes.length, focusNodes: focus.nodes.length }));
}
