#!/bin/sh

echo

if [ -z "$1" ]
then
    echo syntax: $0 version_number
    exit 1
fi

TARGET_DIR_ROOT=_LOOKIO_$1_
TARGET_DIR_SHIP=$TARGET_DIR_ROOT/ship_it
TARGET_DIR_LOCAL=$TARGET_DIR_ROOT/local
LOG_FILE=$TARGET_DIR_ROOT/build_lio_$1.log
CONFIGURATION=Release

rm -rf $TARGET_DIR_ROOT
mkdir $TARGET_DIR_ROOT

if [ -n "$2" ]
then
    CONFIGURATION=$2
fi

echo "Building LookIO v$1 ($CONFIGURATION), please wait..."

sed -i "" "s/##UNKNOWN_VERSION##/$1/g" ./LookIO/Source/LIOLookIOManager.m

rm -rf build
/Developer-4.1/usr/bin/xcodebuild -project LookIO.xcodeproj -target LookIO -configuration Release &>$LOG_FILE

if [ $? -ne 0 ]
then
    echo Build failed. Check $LOG_FILE for details.
    exit 1
fi


#Build the shipable version
mkdir -p $TARGET_DIR_SHIP
mkdir -p $TARGET_DIR_SHIP/LookIO.bundle
cp Testbed/Resources/Sounds/* $TARGET_DIR_SHIP/LookIO.bundle
cp Testbed/Resources/Images/LIO* $TARGET_DIR_SHIP/LookIO.bundle
cp build/Release-universal/libLookIO.a $TARGET_DIR_SHIP
cp LookIO/Source/LIOLookIOManager.h $TARGET_DIR_SHIP

#Convert the manager file to use 10.1.1.1
sed -i "" 's/connect.look.io/10.1.1.1/g' ./LookIO/Source/LIOLookIOManager.m
sed -i "" 's/usesTLS = YES/usesTLS = NO/g' ./LookIO/Source/LIOLookIOManager.m

rm -rf build
/Developer-4.1/usr/bin/xcodebuild -project LookIO.xcodeproj -target LookIO -configuration Release &>$LOG_FILE

if [ $? -ne 0 ]
then
    echo Build failed. Check $LOG_FILE for details.
    exit 1
fi

#Build the local version
mkdir -p $TARGET_DIR_LOCAL
mkdir -p $TARGET_DIR_LOCAL/LookIO.bundle
cp Testbed/Resources/Sounds/* $TARGET_DIR_LOCAL/LookIO.bundle
cp Testbed/Resources/Images/LIO* $TARGET_DIR_LOCAL/LookIO.bundle
cp build/Release-universal/libLookIO.a $TARGET_DIR_LOCAL
cp LookIO/Source/LIOLookIOManager.h $TARGET_DIR_LOCAL
 
#Undo the change
git checkout ./LookIO/Source/LIOLookIOManager.m

#Copy to dropbox
mkdir -p ~/Dropbox/Look.io\ \(Marc\ \&\ Joe\)/libLookIO/$1
mkdir -p ~/Dropbox/Look.io\ \(Marc\ \&\ Joe\)/libLookIO/local/$1
cp -r $TARGET_DIR_SHIP/* ~/Dropbox/Look.io\ \(Marc\ \&\ Joe\)/libLookIO/$1
cp -r $TARGET_DIR_LOCAL/* ~/Dropbox/Look.io\ \(Marc\ \&\ Joe\)/libLookIO/local/$1

