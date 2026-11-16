# RutaAmiga — Contexto integral del workspace para continuar el proyecto

> Documento de traspaso generado el 11 de noviembre de 2026 a partir de la conversación de desarrollo, el estado local de los repositorios y una revisión no destructiva del servidor.

## 1. Cómo debe usar Claude este documento

Este archivo resume el conocimiento acumulado sobre RutaAmiga. Antes de cambiar algo:

1. Inspeccionar el código actual; este documento describe intención y estado conocido, pero el código es la fuente final de verdad.
2. Preservar todos los cambios locales sin commit. No ejecutar `git reset --hard`, `git checkout --`, limpiezas masivas ni sobrescribir archivos del usuario.
3. No copiar, imprimir ni incluir en respuestas el contenido de archivos `.pem`, `.env`, tokens, claves de Supabase, R2, Google o AWS.
4. Distinguir siempre entre “implementado localmente”, “SQL ejecutado” y “desplegado en AWS”. Verificar antes de afirmar que una funcionalidad está publicada.
5. El sistema es un prototipo de tesis. No presentar una corroboración comunitaria como reconocimiento turístico oficial.
6. Los errores técnicos de Supabase, PostgREST, SQL, stack traces y respuestas internas nunca deben mostrarse literalmente al usuario final.

## 2. Resumen ejecutivo

RutaAmiga es una aplicación móvil de exploración turística colaborativa orientada al Perú. Combina:

- Datos oficiales de atractivos turísticos, principalmente MINCETUR.
- Descubrimientos comunitarios aportados mediante fotografía y ubicación GPS.
- Un motor multimodal que analiza la evidencia visual, semántica y geoespacial.
- Flujos de corroboración, duplicidad, revisión humana y enriquecimiento progresivo de fichas.
- Exploración en mapa, rutas, planificación, perfil del viajero y pasaporte de confianza.
- Un panel administrativo para revisar evidencias, coordenadas, auditoría y, en desarrollo, beneficios de agencias.
- Una maqueta funcional de beneficios/descuentos ofrecidos por agencias turísticas.

La propuesta no consiste en declarar automáticamente que cualquier paisaje es un atractivo turístico. El producto identifica evidencia coherente y la presenta como descubrimiento comunitario sujeto a confirmación, diferenciándolo de un registro oficial.

## 3. Objetivo del proyecto y problema abordado

### Problema

Existen lugares con potencial turístico que tienen baja visibilidad digital, información incompleta o datos dispersos. También existe riesgo de confundir una escena natural privada o cotidiana con un atractivo turístico accesible y real.

### Objetivo

Permitir que visitantes aporten fotografías geolocalizadas, validar la coherencia de la evidencia con IA y señales geoespaciales, detectar coincidencias o duplicados y construir progresivamente una ficha comunitaria útil para otros viajeros.

### Principio de confianza

RutaAmiga debe comunicar distintos niveles de certeza:

- **Registro oficial MINCETUR:** fuente institucional.
- **Corroborado por RutaAmiga:** evidencia visual y ubicación coherentes, respaldadas por personas; no equivale a oficialidad.
- **Posible nuevo atractivo / candidato:** requiere más respaldo o revisión.
- **Necesita revisión:** señales insuficientes, contradictorias o ambiguas.
- **Duplicado o aporte a lugar existente:** la nueva evidencia debe enriquecer una ficha en lugar de crear otra.

## 4. Entidades y actores

### Viajero

- Explora atractivos oficiales y comunitarios.
- Aporta fotografías y ubicación.
- Completa información de campo del lugar.
- Guarda lugares, crea viajes y consulta rutas.
- Registra recuerdos privados y reporta cambios o riesgos.
- Puede activar beneficios de agencias en la maqueta funcional.

### Administrador o revisor

- Revisa evidencias, contradicciones, duplicados y casos de baja cobertura.
- Revisa o corrige coordenadas.
- Consulta trazabilidad, eventos y tiempos de decisión.
- No debe ver información técnica cruda como sustituto de mensajes operativos.

### Agencia turística

