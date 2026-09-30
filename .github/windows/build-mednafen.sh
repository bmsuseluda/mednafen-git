#!/usr/bin/env bash

set -euo pipefail

HOST="${1:?Usage: $0 <host-triplet>}"
: "${MINGW_PREFIX:?Run this script in an MSYS2 MinGW environment}"
ARCH="${HOST%%-*}"
VERSION=$(head -n 1 Documentation/modules.def)
PKGDIR="mednafen-$VERSION-$ARCH"

# Use committed Autotools outputs without regenerating them on the runner.
touch aclocal.m4
touch configure include/config.h.in
touch Makefile.in intl/Makefile.in src/Makefile.in

# Keep static compiler runtimes as a distribution policy until dynamic runtime
# linking has been validated on Windows with the corrected MinGW code model.
# Whole-archive handles references from runtime libraries added later by GCC.
RUNTIME_FLAGS="-static-libgcc -static-libstdc++ -Wl,--push-state,-Bstatic,--whole-archive -lwinpthread -Wl,--pop-state"
# Explicit hardening policy; configure no longer disables MinGW's ASLR defaults.
HARDENING_FLAGS="-Wl,--dynamicbase,--nxcompat"
if [[ "$ARCH" == x86_64 ]]; then
	HARDENING_FLAGS+=" -Wl,--high-entropy-va"
fi

# Large-file zlib aliases and the modern Windows Unicode API build profile.
CPPFLAGS="-D_FILE_OFFSET_BITS=64 -DUNICODE=1 -D_UNICODE=1 ${CPPFLAGS:-}" \
LDFLAGS="$RUNTIME_FLAGS $HARDENING_FLAGS ${LDFLAGS:-}" \
./configure --host="$HOST" --disable-alsa --disable-jack --disable-dependency-tracking
make -j"$(nproc)"

mkdir -p "$PKGDIR"
cp src/mednafen.exe "$PKGDIR/"
ldd src/mednafen.exe | grep -iF "$MINGW_PREFIX/bin/" | awk '{print $3}' | sort -u | xargs -I{} cp -v {} "$PKGDIR/"
# sdl2-compat loads SDL3 via LoadLibrary, so it does not appear in ldd's output.
cp -v "$MINGW_PREFIX"/bin/SDL3.dll "$PKGDIR/"
cp COPYING ChangeLog "$PKGDIR/"
cp Documentation/*.html Documentation/*.css Documentation/*.txt "$PKGDIR/"

STRIP="$HOST-strip"
command -v "$STRIP" >/dev/null 2>&1 || STRIP=strip
"$STRIP" --strip-all "$PKGDIR"/*.exe "$PKGDIR"/*.dll

mkdir -p dist
zip -r "dist/$PKGDIR.zip" "$PKGDIR"
