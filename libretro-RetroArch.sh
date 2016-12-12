#!/usr/bin/env zsh

TMP=${TMP:-/tmp}
PKG=$TMP/package-RetroArch
PRGNAM=RetroArch
BUILD=1dc

if [[ -z $ARCH ]]; then
	case $( uname -m ) in
		i?86) ARCH=i486 ;;
		arm*) ARCH=arm ;;
		*) ARCH=$( uname -m ) ;;
	esac
fi

if [[ $ARCH == "i486" ]]; then
	SLKCFLAGS="-O2 -march=i486 -mtune=i686"
	LIBDIRSUFFIX=""
elif [[ $ARCH == "i686" ]]; then
	SLKCFLAGS="-O2 -march=i686 -mtune=i686"
	LIBDIRSUFFIX=""
elif [[ $ARCH == "x86_64" ]]; then
	SLKCFLAGS="-O2 -fPIC"
	LIBDIRSUFFIX="64"
else
	SLKCFLAGS="-O2"
	LIBDIRSUFFIX=""
fi

read -r -d '' PARSER <<EOF
# Get the latest version
import json
import sys

releases = json.load(sys.stdin)
print releases[0]["tag_name"]
EOF

set -e

LATEST=$(curl -H "Accept: application/vnd.github.v3.raw+json" https://api.github.com/repos/libretro/${PRGNAM}/releases | python -c $PARSER)
VERSION=${LATEST:1}

rm -rf $PKG
rm -rf $TMP/${PRGNAM}-${VERSION} $TMP/${PRGNAM}-${LATEST}.tar.gz

mkdir -p $PKG
cd $TMP
echo https://github.com/libretro/${PRGNAM}/archive/${LATEST}/${PRGNAM}-${LATEST}.tar.gz
wget https://github.com/libretro/${PRGNAM}/archive/${LATEST}/${PRGNAM}-${LATEST}.tar.gz
tar xvf ${PRGNAM}-${LATEST}.tar.gz
cd ${PRGNAM}-${VERSION}

# Set the config file default directories to be consistent with the installation.

sed -i "s/# savefile_directory =/savefile_directory = ~\/.config\/retroarch\/savefile/" retroarch.cfg
sed -i "s/# savestate_directory =/savestate_directory = ~\/.config\/retroarch\/savestate/" retroarch.cfg

sed -i "s/# libretro_directory =/libretro_directory = \/usr\/lib$LIBDIRSUFFIX\/libretro/" retroarch.cfg
sed -i "s/# libretro_info_path =/libretro_info_path = \/usr\/lib$LIBDIRSUFFIX\/libretro\/info/" retroarch.cfg
sed -i "s/# video_filter_dir =/video_filter_dir = \/usr\/lib$LIBDIRSUFFIX\/retroarch\/filters\/video/" retroarch.cfg
sed -i "s/# audio_filter_dir =/audio_filter_dir = \/usr\/lib$LIBDIRSUFFIX\/retroarch\/filters\/audio/" retroarch.cfg

sed -i "s/# video_shader_dir =/video_shader_dir = ~\/.config\/retroarch\/shaders/" retroarch.cfg

sed -i "s/# overlay_directory =/overlay_directory = ~\/.config\/retroarch\/overlay/" retroarch.cfg
sed -i "s/# joypad_autoconfig_dir =/joypad_autoconfig_dir = ~\/.config\/retroarch\/autoconf/" retroarch.cfg
sed -i "s/# assets_directory =/assets_directory = ~\/.config\/retroarch\/assets/" retroarch.cfg

sed -i "s/# rgui_config_directory =/rgui_config_directory = ~\/.config\/retroarch/" retroarch.cfg
sed -i "s/# input_remapping_directory =/input_remapping_directory = ~\/.config\/retroarch\/remap/" retroarch.cfg
sed -i "s/# playlist_directory =/playlist_directory = ~\/.config\/retroarch\/playlists/" retroarch.cfg
sed -i "s/# boxarts_directory =/boxarts_directory = ~\/.config\/retroarch\/boxarts/" retroarch.cfg
sed -i "s/# content_database_path =/content_database_path = ~\/.config\/retroarch\/database/" retroarch.cfg
sed -i "s/# cheat_database_path =/cheat_database_path = ~\/.config\/retroarch\/cheats/" retroarch.cfg
sed -i "s/# content_history_path =/content_history_path = ~\/.config\/retroarch\/content_history.lpl/" retroarch.cfg



chown -R root:root .
find -L . \
 \( -perm 777 -o -perm 775 -o -perm 750 -o -perm 711 -o -perm 555 \
  -o -perm 511 \) -exec chmod 755 {} \; -o \
 \( -perm 666 -o -perm 664 -o -perm 640 -o -perm 600 -o -perm 444 \
  -o -perm 440 -o -perm 400 \) -exec chmod 644 {} \;

CWD=$PWD
CFLAGS=$SLKCFLAGS \
	CXXFLAGS="$SLKCFLAGS" \
	./configure \
	--prefix=/usr \
	--enable-cg
make
make -C gfx/video_filters
make -C audio/audio_filters
make DESTDIR=$PKG PREFIX=/usr install
mv $PKG/usr/share/man $PKG/usr
mkdir -p $PKG/usr/doc/RetroArch-$VERSION
cp $CWD/[A-Z][A-Z]* $PKG/usr/doc/RetroArch-$VERSION
mkdir -p $PKG/usr/share/applications
cp $CWD/retroarch.desktop $PKG/usr/share/applications
mkdir -p $PKG/usr/lib$LIBDIRSUFFIX/retroarch/filters/video
cp $CWD/gfx/video_filters/*.so $PKG/usr/lib$LIBDIRSUFFIX/retroarch/filters/video
cp $CWD/gfx/video_filters/*.filt $PKG/usr/lib$LIBDIRSUFFIX/retroarch/filters/video
mkdir -p $PKG/usr/lib$LIBDIRSUFFIX/retroarch/filters/audio
cp $CWD/audio/audio_filters/*.so $PKG/usr/lib$LIBDIRSUFFIX/retroarch/filters/audio
cp $CWD/audio/audio_filters/*.dsp $PKG/usr/lib$LIBDIRSUFFIX/retroarch/filters/audio

find $PKG -print0 | xargs -0 file | grep -e "executable" -e "shared object" | grep ELF \
  | cut -f 1 -d : | xargs strip --strip-unneeded 2> /dev/null || true

for m in $PKG/usr/man/**/*.[0-9]; do
	gzip -9 $m
done

cd $PKG
/sbin/makepkg -l y -c n $TMP/libretro-${PRGNAM}-${VERSION}-${ARCH}-${BUILD}.txz
