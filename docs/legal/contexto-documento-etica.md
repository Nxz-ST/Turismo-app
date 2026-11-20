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
   resultado preliminar. La responsabilidad por el contenido es de quien lo
   sube (Términos, sección 3).
4. Los lugares aprobados se muestran a otros viajeros como fichas
   comunitarias.
5. Agencias de turismo pueden ofrecer beneficios (descuentos) mediante un
   código.

## 3. Datos personales que se tratan (principio de minimización)

| Dato | Obligatorio | Finalidad |
|---|---|---|
| Nombre, correo y contraseña (cifrada) | Sí | Cuenta |
| Foto del lugar con ubicación GPS, fecha, origen (cámara/galería) y metadatos del archivo | Solo si aporta | Validar el lugar y publicarlo si se aprueba |
| Imagen de la persona, si aparece en sus propias fotos | No | Mostrar el lugar con sus visitantes, solo si se aprueba |
| Ubicación del teléfono en momentos puntuales | No (desactivable) | Confirmar que la persona estuvo cerca del lugar; respalda aportes 24 h |
| Cuestionario del lugar (acceso, costo, actividades, servicios, riesgos) | No | Describir el lugar; opciones cerradas, sin texto libre |
| Perfil de viajero: tipo (local/nacional/extranjero), región o país, rango de edad, intereses, experiencia en caminatas, cómo conoció la app | No (se puede omitir) | Recomendaciones y estadísticas anónimas del piloto |
| Versión aceptada de Términos y Privacidad con fecha; consentimiento de investigación con fecha | Sí (registro) | Prueba del consentimiento |
| Bloqueos de cuenta: motivo, fechas y quién lo decidió | Solo si hay bloqueo | Hacer cumplir los Términos y atender reclamos |

**No se pide:** DNI, teléfono, fecha de nacimiento exacta (solo rango de edad),
dirección, género ni datos de pago. No hay publicidad, venta de datos ni
herramientas de marketing. **No se usa reconocimiento facial.**

## 4. Consentimiento informado (cómo funciona en la app)

1. **Al crear la cuenta:** casilla **obligatoria y sin marcar por defecto**:
   *"Tengo 18 años o más y acepto los Términos y condiciones y la Política de
   privacidad. Mis fotos y su ubicación se usarán para validar lugares y, si
   se aprueban, se publicarán como 'Comunidad RutaAmiga', sin mi nombre,
   incluso si aparezco en ellas."* El botón "Crear cuenta" queda desactivado
   hasta marcarla. Ambos documentos se abren y se leen dentro de la app,
   incluso sin conexión.
2. **Casilla separada y opcional:** *"Acepto que mis aportes se usen, de forma
   anónima y agregada, en la investigación académica de RutaAmiga."*
   Es un consentimiento independiente: no aceptarla no impide usar la app.
3. **Registro del consentimiento:** se guarda la versión aceptada (vigente:
   **1.1**, 20 de noviembre de 2026) y la fecha, puesta por el servidor y no
   por el teléfono. Al cambiar la versión, la app pide aceptar de nuevo a
   todas las cuentas.
4. **Pantalla de reaceptación:** las cuentas que aceptaron una versión
   anterior ven "Actualizamos nuestros términos", con los puntos clave en
   lenguaje sencillo, y deben aceptar para seguir (o pueden cerrar sesión).
5. **Retiro del consentimiento:** desde Perfil → "Privacidad y
   consentimiento" la persona ve qué aceptó y cuándo, puede activar o retirar
   el uso en la investigación, editar o vaciar su perfil, leer los documentos
   y solicitar la eliminación de sus datos por correo. Puede pedir el retiro
   de cualquier foto suya en un máximo de 10 días hábiles.
6. **Edad:** solo mayores de 18 años.

## 5. Imagen de las personas en las fotos

- **Imagen propia:** quien aparece en sus propias fotos autoriza de forma
  expresa su publicación (casilla del registro y Términos, sección 3).