- En el concepto futuro, aporta información logística y conocimiento de campo.
- Puede publicar experiencias o descuentos vinculados a atractivos.
- Debe tener un rol limitado para consultar y validar códigos de beneficios, sin acceso al panel administrativo completo.

### Fuentes externas

- MINCETUR: datos de atractivos oficiales.
- Google Maps/Places/Routes: fotografías, servicios cercanos, rutas y mapas según disponibilidad.
- Supabase: autenticación y base de datos.
- Cloudflare R2: almacenamiento de evidencias fotográficas.
- AWS EC2: backend, panel y motor IA.
- Sentinel/relieve/otras señales: apoyo geoespacial; nunca deben ser la única prueba de validez turística.

## 5. Repositorios y rutas locales

### Aplicación Flutter

Ruta:

```text
/Users/sebastianchinchaycollachagua/turismo_app
```

Rama conocida: `main`  
Último commit conocido: `bbaf12d feat: completa trazabilidad y estados de experiencia`

APK existentes:

```text
/Users/sebastianchinchaycollachagua/turismo_app/build/app/outputs/apk/release/app-release.apk
/Users/sebastianchinchaycollachagua/turismo_app/build/app/outputs/flutter-apk/app-release.apk
/Users/sebastianchinchaycollachagua/turismo_app/build/app/outputs/apk/debug/app-debug.apk
```

Cambios locales sin commit detectados:

```text
M android/app/build.gradle.kts
M config/env/development.android.json
M config/env/development.ios.json
M lib/core/widgets/connectivity_status_banner.dart
M lib/features/places/screens/community_place_detail_screen.dart
M lib/features/places/screens/tourist_place_detail_screen.dart
M pubspec.yaml
?? docs/architecture/rutaamiga-arquitectura-integral-v2.png
?? docs/architecture/rutaamiga-arquitectura-software-v3.png
?? docs/architecture/rutaamiga-arquitectura-tecnologica-v4.png
?? lib/features/benefits/
?? test/tourism_benefits_flow_test.dart
```

### Backend FastAPI

Ruta:

```text
/Users/sebastianchinchaycollachagua/turismo_backend
```

Rama conocida: `main`  
Último commit conocido: `db95aea feat: agrega carga de revisores y tiempos de decision`

Cambios locales sin commit detectados:

```text
M app/api/router.py
M app/services/auth.py
M app/services/google_maps.py
M app/services/supabase.py
?? app/api/routes/benefits.py
?? app/schemas/benefit.py
?? sql/016_agency_benefits.sql
```

### Panel web administrativo

Ruta:

```text
/Users/sebastianchinchaycollachagua/rutaamiga_admin
```

Tecnología: React + TypeScript + Vite. Esta carpeta no aparecía como repositorio Git independiente al momento de generar este documento.

Archivos principales:

```text
src/App.tsx
src/main.tsx
src/styles.css
src/types.ts
```

### Vault de Obsidian — memoria técnica y funcional

Ruta del vault:

```text
/Users/sebastianchinchaycollachagua/turismo_app/RutaAmiga-Vault
```

Claude CLI debe considerar este vault como el índice documental vivo de RutaAmiga. La lectura debe comenzar en:

```text
RutaAmiga-Vault/00 - Inicio.md
```

Notas disponibles:

```text
00 - Inicio.md
01 - Estado actual.md
02 - Producto y experiencia.md
03 - Arquitectura.md
04 - Aplicación Flutter.md
05 - Backend y API.md
06 - Base de datos.md
07 - Validación multimodal.md
08 - Decisiones.md
09 - Pendientes.md
10 - Operación y pruebas.md
11 - Variables de entorno.md
12 - Glosario.md
13 - Protocolo de contexto.md
```

También contiene:

- Diagrama de arquitectura en `Arquitectura/diagrama-arquitectura-final-rutaamiga.png`.
- Plan de pruebas revisado en `Pruebas/Plan_de_pruebas_RutaAmiga_v1.1_revisado.docx` y `.html`.
- Plantillas para actualización de estado y registro de decisiones.
- Configuración local de Obsidian en `.obsidian/`.

Reglas propias del vault:

