# Contexto para futuras sesiones

Documento de trabajo **vigente** de `erd-app`. Última revisión: 9 de noviembre
de 2026. Léelo antes de modificar el proyecto. `agents.mb` es el registro
histórico extenso (secciones 1–19); si hay conflicto entre ese registro y el
código actual, mandan este archivo, el código y `README.md`.

Repositorio público: <https://github.com/ZapanaDiego/erd-app>.
Licencia del código propio: **MIT** (`LICENSE`). GitHub Pages aún no está
activado; requiere habilitarlo en Settings → Pages.

---

## 1. Qué es el producto y en qué estado está

`erd-app` es una aplicación web **estática y local** para importar esquemas de
bases de datos y explorarlos como diagramas entidad-relación. No tiene backend,
no requiere `npm install`, no compila y **no ejecuta SQL**: interpreta el DDL
como estructura y dibuja tablas, columnas, claves y relaciones.

- Formatos aceptados: SQL DDL, DBML, GraphQL SDL, AML y documentos JSON de
  `erd-editor` (`.erd.json`).
- Motores SQL seleccionables: MySQL, MariaDB, PostgreSQL, SQLite, MSSQL y
  Oracle. El motor se elige manualmente; no se detecta desde el archivo.
- El documento canónico y el importador pertenecen a `@dineug/erd-editor`
  4.2.0, vendorizado. El canvas de análisis es propio.
- El análisis nunca modifica el documento: filtra y proyecta una copia de
  lectura. El modelo completo sigue disponible en el editor nativo.
- Ejemplo público: `examples/demo-150-mysql.sql`, sintético, con **150 tablas,
  1549 columnas y 356 relaciones**. No contiene datos reales ni `INSERT`.
- Los esquemas SQL privados que se usaron al principio del desarrollo **no
  están en el repositorio**. Las mediciones de `docs/performance/` son
  históricas de un modelo privado de 127 tablas y no se reproducen solo con el
  ejemplo público.

Estado actual: el explorador visual funciona con mapa de módulos, módulo,
enfoque, ruta, selección manual y “Todo el esquema”; incluye inspector,
búsqueda, vistas persistidas, exportaciones, modo fluido y benchmark de
1000/5000 tablas. El repositorio público está en `main`; Pages está pendiente.

### Línea de tiempo de construcción

| Fecha | Etapa |
| --- | --- |
| 27 oct 2026 | Análisis inicial, inventario, importación, persistencia y diagnóstico. Solo documentación (`agents.mb` 1–13). |
| 28 oct 2026 | Correcciones de importación/auditoría, plan visual, explorador, optimización de fluidez y cardinalidades (`agents.mb` 14–19). |
| 9 nov 2026 | Publicación: ejemplo sintético de 150 tablas, servidor standalone, GitHub Pages preparado, licencia MIT y procedencia IA documentada. |

`docs/PLAN_VISUAL_FRONTEND.md` y `docs/PLAN_OPTIMIZACION_CANVAS.md` conservan
los planes; `docs/RESULTADOS_OPTIMIZACION_CANVAS.md` y `docs/performance/`
conservan las mediciones del modelo privado de 127 tablas.

---

## 2. Arranque y comandos

Desde la raíz del repositorio:

```sh
./start.sh
```

Abre <http://127.0.0.1:5173/>. El servidor Python sirve **la raíz del
repositorio**, solo en `127.0.0.1`.

```sh
NO_OPEN=1 ./start.sh
PORT=8080 ./start.sh
```

`start.sh` ya no sirve el directorio padre ni usa `/erd-app/`. La app debe
abrirse por HTTP: con `file://` fallan los workers.

Atajos:

- Ejemplo automático: <http://127.0.0.1:5173/?autoload=1>
- `?autoload=RUTA_RELATIVA` importa otro archivo del mismo origen.

Comprobaciones públicas:

```sh
node tools/test-graph.cjs
node tools/benchmark-analysis.cjs
node tools/benchmark-large-canvas.mjs   # requiere Chrome/Chromium y Python 3
node tools/generate-example.mjs          # regenera el ejemplo y su mapa
```

El benchmark de navegador admite `CHROME_BIN=/ruta/a/chrome` y usa un perfil
temporal independiente. Para desarrollo conviene comprobar también la
importación del ejemplo en un navegador limpio:

```js
await window.__erdApp.ready;
await window.__erdApp.importUrl('examples/demo-150-mysql.sql', { database: 'MySQL' });
window.__erdApp.getStatus();
```

---

## 3. Arquitectura en una vista

```text
index.html
├── vendor/erd-editor.umd.js        editor + importadores + documento canónico
├── schema-audit.js                 inventario/contraste del DDL
├── analysis/graph.js               índice de lectura y proyecciones
├── analysis/storage.js             IndexedDB
├── analysis/renderer.js            render DOM/SVG incremental
├── analysis/explorer.js            estado de análisis, worker, UI del canvas
└── app.js                          importación, editor nativo, persistencia, arranque
        │
        ├── editor.value  ──────────► JSON canónico del documento
        ├── Worker analysis/worker.js ─► graph + ELK layout
        └── AnalysisStorage / localStorage
```

Separación de responsabilidades que debe mantenerse:

1. **Documento canónico**: `editor.value`, generado por `erd-editor`. Es la
   única fuente de verdad del esquema.
2. **Importación**: `app.js` detecta formato, lee, valida, aplica el texto al
   editor, audita y revierte si el resultado no coincide.
3. **Auditoría**: `schema-audit.js` inspecciona el DDL de entrada y compara
   tablas, columnas declaradas y cantidad de relaciones.
4. **Índice de grafo**: `analysis/graph.js` construye tablas, columnas,
   relaciones, grupos, hubs, adyacencia, búsqueda y huella.
5. **Proyección**: `graph.project()` decide qué nodos, relaciones, bundles y
   fronteras se dibujan para el modo actual; no muta el documento.
