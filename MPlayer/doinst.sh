# Handle the incoming configuration files:
config() {
	for infile in $1; do
		NEW="$infile"
		OLD="$( dirname $NEW )/$( basename $NEW .new )"
		# If there's no config file by that name, mv it over:
		if [ ! -r $OLD ]; then
			mv $NEW $OLD
		elif [ "$( cat $OLD | md5sum )" = "$( cat $NEW | md5sum )" ]; then
			# toss the redundant copy
			rm $NEW
		fi
		# Otherwise, we leave the .new copy for the admin to consider...
	done
}

# Installing a bitmap font is considered deprecated; use a TTF font instead.
# We try to link to an installed TTF font at install time.
# Configure a default TrueType font to use for the OSD :
OSDFONTS="LiberationSans-Regular.ttf \
          Arialuni.ttf arial.ttf \
          DejaVuSans.ttf Vera.ttf"
mkdir -p usr/share/mplayer
if [ ! -f usr/share/mplayer/subfont.ttf ]; then
	for font in $OSDFONTS; do
		if [ -f ./lib/X11/fonts/TTF/${font} ]; then
			( cd usr/share/mplayer/
			ln -sf /lib/X11/fonts/TTF/${font} subfont.ttf
			)
			break
		fi
	done
fi

# Prepare the new configuration file
config etc/mplayer/mplayer.conf.new
