# Propuesta: popularidad y evolución de lugares comunitarios

Estado: pendiente de implementación.

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

## Cambios necesarios

### Supabase

- Añadir origen `official` o `community` al catálogo canónico.
- Conservar el vínculo entre evidencia inicial y lugar promovido.
- Crear una vista/RPC agregada de popularidad por lugar.
- Contar usuarios únicos para evitar manipulación del contador.

### Backend

- Promover un nuevo lugar cuando complete la aprobación requerida.
- Permitir que `existing_place` apunte también a lugares comunitarios.
- Devolver métricas de popularidad en catálogo, cercanos y detalle.
- Mantener auditoría de evidencias y visitas que sustentan cada métrica.

### Panel administrativo

- Acción explícita para aprobar y promover el descubrimiento.
- Vista de evidencias relacionadas con el lugar.
- Posibilidad de corregir identidad, categoría y coordenadas antes de publicar.

### Flutter

- Incluir lugares comunitarios aprobados en **Lugar existente**.
- Mostrar marcadores con contador y nivel de popularidad.
- Mostrar desglose de visitantes, aportantes y última verificación.
- Mantener diferenciados los marcadores individuales y los clústeres.

## Criterios de aceptación

- Un descubrimiento aprobado recibe un ID canónico y puede seleccionarse como
  lugar existente.
- Dos aportes de una misma persona no inflan la cantidad de personas únicas.
- Una visita sin verificación GPS no aumenta visitantes verificados.
- Los lugares oficiales y comunitarios usan el mismo sistema de popularidad.
- El contador del mapa coincide con el detalle y con los datos agregados.