6. **Layout**: ELK 0.10.0 en `analysis/worker.js`, con posiciones y rutas.
7. **Render**: `analysis/renderer.js` monta tarjetas HTML y conexiones SVG
   visibles, reutiliza elementos y mantiene minimapa/cámara.
8. **Estado y UI**: `analysis/explorer.js` coordina modos, filtros, selección,
   inspector, vistas, undo, guardado y eventos.
9. **Persistencia**: IndexedDB (`analysis/storage.js`) y copia de compatibilidad
   en `localStorage`.
10. **Editor nativo**: `<erd-editor>` oculto; se muestra con “Editar esquema”.

Flujo de una importación:

```text
archivo/texto/URL
  → detectFormat / readFile
  → SchemaAudit.inspect
  → editor.setSchemaSQL|DBML|GraphQL|AML|setInitialValue
  → normalizeSqlPrimaryKeys
  → editor.value (documento)
  → SchemaAudit.compare (rollback si falla)
  → SchemaExplorer.loadDocument
      → worker index (SchemaGraph.build)
      → project → measure → layout (ELK o cuadrícula)
      → renderer DOM/SVG
  → contadores + informe + persist
```

---

## 4. Mapa de componentes

Tamaños a la fecha de esta revisión; pueden cambiar.

| Ruta | Líneas aprox. | Responsabilidad |
| --- | ---: | --- |
| `index.html` | 73 | Estructura de la app, IDs, controles, diálogos y orden de scripts. |
| `styles.css` | 352 | Shell heredada, editor nativo, diálogos y adaptación general. |
| `analysis/explorer.css` | 27 | Tema del canvas, tarjetas, SVG, inspector y responsive del análisis. |
| `app.js` | 383 | Importación verificada, API del editor, persistencia, eventos, arranque, `__erdApp`. |
| `schema-audit.js` | 139 | Tokenizador e inventario de `CREATE TABLE`, columnas, `REFERENCES`, `KEY/INDEX`. |
| `analysis/graph.js` | 167 | Modelo de lectura, grupos, hubs, cardinalidad, búsqueda, rutas y proyecciones. |
| `analysis/worker.js` | 24 | Protocolo del worker, índice y layout ELK. |
| `analysis/storage.js` | 39 | IndexedDB v2: documento, estado de análisis y layouts. |
| `analysis/renderer.js` | 153 | rAF, índice espacial, virtualización, SVG, minimapa y exportación de aristas. |
| `analysis/explorer.js` | 506 | Estado de análisis, WorkerClient, layout, UI, inspector, vistas y guardado. |
| `examples/demo-150-mysql.sql` | 2567 | Ejemplo sintético MySQL 8: 150 tablas, 1549 columnas, 356 relaciones. |
| `docs/MODULOS_EJEMPLO.json` | 216 | Semilla de 10 módulos para el ejemplo público. |
| `tools/generate-example.mjs` | 372 | Generador determinista del SQL y del mapa de módulos. |
| `tools/test-graph.cjs` | 30 | Pruebas Node del grafo sin navegador. |
| `tools/benchmark-analysis.cjs` | 25 | Ensayo del índice con 1000/5000 tablas. |
| `tools/browser-harness.mjs` | 40 | Servidor + Chrome + CDP, perfil temporal. |
| `tools/benchmark-large-canvas.mjs` | 34 | Benchmark de 1000/5000 tablas en Chrome. |
| `start.sh` | 20 | Servidor local de la raíz. |
| `vendor/erd-editor.umd.js` | — | Bundle MIT de `@dineug/erd-editor` 4.2.0. No modificar. |
| `vendor/elk.bundled.js`, `vendor/elk-worker.min.js` | — | ELK 0.10.0, EPL-2.0. No modificar. |
| `AGENTS.md` | — | Este documento. |
| `agents.mb` | 888 | Registro histórico de sesiones; contiene información y rutas del desarrollo privado. |
| `README.md` | 325 | Documentación pública, uso, ejemplo, licencias y procedencia. |
| `LICENSE` | 21 | MIT del código propio. |

Herramientas **ignoradas** en `.gitignore` y ligadas al modelo privado de 127
tablas: `tools/verify.mjs`, `regressions.mjs`, `analysis-regressions.mjs`,
`performance-regressions.mjs`, `cardinality-regressions.mjs` y
`benchmark-canvas.mjs`. No están en el clon público y no deben darse por
ejecutables sin el SQL privado y los ajustes de URL correspondientes.

---

## 5. Documento canónico y modelo de datos

`editor.value` devuelve el JSON del editor. Las colecciones relevantes son:

| Colección | Contenido |
| --- | --- |
| `collections.tableEntities` | Tablas: `id`, `name`, `columnIds`, `ui`, comentarios y grupo. |
| `collections.tableColumnEntities` | Columnas: `id`, `name`, `dataType`, `options`, `default`, comentario. |
| `collections.relationshipEntities` | Relaciones FK: `start`, `end`, `onDelete`, `onUpdate`, `relationshipType`, nombre. |
| `collections.indexEntities` | Índices importados: `tableId`, `name`, `unique`, `indexColumnIds`. |
| `collections.indexColumnEntities` | Mapeo índice → columna. |
| `collections.tableGroupEntities` | Grupos declarados por el editor, si existen. |
| `settings` | Ajustes del editor: `database`, zoom, origen, bloqueos, etc. |
| `doc` | Metadatos del documento del editor. |

Bits de `ColumnOption` observados en el bundle y usados por el código:

- `1`: AUTO_INCREMENT / autoincremental.
- `2`: PRIMARY KEY.
- `4`: UNIQUE.
- `8`: NOT NULL.

En `relationshipEntities`:

