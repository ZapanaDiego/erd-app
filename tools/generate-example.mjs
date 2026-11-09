#!/usr/bin/env node
/**
 * Genera un ejemplo sintético de 150 tablas para la demo pública.
 *
 * - 10 módulos × 15 tablas.
 * - Sin datos reales ni INSERT.
 * - MySQL 8.0.16+ / InnoDB / utf8mb4.
 * - Relaciones intencionadamente variadas: claves compuestas, autorreferencias,
 *   relaciones 1:1 y referencias transversales.
 *
 * Uso:
 *   node tools/generate-example.mjs
 */

import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const ROOT = join(HERE, '..');
const SQL_FILE = join(ROOT, 'examples', 'demo-150-mysql.sql');
const MAP_FILE = join(ROOT, 'docs', 'MODULOS_EJEMPLO.json');

const MODULES = [
  {
    key: 'core', name: 'Núcleo y seguridad', root: 'empresas',
    tables: ['empresas', 'usuarios', 'roles', 'permisos', 'usuario_roles', 'monedas', 'paises', 'ciudades', 'estados', 'configuracion', 'auditoria', 'notificaciones', 'archivos', 'categorias', 'etiquetas'],
  },
  {
    key: 'crm', name: 'CRM', root: 'clientes',
    tables: ['clientes', 'contactos', 'oportunidades', 'actividades', 'campanas', 'segmentos', 'interacciones', 'prospectos', 'cotizaciones', 'seguimientos', 'consentimientos', 'direcciones', 'telefonos', 'correos', 'encuestas'],
  },
  {
    key: 'ventas', name: 'Ventas', root: 'pedidos',
    tables: ['pedidos', 'pedido_lineas', 'facturas', 'factura_lineas', 'pagos', 'devoluciones', 'descuentos', 'vendedores', 'metas', 'comisiones', 'suscripciones', 'renovaciones', 'contratos', 'ofertas', 'listas_precios'],
  },
  {
    key: 'compras', name: 'Compras', root: 'ordenes',
    tables: ['ordenes', 'orden_lineas', 'proveedores', 'solicitudes', 'recepciones', 'facturas', 'pagos', 'contratos', 'evaluaciones', 'categorias', 'requisiciones', 'comparativas', 'incidencias', 'devoluciones', 'presupuestos'],
  },
  {
    key: 'inventario', name: 'Inventario', root: 'productos',
    tables: ['productos', 'variantes', 'categorias', 'almacenes', 'ubicaciones', 'stock', 'movimientos', 'lotes', 'series', 'transferencias', 'ajustes', 'conteos', 'kits', 'precios', 'reordenes'],
  },
  {
    key: 'finanzas', name: 'Finanzas', root: 'asientos',
    tables: ['asientos', 'asiento_lineas', 'cuentas', 'movimientos', 'presupuestos', 'centros_costo', 'impuestos', 'tipos_cambio', 'conciliaciones', 'cobros', 'pagos', 'periodos', 'activos', 'depreciaciones', 'reportes'],
  },
  {
    key: 'logistica', name: 'Logística', root: 'envios',
    tables: ['envios', 'envio_lineas', 'transportistas', 'rutas', 'paradas', 'guias', 'incidencias', 'centros', 'vehiculos', 'conductores', 'tarifas', 'seguimientos', 'devoluciones', 'paquetes', 'zonas'],
  },
  {
    key: 'proyectos', name: 'Proyectos', root: 'proyectos',
    tables: ['proyectos', 'tareas', 'fases', 'asignaciones', 'hitos', 'riesgos', 'incidencias', 'documentos', 'tiempos', 'presupuestos', 'gastos', 'equipos', 'entregables', 'revisiones', 'comentarios'],
  },
  {
    key: 'soporte', name: 'Soporte', root: 'tickets',
    tables: ['tickets', 'mensajes', 'categorias', 'prioridades', 'estados', 'agentes', 'sla', 'escalamientos', 'soluciones', 'articulos', 'encuestas', 'satisfaccion', 'incidentes', 'cambios', 'problemas'],
  },
  {
    key: 'rrhh', name: 'RR. HH.', root: 'nominas',
    tables: ['nominas', 'nomina_lineas', 'empleados', 'departamentos', 'puestos', 'contratos', 'asistencias', 'vacaciones', 'licencias', 'evaluaciones', 'capacitaciones', 'beneficios', 'reclutamiento', 'candidatos', 'historial'],
  },
];