- **Terceros en primer plano:** quien sube la foto declara tener su permiso.
- **Personas de fondo en lugares públicos** (bañistas, turistas): no se
  requiere permiso, porque el tema es el lugar (Código Civil, art. 15).
- **Menores de edad:** prohibidos como centro de la imagen o claramente
  reconocibles; el revisor rechaza esas fotos.
- **Terceros sin cuenta** pueden pedir el retiro de una foto en la que
  aparecen, en un máximo de 10 días hábiles (Política, sección 6).

## 6. Riesgos éticos y mitigaciones implementadas

| Riesgo | Mitigación |
|---|---|
| Identificar a quien aporta | Las fotos públicas se atribuyen a "Comunidad RutaAmiga", sin nombre; se advierte que quien lo conozca podría reconocerlo si aparece |
| Rastrear la ubicación de las personas | La ubicación personal nunca se publica; lo público es la ubicación del lugar. Las muestras de ubicación respaldan aportes 24 h y se pueden desactivar |
| Fotos accesibles por cualquiera | Almacenamiento privado; las fotos se muestran con enlaces temporales que caducan |
| Acceso a datos de otros usuarios | Reglas de seguridad en la base de datos: cada persona solo puede leer sus propios registros |
| Decisiones automáticas injustas | La IA solo da un resultado preliminar; siempre decide una persona, y cada decisión queda en una bitácora de auditoría |
| Fotografiar a terceros o menores | Reglas de la sección 5; revisión humana antes de publicar; retiro a pedido |
| Contenido inapropiado (sexual, violento, ofensivo, falso) | Prohibido en los Términos (sección 4); el equipo elimina el aporte y puede bloquear la cuenta de forma temporal o definitiva; el usuario ve el motivo y puede reclamar; cada bloqueo queda en bitácora |
| Agencias con datos del turista | La agencia solo ve el código, el lugar y el estado del pase; nunca el nombre ni el correo |
| Uso comercial de los datos | Sin publicidad, sin venta de datos, sin herramientas de marketing |
| Uso en la investigación sin permiso | Consentimiento separado y opcional; los datos se usan solo de forma anónima y agregada |
| Transferencia internacional | La Política nombra a cada proveedor (Supabase, Cloudflare R2, Amazon Web Services, Google, Open-Meteo, Copernicus) y los países (EE. UU. y Unión Europea) |

## 7. Conservación de los datos

- Ubicación del teléfono: respalda aportes 24 h; las muestras de más de 72 h
  se eliminan la siguiente vez que la app registra la ubicación.
- Aportes (incluidos los rechazados), cuenta y perfil: hasta que la persona
  pida eliminarlos o termine el piloto.
- Registros de bloqueo: hasta que termine el piloto.
- Al terminar el piloto, los datos se anonimizan o se eliminan.

## 8. Cómo usar los anexos

- **Anexo A:** Términos y condiciones v1.1 (texto completo abajo).
- **Anexo B:** Política de privacidad v1.1 (texto completo abajo).
- En el cuerpo del documento, cita los anexos. Por ejemplo: "ver Anexo B,
  sección 4" para proveedores y transferencia internacional, "Anexo A,
  sección 4" para contenido prohibido y bloqueo, o "Anexo B, sección 6" para
  los derechos.

---

# Anexo A. Términos y condiciones


**Versión:** 1.1 · **Fecha:** 20 de noviembre de 2026

## A.1. Qué es RutaAmiga

RutaAmiga es una app gratuita para descubrir lugares turísticos del Perú y
aportar fotos de ellos. Es un proyecto académico de la Universidad Peruana Unión en fase de
piloto. Al crear tu cuenta aceptas estos términos y la
[Política de privacidad](politica-de-privacidad.md).

## A.2. Tu cuenta

Debes ser **mayor de 18 años** y usar un correo real. Eres responsable de lo
que se haga con tu cuenta.