- `start` es la tabla **referenciada** (padre).
- `end` es la tabla que **declara la FK** (hijo).
- La flecha del canvas va del hijo al padre.
- `childCols` y `parentCols` conservan el orden de los pares de una FK compuesta.

`settings.database` usa los valores del bundle:

```js
{ MariaDB: 1, MSSQL: 2, MySQL: 4, Oracle: 8, PostgreSQL: 16, SQLite: 32 }
```

`normalizeSqlPrimaryKeys()` añade NOT NULL a las PK importadas cuando el motor
no es SQLite. SQLite conserva la nulabilidad que entrega su parser por sus
excepciones sintácticas.

Invariantes:

- El análisis y los filtros **nunca** escriben en `editor.value`.
- No se borran tablas del documento para simular una vista.
- Exportar “modelo completo” y exportar “vista/contexto” son acciones distintas.
- `counts()` cuenta tablas, columnas, relaciones e índices; la barra inferior
  solo muestra las tres primeras.
- El JSON exportado por `saveJson()` añade `erdApp.version: 1` con el paquete
  de análisis (`analysis`), sin reemplazar las colecciones del editor.

---

## 6. Importación: pipeline y reglas

### 6.1 Entradas

- **Subir esquema**: selector múltiple. Si hay varios archivos, todos deben ser
  SQL del mismo motor y modelo; se concatenan con `\n;\n`.
- **Arrastrar y soltar** sobre el canvas: mismo flujo.
- **Pegar código**: formato elegido manualmente.
- **Abrir .erd.json**: fuerza la ruta JSON.
- **Cargar ejemplo**: `examples/demo-150-mysql.sql` con MySQL.
- **`?autoload=1`**: carga el ejemplo; `?autoload=RUTA` carga una URL relativa
  del mismo origen.

### 6.2 Formatos y detección

`detectFormat()` usa la extensión del nombre/URL:

- `.sql` → SQL.
- `.dbml` → DBML.
- `.graphql`, `.gql`, `.graphqls` → GraphQL.
- `.aml` → AML.
- `.json` (incluye `.erd.json` y `.vuerd.json`) → documento del editor.
- Cualquier otra extensión se **rechaza**; ya no se intenta SQL por defecto.

El JSON se valida como documento moderno de `erd-editor`: debe tener `doc`,
`settings`, `collections.tableEntities`. Un JSON genérico de datos no sirve.

Codificación:

- Se lee con `File.arrayBuffer()`.
- UTF-8 por defecto; UTF-16 LE/BE solo con BOM.
- `TextDecoder(..., { fatal: true })` rechaza secuencias inválidas.
- Se rechaza texto vacío y contenido con NUL que parezca binario.
- No se admiten `.sqlite`, `.db`, `.bak`, `.dump`, ZIP, Excel ni CSV.

### 6.3 Transacción de importación (`runImport`)

1. Si `busy`, rechaza la operación.
2. Activa `setBusy(true)`: `editor.inert`, regiones `inert`, controles
   `[data-import-lock]` deshabilitados y overlay de progreso.
3. Guarda `previous = editor.value` y `previousAnalysis = analysis.pack()`.
4. Espera `editorReady`; lee la entrada; valida texto/formato/codificación.
5. Para SQL, ejecuta `SchemaAudit.inspect(text)` antes de importar.
6. Para JSON, valida el documento y recupera `erdApp` si existe.
7. Para SQL, despacha `settings.changeDatabase` con el motor elegido.
8. Aplica el texto con `applyText()`:
   - SQL/DBML/GraphQL/AML: `setSchema*` con `{ placement: 'grid', mode: 'replace' }`.
   - JSON: `setInitialValue`.
   - Se esperan las promesas reales del editor.
9. Normaliza PK implícitas con `normalizeSqlPrimaryKeys()`.
10. Lee el documento; si no hay tablas, error.
11. `SchemaAudit.compare(expected, doc)`:
    - tablas, columnas declaradas o cantidad de relaciones distintas → error;
    - diferencia de índices → aviso, no rollback.
12. `renderExplorer(doc, metadata)` indexa y dibuja el análisis.
13. Vuelve al canvas de análisis, actualiza nombre, motor, contadores e informe.
14. Persiste el documento; libera `busy`.
15. Si algo falla después de modificar el editor, restaura el documento y el
    paquete de análisis anteriores, muestra el error y conserva el diagrama.

Detalles:

- El bloqueo también impide guardar/reemplazar durante la importación.
- El autoguardado se suspende durante la transacción.
- Los errores asíncronos y de lectura se capturan.
- La importación no usa append ni migraciones; reemplaza el documento.
- No se combinan motores ni formatos distintos.
- `?autoload` con fallo intenta restaurar el documento guardado y luego informa
  el error del archivo solicitado.

### 6.4 Auditoría SQL (`schema-audit.js`)

`inspect(sql)`:

- Tokeniza comentarios `--`, `#`, `/* */`, cadenas (incluye dollar-quoted),
  identificadores entre comillas/backticks/corchetes y texto normal.
- Cuenta `CREATE TABLE`, columnas explícitas y declaraciones `KEY`/`UNIQUE`.
- Cuenta cada `REFERENCES`.
- `foreignKeys()` recorre `CREATE TABLE`/`ALTER TABLE`, nombre de tabla,
  `CONSTRAINT`, `FOREIGN KEY (...) REFERENCES ... (...)`.
- Falla si no hay `CREATE TABLE` o si una definición está incompleta.

`compare(expected, doc)`:

- Compara cantidad de tablas y nombres (nombre completo o nombre corto único).
- Comprueba que cada columna declarada exista en la tabla importada.
- Compara cantidad de relaciones.
- Cualquier diferencia de tablas/columnas/relaciones lanza error y provoca
  rollback.
- La diferencia de índices solo genera un aviso visible.