const DOMAIN_COLUMNS = {
  core: [['descripcion', 'VARCHAR(255) NULL']],
  crm: [['correo', 'VARCHAR(160) NULL'], ['telefono', 'VARCHAR(40) NULL']],
  ventas: [['monto', 'DECIMAL(14,2) NOT NULL DEFAULT 0'], ['fecha', 'DATE NULL']],
  compras: [['monto', 'DECIMAL(14,2) NOT NULL DEFAULT 0'], ['fecha', 'DATE NULL']],
  inventario: [['cantidad', 'INT NOT NULL DEFAULT 0'], ['referencia', 'VARCHAR(60) NULL']],
  finanzas: [['monto', 'DECIMAL(14,2) NOT NULL DEFAULT 0'], ['fecha', 'DATE NULL']],
  logistica: [['cantidad', 'INT NOT NULL DEFAULT 0'], ['fecha', 'DATE NULL']],
  proyectos: [['fecha_inicio', 'DATE NULL'], ['fecha_fin', 'DATE NULL']],
  soporte: [['fecha', 'DATE NULL'], ['detalle', 'TEXT NULL']],
  rrhh: [['fecha', 'DATE NULL'], ['monto', 'DECIMAL(14,2) NOT NULL DEFAULT 0']],
};

const SPECIAL_COLUMNS = {
  core_empresas: [['ruc', 'VARCHAR(20) NOT NULL']],
  core_usuarios: [['correo', 'VARCHAR(160) NOT NULL'], ['telefono', 'VARCHAR(40) NULL']],
  core_monedas: [['simbolo', 'CHAR(3) NOT NULL'], ['decimales', 'TINYINT NOT NULL DEFAULT 2']],
  core_paises: [['codigo_iso', 'CHAR(2) NOT NULL']],
  core_ciudades: [['codigo_postal', 'VARCHAR(12) NULL']],
  core_estados: [['ambito', 'VARCHAR(20) NULL']],
};

const SPECIAL_UNIQUE = {
  core_empresas: ['ruc'],
  core_usuarios: ['correo'],
  core_paises: ['codigo_iso'],
};

const SELF_REFERENCES = new Set([
  'core_categorias',
  'crm_segmentos',
  'compras_categorias',
  'inventario_categorias',
  'soporte_categorias',
  'rrhh_departamentos',
]);

// La FK a la tabla raíz del módulo también es 1:1 en estas tablas.
const ROOT_ONE_TO_ONE = new Map([
  ['ventas_facturas', { nullable: false }],
  ['compras_recepciones', { nullable: false }],
  ['finanzas_conciliaciones', { nullable: true }],
  ['logistica_guias', { nullable: false }],
]);

// Una relación 1:1 adicional fuera de la raíz del módulo.
const EXTRA_ONE_TO_ONE = new Map([
  ['proyectos_entregables', { column: 'tarea_id', target: 'proyectos_tareas', nullable: true }],
]);

// Referencias cruzadas explícitas para que el mapa no sea solo una estrella.
const CROSS_REFERENCES = [
  { fromModule: 'core', from: 'core_usuario_roles', column: 'usuario_id', target: 'core_usuarios', nullable: false },
  { fromModule: 'core', from: 'core_usuario_roles', column: 'rol_id', target: 'core_roles', nullable: false },
  { fromModule: 'core', from: 'core_ciudades', column: 'pais_id', target: 'core_paises', nullable: false },
  { fromModule: 'core', from: 'core_estados', column: 'pais_id', target: 'core_paises', nullable: false },
];

function singular(name) {
  if (name.endsWith('series')) return name.slice(0, -1);
  if (name.endsWith('ces')) return name.slice(0, -3) + 'z';
  if (name.endsWith('es')) return name.slice(0, -2);
  if (name.endsWith('s')) return name.slice(0, -1);
  return name;
}

