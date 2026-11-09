# Plan de optimización de fluidez del explorador

Fecha: 28 de octubre de 2026. Estado original: planificación.
El usuario autorizó después la implementación. Consultar
`RESULTADOS_OPTIMIZACION_CANVAS.md` y la sección 18 de `../agents.mb` para
los cambios efectivos, mediciones, decisión de renderer y límites.
Los objetivos siguientes conservan los criterios del plan original.
Objetivo: que desplazar, acercar, seleccionar y arrastrar respondan con fluidez,
conservando todas las tablas, relaciones, vistas y posibilidades de análisis.

## 1. Diagnóstico y evidencia

La superficie visual actual usa tarjetas HTML y conexiones SVG; no utiliza
Canvas 2D. ELK y las consultas del grafo ya trabajan en workers. El problema
observado no obliga a cambiar toda la arquitectura: hay reconstrucciones
repetidas de la interfaz que primero deben eliminarse.

### Hechos comprobados en el código

| Zona | Trabajo actual | Consecuencia que se debe medir |
| --- | --- | --- |
| `explorer.js`, `wheel` y `zoom()` | Cada evento ejecuta transformación y `renderCanvas()`, sin agrupar por fotograma. | Una ráfaga de entradas puede producir varios renderizados antes del siguiente repintado. |
| `renderCanvas()` | Elimina todas las tarjetas y vuelve a crear las visibles. Filtra todos los nodos y consulta dimensiones del viewport dentro del recorrido. | Asignaciones, mutaciones y lecturas geométricas repetidas durante el gesto. |
| `drawEdges()` | Elimina todas las conexiones SVG, marcadores, etiquetas y zonas interactivas y los reconstruye. No filtra conexiones por viewport. | El coste depende del contexto de relaciones completo, aunque solo una parte esté en pantalla. |
| `transform()` + `renderCanvas()` | Ambos llaman a `drawMinimap()`. Este recrea todos los rectángulos. | Con rueda se reconstruye dos veces por evento un dibujo cuya geometría no cambió. |
| Arrastre de tabla | Actualiza `left/top`, dibuja todas las relaciones y todo el minimapa en cada `pointermove`. | Una tabla movida invalida trabajo de todo el contexto. |
| Arrastre del fondo | Cambia la transformación, pero revisa nodos visibles al terminar el gesto. | Pueden aparecer huecos al entrar en regiones inicialmente virtualizadas. |
| `show()` y `measure()` | Incluso con posiciones en caché, construye tarjetas de medición; alterna inserciones y lecturas `offset*`. Después crea las tarjetas de pantalla. | Trabajo duplicado y riesgo de cálculos síncronos de layout. Ceder cada 50 tablas no elimina ese coste. |
| Detalle automático | Tras cada pausa de zoom llama a `show()`, aunque no haya cruzado el umbral de detalle. | Se repiten proyección y medición sin necesidad. |
| Persistencia | Después de 400 ms de inactividad guarda el paquete completo, incluidos todos los layouts. | Posible coste de clonación y escritura tras gestos; falta atribuir su impacto real. |
| Worker ELK | Al convertir cada arista de salida vuelve a filtrar todos los bundles para excluir autorrelaciones. | Trabajo cuadrático evitable al recoger resultados grandes. |
| Índice y búsqueda | `project()` recorre todas las FK para obtener contextos pequeños; `search()` recompone el texto de cada tabla en cada consulta. Cargar metadatos puede reconstruir el índice dos veces. | Trabajo evitable con modelos mayores; no explica por sí solo el coste de cada movimiento de rueda. |

### Medición exploratoria realizada

Datos completos: `performance/BASELINE_CANVAS_2026-10-28.json`.

Se usó una copia aislada de Chrome headless 154, Linux, 1400 × 900, DPR 1,
con los argumentos del verificador actual, incluido `--disable-gpu`. Se cargó
el SQL real: 127 tablas, 1189 columnas y 427 FK. No se modificó el documento.
Se envolvieron temporalmente cinco métodos con contadores, solo en esa pestaña.
Cada escenario recibió 60 eventos sintéticos de rueda, uno por callback de
`requestAnimationFrame`: 30 desplazamientos de un píxel y 30 de regreso.