Límites: no es un validador SQL completo; no certifica tipos, defaults, CHECK,
triggers, funciones, exclusiones, índices parciales ni el estado final de
migraciones (`DROP`, `RENAME`, `ALTER COLUMN`, etc.). Los casos fuera de alcance
deben exportarse como DDL consolidado o DBML.

### 6.5 API de automatización

`window.__erdApp` expone:

```js
editor
counts()
importText(text, format, name, options)
importFiles(File[], options)
importUrl(url, options)
getStatus()
ready // promesa de arranque
```

- Esperar siempre `await window.__erdApp.ready`.
- `importUrl` solo acepta URLs del mismo origen.
- No hay endpoint de subida ni envío del SQL a un servicio externo.
- `getStatus()` devuelve estado, contadores, `busy`, `lastImport` (incluye
  `verified`, `warnings`, error) y el resultado de `counts()`.

Ejemplo:

```js
await window.__erdApp.ready;
await window.__erdApp.importText(
  'CREATE TABLE users (id INT PRIMARY KEY, name VARCHAR(80));',
  'sql',
  'users.sql',
  { database: 'MySQL' }
);
await window.__erdApp.importUrl('examples/demo-150-mysql.sql', { database: 'MySQL' });
window.__erdApp.getStatus();
```

---

## 7. Análisis: grafo, proyecciones y worker

### 7.1 Construcción del grafo (`SchemaGraph.build`)

- Lee `tableEntities`, `tableColumnEntities`, `relationshipEntities`,
  `indexEntities`, `indexColumnEntities` y `tableGroupEntities`.
- Ordena tablas por nombre. Si hay nombres duplicados, añade
  `#duplicado-N` y emite un aviso.
- Cada tabla conserva columnas (nombre, tipo, comentario, default, `options`),
  índices, grupo, `keyColumns` (PK + columnas que participan en FK),
  `incoming` y `outgoing`.
- `group` se decide en este orden:
  1. grupo declarado (`tableGroupEntities`);
  2. semilla (`seed.groups`) solo si hay ≥50 tablas y ≥80 % de nombres
     coincidentes;
  3. esquema del nombre (`esquema.tabla`);
  4. prefijo antes de `_` si aparece en ≥2 tablas;
  5. `Sin clasificar`.
- `groupOrigin` indica `Declarado`, `Propuesta revisable`, `Esquema`,
  `Sugerido` o `Asignado`.
- `hubs`: tablas con `incoming >= max(12, 25 % de tablas)`. Se ocultan por
  defecto salvo que se activen referencias transversales; también se pueden
  marcar manualmente.
- `fingerprint`: hash FNV-1a de claves/columnas/opciones + claves de relación
  ordenadas. Sirve para invalidar vistas/layouts al cambiar el modelo.
- `regroup(graph, assignments)` aplica asignaciones manuales, reconstruye
  `groups`, cuenta FK internas/externas y calcula `modulePairs` entre módulos.

Semilla pública: `docs/MODULOS_EJEMPLO.json` (10 módulos de 15 tablas). Se
carga al inicio; para otros esquemas solo se usa si cumple el umbral 50/80 %.
El mapa privado de 9 módulos (`docs/MODULOS_PROPUESTOS.json`) no se publica.

### 7.2 Relaciones, nombres y cardinalidad

- Clave de relación: firma estable
  `[child, childCols, parent, parentCols]` + ordinal para paralelas.
- Nombre: `relationship.name` o `metadata.names` recuperado por la auditoría.
- `SchemaGraph.cardinality(graph, relation)`:
  - `known=false` → `?` si faltan columnas.
  - Lado hijo: `0..1` si las columnas de la FK son PK completa, incluyen una
    columna UNIQUE, un índice UNIQUE las cubre, o el tipo de relación es 2/8;
    en otro caso `0..N`.
  - Lado padre: `1` si todas las columnas de la FK son NOT NULL; en otro caso
    `0..1`.
  - No cuenta filas reales ni infiere reglas de negocio. Una FK no obliga a
    que cada padre tenga hijos; el mínimo del lado hijo es 0.

### 7.3 Filtros y modos

Estado (`analysis/explorer.js`):

```js
{
  mode, group, root, depth, cross, direction, filterGroup,
  links, detail, fluid, spacing, selected, relation,
  extraKeys, start, end, via, pathIndex, camera
}
```

Modos:

- `map`: mapa de módulos; nodos = grupos; bundles = `modulePairs`; no dibuja
  las 356 FK; `hidden` = total de relaciones del modelo.
- `module`: tablas de un módulo; relaciones internas/frontera.
- `focus`: tabla raíz + vecinas a 0–2 saltos; hubs resumidos; previsualización
  y selección manual si el contexto supera 25 tablas.
- `path`: ruta más corta entre origen/destino, con paso intermedio opcional y
  hasta 3 alternativas; solo dibuja las aristas de la ruta elegida.
- `all`: todas las tablas y **cada FK como bundle individual**; ignora filtros
  heredados de hubs/módulo/dirección/selección; usa `lane/lanes` para FK
  paralelas. En el ejemplo público: 150 tablas y 356 bundles.
- `custom`: selección manual de tablas + `extraKeys`.

Reglas:

- `allowed()` aplica hubs, `filterGroup` y `direction`.
- `neighbors()` limita la profundidad a 2.
- `shortest()` es BFS con aristas prohibidas.
- `paths()` devuelve hasta 3 rutas alternativas; `via` encadena dos tramos.
- `project()` calcula `relations`, `bundles`, `boundary` y `hidden`; las
  relaciones que tocan una tabla visible pero salen del contexto se agrupan en
  `boundary` por módulo o “Referencias transversales / filtradas”.
- En modos distintos de `all`, las FK paralelas entre el mismo par se agrupan
  en un bundle con `relations.length > 1`; en `all` cada FK es un bundle.
- `search()` busca todas las palabras en nombre, comentario, columnas y
  comentarios de columnas, en minúsculas.

