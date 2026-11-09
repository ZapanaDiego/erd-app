# Vendor

## erd-editor.umd.js

- Paquete: `@dineug/erd-editor`
- Versión: `4.2.0`
- Origen: https://cdn.jsdelivr.net/npm/@dineug/erd-editor@4.2.0/dist/erd-editor.umd.js
- Fecha de descarga: 2026-10-26
- SHA-256: `7e455758efc0f4103340b86004ce25c9b40f1302743c09d9f279cacdf3e0cbc9`
- Licencia: MIT (ver `LICENSE.erd-editor.txt`)

No modificar este archivo. Para actualizar, descargar la nueva versión y
actualizar el hash de este README.

## elk.bundled.js

- Paquete: `elkjs`, versión `0.10.0`.
- Origen: https://cdn.jsdelivr.net/npm/elkjs@0.10.0/lib/elk.bundled.js
- Descarga: 2026-10-28.
- SHA-256: `48d338d5aeddd9503ccf1d12661c11b5d7d43c6afc5f66c7ddb2ea4170c0f6bf`.
- Licencia: Eclipse Public License 2.0 (`LICENSE.elkjs.txt`).
- Código fuente y procedencia: https://github.com/kieler/elkjs/tree/v0.10.0

Se usa sin modificar, desde `analysis/worker.js`. El layout se calcula localmente;
no hay llamadas a servicios remotos ni dependencias CDN durante el uso de la app.

### Worker de ELK

- Archivo: `elk-worker.min.js`, mismo paquete `elkjs@0.10.0` y licencia EPL-2.0.
- Origen: https://cdn.jsdelivr.net/npm/elkjs@0.10.0/lib/elk-worker.min.js
- SHA-256: `cda1839e26f82a7ac142692ee813974f8f359987348d21d1f16af8f86ff96e80`.
- Se incluye sin modificar para ejecutar ELK desde el worker de análisis.