| Vista | Tarjetas montadas | Elementos en viewport | JS por evento, mediana | JS por evento, p95 | Tarjetas creadas en 60 eventos | Reconstrucciones del minimapa |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Mapa | 9 | 67 | 3,5 ms | 4,0 ms | 540 | 120 |
| Ruta de tres tablas | 3 | 124 | 4,1 ms | 4,5 ms | 180 | 120 |
| Todas, claves | 127 | 3600 | 60,0 ms | 134,5 ms | 7620 | 120 |
| Todas, columnas | 127 | 6208 | 92,0 ms | 242,3 ms | 7620 | 120 |

Volver a presentar las mismas vistas completas, con posiciones en caché, tardó
148,3 ms / 232,7 ms y creó 254 tarjetas en cada caso: 127 para medir y 127 para
mostrar. Son muestras de una ejecución, sensibles al entorno y a la recolección
de memoria. Los tiempos de eventos miden ejecución síncrona del manejador,
no incluyen toda la pintura/composición posterior, y no equivalen a FPS,
INP ni latencia física de entrada. El navegador sin GPU no reproduce el equipo
visible del usuario. Los recuentos sí confirman la reconstrucción sistemática.

### Hipótesis todavía pendientes

Atribuir con una traza cuánto pesa cada parte: JavaScript, estilos, layout,
pintura, composición, pausas de memoria, clonación de workers y almacenamiento.
Medir también el editor nativo cuando se abre. Su posible coste no se debe
confundir con el del explorador DOM/SVG. Las pruebas sintéticas anteriores de
5000 tablas solo medían el índice en Node, no la fluidez de pantalla.

## 2. Presupuestos y protocolo de validación

Antes de fijar una promesa se registrará equipo, CPU/GPU, memoria, navegador,
zoom del navegador, DPR, frecuencia de pantalla y estado energético. Ensayar
con GPU activa en una pestaña visible, sin otras cargas relevantes; repetir
con ralentización de CPU ×4 como escenario adicional, identificado por separado.

Escenarios mínimos: mapa, módulo de 15–20 tablas, enfoque de una tabla, ruta,
contexto de 113 tablas y esquema completo de 127 tablas. Cada uno con nombres,
claves y columnas; conexiones ocultas, de selección y de contexto. Probar con
inspector y navegador abiertos/cerrados, y en 1400×900 y 360×800.

Por escenario: cinco repeticiones tras calentamiento, al menos diez segundos de
pan/zoom/arrastre, trayectorias y semilla fijas; separar caché fría/caliente.
Conservar trazas y resultados por repetición, además de mediana y percentiles.
Añadir 1000/5000 tablas con 5000/25000 FK: modelos dispersos, hubs, compuestas y
bucles, tanto exploración acotada como vista global. No exigir todas las
columnas de 5000 tablas montadas simultáneamente para explorar ese modelo.

| Métrica | Meta propuesta, por validar en el equipo de referencia |
| --- | --- |
| Fluidez a 60 Hz, modelo real | Aproximarse a 60 FPS: intervalo entre frames p95 ≤20 ms y ≤1 % de intervalos >33,3 ms en gestos estables. Registrar también la peor pausa. |
| Trabajo JS del explorador | p95 ≤6 ms por frame en pan/zoom del modelo real, dejando margen para el navegador. No usar este dato solo como prueba de fluidez. |
| Feedback de selección/controles | p95 ≤100 ms hasta respuesta visible en el modelo real. Medir entrada→pintura y tareas largas, no solo duración del callback. |
| Bloqueos durante un gesto | Cero tareas del explorador >50 ms en escenarios habituales; documentar excepciones y peor caso. |
| Vistas repetidas | Proyección y dimensiones reutilizadas; objetivo p95 ≤100 ms de solicitud a presentación en rutas/módulos calientes del modelo real. |
| Layout explícito | Feedback ≤100 ms, cancelación efectiva y canvas anterior navegable; tiempo total publicado por tamaño, sin garantía previa para 5000 nodos. |
| Memoria | Tras 20 ciclos abrir/cerrar vistas, memoria retenida estabilizada: objetivo de crecimiento ≤10 % respecto al estado caliente comparable, tras GC controlado de laboratorio. |
| Integridad | 127/1189/427 intactos; vistas, filtros, exportación, FK compuestas y autorrelaciones sin pérdidas. |

