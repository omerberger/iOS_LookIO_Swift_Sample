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
    rm -rf _LOOKIO_$1_
    exit 0
fi

# Publish!
cp -f _LOOKIO_$1_/ship_it/* ../LookIO-Libraries/iOS/release
rm -rf _LOOKIO_$1_
cd ../LookIO-Libraries
git commit -a -m "Jenkins build v$1"
git push origin master
