#!/usr/bin/env bash
# Installs ForeverHUD into an AddOns folder (Wine, macOS or manual Linux setups).
# Usage: bash install/install.sh "/path/to/_forever_/Interface/AddOns"
set -eo pipefail

TARGET=$1
if [ -z "$TARGET" ]; then
  echo "Uso: bash install/install.sh <ruta a Interface/AddOns>" >&2
  echo "Ejemplo: bash install/install.sh \"$HOME/Games/World of Warcraft/_forever_/Interface/AddOns\"" >&2
  exit 1
fi

ROOT=$(cd "$(dirname "$0")/.." && pwd)
SRC="$ROOT/ForeverHUD"
DEST="$TARGET/ForeverHUD"

if [ ! -f "$SRC/ForeverHUD.toc" ]; then
  echo "No encuentro el complemento en $SRC" >&2
  exit 1
fi
if [ ! -d "$TARGET" ]; then
  echo "La carpeta $TARGET no existe" >&2
  exit 1
fi

if [ -d "$DEST" ]; then
  BACKUP="$DEST.bak-$(date +%Y%m%d-%H%M%S)"
  mv "$DEST" "$BACKUP"
  echo "Copia de seguridad: $BACKUP"
fi

cp -R "$SRC" "$DEST"
EXPECTED=$(find "$SRC" -type f | wc -l | tr -d ' ')
ACTUAL=$(find "$DEST" -type f | wc -l | tr -d ' ')
if [ "$EXPECTED" != "$ACTUAL" ]; then
  echo "Verificacion fallida: $ACTUAL de $EXPECTED ficheros" >&2
  exit 1
fi

echo "Instalado en $DEST ($ACTUAL ficheros)"
echo "Reinicia el cliente y escribe /fh en el chat."
