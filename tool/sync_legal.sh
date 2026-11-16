#!/usr/bin/env bash
# Copia los textos legales de docs/legal a assets/legal (los que muestra la app)
# quitando la nota interna de borrador, y regenera los anexos del documento de ética.
set -euo pipefail
cd "$(dirname "$0")/.."
strip() { awk 'BEGIN{skip=0} /^> Borrador/{skip=1} skip && /^>/{next} {skip=0; print}' "$1"; }
strip docs/legal/terminos-y-condiciones.md > assets/legal/terminos.md
strip docs/legal/politica-de-privacidad.md > assets/legal/privacidad.md
{
  echo "# Anexos del documento de ética · RutaAmiga"; echo
  echo "## Anexo A. Términos y condiciones de uso"; echo
  sed '1d' docs/legal/terminos-y-condiciones.md | sed 's/^## /### /'; echo
  echo "## Anexo B. Política de privacidad"; echo
  sed '1d' docs/legal/politica-de-privacidad.md | sed 's/^## /### /'
} > docs/legal/anexos-documento-etica.md
echo "Textos legales sincronizados."
