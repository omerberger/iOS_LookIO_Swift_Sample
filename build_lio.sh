#!/bin/sh

echo

if [ -z "$1" ]
then
    echo syntax: $0 version_number
    exit 1
fi

TARGET_DIR=_LOOKIO_$1_
LOG_FILE=$TARGET_DIR/build_lio_$1.log
CONFIGURATION=Release

rm -rf $TARGET_DIR
mkdir $TARGET_DIR

echo "Building LookIO v$1 ($CONFIGURATION), please wait..."

sed -i "" "s/##UNKNOWN_VERSION##/$1/g" ./LookIO/Source/Managers/LIOLookIOManager.h

rm -rf LookIO/build
PATH=/Applications/Xcode.app/Contents/Developer/usr/bin:$PATH xcodebuild -project LookIO/LookIO.xcodeproj -target LookIO -configuration $CONFIGURATION &>$LOG_FILE

if [ $? -ne 0 ]
then
    echo "Build failed. Here's why:"
    cat "$LOG_FILE"
    exit 1
fi

mkdir -p $TARGET_DIR/LookIO.bundle
cp LookIO/Resources/Images/LIO* $TARGET_DIR/LookIO.bundle
cp LookIO/build/Release-universal/libLookIO.a $TARGET_DIR
cp LookIO/Source/Managers/LIOLookIOManager.h $TARGET_DIR

#Undo the change
git checkout ./LookIO/Source/Managers/LIOLookIOManager.m
git checkout ./LookIO/Source/Managers/LIOLookIOManager.h