1. No guardar contraseñas, tokens, claves API ni contenido real de `.env`.
2. Registrar decisiones importantes en `08 - Decisiones.md`.
3. Actualizar `01 - Estado actual.md` después de cambios funcionales relevantes.
4. Mantener `09 - Pendientes.md` con tareas verificables y retirar las terminadas.
5. Enlazar código y SQL por ruta; no copiar archivos completos dentro de las notas.
6. Cambiar la fecha `updated` de las notas modificadas.

Orden de fuente de verdad definido por el propio vault:

1. Código, migraciones y configuración efectiva.
2. Pruebas y comportamiento observado.
3. Notas del vault.
4. Conversaciones o ideas todavía no implementadas.

Advertencia: varias notas del vault fueron actualizadas por última vez entre el 25 y 26 de octubre de 2026. Por ejemplo, `01 - Estado actual.md` solo enumera como ejecutadas las migraciones 001–006, mientras que el proyecto ya llegó hasta la 016 y el usuario confirmó la ejecución de esta última. Claude debe usar el vault como índice, contrastarlo con este documento y con el código actual, y actualizarlo progresivamente sin borrar su historial.

## 6. Arquitectura desplegada conocida

### Instancia RutaAmiga

- IP conocida: `32.196.90.137`.
- Región: AWS `us-east-1`.
- Tipo: `m7i-flex.large`.
- 2 vCPU visibles, 7.6 GiB de RAM, sin GPU.
- Ubuntu 26.04 LTS.
- Nginx funciona como proxy público.

Acceso SSH conocido:

```bash
ssh -i /Users/sebastianchinchaycollachagua/Downloads/Claves_Prueba.pem ubuntu@32.196.90.137
```

No mostrar ni copiar el contenido del `.pem`.

### Backend orquestador

- Servicio systemd: `rutaamiga-backend.service`.
- Ruta desplegada: `/opt/rutaamiga-backend`.
- Venv: `/opt/rutaamiga-backend/.venv`.
- Uvicorn en `127.0.0.1:8001`, un worker.
- URL pública conocida de API: `http://32.196.90.137/api/v1`.
- Salud: `GET /api/v1/health`.

### Motor IA

- Servicio systemd: `turismo-api.service`.
- Ruta desplegada: `/home/ubuntu/motor-ia-turismo`.
- Venv usado por el servicio: `/home/ubuntu/turismo-deploy/venv-96661ed/`.
- Uvicorn en `127.0.0.1:8000`, un worker.
- No se expone directamente a Internet; lo consume el backend.
- Modelo: `/home/ubuntu/motor-ia-turismo/models/modelo_mobilenetv2_limpio_final.keras`.
- Ollama/Gemma local disponible.

Variables de ejecución del motor:

```text
CUDA_VISIBLE_DEVICES=-1
TF_NUM_INTRAOP_THREADS=2
TF_NUM_INTEROP_THREADS=1
OMP_NUM_THREADS=2
```

### Panel

URL conocida:

```text
http://32.196.90.137/admin/
```

### Segunda instancia AWS observada

En una captura apareció otra instancia `server-bidft`, tipo `t3.micro`, IP `52.22.215.252`. Se determinó que no pertenece al despliegue principal de RutaAmiga. No modificarla sin verificar propietario y propósito.

## 7. Flujo completo de aportes

El flujo público no llama directamente a `/predict`. Funciona así:

1. `POST /api/v1/uploads/presign` solicita URL firmada.
2. La app hace `PUT` de la imagen directamente a Cloudflare R2.
3. `POST /api/v1/evidences` crea la evidencia en Supabase.
4. `POST /api/v1/evidences/{id}/process` crea un trabajo de validación.
5. El backend descarga la imagen desde R2 y llama internamente al motor IA.
6. Se ejecuta análisis visual y semántico.
7. Se ejecuta la etapa geoespacial y la detección de duplicados.
8. Se persisten `validation_jobs`, `processing_events` y `validation_results`.
9. La app consulta `GET /api/v1/evidences/{id}` hasta un estado terminal.
10. Cuando corresponde, se ofrece el cuestionario de campo para enriquecer la ficha.

Estados observados o esperados:

