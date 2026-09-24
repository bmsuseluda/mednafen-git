#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
	cmake           \
	gcc-libs        \
	libao           \
	libx11          \
	libxrandr       \
	libxss          \
	openal          \
	pipewire-audio  \
	pkgconf         \
	pulseaudio      \
 	pulseaudio-alsa \
	sdl2            \
	zlib            \

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
get-debloated-pkgs --add-common --prefer-nano libdecor-mini

(
	./configure --prefix="/usr"
	make -j"$(nproc)"
	make install
	make installcheck
	make clean
	make distclean
)

mkdir -p ./AppDir
cp -rv .github/appimage/AppDir/* ./AppDir

