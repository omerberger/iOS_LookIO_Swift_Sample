#!/bin/sh
# Syntax: go_jenkins_go.sh buildver target
#
# buildver: an int identifying the build version.
#
# target: the branch of LookIO-Libraries in which to store the result.
#   master
#   unstable
#   enterprise_master
#   enterprise_unstable
#

COMMIT_DESCRIPTION="Release version $1"
if [ $2 == "unstable" ]
then
    COMMIT_DESCRIPTION="Unstable version $1"
fi

if [ $2 == "enterprise_master" ]
then
    COMMIT_DESCRIPTION="Stable Enterprise version $1"
fi

if [ $2 == "enterprise_unstable" ]
then
    COMMIT_DESCRIPTION="Unstable Enterprise version $1"
fi

if [ $2 == "ios8" ]
then
    COMMIT_DESCRIPTION="iOS8 version $1"
fi

cd /Users/marc/Development/ios_lib
./build_lio.sh $1

if [ $? -ne 0 ]
then
    echo Sorry, Jenkins, but the build failed.
    rm -rf _LOOKIO_$1_
    exit 1
fi

echo Publishing build #$1 into LookIO-Libraries branch: $2...

pushd ../LookIO-Libraries
git checkout .
rm -rf iOS/*
git fetch
git checkout $2
rm -rf iOS/*
cp -v -f -R  ../ios_lib/_LOOKIO_$1_/libLookIO.a ../ios_lib/_LOOKIO_$1_/LookIO.bundle ../ios_lib/_LOOKIO_$1_/LIOLookIOManager.h iOS
rm -rf ../ios_lib/_LOOKIO_$1_
git add iOS/libLookIO.a
git add iOS/LIOLookIOManager.h
git add iOS/LookIO.bundle/*
git commit -a -m "${COMMIT_DESCRIPTION}"
git push origin $2

otool -f iOS/libLookIO.a

#
# Upload the bundle to the CDN
#

echo "Uploading LookIO.bundle (as bundle.zip) and to CDN..."
popd
# Standard bundle
zip -j ./bundle.zip ~/Development/LookIO-Libraries/iOS/LookIO.bundle/*
python ./upload_bundle.py --version $1 --key AKIAIKCREXYCWO5PI2AA --secret 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
rm -rf ./bundle.zip

echo Build script finished.