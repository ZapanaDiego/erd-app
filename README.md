# erd-app

Visualizador local de esquemas de bases de datos. Importa SQL DDL, DBML,
GraphQL SDL, AML y documentos de erd-editor; permite explorar tablas,
columnas, claves y relaciones en un diagrama entidad-relación (ERD).

Usa `@dineug/erd-editor` **4.2.0**, incluido en `vendor/` con licencia MIT.
No requiere instalar paquetes ni compilar. El SQL no se ejecuta: se interpreta
como estructura para dibujarla en el navegador.

La implementación se construyó principalmente con asistencia de IA y revisión
humana; ver [Origen y método de construcción](#origen).

## Arranque

Desde este directorio:

```sh
./start.sh
```

Abre <http://127.0.0.1:5173/>. También puedes usar:

```sh
NO_OPEN=1 ./start.sh
PORT=8080 ./start.sh
```

El servidor Python sirve la raíz de este repositorio, solo en `127.0.0.1`.
Usa HTTP; abrir `index.html` con `file://` impide el funcionamiento de workers.

## Publicación en GitHub Pages

El repositorio es estático y no necesita compilación. Para publicarlo:

1. GitHub → **Settings** → **Pages**.
2. En **Build and deployment**, elige **Deploy from a branch**.
3. Selecciona la rama `main` y la carpeta `/ (root)`.
4. Guarda. La URL será `https://<usuario>.github.io/erd-app/`.

La app sigue ejecutándose en el navegador: Pages solo sirve los archivos. Los
esquemas que cargues no se suben a GitHub ni a otro servicio. `start.sh` es
solo para el uso local.

## Cargar y explorar

1. Elige el **motor SQL** correspondiente al archivo.
2. Usa **Subir esquema**, arrastra archivos o pulsa **Pegar código**.
3. Para probar la app sin buscar un archivo, pulsa **Cargar ejemplo (150 tablas)**.
   Este botón elige MySQL automáticamente.
4. La importación espera a que termine el ordenamiento y comprueba el resultado.
   Si falla o faltan tablas/columnas/relaciones detectadas, conserva el diagrama
   anterior e informa el problema.
5. Comienza en el **Mapa de módulos**: el ejemplo se divide en diez grupos
   revisables. Selecciona uno para ver sus conexiones o abre sus tablas.
6. Busca por tabla o columna. **Enfoque** muestra vecinas a uno o dos saltos;
   las tablas transversales se resumen y puedes volver a incluirlas. Antes de
   una expansión grande se ofrece seleccionar tablas o abrir todo el contexto.
7. **Ruta entre tablas** permite elegir origen, destino y paso intermedio.
   El inspector muestra los extremos, cada par de columnas de una FK compuesta
   y las acciones declaradas. La flecha apunta hacia la tabla referenciada.
8. Cambia entre nombres, claves o todas las columnas; usa zoom, minimapa,
   posiciones fijadas, reordenamiento y deshacer. Guarda vistas con sus filtros
   y cámara para volver a ellas. Los módulos se pueden reasignar.
9. **Archivo** permite exportar el documento completo, las vistas o un SVG del
   contexto. **Editar esquema** abre el editor original con todas las entidades.
   El análisis y sus filtros conservan intacto el modelo importado.

El documento y las vistas se guardan localmente (IndexedDB, con copia compatible
   del documento en localStorage). Para trasladarlos a otro navegador u origen,
   exporta el documento completo. No se sube información a servicios externos.

Puedes seleccionar varios archivos **SQL del mismo motor y modelo**: se
concatenan en el orden recibido para procesar tablas y FK de `ALTER TABLE`
en una sola importación. No ejecuta migraciones ni combina distintos motores.
Los otros formatos se abren de uno en uno. Se aceptan UTF-8 y UTF-16 con BOM.

Los archivos `.json` deben ser documentos de erd-editor con `doc`, `settings`
y `collections`; un JSON genérico de datos no es un esquema de este editor.
No se admiten bases binarias `.sqlite`, `.db`, respaldos `.bak`, `.dump`, ZIP,
Excel o CSV. Para bases binarias, exporta la estructura a SQL DDL.

## Ejemplo incluido

`examples/demo-150-mysql.sql` es un esquema **sintético** para demostrar la
interfaz con un modelo grande. No contiene datos reales ni `INSERT`:

```text
150 tablas · 1549 columnas · 356 relaciones
```

Está organizado en diez módulos de quince tablas. Incluye nueve FK compuestas,
seis autorreferencias, cinco relaciones 1:1 y un hub de empresas para probar
las referencias transversales. Usa MySQL 8.0.16+ / InnoDB / utf8mb4.

El archivo se genera de forma reproducible con:

```sh
node tools/generate-example.mjs
```

El generador también escribe `docs/MODULOS_EJEMPLO.json`, el mapa de módulos
que usa la demo. Los documentos de `docs/` conservan mediciones históricas de
otro modelo privado de 127 tablas que no se distribuye; esas cifras no son
reproducibles solo con este ejemplo.

La auditoría SQL contrasta nombres de tablas, presencia de las columnas
explícitas en CREATE TABLE y cantidad de REFERENCES con el resultado. Ignora
comentarios y literales para contar. Es un inventario de DDL, no un validador
completo de SQL: no certifica tipos/defaults ni cada extremo de las FK y no
interpreta el estado final de migraciones (DROP, RENAME, ALTER COLUMN, etc.).
Los casos SQL fuera de ese alcance pueden requerir exportar un DDL consolidado
o convertir a DBML. Para esquemas enormes comienza por módulos y enfoque;
mostrar todas las tablas puede seguir produciendo conexiones densas.

## Importación asistida y automatización

Un script o una herramienta de desarrollo puede cargar archivos por el selector
de la interfaz, pegar código, activar el botón de ejemplo o usar las funciones
de integración después de esperar `window.__erdApp.ready`:

```js
await window.__erdApp.ready;
await window.__erdApp.importText(
  'CREATE TABLE users (id INT PRIMARY KEY, name VARCHAR(80));',
  'sql',
  'users.sql',
  { database: 'MySQL' }
);
await window.__erdApp.importUrl('examples/demo-150-mysql.sql', {
  database: 'MySQL'
});
window.__erdApp.getStatus();
```

`importFiles(File[], options)` usa el mismo flujo. Estas funciones devuelven
conteos cuando terminan o `null` al fallar/estar ocupadas. `getStatus()` informa
`busy`, el resultado, los avisos y el error. `importUrl` solo admite el mismo
origen local. No añade un servidor de subida ni envía el esquema a una nube.

Para abrir directamente el ejemplo:
<http://127.0.0.1:5173/?autoload=1>.
También se permite `?autoload=URL_RELATIVA` para otros esquemas servidos
localmente. Si falla la URL, intenta restaurar el documento guardado y comunica
el error de carga.

## Verificación

Comprobaciones que no necesitan navegador:

```sh
node tools/test-graph.cjs
node tools/benchmark-analysis.cjs
```

`test-graph.cjs` cubre adyacencia, fronteras, dirección, FK compuestas, bucles,
búsqueda y reagrupación sin mutar el documento. `benchmark-analysis.cjs`
prueba el índice con 1000/5000 tablas y 5000/25000 FK.

El benchmark de canvas con 1000/5000 tablas sintéticas requiere Chrome/Chromium,
Python 3 y Node con `fetch` y `WebSocket` globales:

```sh
node tools/benchmark-large-canvas.mjs
```

Arranca su propio servidor y perfil temporal, sin tocar el navegador habitual.
Puedes configurar `CHROME_BIN=/ruta/a/chrome`. La suite interna de interacción
ligada al modelo privado de 127 tablas no se publica; sus resultados históricos
están en `docs/RESULTADOS_OPTIMIZACION_CANVAS.md`.

## Archivos

| Ruta | Función |
| --- | --- |
| `index.html`, `styles.css` | Interfaz y panel de detalles. |
| `app.js` | Importación, transacción, vista, archivos y persistencia. |
| `schema-audit.js` | Inventario y contraste del SQL. |
| `analysis/` | Índice, proyecciones, workers, canvas y persistencia de vistas. |
| `examples/demo-150-mysql.sql` | Ejemplo sintético de 150 tablas. |
| `docs/MODULOS_EJEMPLO.json` | Mapa de módulos de la demo. |
| `tools/generate-example.mjs` | Generador reproducible del ejemplo. |
| `tools/test-graph.cjs`, `tools/benchmark-analysis.cjs` | Pruebas y ensayo del índice sin navegador. |
| `tools/browser-harness.mjs`, `tools/benchmark-large-canvas.mjs` | Benchmark de 1000/5000 tablas en Chrome. |
| `start.sh` | Servidor local. |
| `LICENSE` | Licencia MIT del código propio. |
| `AGENTS.md`, `agents.mb` | Contexto y registro de decisiones para futuras sesiones. |
| `vendor/` | Editor y licencias, sin modificaciones. |
| `docs/` | Planes y resultados históricos del desarrollo. |

## Explorador para esquemas grandes

El canvas de análisis usa DOM/SVG con nodos visibles virtualizados y ELK local
en workers para distribuir las tablas. La agrupación del ejemplo es una
propuesta revisable; otros modelos usan grupos declarados, nombres de esquema
o prefijos. No se infiere automáticamente el significado de negocio.

`node tools/benchmark-analysis.cjs` comprueba el índice con 1000/5000 tablas y
5000/25000 FK. No mide importación SQL, tiempo del layout global, fluidez ni
memoria del navegador. El modo automático alterna nombres/claves según el zoom;
todas las columnas se activan explícitamente. Tras mover tablas o restaurar
posiciones se usan conectores ortogonales simples: pueden cruzar otras tablas;
**Reordenar** vuelve a calcular rutas con ELK. Las posiciones fijadas se respetan,
por lo que un reordenamiento con muchas fijaciones puede requerir ajustes manuales.

## Fluidez del explorador

El movimiento y el zoom se agrupan por fotograma. Las tarjetas y conexiones
se conservan mientras sigan visibles; el minimapa actualiza su indicador de
cámara sin reconstruir todas las miniaturas. Al arrastrar una tabla se actualizan
sus conexiones incidentes. Las dimensiones de tarjetas se reutilizan entre
vistas y el zoom automático cambia de detalle con umbrales separados.

**Modo fluido**, en la barra superior, reduce temporalmente las columnas de las
tablas no seleccionadas y las etiquetas de conexiones durante el movimiento.
Los detalles reaparecen al detenerte. Es opcional y se guarda con la vista;
la tabla seleccionada conserva sus columnas durante el gesto.

La cámara y los layouts se guardan por separado en IndexedDB. La versión 2
conserva los documentos y las vistas anteriores. Las escrituras se ordenan,
se limita la caché de consultas y se protegen los layouts de vistas guardadas.
Las mediciones reproducibles y sus límites están en
`docs/RESULTADOS_OPTIMIZACION_CANVAS.md`.

Comprobaciones adicionales:

```sh
node tools/test-graph.cjs
node tools/benchmark-large-canvas.mjs
```

El benchmark de canvas usa un perfil temporal independiente, registra el equipo
y la GPU real cuando Chrome lo permite y admite `--trace` (traza en
`/tmp/erd-canvas.trace.json`), `--cpu4`, `--disable-gpu` y `--output=ruta.json`.
Los intervalos de requestAnimationFrame no certifican FPS presentados.

## Todas las conexiones y cardinalidades

**Todo el esquema** muestra cada FK por separado, incluidas referencias
transversales, claves compuestas, relaciones paralelas y autorrelaciones.
Esta vista ignora los filtros heredados: su contador contrasta las conexiones
con el total del modelo (356 de 356 en el ejemplo). Para filtrar, usa Módulo o
Enfoque. Si se abre la revisión de expansión, elige **Mostrar todas**.

Los extremos de cada conexión indican `1`, `0..1` o `0..N`; `?` señala datos
insuficientes. La flecha va de la tabla que declara la FK a la referenciada.
En esta vista, buscar una tabla la centra sin salir del esquema completo.
Acerca el canvas o selecciona una conexión para leer sus extremos y los pares
exactos de columnas en el inspector. La exportación SVG incluye las cardinalidades.

La nulabilidad determina si cada fila que declara la FK requiere un destino.
PK, UNIQUE y relaciones importadas permiten reconocer un máximo de una fila en
el extremo hijo. Una FK no obliga a que cada padre tenga hijos: su mínimo se
muestra como cero. Son cardinalidades estructurales según el modelo importado,
no conteos reales ni reglas de negocio adicionales. Se mantiene el aviso de
índices omitidos por el importador; no se deducen restricciones ausentes.
Con Modo fluido, las etiquetas se ocultan solo durante el movimiento y vuelven
al detenerse; desactívalo si necesitas verlas continuamente al desplazar.

<a id="origen"></a>

## Origen y método de construcción

Este proyecto se desarrolló principalmente con asistencia de IA en sesiones de
OpenCode, bajo dirección, revisión y validación humanas. La sesión de publicación
usó DeepSeek V4.1 Flash. El código propio se escribió para este proyecto; las
dependencias externas se conservan en `vendor/` con sus licencias. El registro
de sesiones `agents.mb` documenta el proceso; los esquemas SQL privados usados
durante el desarrollo no se distribuyen.

### Fuentes técnicas

- [`@dineug/erd-editor`](https://www.npmjs.com/package/@dineug/erd-editor)
  4.2.0: editor base, descargado de jsDelivr y conservado sin modificaciones en
  `vendor/`. Licencia MIT. Ver `vendor/README.md`.
- [`elkjs`](https://github.com/kieler/elkjs) 0.10.0 y su worker: layout
  jerárquico local. Licencia EPL-2.0. Ver `vendor/README.md`.
- Documentación pública de los dialectos SQL que la app intenta interpretar:
  [MySQL 8.0](https://dev.mysql.com/doc/refman/8.0/en/),
  [PostgreSQL](https://www.postgresql.org/docs/),
  [SQLite](https://www.sqlite.org/docs.html),
  [SQL Server](https://learn.microsoft.com/sql/t-sql/language-reference) y
  [Oracle](https://docs.oracle.com/en/database/oracle/oracle-database/).
  La app no ejecuta SQL ni certifica todos los dialectos; solo inventaría el
  DDL que puede reconocer.
- Documentación web estándar para IndexedDB, Web Workers, SVG y APIs del
  navegador ([MDN Web Docs](https://developer.mozilla.org/) y especificaciones
  del W3C/WHATWG).
- Los esquemas privados que se usaron como prueba durante el desarrollo no
  forman parte del repositorio. El ejemplo público es sintético y se genera con
  `node tools/generate-example.mjs`; no proviene de datos reales.
- Las mediciones de `docs/performance/` se tomaron en Chrome local con un modelo
  privado de 127 tablas. Son históricas y no se reproducen solo con el ejemplo
  público.

### Cómo se construyó

1. Análisis del editor `erd-editor`, de esquemas SQL reales y de los límites de
   importación.
2. Planes de rediseño visual y de optimización del canvas, conservados en
   `docs/PLAN_VISUAL_FRONTEND.md` y `docs/PLAN_OPTIMIZACION_CANVAS.md`.
3. Implementación iterativa del importador, el índice en workers, el render
   incremental DOM/SVG, la persistencia y la interfaz, con asistencia de IA.
4. Verificación con pruebas Node y Chrome, comparación de conteos del DDL y
   pruebas de interacción; los resultados están en `docs/`.
5. Publicación: exclusión de SQL privado, creación del ejemplo sintético de 150
   tablas, servidor local standalone, GitHub Pages y licencia MIT.

### Alcance y límites

La IA puede cometer errores. El software se ofrece "tal cual", sin garantía,
según la licencia MIT. No es un validador completo de SQL, no ejecuta
migraciones y no garantiza compatibilidad con todos los dialectos. Antes de
usarlo con un esquema de producción, revisa el DDL, contrasta los conteos y
prueba una copia. La app no envía los esquemas a ningún servidor.

## Licencias

El código propio de este repositorio se distribuye bajo la **licencia MIT**.
Consulta [`LICENSE`](LICENSE).

Las dependencias incluidas en `vendor/` conservan sus licencias originales:
`@dineug/erd-editor` es MIT y `elkjs` es EPL-2.0. La licencia MIT del proyecto
no sustituye ni relicencia esas dependencias; consulta `vendor/README.md` y los
archivos `vendor/LICENSE.*` antes de redistribuirlas.
