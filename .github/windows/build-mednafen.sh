#!/bin/sh

set -eu

HOST="${1:?Usage: $0 <host-triplet>}"
ARCH="${HOST%%-*}"
VERSION=$(head -n 1 Documentation/modules.def)
PKGDIR="mednafen-$VERSION-$ARCH"

./configure --host="$HOST" --disable-alsa --disable-jack
make -j"$(nproc)"

mkdir -p "$PKGDIR"
cp src/mednafen.exe "$PKGDIR/"
ldd src/mednafen.exe | grep -i '/mingw' | awk '{print $3}' | sort -u | xargs -I{} cp -v {} "$PKGDIR/"
cp COPYING ChangeLog "$PKGDIR/"
cp Documentation/*.html Documentation/*.css Documentation/*.txt "$PKGDIR/" 2>/dev/null || true

mkdir -p dist
zip -r "dist/$PKGDIR.zip" "$PKGDIR"
