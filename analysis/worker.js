importScripts('graph.js', '../vendor/elk.bundled.js');
let layoutWorker;
const elk = new ELK({ workerFactory: () => (layoutWorker = new Worker('../vendor/elk-worker.min.js')) });
let graph;
const metadata = () => ({ kind:'graph-metadata', fingerprint:graph.fingerprint, groups:graph.groups, modulePairs:graph.modulePairs, tableGroups:graph.tables.map(t=>[t.key,t.group,t.groupOrigin]), names:graph.relations.filter(r=>r.name).map(r=>[r.key,r.name]) });
self.onmessage = async ({ data: { id, type, payload } }) => {
  try {
    let result;
    if (type === 'index') result = graph = SchemaGraph.build(payload.document, payload.seed, payload.metadata);
    else if (type === 'metadata') { SchemaGraph.regroup(graph,payload.groups||{}); for(const r of graph.relations)r.name=payload.names?.[JSON.stringify([r.child,r.childCols,r.parent,r.parentCols])]||r.name; result=metadata(); }
    else if (type === 'dispose') { layoutWorker?.terminate(); result=true; }
    else if (type === 'project') result = SchemaGraph.project(graph, payload);
    else if (type === 'groups') { SchemaGraph.regroup(graph, payload); result = metadata(); }
    else if (type === 'search') result = SchemaGraph.search(graph, payload);
    else if (type === 'layout') {
      const { nodes, bundles, spacing = 60 } = payload;
      const routedBundles = bundles.filter(b => b.a !== b.b);
      const input = { id: 'diagram', layoutOptions: { 'elk.algorithm': 'layered', 'elk.direction': 'RIGHT', 'elk.edgeRouting': 'ORTHOGONAL', 'elk.spacing.nodeNode': String(spacing), 'elk.layered.spacing.nodeNodeBetweenLayers': String(spacing + 90), 'elk.layered.spacing.edgeNodeBetweenLayers': '30', 'elk.padding': '[top=40,left=40,bottom=40,right=40]', 'elk.randomSeed': '1' }, children: nodes.map(n => ({ id: n.key, width: n.width, height: n.height, layoutOptions: { 'elk.portConstraints': 'FIXED_POS' }, ports: (n.ports || []).map(p => ({ id: p.id, x: p.x, y: p.y, width: 0, height: 0, layoutOptions: { 'elk.port.side': p.side } })) })), edges: routedBundles.map((b, i) => ({ id: String(i), sources: [b.sourcePort || b.a], targets: [b.targetPort || b.b] })) };
      const output = await elk.layout(input);
      result = { positions: Object.fromEntries(output.children.map(n => [n.id, { x: n.x, y: n.y }])), routes: Object.fromEntries((output.edges || []).map(edge => [routedBundles[Number(edge.id)]?.key, edge.sections || []])), width: output.width, height: output.height };
    } else throw new Error(`Operación desconocida: ${type}`);
    self.postMessage({ id, result });
  } catch (error) { self.postMessage({ id, error: error.message || String(error) }); }
};