## A.3. Tus aportes

Al enviar una foto declaras que:

- La **tomaste tú**, o tienes **autorización escrita de su autor**, y muestra
  el lugar que indicas, en una visita real.
- Si **apareces tú**, nos autorizas a publicarla con tu imagen.
- Si otras personas son **el centro de la foto**, declaras que te dieron su
  permiso. No hace falta si aparecen **de fondo** en un lugar público, como
  bañistas en una playa o turistas en un mirador, porque el tema es el lugar.
- Ningún **menor de edad** es el centro de la imagen ni se le reconoce
  claramente, y no muestra datos de otras personas, como placas o documentos.

Sigues siendo dueño de tus fotos. Nos permites, de forma gratuita y revocable,
guardarlas, analizarlas y mostrarlas en la app como **"Comunidad RutaAmiga"**,
incluida tu imagen si apareces en ellas. Se publican sin tu nombre, pero
**quien te conozca podría reconocerte**. Puedes pedir que retiremos cualquier
foto tuya en cualquier momento; lo haremos en un máximo de **10 días hábiles**.

**Eres el único responsable de lo que subes.** Revisamos los aportes antes de
publicarlos, pero esa revisión no nos hace responsables de su contenido ni
garantiza que cumpla estos términos. Si tu aporte infringe derechos de otras
personas, como su imagen, su privacidad o sus derechos de autor, respondes
tú frente a ellas y frente a RutaAmiga.

## A.4. Contenido prohibido y bloqueo de cuenta

No puedes subir:

- Desnudos, contenido sexual o violento.
- Contenido ofensivo, discriminatorio o que acose a alguien.
- Menores de edad como centro de la imagen o claramente reconocibles, o
  personas en primer plano sin su permiso.
- Fotos falsas, de otro lugar o que no tomaste ni tienes autorización para usar.
- Publicidad, spam o datos de otras personas.

Si subes contenido prohibido o incumples estos términos, podemos **eliminar
el aporte y bloquear tu cuenta**, de forma temporal o definitiva, sin aviso
previo. Al iniciar sesión verás que tu cuenta está bloqueada y el motivo. Si
crees que es un error, escríbenos al correo de contacto. Cuando la ley lo
exija, entregaremos la información necesaria a las autoridades.

## A.5. Información de viaje

La información de lugares, rutas, clima y accesos es **referencial** y puede
estar desactualizada. Las actividades en montaña, nevados, playas o zonas
remotas tienen riesgos: infórmate con fuentes oficiales y respeta las
restricciones de acceso. RutaAmiga no es un servicio de emergencias.

Los beneficios de agencias los ofrece y presta cada agencia, con sus propias
condiciones. RutaAmiga no es responsable de lo que ocurra durante tus viajes
ni de los servicios que contrates con terceros.

## A.6. Responsabilidad

RutaAmiga es un proyecto académico gratuito y se ofrece **tal como está**, sin
garantía de que funcione siempre ni de que la información sea exacta. En la
medida en que la ley lo permita, RutaAmiga, sus responsables y la Universidad
Peruana Unión **no responden** por daños derivados del uso de la app, de los
aportes de otros usuarios ni de decisiones que tomes con base en su
información. Te comprometes a asumir los reclamos que terceros nos hagan por
contenido que tú subiste.

## A.7. Condiciones generales

El servicio puede cambiar o terminar al concluir el piloto. Si cambiamos estos términos te avisaremos en la app. Se rigen por las
leyes del Perú. Contacto: sebastian.chinchay@upeu.edu.pe.

# Anexo B. Política de privacidad