### 7.4 Worker y layout

`analysis/worker.js`:

- `importScripts('graph.js', '../vendor/elk.bundled.js')`.
- ELK usa `new Worker('../vendor/elk-worker.min.js')`.
- Mensajes: `index`, `metadata`, `dispose`, `project`, `groups`, `search`,
  `layout`.
- `index` construye el grafo con `seed` y `metadata`.
- `metadata` y `groups` reagrupan y actualizan nombres sin reindexar todo.
- `layout` usa ELK `layered`, dirección `RIGHT`, routing `ORTHOGONAL`,
  `spacing` configurable, puertos `FIXED_POS`, padding 40, seed 1; omite
  autorrelaciones del layout ELK y devuelve `positions`, `routes`, `width`,
  `height`.
- El cliente (`WorkerClient`) tiene timeout de 60 s, cola `latest` por tipo
  (descarta peticiones viejas), `stop()` termina el worker/ELK y lo reinicia.
- `metadata()` devuelve un payload ligero (`kind: graph-metadata`) con grupos,
  modulePairs, grupos por tabla y nombres; el cliente actualiza el grafo
  cacheado en vez de recibir todas las columnas.

Cachés y límites:

- `projectionCache`: máximo 20 entradas o peso 100 000.
- `measureCache`: hasta 6000 especímenes; se invalida al cargar fuentes o
  cambiar geometría.
- `layouts`: máximo 30 ordinarios; los layouts de vistas guardadas se
  protegen; `layoutHistory` hasta 20 y se reduce por tamaño.
- `views`: máximo 100.
- La cámara y los layouts se guardan por separado.

---

## 8. Render, UI y comportamiento visual

### 8.1 Renderer

`analysis/renderer.js` es DOM/SVG incremental, no Canvas 2D:

- Una sola solicitud `requestAnimationFrame` pendiente; no hay bucle continuo.
- `SpatialIndex` de cuadrícula 1024; las cajas de rutas muy largas se guardan
  aparte para no llenar miles de celdas.
- `scene()` construye índices de nodos/aristas, geometría e incidentes.
- `commit()` aplica transformación de cámara, monta solo nodos/aristas visibles
  con margen y seguridad, actualiza el minimapa y estadísticas.
- `syncNodes()` reutiliza tarjetas por `signature`; conserva el elemento con
  foco o en gesto; `syncEdges()` reutiliza los paths SVG.
- Rutas: usa las rutas ELK si son válidas; si no, conectores ortogonales
  simples. Las autorrelaciones tienen un trazado propio.
- Cada arista tiene `path` visible, `hit` transparente con `role=button` y
  `tabindex=0`, etiqueta, cardinalidades y `<title>`.
- `exportEdges()` genera solo la proyección visible, con cardinalidades; no es
  una exportación del modelo completo.
- El modo fluido (`fluid`) oculta filas no seleccionadas y etiquetas durante
  el gesto; se restaura a los 180 ms. No elimina datos ni cambia posiciones.
- Métricas solo con `?performance`; `stats.frameMs` mide el commit, no FPS
  presentados.

### 8.2 UI

`index.html`:

- Header: marca, motor, subir, menú Archivo (pegar, ejemplo, abrir JSON,
  guardar modelo, exportar/importar vistas, exportar SVG, nuevo), editar
  esquema y tema.
- Nav: mapa/módulo/enfoque/ruta/todo; detalle; modo fluido; guardar vista;
  inspector.
- Sidebar: búsqueda, lista virtualizada, módulos, vistas, resultado de
  importación.
- Canvas: breadcrumb, filtros, ruta, viewport, minimapa, controles de zoom,
  reordenar, deshacer, separación y contadores.
- Inspector: detalle de tabla/relación, columnas, reglas, índices, referencias
  entrantes/salientes, fronteras, acciones y cardinalidad.
- Diálogos: pegar, ampliar contexto, guardar vista, organizar tabla.
- Editor nativo oculto (`<erd-editor>`).

Comportamiento:

- Búsqueda en worker con debounce 120 ms; lista virtualizada de 39 px.
- `requestModule` >50 tablas y `requestFocus` >25 nodos abren diálogo de
  previsualización; se puede elegir subconjunto, abrir todo o cancelar.
- `select`, `selectRelation`, `selectBundle`, `centerTable` mantienen el
  contexto; en `all`, centrar no cambia de modo.
- `map` no muestra columnas; `module/focus/path/all/custom` muestran detalle
  según `names/keys/columns/auto`.
- `auto` usa histéresis: nombres <0.38, claves >0.52; conserva nivel en la
  banda y al restaurar.
- Layout: mapa en cuadrícula; resto ELK. Pins, arrastre, `relayout` y undo.
- Vistas guardadas incluyen estado/cámara/filtros y un `layoutKey`; se
  sanean al restaurar; referencias ausentes se omiten con aviso.
- Exportaciones: documento completo con `erdApp` metadata; vistas
  `erd-analysis-views` v1; SVG del contexto.
- Tema en `localStorage` (`erd.theme`); responsive a 1250/920/600 px;
  inspector/navegador se convierten en paneles flotantes en pantallas
  estrechas.
- Accesibilidad: `aria-pressed`, `aria-label`, foco visible, Enter/Espacio en
  aristas SVG, botones para acciones que no dependen de hover.

### 8.3 Editor nativo

- `toggleNative()` alterna canvas de análisis/editor.
- `focusTable(id)` y `showOverview()` usan `SharedStore` del editor:
  `changeLockSettings` (solo `lockSettingType: 1`), `changeCanvasType`,
  `changeZoomLevel`, `scrollTo`.
- El editor es Shadow DOM cerrado; no se estiliza desde CSS externo.
- `editor.inert` se usa durante importación; no `readonly`, porque el
  importador interno lo necesita.
- `editor.change` programa render/persistencia con 600 ms.

---

