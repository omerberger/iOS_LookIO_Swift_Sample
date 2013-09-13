#!/bin/sh

echo

if [ -z "$1" ]
then
    echo syntax: $0 version_number
    exit 1
fi

TARGET_DIR=_LOOKIO_$1_
LOG_FILE_MAIN=$TARGET_DIR/main_lio_$1.log

rm -rf $TARGET_DIR
mkdir $TARGET_DIR

echo "Building LookIO v$1 (Release), please wait..."

sed -i "" "s/##UNKNOWN_VERSION##/$1/g" ./LookIO/Source/Managers/LIOLookIOManager.h

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
cp LookIO/build/Release-universal/libLookIO.a $TARGET_DIR
cp LookIO/Source/Managers/LIOLookIOManager.h $TARGET_DIR

# Undo the sed change.
git checkout ./LookIO/Source/Managers/LIOLookIOManager.h