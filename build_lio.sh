#!/bin/sh

echo

if [ -z "$1" ]
then
    echo syntax: $0 version_number
    exit 1
fi

TARGET_DIR=_LOOKIO_$1_
LOG_FILE_MAIN=$TARGET_DIR/main_lio_$1.log
LOG_FILE_ARM64=$TARGET_DIR/arm64_lio_$1.log
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
# Next, build the "arm64" library: 64-bit support, arm64
#
rm -rf LookIO/build
PATH=/Applications/Xcode.app/Contents/Developer/usr/bin:$PATH xcodebuild -project LookIO/LookIO.xcodeproj -target LookIO -configuration Release -xcconfig arm64.xcconfig &>$LOG_FILE_ARM64

if [ $? -ne 0 ]
then
    echo "Arm64 build failed. Here's why:"
    cat "$LOG_FILE_ARM64"
    exit 1
fi

# lipo LookIO/build/Release-iphonesimulator/libLookIO.a -thin x86_64 -output $TARGET_DIR/libLookIO_x86_64.a

mv LookIO/build/Release-iphoneos/libLookIO.a $TARGET_DIR/libLookIO_arm64.a

#
# Now, combine the two build products.
#
lipo $TARGET_DIR/libLookIO_main.a $TARGET_DIR/libLookIO_arm64.a -create -output $TARGET_DIR/libLookIO.a &>$LOG_FILE_LIPO

if [ $? -ne 0 ]
then
    echo "lipo operation failed. Here's why:"
    cat "$LOG_FILE_LIPO"
    exit 1
fi

rm $TARGET_DIR/libLookIO_main.a
rm $TARGET_DIR/libLookIO_arm64.a

# Undo the sed change.
git checkout ./LookIO/Source/Managers/LIOLookIOManager.h