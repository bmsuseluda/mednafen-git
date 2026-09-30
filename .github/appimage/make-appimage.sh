#!/bin/sh

set -eu

ARCH=$(uname -m)
VERSION=$(head -n 1 Documentation/modules.def)
export ARCH VERSION
export OUTPATH=./dist
export OUTNAME=mednafen-"$VERSION"-"$ARCH".AppImage
export ADD_HOOKS="self-updater.hook"
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"
export DEPLOY_OPENGL=1

# Deploy dependencies
quick-sharun /usr/bin/mednafen /usr/lib/libSDL3.so.*

# Additional changes can be done in between here

# Turn AppDir into AppImage
quick-sharun --make-appimage

# Test the app for 12 seconds, if the test fails due to the app
# having issues running in the CI use --simple-test instead
quick-sharun --simple-test ./dist/*.AppImage
