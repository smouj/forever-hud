#!/usr/bin/env bash
# Builds dist/ForeverHUD-<version>.zip with the addon folder at the archive root.
set -eo pipefail
cd "$(dirname "$0")/.."

VERSION=$(sed -n 's/^## Version: *//p' ForeverHUD/ForeverHUD.toc | head -1 | tr -d '\r')
if [ -z "$VERSION" ]; then
  echo "No se pudo leer la version del TOC" >&2
  exit 1
fi

ZIP="ForeverHUD-$VERSION.zip"
rm -rf dist
mkdir -p dist

if command -v zip >/dev/null 2>&1; then
  zip -qr "dist/$ZIP" ForeverHUD -x '*.DS_Store'
else
  python3 - "dist/$ZIP" <<'PY'
import os, sys, zipfile
target = sys.argv[1]
with zipfile.ZipFile(target, "w", zipfile.ZIP_DEFLATED) as archive:
    for root, dirs, files in os.walk("ForeverHUD"):
        dirs.sort()
        for name in sorted(files):
            if name == ".DS_Store":
                continue
            full = os.path.join(root, name)
            archive.write(full, full.replace(os.sep, "/"))
PY
fi

python3 - "dist/$ZIP" <<'PY'
import sys, zipfile
path = sys.argv[1]
with zipfile.ZipFile(path) as archive:
    bad = archive.testzip()
    names = archive.namelist()
    if bad:
        raise SystemExit("ZIP corrupto en " + bad)
    toc = [n for n in names if n.endswith("ForeverHUD.toc")]
    if not toc:
        raise SystemExit("Falta ForeverHUD.toc en la raiz del ZIP")
    print("Entradas: %d" % len(names))
    print("TOC: %s" % toc[0])
    print("Integridad: OK")
PY

cd dist
sha256sum "$ZIP" > SHA256SUMS
cat SHA256SUMS
du -h "$ZIP"