**Versión:** 1.1 · **Fecha:** 20 de noviembre de 2026

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
| Fotos de lugares, con su ubicación GPS, fecha, origen (cámara o galería) y los datos internos del archivo, como el modelo del teléfono | Validar el lugar y, si se aprueba, mostrarlo a otros viajeros |
| Tu imagen, si apareces en tus fotos | Mostrar el lugar con sus visitantes, solo si la foto se aprueba |
| Ubicación del teléfono en momentos puntuales (desactivable en tu perfil) | Confirmar que estuviste cerca del lugar que reportas |
| Respuestas del cuestionario del lugar | Describir el lugar para otros viajeros |
| Perfil de viajero **opcional**: tipo de viajero, origen, rango de edad, intereses, experiencia en caminatas, cómo nos conociste | Recomendaciones y estadísticas anónimas del piloto |
| Versión aceptada de estos documentos, con su fecha | Registrar tu consentimiento |
| Favoritos, rutas, reportes y pases de beneficio | Las funciones que uses |
| Bloqueos de tu cuenta: motivo, fechas y quién lo decidió | Hacer cumplir los Términos y atender tus reclamos |

No pedimos DNI, teléfono, fecha de nacimiento exacta, dirección ni datos de pago.

## B.3. Cómo los usamos

- Un sistema automático analiza la foto y una **persona del equipo la revisa**
  antes de publicarla.
- **No usamos reconocimiento facial** ni identificamos a las personas que
  aparecen en las fotos.
- Con tu permiso opcional, usamos tus aportes de forma **anónima y agregada**
  en la investigación académica del proyecto.
- Tratamos tus datos con tu **consentimiento**, que puedes retirar cuando
  quieras.

## B.4. Con quién se comparten

Usamos proveedores tecnológicos que tratan los datos por nuestra cuenta y solo
para el servicio:

| Proveedor | Qué hace | Datos que recibe |
|---|---|---|
| Supabase | Cuentas y base de datos | Tu cuenta, perfil, aportes y ubicaciones |
| Cloudflare (R2) | Guarda las fotos | Tus fotos |
| Amazon Web Services | Servidor de RutaAmiga y análisis de imágenes | Las fotos y su ubicación, mientras se procesan |
| Google (Maps, Places y Routes) | Mapas, servicios cercanos y rutas | Coordenadas de búsqueda, sin tu nombre ni tu correo |
| Open-Meteo y Copernicus (Unión Europea) | Clima e imágenes satelitales | Solo coordenadas de lugares |

Estos proveedores están **fuera del Perú**, principalmente en Estados Unidos y
la Unión Europea. Al aceptar esta política consientes esa transferencia.

Las agencias de turismo solo ven el código, el lugar y el estado de tu pase de
beneficio, **nunca tu nombre ni tu correo**.

Solo entregamos datos a autoridades cuando una ley o una orden judicial lo
exija.

## B.5. Cuánto tiempo los guardamos

- Ubicación del teléfono: solo respalda tus aportes durante **24 horas**. Las
  ubicaciones con más de 72 horas se eliminan la siguiente vez que la app
  registra tu ubicación.
- Aportes, incluidos los rechazados, cuenta y perfil: hasta que pidas
  eliminarlos o hasta que termine el piloto.
- Registros de bloqueo de cuentas: hasta que termine el piloto.
- Al terminar el piloto, los datos se anonimizan o se eliminan.

## B.6. Tus derechos

Puedes pedir **ver, corregir o eliminar tus datos**, oponerte a su uso o
retirar tu consentimiento escribiendo a sebastian.chinchay@upeu.edu.pe, o desde
**Perfil → Privacidad y consentimiento**. Si no te atendemos, puedes reclamar
ante la Autoridad Nacional de Protección de Datos Personales.

Si apareces en una foto que subió otra persona, puedes pedirnos que la
retiremos, aunque no tengas cuenta. Lo haremos en un máximo de **10 días
hábiles**.

## B.7. Seguridad, edad y cambios

Tus fotos se guardan en almacenamiento privado y el acceso a tus datos está
restringido al equipo. La app es solo para **mayores de 18 años**. Si cambiamos esta
política de forma importante, te pediremos aceptarla de nuevo.