```text
pending
processing_ai
processing_gis
candidate
needs_review
duplicate
validated
rejected
failed
```

### Comportamiento UX acordado

- Al pulsar “Enviar reporte”, la app no debe obligar al usuario a permanecer esperando en la pantalla. Debe confirmar recepción y permitir continuar mientras el procesamiento sucede en segundo plano.
- Nunca mostrar JSON, SQL, códigos de Supabase o mensajes como “failing row” al usuario.
- Mostrar mensajes comprensibles: evidencia recibida, ubicación comprobada, verificando lugar, resultado disponible.
- Cuando una evidencia queda validada/candidata, el cuestionario debe aparecer de forma visible y difícil de olvidar, mediante modal, prompt o bandeja de actividad.
- Si el lugar ya existe, la nueva evidencia debe alimentar la ficha existente en lugar de crear otra ficha aislada.
- La tarjeta completa de un lugar debe ser pulsable; no depender de una flecha pequeña.

## 8. Motor de IA: qué entra, qué sale y cómo decide

### Clases del modelo

El modelo contiene ocho clases:

```text
bosque
cascada
desierto
lago
montana
nevado
playa
volcan
```

Para demos se discutió evitar categorías difíciles de justificar, como volcanes o desiertos, pero siguen siendo clases reales del modelo. No eliminarlas sin reentrenamiento y ajuste integral.

### Preprocesamiento productivo

```text
Pillow RGB
→ resize 224×224 con LANCZOS
→ float32
→ MobileNetV2 preprocess_input
→ batch 1
```

El modelo se carga con `compile=False`.

### CNN

MobileNetV2 devuelve probabilidades para las ocho clases. La clase de mayor probabilidad es `clase_cnn`, con `confianza_cnn`.

### Embeddings

- Se crea un extractor cuya salida es la capa `embedding_dense`.
- La imagen genera un vector de 256 dimensiones.
- Se normaliza con norma L2.
- Se compara mediante similitud coseno con `embeddings_v2.pkl`.
- La base conocida contiene 6,812 embeddings.
- Los 15 vecinos más cercanos votan por clase, ponderados por similitud.
- Se devuelven `clase_embeddings`, similitud y los cinco ejemplos más cercanos.
- La clase de embeddings sí participa en la categoría final y su similitud aporta al puntaje.

### Gemma/Ollama

Modelo configurado: `gemma4:e2b-it-qat`.

Gemma recibe la fotografía original y un prompt estructurado. Devuelve JSON con:

- Clase turística, `no_turistico` o `dudoso`.
- Tipo de contenido: captura directa, pantalla, documento, contenido impreso u otro indirecto.
- Si el atractivo es visible.
- Visibilidad alta, media, baja o nula.
- Si las personas aparecen solo como contexto.
- Descripción breve de la escena.

Reglas conservadoras:

- Pantallas, documentos o impresiones no se aceptan como captura real.
- Si el atractivo no aparece, se considera no turístico.
- Baja visibilidad, oclusión o desenfoque llevan a dudoso.
- Una aceptación semántica débil puede degradarse cuando la CNN tiene confianza menor a 0.70.

### Fusión

Se vota entre:

1. Clase CNN.
2. Clase de embeddings.
3. Clase Gemma, solamente si Gemma considera la imagen turística.

Gana la mayoría; en empate se favorece la CNN. Si Gemma contradice la clase dominante, el caso puede pasar a revisión. La clase fusionada se utiliza para la búsqueda GIS y la decisión final.

### Categoría consistente entre aportes

Requisito funcional acordado: los aportes posteriores de una ficha deben ser coherentes con la categoría del lugar. Por ejemplo, una ficha de lago no debe fortalecerse automáticamente con una foto clasificada como bosque. En caso de diferencia, debe mostrarse una instrucción como:

> Solo podemos validar evidencia de la categoría lago para este lugar. Intenta fotografiarlo desde otro ángulo.

Antes de afirmar que esta regla está completa, verificar backend, app y pruebas actuales.

## 9. Geoespacial, Sentinel y límites de interpretación

El sistema combina coordenadas, altitud, cercanía a lugares conocidos, compatibilidad de subtipo, duplicidad y otras señales disponibles.

