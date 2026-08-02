#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
# pacman -Syu --noconfirm PACKAGESHERE

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
# get-debloated-pkgs --add-common --prefer-nano

# Comment this out if you need an AUR package
#make-aur-package PACKAGENAME

# If the application needs to be manually built that has to be done down here
echo "Building static ncurses..."
echo "---------------------------------------------------------------"
git clone --depth 1 https://github.com/mirror/ncurses.git /tmp/ncurses && (
	cd /tmp/ncurses
	./configure \
		--disable-shared     \
		--enable-static      \
		--enable-widec       \
		--prefix=/tmp/static \
		--with-termlib       \
		--without-ada        \
		--without-cxx        \
		--without-debug
	make -j"$(nproc)"
	make install
)

echo "Building static libsensors..."
echo "---------------------------------------------------------------"
git clone --depth 1 https://github.com/lm-sensors/lm-sensors.git /tmp/lm-sensors && (
	cd /tmp/lm-sensors
	make BUILD_LIB=1 BUILD_SHARED_LIB=0 BUILD_STATIC_LIB=1
	cp -v ./lib/libsensors.a /tmp/static/lib
	cp -v ./lib/sensors.h   /tmp/static/include
)

echo "Building htop statically..."
echo "---------------------------------------------------------------"
git clone https://github.com/htop-dev/htop.git ./htop && (
	cd ./htop

	git fetch --tags origin
	TAG=$(git tag --sort=-v:refname | grep -vi 'rc\|alpha\|beta' | head -1)
	git checkout "$TAG"
	echo "$TAG" > ~/version

	./autogen.sh
	export CPPFLAGS="-I/tmp/static/include"
	export LDFLAGS="-L/tmp/static/lib"
	./configure \
		--disable-shared \
		--enable-sensors \
		--enable-static  \
		--prefix=/usr    \
		--with-ncursesw
	make -j"$(nproc)"
	make install
)