function tableName(module, short) {
  return `${module.key}_${short}`;
}

function quote(name) {
  return `\`${name}\``;
}

const tables = [];
const byName = new Map();

for (const module of MODULES) {
  module.tables.forEach((short, index) => {
    const name = tableName(module, short);
    const table = {
      module, short, index, name,
      columns: [], columnNames: new Set(),
      foreignKeys: [], uniques: [],
    };
    tables.push(table);
    byName.set(name, table);
  });
}

function addColumn(table, name, type, order = 2, unique = false) {
  if (table.columnNames.has(name)) return false;
  table.columnNames.add(name);
  table.columns.push({ name, type, order, seq: table.columns.length, unique });
  return true;
}

function markUnique(table, column) {
  const entry = table.columns.find(candidate => candidate.name === column);
  if (!entry) throw new Error(`${table.name}: no existe la columna ${column}`);
  entry.unique = true;
}

function addUnique(table, columns, suffix) {
  const key = suffix || columns.join('_');
  const name = `uq_${table.name}_${key}`;
  if (table.uniques.some(unique => unique.name === name)) return;
  table.uniques.push({ name, columns });
}

function addForeignKey(table, name, columns, refTable, refColumns, onDelete) {
  if (table.foreignKeys.some(fk => fk.name === name)) return;
  table.foreignKeys.push({ name, columns, refTable, refColumns, onDelete, onUpdate: 'CASCADE' });
}

// Columnas base.
for (const table of tables) {
  addColumn(table, 'id', 'BIGINT UNSIGNED NOT NULL AUTO_INCREMENT', 0);
  if (table.name !== 'core_empresas') addColumn(table, 'tenant_id', 'BIGINT UNSIGNED NOT NULL', 1);
  addColumn(table, 'codigo', 'VARCHAR(40) NOT NULL', 3);
  markUnique(table, 'codigo');
  addColumn(table, 'nombre', 'VARCHAR(120) NOT NULL', 4);
  for (const [name, type] of DOMAIN_COLUMNS[table.module.key] || []) addColumn(table, name, type, 5);
  for (const [name, type] of SPECIAL_COLUMNS[table.name] || []) addColumn(table, name, type, 5);
  addColumn(table, 'estado', "VARCHAR(20) NOT NULL DEFAULT 'activo'", 6);
  addColumn(table, 'creado_en', 'DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)', 7);
  addColumn(table, 'actualizado_en', 'DATETIME(6) NULL', 8);
  for (const column of SPECIAL_UNIQUE[table.name] || []) markUnique(table, column);
}

// FK al tenant (empresa).
for (const table of tables) {
  if (table.name === 'core_empresas') continue;
  addForeignKey(table, `fk_${table.name}_tenant`, ['tenant_id'], 'core_empresas', ['id'], 'RESTRICT');
}

// FK a la raíz de cada módulo; la segunda tabla usa una clave compuesta.
for (const table of tables) {
  if (table.module.key === 'core' || table.index === 0) continue;
  const root = byName.get(tableName(table.module, table.module.root));
  const column = `${singular(root.short)}_id`;
  const oneToOne = ROOT_ONE_TO_ONE.get(table.name);
  const composite = table.index === 1;
  const nullable = composite ? false : (oneToOne?.nullable ?? true);
  addColumn(table, column, `BIGINT UNSIGNED ${nullable ? 'NULL' : 'NOT NULL'}`, 2);
  if (composite) {
    addForeignKey(table, `fk_${table.name}_tenant_${singular(root.short)}`, ['tenant_id', column], root.name, ['tenant_id', 'id'], 'CASCADE');
    addUnique(root, ['tenant_id', 'id'], 'tenant');
  } else {
    addForeignKey(table, `fk_${table.name}_${column}`, [column], root.name, ['id'], nullable ? 'SET NULL' : 'RESTRICT');
    if (oneToOne) markUnique(table, column);
  }
}

// Autorreferencias.
for (const name of SELF_REFERENCES) {
  const table = byName.get(name);
  addColumn(table, 'parent_id', 'BIGINT UNSIGNED NULL', 2);
  addForeignKey(table, `fk_${table.name}_parent`, ['parent_id'], table.name, ['id'], 'SET NULL');
}