Sentinel o las señales ambientales pueden devolver valores bajos o cero por:

- Nubes o calidad de la observación.
- Resolución insuficiente.
- Fecha de la imagen satelital.
- Cobertura limitada.
- Diferencia entre el punto exacto y el área visible.

Un valor bajo de Sentinel no invalida por sí solo una fotografía legítima. Debe ser una señal auxiliar. Los casos con fotografía coherente pero señales ambientales débiles deben pasar a revisión humana o quedar como evidencia limitada, no rechazarse automáticamente.

Una laguna dentro de una urbanización no debe etiquetarse automáticamente como atractivo turístico solo por parecer un lago. Para hablar de potencial turístico se necesitan más datos: acceso, interés de visitantes, seguridad, autorización, infraestructura, recurrencia y respaldo comunitario.

## 10. Fichas oficiales y comunitarias

### Ficha oficial

Diseño inspirado en experiencias tipo Airbnb, pero con identidad RutaAmiga:

- Galería fotográfica protagonista.
- Barra superior sobre la imagen con volver, compartir y favorito.
- Etiqueta “Registro oficial MINCETUR”.
- Nombre, ubicación, categoría, distancia y altitud.
- Resumen útil, no copia cruda de la base.
- Pasaporte de confianza.
- Clima y servicios cercanos cuando estén disponibles.
- Actividades, mejor época y datos relevantes en bloques legibles.
- Botones persistentes “Cómo llegar” y “Aportar”.
- Acción “Añadir a mi viaje” integrada sin competir con las acciones principales.
- Recuerdo/valoración privada y reporte de cambios o riesgos.

### Ficha comunitaria

- Etiqueta “Descubrimiento comunitario”.
- Galería de fotografías aportadas.
- Número de fotos, aportes, personas y visitas GPS.
- Información estructurada de campo.
- Progreso de completitud de la ficha.
- Pasaporte de confianza con explicación clara.
- Historial de aportes sin duplicar visualmente la información principal.
- Botones “Cómo llegar” y “Aportar”.
- Debe permitir que futuras contribuciones fortalezcan la misma ficha.

### Cuestionario de campo

Los datos se presentan en bloques con iconos, no como un párrafo repetido:

- Acceso.
- Dificultad.
- Ingreso gratuito/pagado.
- Estado abierto/restringido/cerrado.
- Actividades.
- Servicios.
- Precauciones o riesgos.

La vista principal debe mostrar la información más reciente o consolidada. Las respuestas anteriores deben ir en una sección secundaria, evitando que parezca contenido duplicado.

## 11. Módulos de la aplicación Flutter

### Descubrir

- Contenido inicial, recomendaciones y accesos hacia exploración.
- Conceptos trabajados: “Viaja a tu manera” y “Perú por descubrir”.
- Estos accesos no deben limitarse a redirigir genéricamente a Explorar; deben abrir una experiencia filtrada, recomendación o colección comprensible.

### Explorar

- Mapa y lista/bottom sheet.
- Filtros `Todos`, `Oficiales` y `RutaAmiga`.
- `Todos` debe incluir tanto oficiales como comunitarios.
- En modo RutaAmiga, mostrar información visual completa, no tarjetas vacías o solo texto.
- La tarjeta completa debe abrir detalles.
- Resolver cualquier `RenderFlex overflow` en tarjetas estrechas.
- Debe respetar safe areas, barra de navegación de Android e iOS y Dynamic Island/notch.

### Rutas

- Rutas sugeridas y constructor personalizado.
- Estado activo de recorrido.
- Preparación de ruta, visitas y planificación.
- El diseño fue considerado demasiado plano en una etapa; se buscó reforzar jerarquía visual, imágenes, chips y progresión del recorrido.

### Aportar

- Registrar lugar nuevo o aportar a uno existente.
- Si la imagen y ubicación coinciden con una ficha existente, dirigir el aporte a esa ficha.
- Si es un descubrimiento nuevo, crear evidencia sin declarar oficialidad.
- Mostrar procesamiento asíncrono y seguimiento.

### Mi perfil

