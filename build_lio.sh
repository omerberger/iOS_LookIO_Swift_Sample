#!/bin/sh

echo

if [ -z "$1" ]
then
    echo syntax: $0 version_number
    exit 1
fi

TARGET_DIR=_LOOKIO_$1_
LOG_FILE=build_lio_$1.log
CONFIGURATION=Release

if [ -n "$2" ]
then
    CONFIGURATION=$2
fi

echo "Building LookIO v$1 ($CONFIGURATION), please wait..."
rm -rf build
xcodebuild -project LookIO.xcodeproj -target LookIO -configuration Release &>$LOG_FILE

if [ $? -ne 0 ]
then
    echo Build failed. Check $LOG_FILE for details.
    exit 1
fi

mkdir $TARGET_DIR
mkdir $TARGET_DIR/LookIO.bundle
cp Testbed/Resources/Sounds/* $TARGET_DIR/LookIO.bundle
cp Testbed/Resources/Images/LIO* $TARGET_DIR/LookIO.bundle
cp build/Release-universal/libLookIO.a $TARGET_DIR
cp LookIO/Source/LIOLookIOManager.h $TARGET_DIR

echo Build complete! Find the results in $TARGET_DIR/

echo