// Relación 1:1 adicional.
for (const [name, config] of EXTRA_ONE_TO_ONE) {
  const table = byName.get(name);
  addColumn(table, config.column, `BIGINT UNSIGNED ${config.nullable ? 'NULL' : 'NOT NULL'}`, 2);
  markUnique(table, config.column);
  addForeignKey(table, `fk_${table.name}_${config.column}`, [config.column], config.target, ['id'], config.nullable ? 'SET NULL' : 'RESTRICT');
}

// Referencias explícitas entre módulos.
for (const ref of CROSS_REFERENCES) {
  const table = byName.get(ref.from);
  if (!table) throw new Error(`No existe ${ref.from}`);
  if (!addColumn(table, ref.column, `BIGINT UNSIGNED ${ref.nullable ? 'NULL' : 'NOT NULL'}`, 2)) continue;
  addForeignKey(table, `fk_${table.name}_${ref.column}`, [ref.column], ref.target, ['id'], ref.nullable ? 'SET NULL' : 'RESTRICT');
}

// CRM ↔ Ventas: cada registro comercial conoce su cliente.
for (const table of tables) {
  if (table.module.key !== 'ventas') continue;
  if (table.name === 'ventas_pedidos' || table.name === 'ventas_pedido_lineas') continue;
  if (!addColumn(table, 'cliente_id', 'BIGINT UNSIGNED NULL', 2)) continue;
  addForeignKey(table, `fk_${table.name}_cliente`, ['cliente_id'], 'crm_clientes', ['id'], 'SET NULL');
}
for (const table of tables) {
  if (table.name === 'ventas_pedidos') {
    addColumn(table, 'cliente_id', 'BIGINT UNSIGNED NULL', 2);
    addForeignKey(table, `fk_${table.name}_cliente`, ['cliente_id'], 'crm_clientes', ['id'], 'SET NULL');
  }
}

// Compras ↔ Proveedores.
for (const table of tables) {
  if (table.module.key !== 'compras' || table.name === 'compras_proveedores') continue;
  if (!addColumn(table, 'proveedor_id', 'BIGINT UNSIGNED NULL', 2)) continue;
  addForeignKey(table, `fk_${table.name}_proveedor`, ['proveedor_id'], 'compras_proveedores', ['id'], 'SET NULL');
}

// Usuarios responsables en módulos operativos.
for (const table of tables) {
  if (table.module.key === 'core') continue;
  const global = tables.indexOf(table);
  if (global % 5 !== 4) continue;
  if (!addColumn(table, 'usuario_id', 'BIGINT UNSIGNED NULL', 2)) continue;
  addForeignKey(table, `fk_${table.name}_usuario`, ['usuario_id'], 'core_usuarios', ['id'], 'SET NULL');
}

// Moneda en los módulos económicos.
for (const table of tables) {
  if (!['ventas', 'compras', 'finanzas'].includes(table.module.key)) continue;
  if (table.index % 3 !== 0) continue;
  if (!addColumn(table, 'moneda_id', 'BIGINT UNSIGNED NULL', 2)) continue;
  addForeignKey(table, `fk_${table.name}_moneda`, ['moneda_id'], 'core_monedas', ['id'], 'SET NULL');
}

// Validaciones del generador.
for (const table of tables) {
  if (table.columns.length !== table.columnNames.size) throw new Error(`Columnas duplicadas en ${table.name}`);
  for (const fk of table.foreignKeys) {
    for (const column of fk.columns) if (!table.columnNames.has(column)) throw new Error(`FK ${fk.name}: falta ${column}`);
    if (!byName.has(fk.refTable)) throw new Error(`FK ${fk.name}: no existe ${fk.refTable}`);
    for (const column of fk.refColumns) {
      if (!byName.get(fk.refTable).columnNames.has(column)) throw new Error(`FK ${fk.name}: ${fk.refTable} no tiene ${column}`);
    }
  }
}
if (tables.length !== 150) throw new Error(`Se esperaban 150 tablas, hay ${tables.length}`);

