#!/bin/sh

set -eu

HOST="${1:?Usage: $0 <host-triplet>}"
ARCH="${HOST%%-*}"
VERSION=$(head -n 1 Documentation/modules.def)
PKGDIR="mednafen-$VERSION-$ARCH"

touch aclocal.m4
touch configure include/config.h.in
touch Makefile.in intl/Makefile.in src/Makefile.in

# This MSYS2 mingw-w64-crt snapshot dropped the internal `mingw_app_type` global
# that main.cpp expects, so provide it ourselves and link it in via LIBS.
echo 'int mingw_app_type;' | "$HOST-gcc" -x c -c -o mingw_app_type_stub.o -

# Without this, zlib's gztell/gztell64 aren't aliased and tests.cpp fails to compile.
CPPFLAGS="-D_FILE_OFFSET_BITS=64 ${CPPFLAGS:-}" \
LIBS="$PWD/mingw_app_type_stub.o ${LIBS:-}" \
./configure --host="$HOST" --disable-alsa --disable-jack --disable-dependency-tracking
make -j"$(nproc)"

mkdir -p "$PKGDIR"
cp src/mednafen.exe "$PKGDIR/"
ldd src/mednafen.exe | grep -i '/mingw' | awk '{print $3}' | sort -u | xargs -I{} cp -v {} "$PKGDIR/"
# sdl2-compat loads SDL3 via LoadLibrary at runtime, so it never shows up in ldd's output above.
cp -v "$MINGW_PREFIX"/bin/SDL3.dll "$PKGDIR/"
cp COPYING ChangeLog "$PKGDIR/"
cp Documentation/*.html Documentation/*.css Documentation/*.txt "$PKGDIR/" 2>/dev/null || true

# Strip debug symbols; without this mednafen.exe alone is tens of MBs larger.
"$HOST-strip" --strip-all "$PKGDIR"/*.exe "$PKGDIR"/*.dll

mkdir -p dist
zip -r "dist/$PKGDIR.zip" "$PKGDIR"
