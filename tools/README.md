# Herramientas públicas

Estas utilidades acompañan al ejemplo sintético y a las comprobaciones que no
dependen del modelo privado de 127 tablas usado durante el desarrollo.

## Generar el ejemplo

```sh
node tools/generate-example.mjs
```

Escribe `examples/demo-150-mysql.sql` y `docs/MODULOS_EJEMPLO.json`. El resultado
es determinista: 150 tablas, 1549 columnas y 356 relaciones.

## Comprobaciones sin navegador

```sh
node tools/test-graph.cjs
node tools/benchmark-analysis.cjs
```

`test-graph.cjs` valida adyacencia, fronteras, dirección, FK compuestas, bucles,
búsqueda y reagrupación sin mutar el documento.

`benchmark-analysis.cjs` mide el índice con 1000/5000 tablas y 5000/25000 FK.
No mide importación SQL, layout global, fluidez ni memoria del navegador.

## Benchmark de canvas

Requiere Chrome/Chromium, Python 3 y Node con `fetch` y `WebSocket` globales.

```sh
node tools/benchmark-large-canvas.mjs
```

Arranca su propio servidor y perfil temporal, carga la demo de 150 tablas y
después genera documentos sintéticos de 1000 y 5000 tablas. Puedes indicar el
navegador con `CHROME_BIN=/ruta/a/chrome`.

La suite interna de interacción ligada al modelo privado de 127 tablas no se
publica. Sus resultados históricos están en `docs/RESULTADOS_OPTIMIZACION_CANVAS.md`.
