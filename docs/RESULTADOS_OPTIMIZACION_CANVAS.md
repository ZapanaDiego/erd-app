# Optimización del canvas: implementación y resultados

28 de octubre de 2026. Estado: implementado y verificado.
La aplicación conserva tarjetas HTML y conexiones SVG. El editor y el documento
canónico siguen completos; los filtros y la cámara no modifican sus entidades.

## Cambios efectivos

- Coordinador de render con una petición `requestAnimationFrame` pendiente.
  Rueda, zoom, teclado y puntero acumulan el estado; la cámara se prepara antes
  de presentar una vista nueva. No hay un bucle continuo cuando no hay cambios.
- Tarjetas y conexiones reutilizadas por clave. Pan dentro del margen visible
  no crea tarjetas, rutas ni marcadores. La selección actualiza sus elementos
  afectados y conserva el foco de teclado. Los marcadores SVG se crean una vez.
- Minimapa con geometría estable y rectángulo de cámara independiente. Arrastrar
  una tabla cambia su miniatura y las conexiones incidentes, sin redibujar todo.
- Índice espacial de cuadrícula de 1024 unidades para nodos y cajas de rutas;
  las cajas extensas no se expanden ilimitadamente en celdas. Consulta de
  segmentos conserva líneas que cruzan pantalla con ambos extremos fuera.
  Un margen de montaje y otro de seguridad evitan revisar todo en cada píxel.
- Montaje de tablas cercanas mientras se desplaza el fondo, sin esperar a soltar.
  Se conserva el elemento con foco o captura de arrastre y se limpia al perderlo.
- Medidas cacheadas por contenido, detalle y versión geométrica; invalidación por
  carga de fuentes. Los misses se insertan en lotes de 12, con lecturas separadas
  de escrituras y cesiones entre lotes. Cabeceras se miden con el mismo espacio
  de controles que las tarjetas reales.
- Posiciones estables, validación de geometría/topología de rutas y cachés
  acotadas. Se protegen layouts de vistas guardadas; los layouts ordinarios
  tienen límite de 30. Consultas: máximo 20 entradas y presupuesto de tamaño.
  Undo conserva hasta 20 estados y reduce su historial con layouts grandes.
- Detalle automático con histéresis: nombres por debajo de 0,38, claves por
  encima de 0,52. Dentro de esa banda conserva el nivel anterior. No reproyecta
  si el nivel no cambia y conserva cámara/nivel al restaurar una vista.
- **Modo fluido opcional**: oculta temporalmente filas de tablas no seleccionadas
  y etiquetas al mover/acercar; conserva dimensiones/posiciones. Recupera detalle
  180 ms después del último movimiento. La tabla seleccionada mantiene sus filas.
- Cámara y layouts separados en IndexedDB v2; lectura compatible con documentos
  y paquetes anteriores. Navegar guarda solo el estado ligero si no hay layouts
  pendientes. Escrituras serializadas y un guardado máximo pendiente de 5 s.
  Exportación del documento completo mantiene las vistas y posiciones.
- Proyecciones pequeñas recorren relaciones incidentes por adyacencia;
  agregados de módulos y texto de búsqueda se preparan al indexar. Cambiar
  metadatos no reconstruye el índice completo ni devuelve todas las columnas.
- Cola de consultas sustituibles con última petición pendiente. Versiones
  impiden presentar resultados antiguos. Cancelar dispone el worker de ELK,
  termina el worker de análisis y permite recuperar la navegación.
- Eliminado el filtrado repetido de todos los bundles al recoger resultados ELK.

Archivos principales: `analysis/renderer.js`, `analysis/explorer.js`,
`analysis/graph.js`, `analysis/worker.js`, `analysis/storage.js` y estilos.
No se modificó `vendor/erd-editor.umd.js`; su SHA-256 sigue siendo
`7e455758efc0f4103340b86004ce25c9b40f1302743c09d9f279cacdf3e0cbc9`.

## Evidencia de reutilización

Con el modelo real de 127 tablas y 427 FK, 60 eventos de desplazamiento de un
píxel y regreso, manteniendo el conjunto visible:

| Trabajo | Línea base | Versión optimizada |
| --- | ---: | ---: |
| Tarjetas creadas, vista completa | 7620 | 0 |
| Reconstrucciones del minimapa | 120 | 0 |
| Reconstrucciones geométricas durante pan | Todas las conexiones, 60 veces | 0 |
| Mediciones DOM en una vista caliente sin cambios | 127 tarjetas | 0 |

La línea base está en `performance/BASELINE_CANVAS_2026-10-28.json`.
Los contadores actuales se verifican además como regresiones funcionales;
no dependen de conseguir una velocidad concreta en una máquina concreta.

## Medición de la versión definitiva

`performance/CANVAS_FINAL_2026-10-28.json`: Chrome 154 en ventana visible,
1400×900, DPR 1, AMD Radeon 860M y composición GPU confirmada como habilitada.
Modo fluido activo, una pasada de 60 eventos por escenario:

