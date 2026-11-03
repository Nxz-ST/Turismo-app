# Propuesta: popularidad y evolución de lugares comunitarios

Estado: implementado localmente; pendiente de aplicar la migración 012 en
Supabase y desplegar backend/app.

## Objetivo

Permitir que un lugar descubierto por una persona evolucione a un lugar
reconocido por la comunidad. Después de su aprobación, otras personas deben
poder seleccionarlo como **Lugar existente**, aportar evidencia y registrar
visitas verificadas. El mapa mostrará qué lugares tienen mayor respaldo y
popularidad.

## Flujo esperado

1. Una persona registra un **Nuevo lugar**.
2. El motor y la revisión administrativa validan la evidencia.
3. El backend promueve el descubrimiento a un registro canónico con origen
   `community` y conserva el vínculo con la evidencia original.
4. El lugar aparece en el catálogo y en la búsqueda de **Lugar existente**.
5. Nuevas evidencias y visitas GPS quedan vinculadas al mismo identificador.
6. Supabase calcula la popularidad a partir de usuarios únicos verificados.
7. Flutter muestra el contador y el nivel de popularidad en el mapa y detalle.

## Métrica recomendada

No incrementar un contador manualmente ni contar envíos repetidos de una misma
persona. Calcular la popularidad mediante una vista o función de Supabase:

- usuarios únicos con visitas GPS verificadas;
- usuarios únicos con evidencias aprobadas;
- fecha de la última verificación;
- opcionalmente, ponderación por actualidad.

Además del valor total, exponer por separado `verified_visitors` y
`approved_contributors` para explicar el resultado.

## Presentación en el mapa

- 0 validaciones: marcador normal.
- 1–4 personas verificadas: marcador verde con contador.
- 5–14: marcador turquesa destacado.
- 15 o más: marcador dorado o destacado.

El contador de popularidad debe distinguirse visualmente de los círculos de
agrupación de Google Maps, que representan varios marcadores cercanos.

En el detalle mostrar, por ejemplo:

```text
12 visitantes verificados
4 aportantes con evidencia aprobada
Última verificación: hace 3 días
```

## Implementación realizada

### Supabase

- La migración `012_community_places_trust_passport.sql` crea el catálogo
  canónico `community_places` y recupera evidencias validadas anteriores.
- Conserva la evidencia inicial y vincula aportes posteriores al mismo lugar.
- El respaldo se calcula con usuarios únicos de evidencias aprobadas y visitas
  GPS verificadas; no existe un contador editable.

### Backend

- Promueve un nuevo lugar cuando completa la aprobación administrativa.
- `existing_place` puede apuntar a un lugar oficial o comunitario.
- Devuelve un Pasaporte de confianza con aportantes, visitantes, personas
  independientes, actualidad y condiciones recientes.
- Consolida duplicados aprobados en la ficha canónica existente.

### Panel administrativo

- Acción explícita para aprobar y promover el descubrimiento.
- Vista de evidencias relacionadas con el lugar.
- Posibilidad de corregir identidad, categoría y coordenadas antes de publicar.

### Flutter

- Incluye lugares comunitarios aprobados en **Lugar existente**.
- Muestra el respaldo en las listas del mapa y en la ficha comunitaria.
- Muestra desglose de visitantes, aportantes y última verificación mediante el
  Pasaporte de confianza.
- Los marcadores conservan su diferenciación respecto de los clústeres; el
  marcador numérico personalizado queda como mejora visual posterior.

## Criterios de aceptación

- Un descubrimiento aprobado recibe un ID canónico y puede seleccionarse como
  lugar existente.
- Dos aportes de una misma persona no inflan la cantidad de personas únicas.
- Una visita sin verificación GPS no aumenta visitantes verificados.
- Los lugares oficiales y comunitarios usan el mismo sistema de popularidad.
- El contador del mapa coincide con el detalle y con los datos agregados.
