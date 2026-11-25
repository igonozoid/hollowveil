#!/usr/bin/env bash
# Roda o teste de lógica num perfil vazio, sem tocar no save de verdade.
# Uso: tests/run_tests.sh   (a partir da raiz do projeto)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
cp -r "$ROOT/game" "$TMP/game"
rm -rf "$TMP/game/.godot"
cp "$ROOT/tests/logic_test.gd" "$TMP/game/logic_test.gd"
sed -i 's|^Audio="\*res://scripts/audio/audio.gd"|&\nTest="*res://logic_test.gd"|' "$TMP/game/project.godot"
GODOT="${GODOT:-godot}"
if ! command -v "$GODOT" >/dev/null 2>&1; then GODOT="flatpak run --filesystem=$TMP org.godotengine.Godot"; fi
$GODOT --headless --path "$TMP/game" --import >/dev/null 2>&1 || true
XDG_DATA_HOME="$TMP/data" $GODOT --headless --path "$TMP/game" --fixed-fps 60 -- --qa 2>&1 | grep -E "^(OK|FAIL|RESULTADO)|SCRIPT ERROR|at: res://"