const columnCount = tables.reduce((total, table) => total + table.columns.length, 0);
const foreignKeyCount = tables.reduce((total, table) => total + table.foreignKeys.length, 0);
const compositeForeignKeys = tables.reduce((total, table) => total + table.foreignKeys.filter(fk => fk.columns.length > 1 && fk.columns[0] === 'tenant_id' && fk.columns[1] !== 'id').length, 0);
const selfReferences = tables.reduce((total, table) => total + table.foreignKeys.filter(fk => fk.refTable === table.name).length, 0);
const oneToOne = tables.reduce((total, table) => total + table.columns.filter(column => column.unique && table.foreignKeys.some(fk => fk.columns.length === 1 && fk.columns[0] === column.name)).length, 0);

function columnSql(column) {
  return `  ${quote(column.name)} ${column.type}${column.unique ? ' UNIQUE' : ''}`;
}

function tableSql(table) {
  const columns = [...table.columns].sort((a, b) => a.order - b.order || a.seq - b.seq).map(columnSql);
  const lines = [...columns, '  PRIMARY KEY (`id`)'];
  for (const unique of table.uniques) {
    lines.push(`  UNIQUE KEY ${quote(unique.name)} (${unique.columns.map(quote).join(', ')})`);
  }
  for (const fk of table.foreignKeys) {
    lines.push(`  CONSTRAINT ${quote(fk.name)} FOREIGN KEY (${fk.columns.map(quote).join(', ')}) REFERENCES ${quote(fk.refTable)} (${fk.refColumns.map(quote).join(', ')}) ON DELETE ${fk.onDelete} ON UPDATE ${fk.onUpdate}`);
  }
  return `CREATE TABLE ${quote(table.name)} (\n${lines.join(',\n')}\n) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;`;
}

const sql = [
  '-- erd-app · ejemplo sintético de 150 tablas',
  '-- Generado por tools/generate-example.mjs; no editar a mano.',
  '-- MySQL 8.0.16+ / InnoDB / utf8mb4. No contiene datos reales ni INSERT.',
  `-- ${tables.length} tablas · ${columnCount} columnas · ${foreignKeyCount} relaciones.`,
  '',
  'CREATE DATABASE IF NOT EXISTS `erd_demo_150` CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;',
  'USE `erd_demo_150`;',
  '',
  'SET NAMES utf8mb4;',
  "SET time_zone = '+00:00';",
  'SET FOREIGN_KEY_CHECKS = 0;',
  '',
];

for (const module of MODULES) {
  sql.push(`-- ============================================================`);
  sql.push(`-- Módulo: ${module.name}`);
  sql.push(`-- ============================================================`);
  sql.push('');
  for (const table of tables.filter(table => table.module === module)) {
    sql.push(tableSql(table));
    sql.push('');
  }
}
sql.push('SET FOREIGN_KEY_CHECKS = 1;');
sql.push('');

const map = {
  status: 'ejemplo sintético revisable',
  source: 'examples/demo-150-mysql.sql',
  note: 'No contiene datos reales. Se regenera con node tools/generate-example.mjs.',
  measurements: {
    tables: tables.length,
    columns: columnCount,
    foreignKeys: foreignKeyCount,
    modules: MODULES.length,
    compositeForeignKeys,
    selfReferences,
    oneToOneRelations: oneToOne,
  },
  groups: MODULES.map(module => ({
    name: module.name,
    tables: module.tables.map(short => tableName(module, short)),
  })),
};

mkdirSync(dirname(SQL_FILE), { recursive: true });
mkdirSync(dirname(MAP_FILE), { recursive: true });
writeFileSync(SQL_FILE, `${sql.join('\n')}`, 'utf8');
writeFileSync(MAP_FILE, `${JSON.stringify(map, null, 2)}\n`, 'utf8');

console.log(`Ejemplo generado: ${SQL_FILE}`);
console.log(`${tables.length} tablas · ${columnCount} columnas · ${foreignKeyCount} relaciones`);
console.log(`Compuestas: ${compositeForeignKeys} · autorreferencias: ${selfReferences} · 1:1: ${oneToOne}`);
console.log(`Mapa de módulos: ${MAP_FILE}`);
