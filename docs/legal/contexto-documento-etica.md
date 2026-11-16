# Contexto para redactar el documento de ética · RutaAmiga

> **Para Claude Desktop:** este archivo resume qué es RutaAmiga, qué datos
> trata, cómo protege a las personas y qué consentimiento pide. Úsalo para
> redactar las secciones éticas del documento de tesis (consideraciones
> éticas, consentimiento informado, privacidad y protección de datos, riesgos
> y mitigaciones). Al final están los textos completos de los **Términos y
> condiciones** y la **Política de privacidad**, que van como **Anexo A** y
> **Anexo B**. No inventes medidas que no estén aquí.

## 1. Proyecto y responsables

- **Proyecto:** RutaAmiga, aplicación móvil de turismo para **Android**,
  distribuida como archivo APK directamente a los participantes del piloto
  (no está publicada en tiendas de aplicaciones), con backend propio y un
  panel web de revisión para el equipo.
- **Institución:** Universidad Peruana Unión, Lima, Perú.
- **Responsables:** Sebastián Chinchay y Daniel Calderón.
- **Contacto:** sebastian.chinchay@upeu.edu.pe
- **Etapa:** piloto académico, gratuito, sin publicidad ni fines comerciales.
- **Marco legal:** Ley N.° 29733, Ley de Protección de Datos Personales del
  Perú, y su Reglamento.

## 2. Qué hace la app

1. Permite descubrir atractivos turísticos del Perú y planificar rutas.
2. Las personas pueden **aportar fotos de lugares naturales** (cámara o
   galería), con su ubicación GPS, para documentar lugares poco conocidos.
3. Cada aporte se valida en dos pasos:
   - un **análisis automático** (clasificación del tipo de paisaje con IA y
     coherencia con datos geográficos como relieve e imágenes satelitales);
   - una **revisión humana obligatoria** por el equipo en el panel web.
   **Ningún aporte se publica sin revisión humana.** La IA solo da un
   resultado preliminar.
4. Los lugares aprobados se muestran a otros viajeros como fichas
   comunitarias.
5. Agencias de turismo pueden ofrecer beneficios (descuentos) mediante un
   código.

## 3. Datos personales que se tratan (principio de minimización)

| Dato | Obligatorio | Finalidad |
|---|---|---|
| Nombre, correo y contraseña (cifrada) | Sí | Cuenta |
| Foto del lugar, ubicación GPS, fecha y origen (cámara/galería) | Solo si aporta | Validar el lugar y publicarlo si se aprueba |
| Ubicación del teléfono en momentos puntuales | No (desactivable) | Confirmar que la persona estuvo cerca del lugar; se borra a las 72 h |
| Cuestionario del lugar (acceso, costo, actividades, servicios, riesgos) | No | Describir el lugar; opciones cerradas, sin texto libre |
| Perfil de viajero: tipo (local/nacional/extranjero), región o país, rango de edad, intereses, experiencia en caminatas, cómo conoció la app | No (se puede omitir) | Recomendaciones y estadísticas anónimas del piloto |
| Versión aceptada de Términos y Privacidad con fecha; consentimiento de investigación con fecha | Sí (registro) | Prueba del consentimiento |

**No se pide:** DNI, teléfono, fecha de nacimiento exacta (solo rango de edad),
dirección, género ni datos de pago. No hay publicidad, venta de datos ni
herramientas de marketing.

## 4. Consentimiento informado (cómo funciona en la app)

1. **Al crear la cuenta:** casilla **obligatoria y sin marcar por defecto**:
   *"Tengo 18 años o más y acepto los Términos y condiciones y la Política de
   privacidad. Mis fotos y su ubicación se usarán para validar lugares y, si
   se aprueban, se publicarán como 'Comunidad RutaAmiga', sin mi nombre."*
   El botón "Crear cuenta" queda desactivado hasta marcarla. Ambos documentos
   se abren y se leen dentro de la app, incluso sin conexión.
2. **Casilla separada y opcional:** *"Acepto que mis aportes se usen, de forma
   anónima y agregada, en la investigación académica de RutaAmiga."*
   Es un consentimiento independiente: no aceptarla no impide usar la app.
