#!/bin/sh
set -eu

ROOT="${1:-$(pwd)}"
PAYLOAD="$ROOT/.aweme_1039_patch"
cd "$ROOT"

[ -f control ] || { echo "ERROR: run from the AwemeLiquidBar repository root"; exit 1; }
[ -f Tweak.x ] || { echo "ERROR: Tweak.x not found"; exit 1; }
[ -f AwemeAlbumMorphBar.swift ] || { echo "ERROR: AwemeAlbumMorphBar.swift not found"; exit 1; }
[ -d "$PAYLOAD" ] || { echo "ERROR: patch payload not found"; exit 1; }

grep -Eq '^Version: 1\.0\.(37|39)$' control || {
  echo "ERROR: expected the 1.0.37 cloud project (or an already-applied 1.0.39 tree)"
  exit 1
}

mkdir -p .github/workflows scripts layout/DEBIAN
for f in .gitignore Makefile AwemeLiquidBar.plist APPLY.txt TEST_PROTOCOL.txt Tweak.x AwemeAlbumMorphBar.swift control README.md build_no_install.sh; do
  cp "$PAYLOAD/$f" "$f"
done
cp "$PAYLOAD/.github/workflows/build.yml" .github/workflows/build.yml
cp "$PAYLOAD/scripts/preflight.sh" scripts/preflight.sh
cp "$PAYLOAD/layout/DEBIAN/postinst" layout/DEBIAN/postinst
chmod +x build_no_install.sh scripts/preflight.sh layout/DEBIAN/postinst

grep -q '^Version: 1.0.39$' control
grep -q 'LiquidBar 设置 · 1.0.39' Tweak.x
[ "$(grep -c 'const CGFloat diameter = 46.0;' Tweak.x)" -eq 2 ]
grep -q 'let designScale: CGFloat = 3.0' AwemeAlbumMorphBar.swift
grep -q 'let maximumPixelEdge: CGFloat = 100.0' AwemeAlbumMorphBar.swift
grep -q '.glassEffect(.clear.interactive(), in: Capsule())' AwemeAlbumMorphBar.swift
grep -q '.glassEffect(.regular.interactive(), in: Capsule())' AwemeAlbumMorphBar.swift
bash scripts/preflight.sh

rm -rf "$PAYLOAD"
rm -f "$ROOT/apply_patch_1.0.39.sh"
echo "Applied AwemeLiquidBar 1.0.39: true 46 pt square-Capsule glass and @3x 100 px PNG sizing"
