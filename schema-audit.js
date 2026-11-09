/* Inventario de DDL para contrastar la importación; no ejecuta SQL. */
(() => {
  function tokenize(sql) {
    const tokens = [];
    for (let i = 0; i < sql.length;) {
      const rest = sql.slice(i);
      const skip = rest.match(/^(?:\s+|--[^\r\n]*|#[^\r\n]*|\/\*[\s\S]*?\*\/)/);
      if (skip) { i += skip[0].length; continue; }
      const dollar = rest.match(/^\$(?:[A-Za-z_][\w]*)?\$/);
      if (dollar) {
        const end = sql.indexOf(dollar[0], i + dollar[0].length);
        if (end < 0) throw new Error('Bloque SQL sin cerrar.');
        i = end + dollar[0].length;
        tokens.push({ text: '', quoted: true, literal: true });
        continue;
      }
      const char = sql[i];
      if ("'\"`[".includes(char)) {
        const close = char === '[' ? ']' : char;
        let text = '', closed = false;
        i++;
        while (i < sql.length) {
          if (sql[i] === close) {
            if (sql[i + 1] === close) { text += close; i += 2; continue; }
            i++; closed = true; break;
          }
          if (sql[i] === '\\' && char === "'" && i + 1 < sql.length) i++;
          text += sql[i++];
        }
        if (!closed) throw new Error('Texto o identificador SQL sin cerrar.');
        tokens.push({ text, quoted: true, literal: char === "'" });
        continue;
      }
      const word = rest.match(/^[\p{L}\p{N}_$]+/u);
      const text = word ? word[0] : char;
      tokens.push({ text, quoted: false, literal: false });
      i += text.length;
    }
    return tokens;
  }

  const is = (token, text) => token && !token.quoted && token.text.toUpperCase() === text;
  const identifier = token => token && !token.literal &&
    (token.quoted || /^[\p{L}_][\p{L}\p{N}_$]*$/u.test(token.text));

  function foreignKeys(tokens) {
    const result = []; let owner = '', constraint = '';
    const qualified = start => { const parts = []; let i = start; if (!identifier(tokens[i])) return null; parts.push(tokens[i++].text); while (tokens[i]?.text === '.' && identifier(tokens[i + 1])) { parts.push(tokens[i + 1].text); i += 2; } return { name: parts.join('.'), next: i }; };
    const tuple = start => { if (tokens[start]?.text !== '(') return null; const names = []; let i = start + 1; while (i < tokens.length && tokens[i].text !== ')') { if (!identifier(tokens[i])) return null; names.push(tokens[i++].text); if (tokens[i]?.text === ',') i++; else if (tokens[i]?.text !== ')') return null; } return tokens[i]?.text === ')' ? { names, next: i + 1 } : null; };
    for (let i = 0; i < tokens.length; i++) {
      if (is(tokens[i], 'CREATE') || is(tokens[i], 'ALTER')) {
        let j = i + 1; if (is(tokens[j], 'TEMPORARY') || is(tokens[j], 'TEMP') || is(tokens[j], 'UNLOGGED')) j++;
        if (is(tokens[j], 'TABLE')) { j++; if (is(tokens[j], 'IF')) j += 3; const table = qualified(j); if (table) owner = table.name; constraint = ''; }
      }
      if (tokens[i].text === ';' && !tokens[i].quoted) { owner = ''; constraint = ''; }
      if (is(tokens[i], 'CONSTRAINT') && identifier(tokens[i + 1])) constraint = tokens[i + 1].text;
      if (!owner || !is(tokens[i], 'FOREIGN') || !is(tokens[i + 1], 'KEY')) continue;
      const columns = tuple(i + 2); if (!columns || !is(tokens[columns.next], 'REFERENCES')) continue;
      const parent = qualified(columns.next + 1); if (!parent) continue; const target = tuple(parent.next); if (!target) continue;
      result.push({ child: owner, childCols: columns.names, parent: parent.name, parentCols: target.names, name: constraint }); constraint = '';
    }
    return result;
  }

  function inspect(sql) {
    const tokens = tokenize(sql), tables = [];
    let relationships = 0, indexes = 0;
    for (let i = 0; i < tokens.length; i++) {
      if (is(tokens[i], 'REFERENCES')) relationships++;
      if (is(tokens[i], 'CREATE')) {
        let j = i + 1;
        if (is(tokens[j], 'UNIQUE')) j++;
        if (is(tokens[j], 'INDEX')) indexes++;
        j = i + 1;
        if (is(tokens[j], 'TEMPORARY') || is(tokens[j], 'TEMP') || is(tokens[j], 'UNLOGGED')) j++;
        if (!is(tokens[j++], 'TABLE')) continue;
        if (is(tokens[j], 'IF') && is(tokens[j + 1], 'NOT') && is(tokens[j + 2], 'EXISTS')) j += 3;
        if (!identifier(tokens[j])) throw new Error('CREATE TABLE sin nombre reconocible.');
        const parts = [tokens[j++].text];
        while (tokens[j]?.text === '.' && identifier(tokens[j + 1])) {
          parts.push(tokens[j + 1].text); j += 2;
        }
        if (tokens[j]?.text !== '(') {
          throw new Error(`La tabla ${parts.join('.')} no declara columnas. Exporta su DDL completo (CREATE TABLE con columnas).`);
        }
        const columns = [];
        let depth = 1, segment = [], closed = false;
        const consume = () => {
          if (!segment.length) return;
          const first = segment[0];
          if (['CONSTRAINT', 'PRIMARY', 'FOREIGN', 'UNIQUE', 'CHECK', 'KEY', 'INDEX', 'EXCLUDE', 'FULLTEXT', 'SPATIAL'].some(k => is(first, k))) {
            if (['KEY', 'INDEX', 'FULLTEXT', 'SPATIAL'].some(k => is(first, k)) ||
                (is(first, 'UNIQUE') && segment.some(t => is(t, 'KEY') || is(t, 'INDEX')))) indexes++;
          } else if (identifier(first)) columns.push(first.text);
          segment = [];
        };
        for (j++; j < tokens.length; j++) {
          const t = tokens[j];
          if (!t.quoted && t.text === '(') depth++;
          if (!t.quoted && t.text === ')') {
            depth--;
            if (depth === 0) { consume(); closed = true; break; }
          }
          if (!t.quoted && t.text === ',' && depth === 1) consume();
          else segment.push(t);
        }
        if (!closed) throw new Error(`Definición sin cerrar: ${parts.join('.')}.`);
        tables.push({ name: parts.join('.'), shortName: parts.at(-1), columns });
      }
    }
    if (!tables.length) throw new Error('Este SQL no contiene CREATE TABLE. Los índices, triggers y restricciones por sí solos no definen las tablas. Carga el DDL completo.');
    return { tables, relationships, indexes, foreignKeys: foreignKeys(tokens) };
  }

  function compare(expected, doc) {
    const collections = doc.collections || {};
    const tables = Object.values(collections.tableEntities || {});
    const columns = collections.tableColumnEntities || {};
    const problems = [];
    if (tables.length !== expected.tables.length) problems.push(`${tables.length} de ${expected.tables.length} tablas`);
    for (const source of expected.tables) {
      const table = tables.find(t => t.name === source.name) ||
        (expected.tables.filter(t => t.shortName === source.shortName).length === 1 && tables.find(t => t.name === source.shortName));
      if (!table) { problems.push(`falta ${source.name}`); continue; }
      const names = (table.columnIds || []).map(id => columns[id]?.name);
      const missing = source.columns.filter(name => !names.includes(name));
      if (missing.length) problems.push(`${source.name}: faltan columnas ${missing.join(', ')}`);
    }
    const relationships = Object.keys(collections.relationshipEntities || {}).length;
    if (relationships !== expected.relationships) problems.push(`${relationships} de ${expected.relationships} relaciones`);
    if (problems.length) throw new Error(`Importación incompleta: ${problems.slice(0, 6).join('; ')}. Revisa el dialecto o convierte el esquema a DBML.`);
    const indexes = Object.keys(collections.indexEntities || {}).length;
    return indexes !== expected.indexes
      ? [`Índices: ${indexes} importados de ${expected.indexes} declaraciones KEY/INDEX. El editor puede consolidar u omitir índices; revisa el SQL original.`]
      : [];
  }

  window.SchemaAudit = { inspect, compare };
})();
