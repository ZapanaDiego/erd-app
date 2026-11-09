# Plan visual del frontend para esquemas grandes

Estado original: propuesta del 27 de octubre.
Actualización del 28 de octubre: explorador implementado; consultar sección 16
de `../agents.mb` y `../README.md` para alcance comprobado y límites.
Las fases y criterios siguientes conservan la propuesta original.
Fecha de investigación: 27 de octubre de 2026.
Base analizada: erd-app y Urbanizadoras_SaaS_MySQL.sql.
Objetivo: comprender un esquema completo sin seguir manualmente cientos de líneas.

## 1. Decisión de producto

Diseñar un explorador con tres escalas: **mapa de módulos → tablas de un módulo →
enfoque de una tabla o una ruta**. El documento completo permanece disponible;
cambia la proyección que se dibuja, no su estructura ni sus exportaciones.

La vista inicial debe mostrar el mapa de módulos. «Todas las tablas y todas las
líneas» será una vista explícita de inspección, no el punto de entrada.
La vista completa sigue siendo útil para buscar patrones globales, pero no debe
cargar con la tarea de leer cada columna y cada relación simultáneamente.

No basta con cambiar colores, aumentar el canvas, disminuir el zoom o aplicar
un auto-layout global diferente. La dificultad es tanto de densidad y jerarquía
como de posición. La propuesta combina organización espacial estable, reducción
progresiva del detalle y consultas concretas sobre el grafo.

Este encargo se limita a planificar: no cambiar app.js, index.html, styles.css,
el bundle, los SQL ni la vista guardada del usuario en esta fase.

## 2. Evidencia del esquema real

Se extrajeron las declaraciones CREATE TABLE y las FK de ALTER TABLE del SQL
con patrones adaptados a este archivo concreto. No son un parser SQL universal.

| Medición | Resultado | Consecuencia visual |
| --- | ---: | --- |
| Tablas | 127 | El mapa general debe agrupar, no encoger 127 tarjetas. |
| Columnas | 1189, verificadas en la fase anterior | El detalle completo debe limitarse al contexto de trabajo. |
| Restricciones FK | 427 | Mostrar todas las líneas simultáneamente dificulta el rastreo. |
| Pares de tablas conectados, sin distinguir dirección | 382 | Agrupar FK paralelas ayuda, pero por sí solo reduce poco el ruido. |
| FK compuestas | 281 | Una relación debe conservar todos sus pares de columnas. |
| Autorrelaciones | 7 | Necesitan representación propia, no desaparición al agrupar. |
| FK que incluyen organization_id en el lado referenciante | 389 | El aislamiento multiempresa atraviesa casi todo el modelo. |
| Tablas sin ninguna relación | 0 | No existe un conjunto grande de tablas aisladas fácil de separar. |

Tablas con mayor cantidad de FK recibidas:

| Tabla referenciada | FK entrantes | Tablas vecinas distintas, sin dirección |
| --- | ---: | ---: |
| organizations | 110 | 111 |
| organization_memberships | 105 | 73 |
| projects | 19 | 23 |
| commercial_operations | 13 | 20 |
| currencies | 13 | 13 |
| territorial_units | 12 | 15 |

Las primeras dos reciben 215 de 427 FK: **50.4%**. Clasificarlas visualmente como
referencias transversales, con control reversible, ofrece una reducción relevante.
No deben eliminarse del modelo ni etiquetarse automáticamente como irrelevantes.
En la vista de acceso y organización sí pueden ser el centro del análisis.

El enfoque por saltos sin límites tampoco resuelve todo:

| Tabla inicial | Vecinas a un salto | Tablas alcanzadas hasta dos saltos, excluida la inicial |
| --- | ---: | ---: |
| organizations | 111 | 123 |
| lots | 12 | 112 |
| commercial_operations | 20 | 115 |
| payments | 8 | 115 |
| users | 3 | 73 |

