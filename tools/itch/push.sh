#!/usr/bin/env bash
# Envia as versões exportadas para o itch.io com o butler.
# Antes: crie a página do jogo no itch.io e rode "butler login" uma vez.
# Uso: tools/itch/push.sh usuario/slug-do-jogo [versão]
#   ex.: tools/itch/push.sh fulano/hollowveil 1.0.0
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TARGET="${1:?Informe usuario/slug-do-jogo, como no endereço da página do itch.io}"
VERSION="${2:-$(git -C "$ROOT" describe --tags --always)}"
butler push "$ROOT/releases/linux"   "$TARGET:linux"   --userversion "$VERSION"
butler push "$ROOT/releases/windows" "$TARGET:windows" --userversion "$VERSION"
butler push "$ROOT/releases/web"     "$TARGET:html5"   --userversion "$VERSION"
butler status "$TARGET"