- Aportes propios.
- Actividad y pendientes.
- Mi viaje.
- Guardados.
- Pasaporte.
- Recomendaciones personalizadas.
- Comparación de lugares.
- Herramientas del explorador.

### Accesibilidad y conectividad

Existen servicios y widgets para:

- Mensajes de conectividad.
- Estados de carga, vacío y error.
- Guía inicial.
- Notificaciones locales.
- Accesibilidad.
- Persistencia o sincronización de acciones compatibles con modo offline.

No mostrar “Sin conexión” solo porque un servicio secundario falló. Diferenciar conectividad real de error de API, R2 o facturación de servicios externos.

## 12. Panel administrativo

El panel conocido se llama “Centro de validación”. Incluye o proyecta:

- Evidencias.
- Coordenadas.
- Revisores.
- Auditoría.
- Configuración.

La vista de evidencias muestra métricas de candidatos, revisión y duplicados. Problemas históricos:

- Podía quedar cargando aunque el backend figuraba conectado.
- Debe manejar cero resultados y errores con mensajes claros.
- El mapa de “Punto de captura” usa Leaflet/OpenStreetMap. Se preguntó si podía usar Google Maps; es posible, pero implica API, facturación y términos. No cambiar sin evaluar costo y configuración.

Mejoras recomendadas para tesis:

- Filtros por estado, categoría, fecha y cobertura.
- Detalle de señales y trazabilidad por etapa.
- Historial de decisiones humanas.
- Métricas de tiempos de procesamiento y tasa de contradicción.
- Gestión limitada de agencias y beneficios.
- Exportación de evidencia para análisis de tesis.

## 13. Beneficios y agencias turísticas

### Idea funcional

En el detalle de un atractivo se muestran experiencias ofrecidas por agencias:

- Agencia.
- Experiencia.
- Duración.
- Incluye movilidad, guía u otros servicios.
- Precio normal y precio con beneficio.
- Porcentaje de descuento.
- Condiciones y vigencia.

El usuario activa un beneficio y recibe un código RutaAmiga. Como es una maqueta, debe indicarse que no representa una reserva o descuento comercial real.

### Evolución deseada

El código no debe depender únicamente de un código de barras, porque la agencia puede no tener lector. Flujo propuesto:

1. El usuario activa el beneficio.
2. El código queda persistido en la base.
3. La agencia inicia sesión con rol limitado.
4. Introduce o escanea el código desde una vista web simple.
5. El sistema muestra válido, vencido o utilizado.
6. La agencia confirma el canje.
7. Se registra fecha, agencia y operador.

WhatsApp puede servir para contacto o reserva rápida, pero no debe ser la fuente de verdad del canje.

### Estado conocido

- Existe `sql/016_agency_benefits.sql`.
- El usuario confirmó haber ejecutado la migración 016.
- Hay implementación local sin commit en app y backend.
- Verificar si las rutas nuevas y el panel de agencia fueron desplegados antes de probarlos en producción.

## 14. Esquema y migraciones Supabase

Migraciones locales conocidas:

```text
001_backend_schema.sql
002_multimodal_scoring.sql
003_presence_verification.sql
004_processing_events.sql
005_official_coordinate_corrections.sql
006_fix_nearby_places_rpc.sql
007_route_visits_passport.sql
008_existing_place_contributions.sql
009_user_travel_state.sql
010_place_condition_reports.sql
011_coordinate_quality_audit.sql
012_community_places_trust_passport.sql
013_evidence_duplicate_statuses.sql
014_community_profile_events.sql
015_place_issue_reports.sql
016_agency_benefits.sql
```

Tablas o conceptos relevantes observados:

- `evidences`.
- `validation_jobs`.
- `processing_events`.
- `validation_results`.
- `community_places`.
- Lugares turísticos oficiales.
- Visitas de ruta y pasaporte.
- Estado de viaje del usuario.
- Reportes de condición/riesgo.
- Auditoría de coordenadas.
- Beneficios, agencias y canjes, según migración 016.

## 15. Datos oficiales, agencias y recopilación de información

Se investigó una agencia llamada NASSF Travel (`https://nassftravel.com/`) como posible fuente de conocimiento, no como cliente directo de una solución hecha exclusivamente para ella.

