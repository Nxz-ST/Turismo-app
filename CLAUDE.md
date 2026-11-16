# Instrucciones de contexto para Claude — RutaAmiga

Este directorio es el workspace principal de la aplicación móvil RutaAmiga.
Antes de analizar, proponer o modificar cualquier elemento del proyecto:

1. Lee completamente `RUTAAMIGA_CONTEXT_FOR_CLAUDE.md`.
2. Usa `RutaAmiga-Vault/00 - Inicio.md` como índice documental.
3. Lee `RutaAmiga-Vault/13 - Protocolo de contexto.md` y respeta sus reglas.
4. Revisa `RutaAmiga-Vault/01 - Estado actual.md`, pero contrástalo con el
   código porque algunas notas pueden estar desactualizadas.
5. Conserva todos los cambios locales sin commit.
6. No muestres ni copies secretos, archivos `.env`, tokens, claves API o el
   contenido de archivos `.pem`.
7. Usa este orden de fuente de verdad:
   - Código, migraciones y configuración efectiva.
   - Pruebas y comportamiento observado.
   - Notas del vault y documento de traspaso.
   - Conversaciones o ideas todavía no implementadas.

## Componentes relacionados

- Aplicación Flutter: este directorio.
- Backend FastAPI: `/Users/sebastianchinchaycollachagua/turismo_backend`.
- Panel administrativo: `/Users/sebastianchinchaycollachagua/rutaamiga_admin`.

Si la sesión solo tiene permisos sobre `turismo_app`, informa antes de intentar
cambios en el backend o panel. Para trabajar en los tres componentes conviene
abrir como workspace `/Users/sebastianchinchaycollachagua`.

Después de un cambio funcional importante, actualiza las notas pertinentes del
vault, especialmente estado, decisiones y pendientes, sin duplicar código largo.
