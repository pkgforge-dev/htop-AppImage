#!/bin/sh

set -eux

export ARCH="$(uname -m)"
export APPIMAGE_EXTRACT_AND_RUN=1

APP=htop
APPDIR="$APP".AppDir
UPINFO="gh-releases-zsync|$(echo $GITHUB_REPOSITORY | tr '/' '|')|continuous|*$ARCH.AppImage.zsync"
APPIMAGETOOL="https://github.com/pkgforge-dev/appimagetool-uruntime/releases/download/continuous/appimagetool-$ARCH.AppImage"

# CREATE DIRECTORIES
mkdir -p ./AppDir
cd ./AppDir

# DOWNLOAD AND BUILD HTOP
CURRENTDIR="$(dirname "$(readlink -f "$0")")" # DO NOT MOVE THIS
HTOP_URL=$(wget -q https://api.github.com/repos/htop-dev/htop/releases -O - \
	| sed 's/[()",{} ]/\n/g' | grep -oi 'https.*releases.*htop.*tar.xz' | head -1)

wget "$HTOP_URL"
tar fx ./*.tar.*

cd ./htop*
./autogen.sh
./configure --prefix="$CURRENTDIR" --enable-sensors --enable-static
make
make install
cd ..
rm -rf ./htop* ./*.tar.*

# PREPARE APPIMAGE
cp -v ./share/applications/*.desktop ./
cp -v ./share/pixmaps/*              ./htop.png
cp -v ./share/pixmaps/*              ./.DirIcon

ln -s ./bin/htop ./AppRun
chmod +x ./bin/htop
VERSION="$(./AppRun -V | awk '{print $2; exit}')"
echo "$VERSION" > ~/version

# MAKE APPIMAGE
cd ..
wget "$APPIMAGETOOL" -O ./appimagetool
chmod +x ./appimagetool
./appimagetool -n -u "$UPINFO" "$PWD"/AppDir "$PWD"/"$APP"-"$VERSION"-anylinux-"$ARCH".AppImage

echo "All Done!"