## 9. Persistencia

### IndexedDB (`analysis/storage.js`)

Base: `erd-app-workspace`, versión 2. Stores:

- `entries`: documento actual (`current-model`), metadata de análisis
  (`analysis:<fingerprint>`), estado ligero (`analysis-state:<fingerprint>`).
- `layouts`: layouts por `fingerprint + '\0' + layoutKey`.

`get(key)`:

- Lee la entrada; si tiene `layoutRefs`, carga estado y layouts asociados.
- Abre una transacción para todos los layouts de la vista.
- Devuelve `value` con `state`/`layouts` reconstruidos.

`set(key, value)`: guarda una entrada.

`saveAnalysis(metadata, layouts, cameraOnly)`:

- Guarda estado de análisis y, si no es `cameraOnly`, layouts y metadata.
- Borra layouts que ya no están en `layoutRefs`.
- Transacciones ordenadas; errores de aborto se propagan.

### localStorage

- `erd-app.current-model`: copia compatible del documento.
- `urbanizadoras.erd.app`: clave heredada, solo lectura para migrar.
- `erd.theme`: tema.
- La copia de compatibilidad se escribe en cada `persist()`; si falla, la app
  avisa que no pudo autoguardar.

### Cuándo se guarda

- Importación exitosa: `persist()` inmediato.
- `editor.change`: debounce 600 ms.
- Estado de análisis: `scheduleSave()` 500 ms, máximo 5 s; cámara sola puede
  guardar solo el estado ligero.
- Al ocultar la pestaña se intenta guardar.
- Exportar documento/vistas es la forma de mover datos a otro origen/equipo.
- El almacenamiento está aislado por origen; cambiar puerto/host cambia el
  espacio de almacenamiento.

### Exportar/importar

- `saveJson()`: documento completo + `erdApp.version 1` + `analysis.pack()`
  (estado, vistas, nombres, asignaciones, hubs, layouts).
- `export-view`: `{type:'erd-analysis-views', version:1, ...pack()}`.
- `unpack()` valida versión, sanea estados, descarta referencias ausentes,
  solo restaura layouts si coincide el `fingerprint`; avisa.
- `exportSVG()`: solo la proyección actual, con nombres y relaciones; no es el
  modelo completo ni un SVG editable.
- Límite de 100 vistas; el layout de vistas guardadas se protege de la caché.

---

## 10. Ejemplo sintético público

`examples/demo-150-mysql.sql` se genera con `tools/generate-example.mjs`:

- 10 módulos × 15 tablas = **150 tablas**.
- **1549 columnas**, **356 relaciones**.
- 149 FK al tenant `core_empresas`.
- 126 FK a la raíz del módulo: 117 simples + 9 compuestas.
- 6 autorreferencias.
- 4 relaciones 1:1 en la raíz del módulo + 1 adicional
  (`proyectos_entregables.tarea_id`).
- 4 referencias cruzadas explícitas en `core`.
- 14 referencias Ventas → CRM, 14 Compras → Proveedores.
- 27 referencias a `core_usuarios` y 15 a `core_monedas`.
- MySQL 8.0.16+, InnoDB, utf8mb4; sin `INSERT` ni datos reales.
- 9 FK compuestas, 6 autorreferencias, 5 1:1. El mapa público tiene 10 grupos
  de 15 tablas (`docs/MODULOS_EJEMPLO.json`): Núcleo y seguridad, CRM, Ventas,
  Compras, Inventario, Finanzas, Logística, Proyectos, Soporte y RR. HH.

Validación realizada en la sesión de publicación:

- Importación limpia: 150 tablas, 1549 columnas, 356 relaciones, sin warnings.
- 10 grupos de 15 tablas.
- “Todo el esquema”: 150/356; cardinalidad compuesta, autorreferencia y 1:1
  comprobadas.
- Clon fresco del repositorio + Chrome: correcto.
- DDL validado sintácticamente en MariaDB 10.11 sustituyendo la colación MySQL
  8 por una equivalente; el archivo declara `utf8mb4_0900_ai_ci`.

El ejemplo **no** reproduce las mediciones históricas de `docs/performance/`
(127 tablas). No mezclar esos números con la demo pública.

---

## 11. Pruebas y verificación

### Públicas

```sh
node tools/test-graph.cjs
node tools/benchmark-analysis.cjs
node tools/benchmark-large-canvas.mjs
```

- `test-graph.cjs`: adyacencia, fronteras, dirección, FK compuestas, bucles,
  búsqueda y reagrupación sin mutar el documento.
- `benchmark-analysis.cjs`: índice de 1000/5000 tablas y 5000/25000 FK; no mide
  importación, layout global, memoria ni FPS.
- `benchmark-large-canvas.mjs`: arranca servidor + Chrome con perfil temporal,
  carga el ejemplo de 150 tablas y genera documentos sintéticos de 1000/5000
  tablas; mide mapa, enfoque, módulo, pan, heap de laboratorio y errores.
  Requiere Chrome/Chromium, Python 3, Node con `fetch`/`WebSocket`; admite
  `CHROME_BIN` y `--output`.
- `tools/browser-harness.mjs` acepta `autoload:false` para probar la app vacía
  y el botón de ejemplo; por defecto carga `?autoload=1`.

### Privadas/ignoradas

La suite interna de la sección 16–19 de `agents.mb` (127 tablas, 427 FK, rutas
`payments/lots`, URL antigua `/erd-app/`) está en `.gitignore` y no se publica.
No asumir que `tools/verify.mjs` funciona en un clon limpio: depende de
`../Urbanizadoras_SaaS_MySQL.sql`, conteos fijos y la estructura anterior.

### Evidencia de la sesión de publicación

- `node tools/test-graph.cjs`: OK.
- `node tools/benchmark-analysis.cjs`: OK (1000/5000).
- `node tools/benchmark-large-canvas.mjs`: OK, 1000/5000, 0 errores,
  `sourceUnchanged: true`.