En pantallas de otra frecuencia, registrar su presupuesto (1000/Hz ms) y no
mezclar resultados. Observar `requestAnimationFrame` solo en pestaña visible,
y contrastar con trazas de frames presentados: contar callbacks no prueba FPS.
Usar User Timing y PerformanceObserver para tareas/frames largos si están
disponibles, con traza de DevTools como alternativa. La navegación continua
necesita métricas propias; una puntuación Lighthouse o INP aislada no la valida.

## 3. Secuencia de implementación

### Fase 0 — Línea base reproducible y protecciones (P0)

Entregables futuros: `tools/benchmark-canvas.mjs`, escenarios y resultados JSON,
marcas de medida y contadores activables solo para desarrollo. Ampliar el ensayo
exploratorio con entradas reales del navegador, trazas de pintura y GPU activa.
Registrar eventos recibidos, frames, tarjetas creadas/retiradas, rutas cambiadas,
mediciones DOM, mensajes de worker, bytes guardados y duración de cada fase.

Reutilizar el arnés de Chrome de `tools/verify.mjs`, con perfil independiente.
No mezclar pruebas de velocidad con el verificador funcional: sus esperas,
instrumentación y configuración de GPU tienen otro objetivo. Guardar trazas
con detalle suficiente para comparar antes/después del mismo cambio.

Cierre: reproducir y atribuir el atasco del modelo real; marcar objetivos
alcanzados, pendientes y limitados por dispositivo. Nunca publicar ganancias
porcentuales sin ejecuciones comparables.

### Fase 1 — Un trabajo visual por fotograma (P0, primer cambio)

Introducir un coordinador de render con un único `requestAnimationFrame`
pendiente. Los manejadores solo acumulan cámara/posición final y marcan qué
cambió. Agrupar ráfagas de rueda y puntero; conservar el orden matemático del
zoom respecto al cursor, sin descartar desplazamientos intermedios acumulados.

Separar invalidaciones: cámara, conjunto visible, geometría de nodo, rutas,
selección, detalle, minimapa estático y rectángulo de cámara del minimapa.
Durante pan cambiar el `transform` del mundo y ese rectángulo. Recalcular
visibilidad cuando se agote el margen anticipado, sin reconstruir todo.
Un cambio de tamaño tendrá el mismo coordinador, leyendo dimensiones una vez.
Preparar la cámara definitiva antes del primer render de `show()/fit()` para
eliminar el render con cámara antigua seguido del render ajustado.

Cierre: a lo sumo un commit visual por frame; un pan que conserva el conjunto
visible crea cero tarjetas, cambia cero rutas y no vuelve a medir tarjetas.
Ni bucles permanentes de animación cuando no hay cambios, ni guardados en rAF.

### Fase 2 — Conservar nodos, conexiones y minimapa (P0)

Mantener mapas por clave de nodos y bundles. Añadir/retirar únicamente elementos
que entran/salen de la vista; modificar contenido solo cuando cambia su versión.
Seleccionar actualiza clases de las selecciones anterior/nueva y el inspector,
conservando el foco del teclado y los elementos que ya están montados.
Crear `<defs>` y marcadores SVG una vez por renderer.

Separar minimapa en geometría estática y rectángulo de cámara. Recalcular
extensiones al cambiar layout, actualizar un nodo al arrastrarlo y actualizar
solo el rectángulo al navegar. Un segundo refresco limitado a 10–15 Hz se puede
ensayar para miniaturas grandes, sin retrasar el canvas principal.

