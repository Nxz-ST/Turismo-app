# Plan de pruebas funcionales — RutaAmiga

## Objetivo

Validar con cinco participantes que RutaAmiga permite descubrir, aportar, corroborar y planificar visitas a lugares turísticos oficiales y comunitarios. No se busca demostrar que cualquier paisaje es turístico; se evalúa el flujo tecnológico, la trazabilidad y la comprensión del usuario.

## Organización

- Participantes: 5 personas.
- Casos: 10 casos ejecutados por todos los participantes (50 ejecuciones).
- Dispositivos: Android físico y simulador iOS, según disponibilidad.
- Datos: atractivos oficiales MINCETUR y fichas controladas del piloto.
- Evidencia: captura de pantalla, resultado observado, tiempo, incidencias y comentario breve.
- Criterio global: al menos 90 % de ejecuciones satisfactorias y cero fallos bloqueantes.

## Casos

| ID | Caso | Acción principal | Resultado esperado | Indicador |
|---|---|---|---|---|
| CP-01 | Inicio y permisos | Iniciar sesión y aceptar/denegar ubicación | La app explica el permiso y sigue operativa sin pantalla bloqueada | Éxito, tiempo |
| CP-02 | Explorar oficiales | Buscar una zona y abrir un atractivo MINCETUR | Mapa, tarjeta y detalle muestran información coherente | Éxito, claridad |
| CP-03 | Explorar comunitarios | Activar RutaAmiga y abrir una ficha corroborada | Se visualizan fotos, respaldo, datos de campo y aviso no oficial | Éxito, comprensión |
| CP-04 | Aportar lugar nuevo | Tomar/subir foto con ubicación en un escenario controlado | La evidencia queda enviada y presenta estado comprensible | Éxito, tiempo, errores |
| CP-05 | Aportar a existente | Aportar desde una ficha ya registrada | El aporte se vincula a la ficha y no crea un duplicado visible | Vinculación correcta |
| CP-06 | Validación administrativa | Revisar evidencia, categoría, señales y decidir | La decisión queda trazada y la app muestra un mensaje público, no técnico | Decisión y trazabilidad |
| CP-07 | Cuestionario posvalidación | Abrir la app después de validar un lugar | Aparece el recordatorio y se guardan acceso, dificultad, servicios y riesgos | Completitud |
| CP-08 | Mi viaje mixto | Añadir un lugar oficial y uno comunitario | Ambos aparecen en Mi viaje, se pueden ordenar y abrir como ruta | Éxito y consistencia |
| CP-09 | Reportar un cambio | Reportar cierre, riesgo, ubicación o información desactualizada | El panel recibe la alerta y permite revisarla, resolverla o descartarla con nota | Trazabilidad |
| CP-10 | Recuperación de errores | Probar conexión lenta/sin red y reintentar | Se muestran carga, error y reintento sin datos técnicos ni pantalla vacía | Recuperación |

## Datos a registrar por ejecución

| Campo | Descripción |
|---|---|
| Participante | Código P01 a P05, sin nombres personales |
| Dispositivo | Modelo, sistema y versión |
| Resultado | Satisfactorio / Parcial / Fallido |
| Tiempo | Segundos desde inicio hasta resultado |
| Ayuda | Sí/No y qué indicación necesitó |
| Incidencia | Descripción reproducible |
| Evidencia | Nombre de captura o video |
| Observación | Comentario del participante |

## Métricas para la tesis

- Tasa de éxito por caso y general.
- Tiempo promedio y mediana por tarea.
- Porcentaje de tareas completadas sin ayuda.
- Duplicados evitados por consolidación.
- Fichas comunitarias publicadas y enriquecidas.
- Personas aportantes únicas.
- Cuestionarios de campo completados.
- Alertas ciudadanas resueltas.
- Casos con presencia GPS y señales geoespaciales disponibles.
- Errores bloqueantes, no bloqueantes y observaciones de usabilidad.

## Separación de responsabilidades

- El participante aporta evidencia y evalúa usabilidad.
- El sistema clasifica y contrasta señales.
- El administrador toma la decisión humana y deja una nota.
- La ficha comunitaria indica que no reemplaza un registro oficial.
- MINCETUR/PROMPERÚ pueden evaluar utilidad, calidad de datos y posibles criterios futuros; no se afirma integración institucional.

## Trabajo futuro fuera del alcance de esta versión de tesis

HTTPS y dominio definitivo, publicación en tiendas, notificaciones push, escalado de infraestructura, monitoreo productivo y acuerdos formales con instituciones.
