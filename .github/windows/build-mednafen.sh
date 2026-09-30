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

# Without --dynamicbase/--high-entropy-va, the exe stays pinned at its low
# fixed preferred base while system DLLs load at high, ASLR'd addresses; the
# resulting distance overflows the 32-bit auto-import pseudo-relocations,
# crashing at startup with "pseudo relocation ... out of range".
# Even with those flags, libgcc_s/libstdc++/libwinpthread still export DATA
# symbols (vtables, typeinfo, TLS globals) that get auto-imported across the
# DLL boundary via the same 32-bit fixups, so statically link those in too.
# Without _FILE_OFFSET_BITS=64, zlib's gztell/gztell64 aren't aliased and tests.cpp fails to compile.
CPPFLAGS="-D_FILE_OFFSET_BITS=64 ${CPPFLAGS:-}" \
LIBS="$PWD/mingw_app_type_stub.o ${LIBS:-}" \
LDFLAGS="-static-libgcc -static-libstdc++ -Wl,-Bstatic,--whole-archive -lwinpthread -Wl,--no-whole-archive -Wl,-Bdynamic -Wl,--dynamicbase -Wl,--high-entropy-va -Wl,--nxcompat ${LDFLAGS:-}" \
./configure --host="$HOST" --disable-alsa --disable-jack --disable-dependency-tracking
make -j"$(nproc)"

mkdir -p "$PKGDIR"
cp src/mednafen.exe "$PKGDIR/"
ldd src/mednafen.exe | grep -i '/mingw' | awk '{print $3}' | sort -u | xargs -I{} cp -v {} "$PKGDIR/"
# sdl2-compat loads SDL3 via LoadLibrary at runtime, so it never shows up in ldd's output above.
cp -v "$MINGW_PREFIX"/bin/SDL3.dll "$PKGDIR/"
cp COPYING ChangeLog "$PKGDIR/"
cp Documentation/*.html Documentation/*.css Documentation/*.txt "$PKGDIR/" 2>/dev/null || true

STRIP="$HOST-strip"
command -v "$STRIP" >/dev/null 2>&1 || STRIP=strip
"$STRIP" --strip-all "$PKGDIR"/*.exe "$PKGDIR"/*.dll

mkdir -p dist
zip -r "dist/$PKGDIR.zip" "$PKGDIR"