Índice de relaciones incidentes por tabla: durante arrastre mover un nodo con
transformación y actualizar únicamente sus conexiones. Mantener sus extremos
en coordenadas del mundo y su vista previa coherente; confirmar posición al
soltar, sin ejecutar ELK continuamente. Conservar zona de selección y acceso
por teclado de cada relación. No perder FK compuestas ni bucles.

Cierre: una tabla movida no recrea tarjetas ajenas ni conexiones no incidentes;
seleccionar no desmonta el botón enfocado; pan/zoom no reconstruyen el minimapa.

### Fase 3 — Visibilidad real y detalle según escala (P1)

Primero medir si un recorrido lineal sobre rectángulos almacenados cumple el
presupuesto de 127 tablas. Para 1000/5000, incorporar cuadrícula espacial o
quadtree solo si reduce coste frente a ese recorrido. Leer ancho/alto una vez,
no dentro de cada prueba de intersección. Ajustar el margen de 600 px actual a
velocidad de desplazamiento y escala, con topes medidos.

Filtrar también aristas por sus segmentos/rutas: deben conservarse líneas que
cruzan el viewport aunque ambos extremos queden fuera. Cachear rutas y sus
cajas; comprobar segmentos en casos ambiguos. No cortar autorrelaciones ni
perder la posibilidad de consultar conexiones resumidas en el inspector.

A bajo zoom usar tarjetas compactas y conexiones agregadas/seleccionadas.
Añadir histéresis a los umbrales de detalle para evitar alternar continuamente.
Cambiar detalle solo al cruzar un umbral estable, manteniendo el ancla de cámara
y posiciones. Si el usuario eligió columnas explícitamente, respetarlo; ofrecer
un modo fluido opcional que reduzca temporalmente detalle durante el gesto y
lo restaure al quedar quieto. Cualquier resumen debe mostrar su contador.

Al arrastrar el fondo, montar el área próxima antes de agotar el margen para
que no haya huecos. Mantener montado el elemento con foco, captura activa o
selección accesible; no permitir fugas al acumular elementos fijados al DOM.

Cierre: coste de montaje y conexiones determinado por lo visible y el detalle,
no por todas las entidades. Navegar hasta una tabla lejana la hace aparecer
sin tener que soltar y volver a mover. No hay parpadeos en el umbral.

### Fase 4 — Medidas, proyecciones y layout reutilizables (P1)

Cachear dimensiones y puertos por identidad/versión de tabla, nivel de detalle,
ancho y versión tipográfica/estilos que afecten la geometría. Invalidar al
cambiar columnas, nombres que envuelvan texto, fuentes, ancho o estilos de
medición; un cambio de tema sin cambio geométrico no debería invalidarlas.

Para misses, construir lotes de tarjetas, escribir el DOM en bloque y después
leer geometría en bloque. Ceder según presupuesto temporal medido, no solo
cada 50 tablas. Ensayar alturas calculadas para filas fijas, conservando medición
real de cabeceras variables. `DocumentFragment` por sí solo no garantiza mejora.

Separar cachés de posiciones estables, proyección y rutas. Una clave de rutas
incluye topología visible, geometría, puertos y opciones de layout; una cámara
nueva no la invalida. Mantener coordenadas existentes al filtrar, pero invalidar
solo rutas que dejan de ser válidas. Usar límites LRU por tamaño y número,
no un objeto que crece indefinidamente. Acotar también undo y memoria retenida.

No enviar todo al algoritmo por selección, pan, zoom o cambios cosméticos.
Reservar ELK para primer layout, cambio estructural relevante o Reordenar;
calcular inserciones locales/por módulo al expandir. Corregir antes el filtrado
repetido de bundles en la conversión de resultados del worker.

Cierre: vista caliente sin misses geométricos realiza cero mediciones DOM;
selección y navegación no llaman a ELK; restaurar posiciones no reutiliza rutas
incompatibles; tras invalidar estilos se recalculan medidas correctas.

### Fase 5 — Consultas y workers con carga controlada (P1/P2)

