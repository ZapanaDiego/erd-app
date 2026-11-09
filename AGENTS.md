# Contexto para futuras sesiones

Leer `agents.mb` antes de trabajar en este proyecto. Contiene el análisis del
27 de octubre de 2026: objetivo del usuario, arquitectura, importación,
persistencia, archivos SQL disponibles, comprobaciones y problemas encontrados.

La fase inicial fue solo análisis. En su siguiente mensaje el usuario autorizó
**corregir los fallos e importar archivos/código para dejar visible el diagrama**.
La sección 14 de `agents.mb` documenta esa fase; las secciones 16 y 18
contienen el estado visual y la optimización vigente. Las anteriores conservan el diagnóstico histórico.

Después pidió **primero un plan de rediseño visual**, sin implementarlo en
esa fase. Más tarde autorizó su construcción. Ver `docs/PLAN_VISUAL_FRONTEND.md`,
`docs/MODULOS_PROPUESTOS.json` y la sección 15 de `agents.mb`.

Objetivo de producto: cargar archivos de bases de datos y visualizar en detalle
todas las tablas, columnas y relaciones. Actualmente es una app estática local
de diagramas entidad-relación sobre `@dineug/erd-editor` 4.2.0.

No modificar directamente `vendor/erd-editor.umd.js`; consultar las indicaciones
de `vendor/README.md` si una tarea futura requiere actualizar la dependencia.

Mantener separados los hechos comprobados, los riesgos inferidos del código
y los requisitos todavía pendientes de definir. No dar por compatible un formato
o dialecto SQL por su extensión o por las funciones disponibles en el editor.

El usuario autorizó después implementar el plan y continuar la construcción.
El explorador está implementado; leer las secciones 16 y 18 de `agents.mb`
para arquitectura, optimización, pruebas y límites. Las secciones 14/15 son el historial.

La petición posterior solicitó primero planificar la optimización de fluidez,
sin implementarla en esa fase. Leer `docs/PLAN_OPTIMIZACION_CANVAS.md` y la sección 17 de
`agents.mb`: incluyen una medición exploratoria y sus límites explícitos.

El usuario autorizó después aplicar esa optimización. Está implementada:
leer la sección 18 de `agents.mb` y `docs/RESULTADOS_OPTIMIZACION_CANVAS.md`.
El renderer definitivo es DOM/SVG incremental; el prototipo 2D se descartó tras
comparación. Mantener las distinciones entre datos medidos, rAF y FPS reales.

Para la petición posterior de todas las conexiones y cardinalidades, leer la
sección 19 de `agents.mb`: Todo el esquema ahora incluye cada FK sin filtros
heredados y muestra cardinalidad por extremo según las restricciones importadas.