3. **Registro del consentimiento:** se guarda la versión aceptada (1.0) y la
   fecha, puesta por el servidor y no por el teléfono. Si los textos cambian
   de forma importante, se sube la versión y la app pide aceptar de nuevo.
4. **Cuentas creadas antes de este cambio:** al abrir la app ven la pantalla
   "Antes de continuar", con 4 puntos clave en lenguaje sencillo, y deben
   aceptar para seguir (o pueden cerrar sesión).
5. **Retiro del consentimiento:** desde Perfil → "Privacidad y
   consentimiento" la persona ve qué aceptó y cuándo, puede activar o retirar
   el uso en la investigación, editar o vaciar su perfil, leer los documentos
   y solicitar la eliminación de sus datos por correo.
6. **Edad:** solo mayores de 18 años.

## 5. Riesgos éticos y mitigaciones implementadas

| Riesgo | Mitigación |
|---|---|
| Identificar a quien aporta | Las fotos públicas se atribuyen a "Comunidad RutaAmiga", sin nombre |
| Rastrear la ubicación de las personas | La ubicación personal nunca se publica; lo público es la ubicación del lugar. Las muestras de ubicación del teléfono se usan 24 h, se borran a las 72 h y se pueden desactivar |
| Fotos accesibles por cualquiera | Almacenamiento privado; las fotos se muestran con enlaces temporales que caducan |
| Acceso a datos de otros usuarios | Reglas de seguridad en la base de datos: cada persona solo puede leer sus propios registros |
| Decisiones automáticas injustas | La IA solo da un resultado preliminar; siempre decide una persona, y cada decisión queda en una bitácora de auditoría |
| Fotografiar a terceros | Los términos piden no incluir rostros, menores ni datos de otras personas; el equipo puede rechazar u ocultar esas fotos |
| Agencias con datos del turista | La agencia solo ve el código, el lugar y el estado del pase; nunca el nombre, correo ni teléfono |
| Uso comercial de los datos | Sin publicidad, sin venta de datos, sin herramientas de marketing |
| Uso en la investigación sin permiso | Consentimiento separado y opcional; los datos se usan solo de forma anónima y agregada |
| Transferencia internacional | Se informa en la política que algunos proveedores tecnológicos (nube, análisis de imágenes, mapas) están fuera del Perú |

## 6. Conservación de los datos

- Ubicación del teléfono: 72 horas.
- Aportes rechazados: 6 meses.
- Cuenta, perfil y aportes aprobados: hasta que la persona pida eliminarlos.
- Al terminar el piloto, los datos se anonimizan o se eliminan.

## 7. Cómo usar los anexos

- **Anexo A:** Términos y condiciones (texto completo abajo).
- **Anexo B:** Política de privacidad (texto completo abajo).
- En el cuerpo del documento, cita los anexos. Por ejemplo: "ver Anexo B,
  sección 4" para proveedores y transferencia internacional, o "sección 6"
  para los derechos.

---

# Anexo A. Términos y condiciones


**Versión:** 1.0 · **Fecha:** 13 de noviembre de 2026

## A.1. Qué es RutaAmiga

RutaAmiga es una app gratuita para descubrir lugares turísticos del Perú y
aportar fotos de ellos. Es un proyecto académico de la Universidad Peruana Unión en fase de
piloto. Al crear tu cuenta aceptas estos términos y la
[Política de privacidad](politica-de-privacidad.md).

## A.2. Tu cuenta

Debes ser **mayor de 18 años** y usar un correo real. Eres responsable de lo
que se haga con tu cuenta. Podemos suspender cuentas que incumplan estos
términos.

## A.3. Tus aportes

Al enviar una foto declaras que:

- La **tomaste tú**, o tienes **autorización escrita de su autor**, y muestra
  el lugar que indicas, en una visita real.
- **No muestra** rostros reconocibles sin permiso, menores de edad ni datos de
  otras personas.

Sigues siendo dueño de tus fotos. Nos permites, de forma gratuita y revocable,
guardarlas, analizarlas y mostrarlas en la app como **"Comunidad RutaAmiga"**.

**Todo aporte pasa por revisión humana** antes de publicarse. El análisis
automático es solo preliminar, y el equipo puede aprobar, corregir o rechazar
un aporte.

## A.4. Información de viaje