Por eso «mostrar vecinas» debe tener filtros de módulo/tipo, previsualización del
conteo y expansión voluntaria. Dos saltos desde lots casi reconstruyen el mapa entero.

## 3. Investigación de proyectos existentes

Se revisaron documentación oficial, notas de producto y, para el editor actual,
fragmentos del bundle instalado. No se compararon productos mediante una prueba
de rendimiento común ni se utilizaron cuentas de pago. Las recomendaciones
siguientes son decisiones para este proyecto, no un ranking medido de productos.

| Proyecto | Evidencia consultada | Patrón aplicable |
| --- | --- | --- |
| dbdiagram | [Vistas](https://docs.dbdiagram.io/diagram-views/), [detalle](https://docs.dbdiagram.io/diagram-detail-levels/), [grupos](https://docs.dbdiagram.io/table-groups/) | Vistas por subconjuntos; grupos plegables; alternar nombres, claves o columnas. Separar «modelo completo» de «lo que necesito ver». |
| DataGrip | [Database diagrams](https://www.jetbrains.com/help/datagrip/creating-diagrams.html) | Enfoque de vecindarios y de caminos entre dos nodos. El usuario expresa una pregunta y ve el subgrafo relevante. |
| SqlDBM | [View Modes](https://support.sqldbm.com/hc/en-us/articles/37028707527821-View-Modes) | Distintas lecturas de un mismo modelo: conceptual, física y claves. El detalle se adapta al trabajo sin convertir ni duplicar el modelo. |
| DBeaver | [Diagramas](https://dbeaver.com/docs/dbeaver/ER-Diagrams/) | Visibilidad configurable de atributos, conservación del layout y opciones de enrutamiento. Las posiciones deben sobrevivir a la navegación. |
| drawDB | [Personalización](https://drawdb-io.github.io/docs/customizing-editor), [arquitectura](https://drawdb-io.github.io/docs/how-it-works) | Controles explícitos de etiquetas, cardinalidad, comentarios y tipos; ajuste al área; separación de vista y esquema. Su superficie SVG muestra una alternativa de implementación. |
| ChartDB | [Notas de versión](https://github.com/chartdb/chartdb/releases), [dependencias](https://github.com/chartdb/chartdb/blob/main/package.json) | Filtro por áreas como precedente; React Flow como referencia técnica. No se afirma que sus prestaciones sean las de un paquete insertable sin adaptación. |
| erd-editor actual | [Visualización](https://github.com/dineug/erd-editor-docs/blob/main/docs/guide/guides/visualization.md), bundle local 4.2.0 | Ya hay Flow/Graph, enfoque y modos de filas. Aprovechar capacidades existentes antes de migrar. |

La documentación del editor describe Flow para tarjetas y Graph para una lectura
de conectividad; permite enfocar tablas y vecinas, cambiar las filas mostradas y
resaltar relaciones. El bundle local contiene los modos Name only, Keys only y
All fields, y el atajo Alt+F. Esto confirma una base reutilizable. Las vistas de
Flow no equivalen a vistas de negocio persistidas, y los grupos no se representan
allí según la documentación. Falta validar por interfaz/API qué puede integrarse
sin depender de detalles internos. No se da por resuelto el nuevo explorador.

Conclusión de la comparación: combinar **subconjuntos guardados, niveles de
detalle, foco y layout estable**. Copiar solo un estilo de líneas o un color de
cabecera no reproduciría la utilidad de esas herramientas.

## 4. Experiencia propuesta

### A. Mapa general por módulos

Primera pantalla tras importar un esquema grande:

- Bloques con nombre del módulo y número de tablas; no mostrar columnas.
- Los enlaces se agregan entre pares de módulos y muestran la cantidad de FK.
  Un enlace agregado no representa una FK nueva ni tiene una cardinalidad única.
- Inicialmente dibujar enlaces del módulo seleccionado; opción de verlos todos.
  Incluso nueve módulos pueden producir demasiados cruces si se dibujan todos.
- Doble clic o «Abrir módulo» revela sus tablas. Teclado y clic simple con acción
  visible deben permitir lo mismo, sin depender de hover o doble clic.
- Tablas compartidas se muestran como referencias identificadas, no se duplican
  en el modelo. Un mismo objeto puede participar en varias vistas de trabajo.
- Navegación de contexto: «Esquema / Operaciones comerciales / payments».
- El mapa, el buscador y el detalle comparten selección y conteos.

Propuesta inicial de clasificación manual del SQL de referencia:

| Módulo sugerido | Tablas |
| --- | ---: |
| Catálogos y geografía | 9 |
| Organización y acceso | 20 |
| Territorio e inventario | 17 |
| CRM y privacidad | 16 |
| Operaciones comerciales | 15 |
| Pagos y documentos | 11 |
| Publicaciones y revisiones | 12 |
| Comisiones | 16 |
| Importación y seguimiento | 11 |
| **Total** | **127** |

Es una propuesta de organización, no una verdad deducida del motor SQL.
La asignación completa, revisable, de las 127 tablas se conserva en
`docs/MODULOS_PROPUESTOS.json`. Cada tabla tiene allí un módulo principal;
las vistas de trabajo podrán incluir referencias a tablas de otros módulos.
Con esta asignación existen 157 FK dentro de módulos y 270 entre módulos,
resumibles en 32 pares de módulos sin dirección. Dibujar las 32 de entrada
seguiría siendo denso: se revelan por selección o por tarea.

Para otras bases: priorizar esquemas/grupos declarados; después sugerencias por
nombres y estructura de FK, con revisión manual. Reducir el peso de hubs al
sugerir grupos para evitar que organizations absorba todo. Guardar correcciones
del usuario y mostrar tablas «sin clasificar» en lugar de inventar dominios.
No fijar nueve módulos para todos los archivos ni hacer depender esto de una nube.

### B. Vista de un módulo

- Trabajar habitualmente con unas 8–25 tablas visibles; es una guía de densidad,
  no un límite del documento ni un recorte silencioso de información.
- Nombre completo de la tabla, número de columnas y claves a simple vista.
- Selector explícito «Nombres / Claves / Todas las columnas».
- Modo inicial «Claves» cuando el subgrafo es legible; si excede la densidad
  objetivo, sugerir subdividir o enfocar en lugar de seguir alejando el zoom.
- Las referencias a módulos externos aparecen como conectores resumidos:
  «Organización y acceso · 34 FK», expandibles o abribles en su vista.
- Mostrar contador de tablas/relaciones visibles y de referencias fuera de vista.
- El detalle completo de una tabla se abre en un inspector lateral independiente;
  no debajo de una lista larga que obliga a desplazar todo el panel.

### C. Modo enfoque

Al elegir una tabla:

1. Mostrar la tabla central y un contexto pequeño de vecinas relevantes.
2. Separar «Referencia a» de «Es referenciada por»; la dirección se explica en texto.
3. Mantener por defecto las referencias transversales resumidas, con su cantidad.
4. Permitir «solo esta tabla», «un salto», «dos saltos» y selección manual.
5. Antes de una expansión grande, mostrar cuántos nodos y enlaces añadirá y ofrecer
   filtros. Nunca truncar vecinas sin aviso ni decidir por orden alfabético.
6. Expandir por lotes elegidos conservando la posición de las tablas ya presentes.
7. Fijar/persistir una relación resaltada mediante clic; hover solo como atajo.
8. Volver a la vista anterior restaura selección, filtros y posición de cámara.

En organizaciones con muchas dependencias, abrir primero la lista de relaciones
agrupada por módulo y permitir elegir cuáles revelar en el canvas.

### D. Modo ruta: responder una pregunta concreta

Acción: «¿Cómo se relacionan A y B?».

Ejemplo comprobado en este SQL:

`payments → commercial_operations → lots`

Aquí la flecha significa **la tabla de la izquierda tiene una FK hacia la tabla
de la derecha**. Esto es una ruta estructural; no demuestra un flujo temporal de
negocio, ejecución de procesos, lineage de registros ni un borrado en cascada.

- Origen y destino mediante búsqueda; ruta corta por defecto.
- Permitir forzar una tabla intermedia o limitar módulos/tipos de relaciones.
- Mostrar rutas alternativas de forma acotada; no enumerar todos los caminos
  de un grafo cíclico. Una ruta mínima no siempre es la explicación de negocio.
- Se puede recorrer FK en ambos sentidos si el usuario lo elige; cada tramo
  conserva su flecha real. «Dependencias» y «referencias recibidas» son modos
  distintos, no una inversión silenciosa del significado.
- Vista tipo lectura por pasos y la misma ruta resaltada en el canvas.
- Si el filtro excluye una conexión necesaria, decir «sin ruta bajo estos filtros»;
  no afirmar que las tablas no se relacionan en el documento completo.

### E. Inspector de relaciones

Al seleccionar un enlace mostrar, sin necesidad de perseguir la línea:

- Nombre de la FK y tabla que la declara.
- Tabla/columnas referenciadas.
- Correspondencia ordenada de cada columna de una FK compuesta.
- Cardinalidad y opcionalidad que permita inferir el modelo, explicando cuando
  no se puedan determinar; no asumir uno-a-muchos para toda FK.
- ON DELETE / ON UPDATE si están disponibles en el modelo importado.
- Acciones «Ir al origen», «Ir al destino» y «Aislar esta relación».

Ejemplo real de pareja de columnas:

`payments (organization_id, operation_id)`
`→ commercial_operations (organization_id, id)`

Las 281 FK compuestas se conservan como restricciones únicas con varios pares.
Ocultar visualmente el conector transversal hacia organizations NO elimina
organization_id de esta relación ni de su explicación.

## 5. Política de conexiones

| Contexto | Qué se dibuja inicialmente |
| --- | --- |
| Mapa | Enlaces agregados del módulo seleccionado; columnas ocultas. |
| Módulo | Conexiones locales legibles; externas resumidas por destino. |
| Enfoque | Enlaces del contexto elegido, con énfasis en la selección. |
| Ruta | Solo los tramos seleccionados; contexto adicional voluntario. |
| Todo | Disponible bajo acción explícita, con advertencia de densidad y filtros. |

Reglas transversales:

- Un estilo neutro para conexiones normales; un único acento fuerte para lo
  seleccionado. Color de módulo estable en encabezados, acompañado por texto.
- No usar rojo para todas las FK ni depender del color para indicar dirección.
- Las FK paralelas entre dos tablas pueden resumirse como «4 relaciones».
  Al abrir ese resumen, listar cada restricción por separado y conservar sus campos.
- Las autorrelaciones aparecen como bucle o indicador expandible, no se omiten.
- Ocultar etiquetas largas por defecto y mostrarlas en selección/inspector.
- Rutas ortogonales con canales de paso, separación suficiente y puertos estables.
  En detalle, anclar a columnas; en modo compacto, a la cabecera de la tabla.
- Nunca llevar una línea a una fila oculta dando a entender otra columna.
- Evitar animación continua de todas las conexiones; permitir reducir movimiento.
- Bajar opacidad puede ayudar en selección, pero no reemplaza filtrar o agregar:
  427 líneas semitransparentes siguen siendo 427 líneas.

## 6. Organización espacial y zoom

Layout en dos escalas: primero los módulos; después las tablas de cada módulo.
La vista de ruta usa un layout corto de izquierda a derecha. Los ciclos se
mantienen como ciclos, con tramos de retorno diferenciados.

[ELK Layered](https://eclipse.dev/elk/reference/algorithms/org-eclipse-elk-layered.html)
soporta distribución por capas, minimización de cruces, grafos compuestos y
puertos con enrutamiento ortogonal. Es un candidato para probar, no una promesa
de eliminar todos los cruces ni un requisito de cálculo global en cada clic.

Reglas del layout:

- Medir tamaños reales del modo de tarjeta, no estimarlos solo por caracteres.
- Conservar posiciones al filtrar, seleccionar, desplazar y abrir inspectores.
- Recalcular automáticamente solo el subgrafo nuevo cuando sea necesario.
- Reordenar el módulo o todo el mapa mediante acciones distintas y reversibles.
- Ofrecer fijación de tablas, separación configurable y restaurar distribución.
- Deshacer un reordenamiento sin deshacer cambios del esquema.
- Cachear por huella del modelo, vista, medidas y configuración de layout.
- Descartar respuestas de cálculo anteriores si cambió la vista mientras corrían.
- Mantener al usuario orientado con breadcrumb, historial y minimapa simplificado
  de bloques. No dibujar una segunda maraña de líneas en el minimapa.

Zoom con detalle semántico, condicionado al motor:

- Lejos: módulos o nombres y conteos; tipografía de interfaz legible.
- Medio: tablas compactas y claves.
- Cerca: columnas relevantes, tipos y extremos de FK.
- El usuario puede fijar el nivel de detalle para que el zoom no cambie su tarea.
- Cambiar el nivel cerca de un umbral no debe producir saltos repetidos de tamaño
  y layout; usar histéresis o confirmación, manteniendo el objeto enfocado estable.

El mapa de módulos debe existir a escala de lectura normal. No depender de
reducir el zoom debajo del mínimo 10% del editor para resolver la densidad.

## 7. Distribución del frontend

Propuesta de escritorio:

```text
Archivo / Importación   | Buscar tabla o columna          | Vistas guardadas
Esquema > Módulo > Tabla | Nombres / Claves / Columnas     | Filtros activos
┌───────────────────┬─────────────────────────────────┬────────────────────┐
│ Módulos           │                                 │ Inspector          │
│ Tablas            │       Canvas contextual         │ Tabla / Relación   │
│ Vistas            │                                 │ Mapeos de columnas │
│ Resultados        │                                 │ Ir a extremos      │
└───────────────────┴─────────────────────────────────┴────────────────────┘
127 tablas totales · 12 visibles · 18 relaciones visibles · referencias resumidas
```

El inspector derecho es plegable y solo ocupa espacio cuando hace falta. El
panel izquierdo navega; el derecho explica. La importación se agrupa en un menú
para liberar la barra, conservando acceso a pegar código y a los errores.
La cantidad visible depende del viewport; no se exige mantener tres paneles en
pantallas estrechas. En portátil, el inspector puede sustituir temporalmente al
navegador. En móvil, usar un panel por vez y lista de relaciones como alternativa
al trazado espacial.

Búsqueda global por tabla, columna y, cuando esté disponible, descripción.
El resultado indica módulo y campos coincidentes; acciones «Enfocar» y «Añadir a
la vista». No alterar todos los resultados del canvas en cada pulsación.

## 8. Arquitectura propuesta y elección de motor

Separar responsabilidades antes de ampliar la interfaz:

1. Documento canónico importado: todas las tablas, columnas y restricciones.
2. Índice de grafo: accesos por tabla, columna, FK, vecinas y módulos.
3. Estado de análisis: selección, vistas, grupos, filtros, nivel de detalle y cámara.
4. Proyector: decide qué nodos/aristas/resúmenes corresponden a la vista actual.
5. Servicio de layout en worker: posiciones y rutas, sin bloquear la interacción.
6. Adaptador de dibujo: motor elegido, sin controlar el documento canónico.
7. Inspector y búsqueda: consumen el mismo índice, aunque una tabla esté oculta.

No implementar filtros borrando tablas de `editor.value`. No autoguardar un
subgrafo como si fuera el documento completo. Exportar «modelo completo» y
«vista actual» como acciones claramente distintas.

### Decisión recomendada: aprovechar el motor y establecer una prueba de capacidad

**Primera opción:** conservar erd-editor e integrar sus capacidades nativas de
Flow/enfoque/detalle cuando cubran la necesidad. Añadir mapa de módulos y estado
de vistas por fuera del componente, mediante una interfaz de integración acotada.
El Shadow DOM cerrado impide resolver esto simplemente con CSS externo.

Antes de comprometer la implementación, comprobar en un prototipo aislado:

- Cómo seleccionar un conjunto exacto, no solo toda su vecindad automática.
- Si se pueden filtrar tipos de FK/hubs sin mutar el documento.
- Cómo conservar posiciones, cámara y modo de filas por vista.
- Si el renderer permite los resúmenes de módulos y de FK paralelas.
- Si permite inspección accesible de extremos y anclaje por columnas.
- Cómo exponer estas funciones sin simular atajos ni atarse a acciones internas
  inestables de la versión minificada.

**Si las capacidades nativas no cubren esas pruebas:** incorporar un canvas de
análisis separado. React Flow con tarjetas propias y un adaptador ELK es el
candidato inicial para un subgrafo acotado; mantener el editor/importador actual
para editar y obtener el modelo completo. Esto requiere introducir compilación
y dependencias frontend, con un coste mayor que la aplicación estática actual.

No elegir React Flow por una supuesta superioridad de rendimiento sin medir.
Su [guía de rendimiento](https://reactflow.dev/learn/advanced-use/performance)
recomienda limitar renderizados, desacoplar suscripciones y plegar nodos; también
ofrece [renderizado de elementos visibles](https://reactflow.dev/api-reference/react-flow).
Cytoscape.js es otra opción para mapas de conectividad densos, según sus
[consideraciones de rendimiento](https://js.cytoscape.org/#performance), pero las
filas HTML y los puertos de columna exigen evaluar otro diseño de tarjetas.
No usar dos motores de análisis en la primera versión sin necesidad demostrada.

No migrar todo a ChartDB/drawDB ni copiar sus fuentes para obtener un estilo.
La elección es por capacidades de navegación y mantenimiento, no por apariencia.

## 9. Rendimiento y persistencia para tamaños mayores

127 tablas es el caso real inicial, no el límite de diseño. Probar además
1000 tablas/5000 FK y 5000 tablas/25000 FK sintéticas, con versiones de alta
concentración en hubs, claves compuestas y componentes desconectados.
Estos tamaños son objetivos de ensayo, no prestaciones ya garantizadas.

- Parseo e índices una vez por cambio relevante, no por movimiento de cámara.
- Listas de tablas/columnas virtualizadas cuando crezcan.
- Dibujar únicamente el subgrafo visible y su contexto cercano.
- No crear controles HTML para miles de columnas fuera de vista.
- Cálculos de grupos, rutas y layout en worker, con cancelación/versionado.
- Vecindarios mediante índices de adyacencia; rutas mínimas acotadas, sin
  enumeración exponencial de todos los caminos simples.
- Layout inicial de módulos antes de calcular detalles que quizá no se abrirán.
- Guardado diferido fuera del gesto de arrastre. Evaluar IndexedDB para documentos
  grandes; migrar el guardado existente de forma reversible si se decide usarlo.
- Huella/versionado del modelo; vistas guardadas referencian identificadores
  estables, apoyados en esquema/nombre cualificado, no solo IDs aleatorios nuevos.
- Al reimportar, informar tablas renombradas/eliminadas y referencias de vistas
  que no pueden reconciliarse; no asociarlas por parecido silenciosamente.

Objetivos iniciales de aceptación en el equipo de referencia, por medir:

- Respuesta visual de selección/filtro con p95 < 100 ms una vez indexado el grafo.
- Layout del módulo típico sin bloquear el hilo principal; progreso y cancelación
  cuando dure más de un segundo. No se promete un tiempo global fijo para todo DDL.
- Pan/zoom de vistas acotadas cerca de 60 fps en condiciones de prueba acordadas.
- Cero desapariciones silenciosas de tablas/FK y cero pérdida del documento.

Registrar hardware, tamaño, distribución del grafo y escenario antes de publicar
resultados. Un esquema de 127 tablas de 4 columnas no equivale a uno con 1189.

## 10. Desarrollo por entregas

| Entrega | Trabajo | Resultado verificable |
| --- | --- | --- |
| 0. Contrato visual y prueba de motor | Medir el grafo; prototipo aislado de foco, subconjuntos, filas y persistencia con el motor actual. Comparar alternativa solo donde falle. | Decisión documentada de integración, sin reescribir el parser ni cambiar el esquema. |
| 1. Alivio inmediato | Nombres/claves/columnas, foco de una tabla, separación de paneles, resaltar y fijar una relación, ajuste al contexto visible. | Abrir lots y leer sus relaciones sin recorrer el mapa global. |
| 2. Módulos y referencias transversales | Grupos revisables, mapa agregado, resumen de hubs, conteos de lo visible y oculto. | Las 127 tablas son accesibles desde nueve módulos propuestos, sin pintar 427 FK al entrar. |
| 3. Distribución estable | Layout por módulo/ruta, puertos, canales ortogonales, posiciones fijadas y deshacer reordenamiento. | No hay tarjetas superpuestas ni saltos globales al seleccionar o filtrar. |
| 4. Análisis y vistas | Origen/destino, rutas, inspector de FK compuestas, guardar y restaurar vistas. | Encontrar payments → commercial_operations → lots con sus columnas exactas. |
| 5. Escala y accesibilidad | Workers, virtualización, persistencia y benchmark; teclado y pantallas pequeñas. | Pruebas con modelos mayores y tareas reales sin pérdida de entidades ni bloqueo. |

Cada entrega conserva las verificaciones de importación ya existentes. Una
mejora visual no debe convertir una importación parcial en un éxito aparente.

## 11. Criterios de aceptación de producto

1. En la entrada se entienden los módulos y el total importado sin leer nombres
   de 127 tablas en miniatura ni ver las 427 conexiones.
2. Buscar payments y enfocar su contexto requiere como máximo búsqueda y una acción.
3. Una FK seleccionada permite leer origen/destino/pares de columnas en el inspector,
   incluso si su línea está agregada o un extremo queda fuera del viewport.
4. Las 281 FK compuestas del ejemplo conservan el orden y la pareja de sus columnas.
5. Se pueden revelar las 215 referencias hacia organizations/memberships resumidas;
   el contador explica el filtro y cambiar de vista no las elimina.
6. Una expansión de dos saltos desde lots muestra de antemano sus 112 tablas
   potenciales y ofrece acotar el contexto; no las carga silenciosamente.
7. Seleccionar un nodo no reordena todo el diagrama. Volver restaura la cámara.
8. Ningún filtro modifica el total canónico de 127 tablas/1189 columnas/427 relaciones.
9. El usuario distingue «sin relación» de «relación fuera de los filtros actuales».
10. Una prueba de uso permite responder, sin seguir líneas a mano: de qué depende
    una tabla, quién la referencia y cómo conecta con otra. Medir errores y tiempo
    frente a la vista actual antes de dar el rediseño por mejorado.

## 12. Prioridades y exclusiones

Prioridad máxima: foco y control de conexiones; después mapa de módulos y layout
estable; finalmente rutas avanzadas y ajuste de escala.

No incluir en esta fase: dashboards de registros, consultas contra una base real,
reconstrucción de flujos de negocio a partir de FK, inferir relaciones no
existentes, colaboración en nube, animaciones decorativas ni una conversión UML
con métodos/herencia. El objeto de análisis sigue siendo el esquema de la base.

La maqueta que acompaña esta propuesta ilustra navegación y lectura con datos
estructurales del SQL local. No constituye un nuevo renderer integrado ni una
prueba de rendimiento del futuro frontend.

Se verificaron en esa maqueta el enfoque de payments, el mapeo de sus columnas
hacia commercial_operations y la ruta payments → commercial_operations → lots.
También se revisó una pantalla estrecha de 360 px sin desbordamiento horizontal.