| Escenario | Manejador p95 | Commit JS p95 | Intervalo de rAF p95 | Tarjetas creadas durante pan |
| --- | ---: | ---: | ---: | ---: |
| Mapa | 0,3 ms | 0,3 ms | 16,7 ms | 0 |
| Ruta | 0,4 ms | 0,3 ms | 16,8 ms | 0 |
| Todas, claves | 0,3 ms | 0,2 ms | 16,8 ms | 0 |
| Todas, columnas | 0,3 ms | 0,3 ms | 16,8 ms | 0 |

Las cinco repeticiones de diez segundos de la vista completa con todas las
columnas y modo fluido produjeron intervalos p95 de 16,7–16,8 ms con SVG.
Véase `performance/CANVAS_COMPARACION_SVG_FLUIDO_2026-10-28.json`.
Sin modo fluido, esa escena extrema conservó intervalos cercanos a 50 ms en
esta comparación. Mostrar todos los detalles a la vez sigue teniendo coste.

Estos intervalos son callbacks de `requestAnimationFrame`, **no una certificación
de FPS presentados** ni de latencia física de entrada. Las entradas del benchmark
son sintéticas. Se registraron equipo, GPU, configuración y errores; hubo además
traza de DevTools (`/tmp/erd-canvas.trace.json`, temporal, regenerable con
`--trace`) y revisión del esquema en el navegador integrado. No extrapolar a
otros equipos, pestañas ocultas ni a 5000 tablas con todas sus columnas globales.
Los tiempos del manejador y del commit están separados: no presentar el descenso
del manejador como si incluyera todo el trabajo de pintura posterior.

## Decisión sobre Canvas 2D

Se construyó y probó un prototipo para conexiones densas con selección espacial,
acceso por teclado y exportación SVG. Pasó sus pruebas funcionales, pero no
superó el criterio de mejora repetible del plan. Cinco repeticiones comparables:

| Todas las columnas | SVG incremental, rAF p95 | Prototipo 2D, rAF p95 |
| --- | --- | --- |
| Sin modo fluido | 49,9–50,0 ms | 49,9 ms |
| Con modo fluido | 16,7–16,8 ms | 16,7–16,8 ms |

El commit JS de SVG fue 0,2–0,3 ms y el de 2D aproximadamente 2,1–2,6 ms.
Se retiró el prototipo y su integración del producto. No se añadió una dependencia
ni un renderer alternativo sin beneficio medido. Los JSON `COMPARACION_2D*`
son evidencia histórica del experimento, no configuración disponible en la app.
Las pasadas exploratorias anteriores también se conservan como historial;
la referencia del producto definitivo es `CANVAS_FINAL` y la batería funcional.

## Modelos sintéticos y memoria

`performance/CANVAS_GRANDE_2026-10-28.json`: ocho columnas y cinco FK por tabla,
incluidas compuestas. Se ensayó mapa, enfoque y módulo, no un layout global de
5000 tablas y 25000 conexiones.

| Modelo | Mapa | Enfoque | Módulo | Variación de heap tras 20 ciclos, GC de laboratorio |
| --- | ---: | ---: | ---: | ---: |
| 1000 tablas / 5000 FK | 20 grupos | 11 tablas | 50 tablas | +0,38 % |
| 5000 tablas / 25000 FK | 20 grupos | 11 tablas | 250 tablas | +0,34 % |

En ambos casos hubo cero tarjetas creadas durante el pan del enfoque, documento
canónico de referencia intacto y cero errores sin capturar. El tiempo de índice
más primera interfaz fue 185 ms / 1102,7 ms en esa ejecución exploratoria.
El heap medido es de laboratorio, con GC forzado, y no mide toda la memoria de
GPU, todos los procesos ni la importación SQL de esos modelos sintéticos.

## Validación y límites

`node tools/verify.mjs` → **RESULTADO: OK**, **0 errores sin capturar**.
Incluye importaciones anteriores, 127 tablas/1189 columnas/427 relaciones,
281 FK compuestas, 7 autorrelaciones, módulos, rutas, expansión/cancelación,
reutilización, líneas fuera de pantalla, arrastre incidente, cámara guardada,
restauración de detalle automático, cola de consultas, cancelación del motor,
modo fluido, clic y arrastre reales, recarga real y ancho de 360 px.
`node tools/test-graph.cjs` verifica adyacencia, fronteras, dirección, compuestas,
bucles, búsqueda y reagrupación. Pasaron los chequeos de sintaxis. Una prueba
adicional de navegador confirmó foco y selección de una relación SVG con Enter.

Se mantiene la separación entre número total del modelo y contexto dibujado.
El modo fluido no elimina datos y no reemplaza la exploración por módulos.
Persisten límites previos: 265 índices importados frente a 283 declaraciones,
rutas simples tras restaurar/mover posiciones y posibles cruces o solapamientos
con fijaciones. No se certifican todos los dialectos ni el render global de
5000 tablas detalladas. No se afirma que toda escena alcance 60 FPS.