La utilidad de una agencia para RutaAmiga sería:

- Confirmar qué lugares visitan realmente.
- Informar accesos, tiempos, costos, temporada, riesgos y servicios.
- Identificar puntos frecuentados que no estén bien representados en la data oficial.
- Aportar fotografías autorizadas y conocimiento operativo.
- Validar si un supuesto descubrimiento tiene flujo real de visitantes.

Preguntas directas útiles para una CEO/agencia:

1. ¿Qué lugares visitan que no aparecen o aparecen incompletos en los registros oficiales?
2. ¿Qué coordenadas, accesos y tiempos reales manejan para esos lugares?
3. ¿Qué riesgos, restricciones o temporadas deben conocer los viajeros?
4. ¿Qué servicios existen realmente y cuáles faltan?
5. ¿Pueden compartir fotografías propias y datos de recorridos con autorización?
6. ¿Aceptarían validar información o probar beneficios para usuarios de RutaAmiga?

Beneficio posible para la agencia: visibilidad dentro de las fichas, derivación de viajeros interesados, presencia en experiencias y métricas agregadas de interés; nunca prometer ventas garantizadas.

## 16. Datos demo y ética

Se discutió crear datos de demostración que parezcan una comunidad activa. La decisión responsable es:

- Mantenerlos identificados como demo/prueba en base de datos.
- No presentarlos como aportes reales de personas reales.
- Usar cuentas técnicas o perfiles ficticios claramente marcados internamente.
- No falsificar visitas GPS reales ni atribuir fotografías a personas inexistentes.
- Conservar los datos demo en tablas, usuarios o marcadores separables para poder eliminarlos.
- Usar fotografías con permiso o licencia compatible y registrar fuente/licencia.

El usuario planteó carpetas de fotografías por lugar y varios aportes por categoría. Antes de poblar datos, validar que el lugar no esté ya registrado, que sea visitado turísticamente y que las coordenadas e imágenes correspondan realmente al mismo sitio.

No usar fotografías descargadas arbitrariamente de Internet sin verificar derechos. No convertir una simulación en evidencia científica real.

## 17. Lugares y casos discutidos

Se analizaron o mencionaron, entre otros:

- Lago Zapote.
- Lago Juanachi o Moena.
- Bosque Pumayacu/Pumayaku: se comprobó que sí aparecía en un registro turístico oficial mostrado por el usuario.
- Cascadas del Chullachaqui, Tarapoto, San Martín: se consideró para una prueba de categoría cascada; verificar registro oficial y coordenadas antes de usar.
- Lago Soledad: hubo aportes repetidos y señales ambientales/relieve bajas; se decidió no interpretar esas señales como rechazo automático.
- Laguna Prueba 2 y Cascada Arampampa: fichas comunitarias utilizadas durante pruebas del flujo y diseño.
- Tobogán Natural de Songos y otros atractivos oficiales de Huarochirí: usados para probar la vista de detalle.

## 18. Diseño y lenguaje visual

Identidad visual general:

- Verde oscuro y tonos naturales para oficiales y navegación principal.
- Morado para descubrimientos comunitarios/corroborados.
- Fondos claros cálidos.
- Tarjetas redondeadas, iconografía simple y fotografías protagonistas.
- Evitar pantallas compuestas únicamente por párrafos y cajas iguales.
- Crear jerarquía clara: fotografía → identidad/confianza → información esencial → acciones → detalles secundarios.

Principios acordados:

- Interfaces modernas y algo futuristas, pero comprensibles.
- Acciones importantes con áreas táctiles grandes.
- No colocar demasiadas acciones equivalentes en la barra inferior.
- Compartir y favorito deben estar sobre la imagen o en la cabecera.
- “Cómo llegar” es acción principal; “Aportar” secundaria persistente.
- Usar mayúscula inicial y normalización de nombres ingresados por usuarios.
- Evitar texto repetido entre resumen comunitario e historial.
- Usar skeletons, placeholders y estados vacíos para evitar pantallas blancas.
- Todas las vistas deben ser responsive y respetar safe areas de Android e iOS.