- Smoke test en Chrome: importación 150/1549/356, 10 grupos, sin warnings.
- Smoke test de clon fresco: OK.
- No se ejecutó la suite privada de 127 tablas en esta sesión.

Las cifras históricas de `docs/RESULTADOS_OPTIMIZACION_CANVAS.md` siguen siendo
válidas como registro del modelo privado; no certifican FPS reales ni el
rendimiento de 5000 tablas con todas las columnas.

---

## 12. Límites, riesgos y cosas que no se prometen

### SQL e importación

- No es un parser SQL completo ni un validador semántico. La auditoría solo
  contrasta tablas, columnas declaradas y cantidad de relaciones; los índices
  pueden diferir y se avisan.
- No interpreta el estado final de migraciones (`DROP`, `RENAME`, `ALTER
  COLUMN`, etc.), `CHECK`, triggers, funciones, exclusiones ni índices
  parciales.
- No hay bases binarias, ZIP, Excel ni CSV.
- La compatibilidad por dialecto es limitada y depende del importador de
  `erd-editor`; no se certifica por extensión.
- Varios SQL solo se combinan si son del mismo motor/modelo; no hay append,
  overlays ni migraciones.
- Una importación parcial se detecta si cambia el conteo de tablas/columnas/
  relaciones, pero no se garantiza cada detalle semántico.
- Nombres de tabla duplicados reciben sufijo y aviso; las vistas antiguas pueden
  quedar sin reconciliación automática al reimportar.

### Análisis, layout y render

- Enfoque máximo 2 saltos; rutas alternativas máximo 3; el layout global de
  5000 tablas no se ha validado.
- Tras mover/restaurar posiciones, las rutas simples pueden cruzar tarjetas;
  `Reordenar` recalcula ELK. Pins y reordenamientos pueden solaparse.
- “Todo el esquema” es denso por diseño; las etiquetas pueden requerir zoom.
- La virtualización dibuja lo visible y rutas que cruzan viewport, pero no
  promete una vista global libre de cruces.
- `requestAnimationFrame` no equivale a FPS presentados; las mediciones son de
  laboratorio y de un equipo concreto.
- No se garantiza 60 FPS en todos los equipos ni con 5000 tablas detalladas.

### Persistencia y navegador

- IndexedDB/localStorage dependen del origen; cambiar puerto/host separa datos.
- No hay resolución de conflictos entre pestañas.
- Límites: 100 vistas, 30 layouts ordinarios, 6000 medidas, 20 proyecciones,
  timeout de worker 60 s.
- `file://` no funciona por workers; usar `start.sh`/HTTP.
- El almacenamiento puede fallar por cuota; la UI avisa, pero conviene exportar.

### Privacidad y seguridad

- El SQL se procesa en el navegador; la app no tiene backend ni sube esquemas.
- `importUrl` solo acepta mismo origen.
- Los esquemas quedan persistidos localmente; limpiar/exportar antes de
  compartir un equipo.
- El repositorio es público: no commitear SQL de clientes, `docs/
  MODULOS_PROPUESTOS.json` ni datos internos. Revisar `.gitignore` y
  `git status --ignored`.
- `AGENTS.md` y `agents.mb` están publicados en el repositorio actual;
  `agents.mb` contiene rutas locales y nombres del proyecto. Si se decide
  ocultarlos, retirarlos con un commit y volver a excluirlos.
- No hay auditoría formal de seguridad; la app es una herramienta local de
  lectura.

### IA y licencia

- Gran parte del código, la documentación y las pruebas se generaron con
  asistencia de IA en OpenCode; la sesión de publicación usó DeepSeek V4.1
  Flash. Hubo dirección, revisión y validación humanas.
- La IA puede cometer errores. El software se ofrece “tal cual”, sin garantía,
  bajo MIT. No es un validador SQL ni una herramienta de migración.
- El código propio es MIT (`LICENSE`); `vendor/` conserva MIT (erd-editor) y
  EPL-2.0 (elkjs). No relicenciar el vendor.

### Vendor

- No modificar `vendor/erd-editor.umd.js`, `vendor/elk.bundled.js` ni
  `vendor/elk-worker.min.js` directamente.
- Si se actualiza, seguir `vendor/README.md`, verificar versión, procedencia,
  SHA-256 y licencias; volver a ejecutar las pruebas.
- El editor usa Shadow DOM cerrado; no depender de CSS interno ni de acciones
  minificadas inestables.

---

## 13. Publicación, licencia y procedencia

- Repositorio: <https://github.com/ZapanaDiego/erd-app>.
- Rama: `main`; `origin/main` sincronizado.
- Licencia: MIT en `LICENSE`; GitHub la detecta como MIT.
- Pages: pendiente de activación manual en
  `https://github.com/ZapanaDiego/erd-app/settings/pages`
  (Deploy from a branch → `main` → `/ (root)`). `.nojekyll` ya está incluido.
  URL prevista: `https://zapanadiego.github.io/erd-app/`.
- La app es estática; Pages solo sirve archivos y no recibe esquemas.
- El repositorio es público. El commit inicial y el historial exponen el correo
  configurado en Git; revisar `git log --format='%an <%ae>'` antes de añadir
  nuevos commits.
- `README.md` documenta el ejemplo, la verificación, las fuentes, la
  procedencia IA y las licencias. Si cambia el comportamiento, actualizar
  README y AGENTS.md.
- `agents.mb` conserva el historial detallado (secciones 1–19), pero está
  desactualizado en varios puntos: start.sh/URL, ejemplo 127→150, storage key,
  importación múltiple, formatos desconocidos, auditoría/rollback, git y
  publicación. En caso de conflicto, manda el código actual.
