#!/bin/sh

echo

if [ -z "$1" ]
then
    echo syntax: $0 version_number
    exit 1
fi

TARGET_DIR=_LOOKIO_$1_
LOG_FILE_ARM=$TARGET_DIR/arm_lio_$1.log
LOG_FILE_ARM64=$TARGET_DIR/arm64_lio_$1.log
LOG_FILE_I386=$TARGET_DIR/i386_lio_$1.log
LOG_FILE_X86_64=$TARGET_DIR/x86_64_lio_$1.log
LOG_FILE_LIPO=$TARGET_DIR/lipo_lio_$1.log

rm -rf $TARGET_DIR
mkdir $TARGET_DIR

echo "Building LookIO v$1 (Release), please wait..."

sed -i "" "s/##UNKNOWN_VERSION##/$1/g" ./LookIO/Source/Managers/LIOLookIOManager.h

#
# First, build the "arm" library: arm7, arm7s.
#
rm -rf LookIO/build
PATH=/Applications/Xcode.app/Contents/Developer/usr/bin:$PATH xcodebuild -project 'LookIO/LookIO.xcodeproj' -target LookIO -configuration 'Release' -sdk 'iphoneos7.0' clean build ARCHS='armv7 armv7s' IPHONEOS_DEPLOYMENT_TARGET='4.3' TARGET_BUILD_DIR='./build-arm' BUILT_PRODUCTS_DIR='./build-arm' &>$LOG_FILE_ARM

if [ $? -ne 0 ]
then
    echo "arm7/arm7s build failed. Here's why:"
    cat "LOG_FILE_ARM"
    exit 1
fi

mkdir -p $TARGET_DIR/LookIO.bundle
cp LookIO/Resources/Images/LIO* $TARGET_DIR/LookIO.bundle
cp -R LookIO/Resources/Strings/* $TARGET_DIR/LookIO.bundle
cp LookIO/Source/Managers/LIOLookIOManager.h $TARGET_DIR

#
# Next, build the "arm64" library: 64-bit support, arm64
#

PATH=/Applications/Xcode.app/Contents/Developer/usr/bin:$PATH xcodebuild -project 'LookIO/LookIO.xcodeproj' -target LookIO -configuration 'Release' -sdk 'iphoneos7.0' clean build ARCHS='arm64' IPHONEOS_DEPLOYMENT_TARGET='6.0' TARGET_BUILD_DIR='./build-arm64' BUILT_PRODUCTS_DIR='./build-arm64' &>$LOG_FILE_ARM64

if [ $? -ne 0 ]
then
    echo "arm64 build failed. Here's why:"
    cat "$LOG_FILE_ARM64"
    exit 1
fi

#
# Next, build the "i386" library: i386
#

PATH=/Applications/Xcode.app/Contents/Developer/usr/bin:$PATH xcodebuild -project 'LookIO/LookIO.xcodeproj' -target LookIO -configuration 'Release' -sdk 'iphonesimulator7.0' clean build ARCHS='i386' IPHONEOS_DEPLOYMENT_TARGET='4.3' TARGET_BUILD_DIR='./build-i386' BUILT_PRODUCTS_DIR='./build-i386' &>$LOG_FILE_I386

if [ $? -ne 0 ]
then
    echo "i386 build failed. Here's why:"
    cat "LOG_FILE_I386"
    exit 1
fi

#
# Next, build the "x86_64" library: x86_64
#

PATH=/Applications/Xcode.app/Contents/Developer/usr/bin:$PATH xcodebuild -project 'LookIO/LookIO.xcodeproj' -target LookIO -configuration 'Release' -sdk 'iphonesimulator7.0' clean build ARCHS='x86_64' VALID_ARCHS='x86_64' IPHONEOS_DEPLOYMENT_TARGET='6.0' TARGET_BUILD_DIR='./build-x86_64' BUILT_PRODUCTS_DIR='./build-x86_64' &>$LOG_FILE_X86_64

if [ $? -ne 0 ]
then
    echo "x86_64 build failed. Here's why:"
    cat "LOG_FILE_X86_64"
    exit 1
fi

#
# Now, combine the four build products.
#
lipo -create 'LookIO/build-arm/libLookIO.a' 'LookIO/build-arm64/libLookIO.a' 'LookIO/build-i386/libLookIO.a' 'LookIO/build-x86_64/libLookIO.a' -output $TARGET_DIR/libLookIO.a &>$LOG_FILE_LIPO

if [ $? -ne 0 ]
then
    echo "lipo operation failed. Here's why:"
    cat "$LOG_FILE_LIPO"
    exit 1
fi

rm -rf LookIO/build-arm
rm -rf LookIO/build-arm64
rm -rf LookIO/build-i386
rm -rf LookIO/build-x86_64

# Undo the sed change.
git checkout ./LookIO/Source/Managers/LIOLookIOManager.h