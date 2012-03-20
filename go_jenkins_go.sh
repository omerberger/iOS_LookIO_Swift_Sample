#!/bin/sh

cd /Users/marc/Development/ios_lib
git checkout .
git pull origin master
./build_lio_41.sh $1

if [ $? -ne 0 ]
then
    echo Sorry, Jenkins, but the build failed.
    rm -rf _LOOKIO_$1_
    exit 1
fi

# Don't publish.
if [ -z "$2" ]
then
    echo Skipped publishing.
    rm -rf _LOOKIO_$1_
    exit 0
fi

# Publish!
cp -v -f -R  _LOOKIO_$1_/libLookIO.a _LOOKIO_$1_/LookIO.bundle _LOOKIO_$1_/LIOLookIOManager.h ../LookIO-Libraries/iOS/release
rm -rf _LOOKIO_$1_
cd ../LookIO-Libraries
#git commit -a -m "Jenkins build v$1"
#git push origin master

echo PUBLISHED
