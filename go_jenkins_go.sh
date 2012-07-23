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
pushd ../LookIO-Libraries
git checkout .
rm -rf iOS/release/*
git checkout dev
rm -rf iOS/release/*
cp -v -f -R  ../ios_lib/_LOOKIO_$1_/libLookIO.a ../ios_lib/_LOOKIO_$1_/LookIO.bundle ../ios_lib/_LOOKIO_$1_/LIOLookIOManager.h iOS/release
rm -rf ../ios_lib/_LOOKIO_$1_
git add iOS/release/LookIO.bundle/*
git commit -a -m "Jenkins build v$1"
git push origin dev

echo PUBLISHED

popd
zip -j ./bundle.zip ~/Development/LookIO-Libraries/iOS/release/LookIO.bundle/*
python ./upload_bundle.py --version $1 --key $3 --secret $4
rm -rf ./bundle.zip