Usar adyacencia para recolectar FK incidentes de contextos pequeños, deduplicando
por clave y conservando conteos de frontera. Precalcular pares agregados por
módulo y texto normalizado de búsqueda al indexar; actualizar solo lo afectado.

Evitar reconstruir todo el índice solo para asignar nombres de restricciones.
Conservar el grafo completo en el worker y transferir al hilo visual únicamente
lo requerido por la interfaz; medir tamaño/coste antes de usar buffers binarios.
Evitar duplicar el grafo entero en cada cambio de grupos.

Cola con revisión/modelo identificados: conservar la petición más reciente de
cada consulta sustituible, ignorar resultados antiguos antes de trabajo DOM y
no acumular layouts que ya no se usarán. Separar control del worker de consultas
y del worker de ELK si el perfil muestra competencia. Cancelar también el motor
ELK anidado, comprobando que no queda cálculo huérfano; reconstruir solo el
componente necesario y conservar la vista anterior navegable.

Cierre: una ráfaga de consultas no crea cola creciente; resultados antiguos no
se presentan ni se miden; cancelación responde y realmente detiene el trabajo.
Comparar resultados contra la implementación de referencia para no alterar
rutas, direcciones, filtros, límites de saltos ni FK compuestas.

### Fase 6 — Guardado y costes de pintura (P2)

Guardar cámara, posiciones, configuración y modelo con versiones y suciedad
independientes. No clonar todos los layouts al terminar un pan. Unificar cambios
pendientes y serializar escrituras para que una antigua no pise una nueva.
Guardar al finalizar gestos y en inactividad con límite de espera. No confiar
solo en `requestIdleCallback` ni en un último guardado al cerrar; disponer de
fallback y exportación explícita. Mantener compatibilidad con datos existentes.

Medir bytes, duración y memoria de structured clone/IndexedDB; limitar cachés
de cálculo, sin eliminar vistas guardadas por el usuario. Reducir retenciones
de historial. Optimizar la lectura/serialización del editor solo si aparece en
trazas; no cambiar su bundle.

Perfilar pintura de sombras, bordes, resaltados y SVG. Probar simplificar adornos
durante gestos manteniendo contraste/foco. Evaluar `contain` en contenedores
apropiados; no recortar conectores ni alterar mediciones. Evitar `will-change`
en cada tarjeta: muchas capas pueden consumir más memoria. Validar con GPU.

Cierre: no hay guardados pesados dentro de frames de interacción, el último
estado persiste tras recarga y la mejora de pintura no degrada legibilidad.

### Fase 7 — Decisión de renderer basada en resultados (condicional, P3)

Después de las fases anteriores, repetir exactamente la matriz. Si las líneas
SVG aún dominan el presupuesto, comparar una capa Canvas 2D para conexiones con
las mismas tarjetas HTML. Conservar transformación, prueba espacial de clic,
resaltados, FK compuestas, exportación SVG y una lista accesible de relaciones.
Probar dibujo por capas, geometría reutilizable y DPR acotado; OffscreenCanvas
solo si se demuestra ventaja y existe fallback. Contemplar WebGL únicamente si
la densidad medida lo exige: complica texto, selección, accesibilidad y soporte.

Criterio de decisión: prototipo supera presupuesto previo en la misma máquina
con mejora relevante y repetible (umbral propuesto ≥25 % en p95 del cuello de
botella) y pasa integridad/accesibilidad. No migrar si DOM/SVG ya cumple metas.
No suponer que introducir React Flow, Cytoscape o GPU resuelve reconstrucciones
innecesarias. La prueba comparará escenas equivalentes y coste total.

## 4. Mapa técnico y dependencias

