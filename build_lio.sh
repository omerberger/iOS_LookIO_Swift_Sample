#!/bin/sh

echo

if [ -z "$1" ]
then
    echo syntax: $0 version_number
    exit 1
fi

TARGET_DIR=_LOOKIO_$1_
LOG_FILE_MAIN=$TARGET_DIR/main_lio_$1.log
LOG_FILE_LEGACY=$TARGET_DIR/legacy_lio_$1.log
LOG_FILE_LIPO=$TARGET_DIR/lipo_lio_$1.log

rm -rf $TARGET_DIR
mkdir $TARGET_DIR

echo "Building LookIO v$1 (Release), please wait..."

sed -i "" "s/##UNKNOWN_VERSION##/$1/g" ./LookIO/Source/Managers/LIOLookIOManager.h


#
# First, build the "main" library: modern SDK, armv7 armv7s i386.
#
rm -rf LookIO/build
PATH=/Applications/Xcode.app/Contents/Developer/usr/bin:$PATH xcodebuild -project LookIO/LookIO.xcodeproj -target LookIO -configuration Release -xcconfig main.xcconfig &>$LOG_FILE_MAIN

if [ $? -ne 0 ]
then
    echo "Main build failed. Here's why:"
    cat "$LOG_FILE_MAIN"
    exit 1
fi

mkdir -p $TARGET_DIR/LookIO.bundle
cp LookIO/Resources/Images/LIO* $TARGET_DIR/LookIO.bundle
cp -R LookIO/Resources/Strings/* $TARGET_DIR/LookIO.bundle
mv LookIO/build/Release-universal/libLookIO.a $TARGET_DIR/libLookIO_main.a
cp LookIO/Source/Managers/LIOLookIOManager.h $TARGET_DIR


#
# Next, build the "legacy" library: older SDK, armv6.
#
rm -rf LookIO/build
PATH=/Applications/Xcode4.3.3.app/Contents/Developer/usr/bin:$PATH xcodebuild -project LookIO/LookIO.xcodeproj -target LookIO -configuration Release -xcconfig legacy.xcconfig &>$LOG_FILE_LEGACY

if [ $? -ne 0 ]
then
    echo "Legacy build failed. Here's why:"
    cat "$LOG_FILE_LEGACY"
    exit 1
fi

lipo LookIO/build/Release-iphoneos/libLookIO.a -thin armv6 -output $TARGET_DIR/libLookIO_legacy.a


#
# Now, combine the two build products.
#
lipo $TARGET_DIR/libLookIO_main.a $TARGET_DIR/libLookIO_legacy.a -create -output $TARGET_DIR/libLookIO.a &>$LOG_FILE_LIPO

if [ $? -ne 0 ]
then
    echo "lipo operation failed. Here's why:"
    cat "$LOG_FILE_LIPO"
    exit 1
fi

rm $TARGET_DIR/libLookIO_main.a
rm $TARGET_DIR/libLookIO_legacy.a


# Undo the sed change.
git checkout ./LookIO/Source/Managers/LIOLookIOManager.h