- `docs/PLAN_VISUAL_FRONTEND.md`, `docs/PLAN_OPTIMIZACION_CANVAS.md` y
  `docs/RESULTADOS_OPTIMIZACION_CANVAS.md` son registro histórico/diseño.
  `docs/README.md` aclara qué no se distribuye.
- `docs/performance/` contiene mediciones del modelo privado de 127 tablas;
  no son reproducibles con el ejemplo público.

Commits relevantes de la publicación (consultar `git log` para el estado
actual):

- `4f1e109` — primera publicación.
- `255c3c3` — añadió `AGENTS.md` y `agents.mb` (no fue creado por la sesión de
  publicación original; revisar privacidad).
- `fef9850` — licencia MIT y procedencia.
- `0ce8a9e`, `c7bd3c7` — ajustes de README/procedencia.

---

## 14. Reglas para futuras sesiones

1. Leer este archivo y el código relevante antes de cambiar. `agents.mb` es
   histórico; no copiar sus URLs, conteos o claves sin verificar.
2. No modificar `vendor/` a mano. Si hay que actualizar, seguir
   `vendor/README.md` y conservar licencias/hashes.
3. Mantener el documento canónico intacto. Filtros, modos, vistas y análisis
   no deben escribir en `editor.value` ni eliminar tablas para “simular” una
   vista.
4. Respetar la separación: importación/auditoría → documento → índice →
   proyección → layout → render → UI → persistencia.
5. Usar el pipeline existente (`runImport`, `applyText`, `SchemaAudit`,
   `SchemaExplorer.loadDocument`); no duplicar lógica de importación ni
   persistencia.
6. Al cambiar el grafo/proyecciones, ejecutar `node tools/test-graph.cjs` y
   comprobar el ejemplo 150/1549/356.
7. Al cambiar el renderer/UI, comprobar `?autoload=1`, mapa/módulo/enfoque/
   ruta/todo, modo fluido, teclado, minimapa, guardado/restauración y 360 px.
8. Al cambiar el ejemplo, ejecutar `node tools/generate-example.mjs` y
   actualizar conteos/mapa/README si cambian.
9. Al cambiar almacenamiento, mantener compatibilidad con IndexedDB v2,
   `erd-app.current-model` y la clave heredada; migrar sin borrar datos.
10. No commitear SQL privado, `docs/MODULOS_PROPUESTOS.json` ni la suite
    interna ignorada. Revisar `git status --ignored` antes de publicar.
11. Mantener la licencia MIT del código propio y las licencias de vendor.
    No relicenciar dependencias.
12. Mantener la transparencia sobre la asistencia de IA y las fuentes en
    README/AGENTS; no presentar cifras históricas como actuales.
13. Medir antes de afirmar mejoras: separar datos medidos, rAF, FPS reales y
    extrapolaciones; documentar hardware/escenario.
14. Mantener la UI en español, accesible por teclado y sin frameworks/build
    nuevos salvo necesidad medida.
15. Si se activa GitHub Pages o se cambia la privacidad de `AGENTS.md`/
    `agents.mb`, actualizar este archivo.

---

## 15. Glosario

- **Documento canónico**: JSON completo del editor (`editor.value`); única
  fuente de verdad del esquema.
- **Grafo**: índice de lectura de tablas, columnas, relaciones y grupos.
- **Proyección**: subconjunto/agregación calculada para una vista; no muta el
  documento.
- **Bundle**: arista visual que puede agrupar varias FK paralelas; en
  “Todo el esquema” cada bundle es una sola FK.
- **Módulo/grupo**: agrupación revisable de tablas; no es una verdad de negocio.
- **Hub**: tabla con muchas FK entrantes; se resume salvo que se activen
  referencias transversales.
- **Semilla**: mapa de módulos (`docs/MODULOS_EJEMPLO.json`) usado solo si
  coincide con suficiente porcentaje de tablas.
- **Fingerprint**: hash del modelo para invalidar vistas/layouts.
- **Layout**: posiciones, rutas, pins y validez de una vista.
- **Vista**: estado guardado (modo, filtros, cámara, layout) con nombre.
- **Cardinalidad**: extremos `1`, `0..1`, `0..N` o `?` derivados de claves y
  nulabilidad, no de conteos reales.
- **Modo fluido**: oculta temporalmente detalle/etiquetas durante el gesto.
- **rAF**: `requestAnimationFrame`; no es una certificación de FPS.

---

## 16. Documentos de referencia

- `AGENTS.md` — este documento, estado vigente.
- `agents.mb` — historial completo de sesiones (1–19); útil para entender
  decisiones, pero contiene datos del desarrollo privado y afirmaciones
  obsoletas.
- `README.md` — uso público, ejemplo, verificación, fuentes y licencias.
- `docs/PLAN_VISUAL_FRONTEND.md` — plan de mapa/módulo/enfoque/ruta e
  investigación de productos.
- `docs/PLAN_OPTIMIZACION_CANVAS.md` — diagnóstico y plan de fluidez.
- `docs/RESULTADOS_OPTIMIZACION_CANVAS.md` — cambios y mediciones del modelo
  privado de 127 tablas.
- `docs/README.md` — nota sobre documentación histórica.
- `vendor/README.md` — procedencia, versiones, hashes y licencias de vendor.
- `LICENSE` — MIT del código propio.

Trabajo pendiente / decisiones abiertas:

- Activar GitHub Pages.
- Decidir si `AGENTS.md` y `agents.mb` deben seguir públicos (privacidad).
- Valorar adaptar la suite de navegador privada al ejemplo de 150 tablas o
  mantenerla fuera del repositorio.
- Revisar/actualizar `agents.mb` o marcarlo definitivamente como histórico.
- Ampliar pruebas de dialectos, navegadores, accesibilidad, cuotas de
  almacenamiento, concurrencia entre pestañas y reimportación con renombres.
- Validar layout/render de 5000 tablas detalladas y escenarios de GPU reales.