| Orden | Archivos previstos | Entrega y validación |
| --- | --- | --- |
| 0 | `tools/benchmark-canvas.mjs` nuevo y escenarios | Línea base visible/GPU, trazas y reporte repetible. |
| 1 | `analysis/explorer.js`; coordinador opcional en módulo separado | Agrupación por frame e invalidaciones; mismo resultado de cámara. |
| 2 | Renderer en `analysis/` y estilos | DOM/SVG incremental, minimapa estático y arrastre local; foco conservado. |
| 3 | Índice espacial y renderer | Nodos/aristas visibles y LOD; pruebas de cruces de viewport y zoom. |
| 4 | `explorer.js`, `worker.js` | Cachés correctas, medidas en lotes y ELK acotado. |
| 5 | `graph.js`, `worker.js`, cliente worker | Consultas incrementales, respuestas mínimas, cancelación. |
| 6 | `storage.js`, `explorer.js`, integración en `app.js`, CSS | Guardados parciales compatibles y menor pintura. |
| 7 | Capa experimental opcional | Comparativa Canvas 2D; adoptar solo si justificado. |

Dependencias: 0→1→2; 3/4 parten de invalidaciones estables; 5 se puede abordar
tras atribuir tiempos; 6 tras distinguir qué estado cambió; 7 requiere volver a
medir todo lo anterior. Cada entrega debe quedar utilizable y reversible.
No se fija calendario sin validar el perfil inicial y el alcance de renderer.

## 5. Regresiones obligatorias y definición de terminado

- Conservar el documento original y 127 tablas/1189 columnas/427 FK. Comprobar
  281 FK compuestas y 7 autorrelaciones; exportación editable completa.
- Mantener mapa, módulo, enfoque, rutas, expansión parcial/cancelada, resúmenes
  reversibles y dirección de flechas. Comparar las consultas optimizadas con
  resultados de referencia en modelos pequeños conocidos y sintéticos.
- Probar clic frente a arrastre, captura/cancelación de puntero, pan largo,
  trackpad con ráfagas, zoom anclado, teclado y foco conservado al virtualizar.
- Validar posiciones fijadas, deshacer, medidas tras fuentes/anchos nuevos,
  restauración de rutas, vistas antiguas, exportación y fallo/cuota de guardado.
- Probar cambios rápidos de modelo/vista mientras hay layout, mediciones o
  guardado; ninguna respuesta antigua debe reemplazar el modelo actual.
- Ejecutar `node tools/verify.mjs` como regresión funcional y, por separado,
  el nuevo benchmark de interacción. Cero errores sin capturar.
- Comparar resultados por fase con línea base equivalente y ensayar con el
  archivo real en el navegador visible. Preservar detalle a petición del usuario.

La primera entrega útil termina cuando pan/zoom dejan de reconstruir el grafo
visible completo, el minimapa deja de duplicarse y el perfil muestra la mejora.
El trabajo total termina al alcanzar los presupuestos acordados para el modelo
real y la exploración acotada de modelos grandes, o al documentar una limitación
medida y una decisión explícita de renderer. No se declara fluidez de 5000 tablas
basándose únicamente en velocidad del índice o en un contador de callbacks.

## 6. Fuentes oficiales que sustentan las decisiones

- [web.dev: evitar layouts complejos y layout thrashing](https://web.dev/articles/avoid-large-complex-layouts-and-layout-thrashing).
  Sustenta separar lecturas/escrituras y perfilar layout forzado (fases 0 y 4).
- [web.dev: limitar trabajo en manejadores de entrada](https://web.dev/articles/debounce-your-input-handlers).
  Sustenta acumular cambios y programar su actualización visual (fase 1).
- [MDN: requestAnimationFrame](https://developer.mozilla.org/en-US/docs/Web/API/Window/requestAnimationFrame).
  Documenta sincronización con refresco y pausas en pestañas ocultas; afecta
  coordinador y metodología de medición.
- [MDN: Long animation frame timing](https://developer.mozilla.org/en-US/docs/Web/API/Performance_API/Long_animation_frame_timing).
  Permite atribuir frames largos donde esté disponible, con fallback a trazas.
- [MDN: Optimizing canvas](https://developer.mozilla.org/en-US/docs/Web/API/Canvas_API/Tutorial/Optimizing_canvas).
  Fundamenta la evaluación condicional de capas y dibujo reutilizado si se
  introduce Canvas 2D; no demuestra que esa migración sea necesaria aquí.