La información de lugares, rutas, clima y accesos es **referencial** y puede
estar desactualizada. Las actividades en montaña, nevados, playas o zonas
remotas tienen riesgos: infórmate con fuentes oficiales y respeta las
restricciones de acceso. RutaAmiga no es un servicio de emergencias.

Los beneficios de agencias los ofrece y presta cada agencia, con sus propias
condiciones.

## A.5. Condiciones generales

El servicio se ofrece tal como está y puede cambiar o terminar al concluir el
piloto. Si cambiamos estos términos te avisaremos en la app. Se rigen por las
leyes del Perú. Contacto: sebastian.chinchay@upeu.edu.pe.

---

# Anexo B. Política de privacidad


**Versión:** 1.0 · **Fecha:** 13 de noviembre de 2026

## En pocas palabras

- Usamos tus fotos y su ubicación **solo para validar lugares turísticos**.
- Las fotos aprobadas se publican como **"Comunidad RutaAmiga"**, sin tu nombre.
- **Tu ubicación personal no se muestra** a otros usuarios.
- **No vendemos tus datos** ni los usamos para publicidad.

## B.1. Responsable

Sebastián Chinchay y Daniel Calderón, responsables del proyecto académico
RutaAmiga de la Universidad Peruana Unión, con domicilio en Lima, Perú. Contacto:
sebastian.chinchay@upeu.edu.pe. Esta política se rige por la Ley N.° 29733, Ley de
Protección de Datos Personales, y su Reglamento.

## B.2. Datos que usamos y para qué

| Dato | Para qué |
|---|---|
| Nombre, correo y contraseña (cifrada) | Tu cuenta |
| Fotos de lugares, con su ubicación GPS, fecha y origen (cámara o galería) | Validar el lugar y, si se aprueba, mostrarlo a otros viajeros |
| Ubicación del teléfono en momentos puntuales (desactivable en tu perfil) | Confirmar que estuviste cerca del lugar que reportas |
| Respuestas del cuestionario del lugar | Describir el lugar para otros viajeros |
| Perfil de viajero **opcional**: tipo de viajero, origen, rango de edad, intereses, experiencia en caminatas, cómo nos conociste | Recomendaciones y estadísticas anónimas del piloto |
| Versión aceptada de estos documentos, con su fecha | Registrar tu consentimiento |
| Favoritos, rutas, reportes y pases de beneficio | Las funciones que uses |

No pedimos DNI, teléfono, fecha de nacimiento exacta, dirección ni datos de pago.

## B.3. Cómo los usamos

- Un sistema automático analiza la foto y una **persona del equipo la revisa**
  antes de publicarla.
- Con tu permiso opcional, usamos tus aportes de forma **anónima y agregada**
  en la investigación académica del proyecto.
- Tratamos tus datos con tu **consentimiento**, que puedes retirar cuando
  quieras.

## B.4. Con quién se comparten

Usamos proveedores tecnológicos que tratan los datos por nuestra cuenta y solo
para el servicio: alojamiento en la nube, análisis de imágenes, mapas y datos
geográficos. Algunos están **fuera del Perú**; al aceptar esta política
consientes esa transferencia.

Las agencias de turismo solo ven el código, el lugar y el estado de tu pase de
beneficio, **nunca tu nombre ni tu correo**.

## B.5. Cuánto tiempo los guardamos

- Ubicación del teléfono: se borra a las **72 horas**.
- Aportes rechazados: **6 meses**.
- Cuenta, perfil y aportes aprobados: hasta que pidas eliminarlos.
- Al terminar el piloto, los datos se anonimizan o se eliminan.

## B.6. Tus derechos

Puedes pedir **ver, corregir o eliminar tus datos**, oponerte a su uso o
retirar tu consentimiento escribiendo a sebastian.chinchay@upeu.edu.pe, o desde
**Perfil → Privacidad y consentimiento**. Si no te atendemos, puedes reclamar
ante la Autoridad Nacional de Protección de Datos Personales.

## B.7. Seguridad, edad y cambios

Tus fotos se guardan en almacenamiento privado y el acceso a tus datos está
restringido al equipo. La app es solo para **mayores de 18 años**. Si cambiamos esta
política de forma importante, te pediremos aceptarla de nuevo.
