#!/usr/bin/env bash
# Exporta as três versões do HollowVeil para releases/ (Linux, Windows, navegador).
# Precisa dos modelos de exportação do Godot 4.7.2 instalados.
# Uso: tools/itch/build.sh   (a partir da raiz do projeto)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GODOT="${GODOT:-godot}"
if ! command -v "$GODOT" >/dev/null 2>&1; then GODOT="flatpak run --filesystem=$ROOT org.godotengine.Godot"; fi
mkdir -p "$ROOT/releases/linux" "$ROOT/releases/windows" "$ROOT/releases/web"
cd "$ROOT/game"
$GODOT --headless --path . --import >/dev/null 2>&1 || true
$GODOT --headless --path . --export-release "Linux" "../releases/linux/HollowVeil.x86_64"
$GODOT --headless --path . --export-release "Windows" "../releases/windows/HollowVeil.exe"
$GODOT --headless --path . --export-release "Web" "../releases/web/index.html"
cp "$ROOT/docs/WALKTHROUGH.md" "$ROOT/releases/linux/" 
cp "$ROOT/docs/WALKTHROUGH.md" "$ROOT/releases/windows/"
echo "Pronto: releases/linux, releases/windows, releases/web"
