#!/bin/sh
#
#
# This script will create a bundle file given an existing kit.
#
# Parameters:
#	$1: Platform type (linux, aix, hpux, sun)
#	$2: Directory to package file
#	$3: Package name for OM package
#
# We expect this script to run from the BUILD directory (i.e. scxcore/build).
# Directory paths are hard-coded for this location.

SOURCE_DIR=`(cd ../installer/bundle; pwd -P)`
INTERMEDIATE_DIR=`(cd ../installer/intermediate; pwd -P)`

# Exit on error

set -e
set -x

usage()
{
    echo "usage: $0 platform directory package-name"
    echo "  where"
    echo "    platform is one of: linux, aix, hpux, sun"
    echo "    directory is directory path to package file"
    echo "    package-name is the name of the installation package"
    exit 1
}

# Validate parameters

if [ -z "$1" ]; then
    echo "Missing parameter: Platform type" >&2
    echo ""
    usage
    exit 1
fi

case "$1" in
    linux|aix|hpux|sun)
	;;

    *)
	echo "Invalid platform type specified: $1" >&2
	exit 1
esac

if [ -z "$2" ]; then
    echo "Missing parameter: Directory to platform file" >&2
    echo ""
    usage
    exit 1
fi

if [ ! -d "$2" ]; then
    echo "Directory \"$2\" does not exist" >&2
    exit 1
fi

if [ -z "$3" ]; then
    echo "Missing parameter: package-name" >&2
    echo ""
    usage
    exit 1
fi

if [ ! -f "$2/$3" ]; then
    echo "Package \"$2/$3\" does not exist"
    exit 1
fi

# Determine the bundle file name
BUNDLE_FILE=`echo $3 | sed -e "s/.rpm/.sh/"`
OUTPUT_DIR=`(cd $2; pwd -P)`

# Work from the temporary directory from this point forward

cd $INTERMEDIATE_DIR

# Fetch the bundle skeleton file
cp $SOURCE_DIR/primary.skel .
chmod u+w primary.skel

# Edit the bundle file for hard-coded values
sed -e "s/PLATFORM=<PLATFORM_TYPE>/PLATFORM=$1/" < primary.skel > primary.$$
mv primary.$$ primary.skel

sed -e "s/OM_PKG=<OM_PKG>/OM_PKG=$3/" < primary.skel > primary.$$
mv primary.$$ primary.skel

# Fetch the kit
cp $OUTPUT_DIR/$3 .

# Build the bundle
tar cfvz - $3 | cat primary.skel - > $BUNDLE_FILE
chmod +x $BUNDLE_FILE
rm primary.skel

# Remove the kit and copy the bundle to the kit location
rm $3
mv $BUNDLE_FILE $OUTPUT_DIR/

exit 0