## 19. Pruebas y problemas ya observados

Problemas históricos que deben permanecer cubiertos:

- Pantalla negra al instalar un APK compartido.
- App mostrando “Sin conexión” aunque el problema era facturación o servicio externo.
- Imágenes que no cargaban.
- Panel cargando indefinidamente.
- Error Supabase 400 mostrado literalmente al usuario.
- Formulario que desaparecía o no se abría después de una validación.
- Tarjetas con `BOTTOM OVERFLOWED` en iOS.
- Vista de detalle comunitaria en blanco.
- Botón o chip “Mi viaje” colocado de forma extraña.
- Datos comunitarios mostrados como un párrafo largo y repetido.
- Tarjetas que solo abrían detalle al tocar una flecha pequeña.
- Estado duplicado o ficha repetida visualmente.
- Primera carga lenta de imágenes.

La aplicación fue ejecutada en emulador iPhone 16 Plus con iOS 18.5 y también se generaron APK Android. No asumir que todas las correcciones visuales continúan perfectas después de cambios posteriores; volver a probar tamaños pequeños.

## 20. Presentación y enfoque institucional

La presentación a docentes, agencias, MINCETUR o PROMPERÚ debe ser breve y enfocada en:

1. Introducción: baja visibilidad e información dispersa de lugares.
2. Problemática: dificultad para descubrir, verificar y mantener información útil.
3. Objetivo: plataforma colaborativa con validación multimodal.
4. Propuesta: app, motor IA, geolocalización, comunidad y panel de revisión.
5. Arquitectura: Flutter, FastAPI, Supabase, R2, AWS, MobileNetV2, embeddings, Gemma y GIS.
6. Flujo de usuario: descubrir, aportar, validar, enriquecer y planificar.
7. Diferenciación: oficial vs comunitario, trazabilidad y confianza.
8. Evidencia: pruebas físicas y resultados de desempeño.
9. Valor institucional: actualización de campo, detección de vacíos de información y datos estructurados; no reemplazo de la autoridad oficial.
10. Trabajo futuro: pilotos, convenios, seguridad, HTTPS y escalamiento.

## 21. Prioridades recomendadas antes de cerrar la tesis

1. Preservar y versionar los cambios locales actuales.
2. Verificar qué parte del módulo de beneficios está realmente desplegada.
3. Ejecutar pruebas Flutter, backend y flujo visual en Android/iOS.
4. Confirmar que `Todos` mezcla oficiales y RutaAmiga sin duplicados.
5. Probar creación de lugar, aporte a lugar existente y categoría contradictoria.
6. Probar formulario automático después de candidato/validado.
7. Probar estados offline, error de R2, error de API e imágenes faltantes.
8. Revisar accesibilidad, safe areas y overflow en pantallas pequeñas.
9. Añadir una política clara para datos demo y limpieza.
10. Documentar limitaciones: prototipo, HTTP temporal, una sola instancia, CPU, dependencia de servicios externos y ausencia de validación institucional automática.

## 22. Comandos de trabajo habituales

### Flutter

Revisar el archivo de entorno correcto antes de ejecutar; no imprimir sus secretos.

```bash
cd /Users/sebastianchinchaycollachagua/turismo_app
flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk --release
```

### Backend local

```bash
cd /Users/sebastianchinchaycollachagua/turismo_backend
source .venv/bin/activate
pytest
```

### Panel

```bash
cd /Users/sebastianchinchaycollachagua/rutaamiga_admin
npm install
npm run build
```

No desplegar automáticamente sin comprobar diferencias locales, servicio destino y autorización del usuario.

## 23. Definición corta para Claude

RutaAmiga no es solo un mapa turístico. Es un sistema de evidencia comunitaria que combina fotografía, ubicación, IA visual, análisis semántico, señales geoespaciales, detección de duplicados y revisión humana para descubrir y mantener fichas de lugares, separando claramente los registros oficiales de los descubrimientos corroborados por la comunidad.

La prioridad de cualquier cambio debe ser aumentar confianza, claridad y trazabilidad sin inventar oficialidad, visitantes, coordenadas, derechos sobre imágenes ni resultados técnicos.
