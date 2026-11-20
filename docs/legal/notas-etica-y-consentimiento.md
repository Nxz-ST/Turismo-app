# Notas para el documento de ética y textos de consentimiento

**Fecha:** 13 de noviembre de 2026 · Documento interno, no se publica en la app.

## 1. Textos cortos para la app

**Registro (checkbox obligatorio, sin marcar por defecto):**
> ☐ Tengo 18 años o más y acepto los [Términos y condiciones] y la
> [Política de privacidad]. Entiendo que mis fotos y su ubicación se usarán
> para validar lugares turísticos y que, si se aprueban, se publicarán como
> "Comunidad RutaAmiga", sin mi nombre.

**Checkbox opcional (separado):**
> ☐ Acepto que mis aportes se usen, de forma anónima y agregada, en la
> investigación académica de RutaAmiga.

**Antes del primer aporte (una sola vez):**
> Tu foto y su ubicación se analizan para confirmar el lugar. Un miembro del
> equipo la revisa antes de publicarla. Puedes aparecer tú; otras personas solo de fondo o con su permiso, y ningún menor en primer plano.

**Textos de permisos (Info.plist), propuestos:**

- **Cámara:** "Usamos la cámara para que fotografíes el lugar turístico que
  quieres aportar. Las fotos se revisan antes de publicarse."
- **Galería:** "Puedes elegir una foto de tu galería de una visita al lugar.
  Solo se sube la foto que selecciones."
- **Ubicación al usar la app:** "Usamos tu ubicación para mostrarte lugares
  cercanos y ubicar el lugar que aportas. No mostramos tu ubicación a otros
  usuarios."
- **Guardar en galería** (`NSPhotoLibraryAddUsageDescription`): borrarlo si la
  app no guarda imágenes en el carrete. Hoy no se encontró ese uso.

## 2. Argumentos para el comité de ética (verificados en el código)

| Riesgo | Mitigación que ya existe |
|---|---|
| Exposición del aportante | Las fotos públicas se atribuyen a "Comunidad RutaAmiga" (`app/api/routes/maps.py`). |
| Rastreo de la ubicación del usuario | La presencia solo respalda aportes durante 24 h y se borra a las 72 h; se puede desactivar en el perfil. La ubicación personal no se publica. |
| Fotos accesibles por cualquiera | Bucket R2 privado con URLs firmadas de 15 min (60 min en la galería). |
| Acceso entre usuarios | RLS activado; cada usuario lee solo sus registros. |
| Decisión automática injusta | La IA solo da un resultado preliminar; todo se publica tras revisión humana, con bitácora de auditoría. |
| Agencias con datos del turista | La agencia ve el código, el lugar y el estado, no el nombre, correo ni teléfono. |
| Uso comercial de datos | No hay publicidad, venta de datos ni SDK de analítica o marketing. |

## 3. Lo que falta para que la política sea cierta (pendientes técnicos)

Prioridad alta:

1. **Pantalla de aceptación en el registro.** Hoy no hay checkbox de términos
   ni de privacidad. Guardar la versión aceptada y la fecha.
2. **Eliminar los metadatos EXIF** de la foto antes de subirla. Hoy se
   recomprime al 85% y a 1600 px como máximo, pero no se verificó que se borren
   el GPS ni el modelo del teléfono incrustados en el archivo.
3. **Eliminación de cuenta y de aportes.** No existe en la app ni en el
   backend. Para el piloto basta con atender pedidos por correo, pero Apple y
   Google exigen borrar la cuenta desde la app para publicarla en tiendas.
4. **`NSAllowsArbitraryLoads = true`** en `Info.plist` permite HTTP sin cifrar.
   La política dice "conexión cifrada": hay que servir el backend por HTTPS y
   quitar esta excepción.

Prioridad media:

5. Borrado programado de las muestras de presencia. Hoy solo se limpian
   cuando el usuario registra una nueva.
6. Definir plazos de retención de los aportes rechazados y del piloto.
7. Que la consulta de canjes de la agencia no devuelva `user_id` (hoy trae `*`).
8. Revisar si la foto, con sus coordenadas, que se envía al servicio de IA se
   guarda en ese servicio, e indicar dónde está alojado.
9. Desenfoque de rostros o un aviso al revisor (opcional).

Trámite:

10. Evaluar la inscripción del banco de datos en el Registro Nacional de
    Protección de Datos Personales (ANPD), o confirmar con el asesor si el piloto
    académico está exceptuado.
11. Completar el responsable, la universidad, el correo de contacto y los plazos
    marcados con `[ ]`.
