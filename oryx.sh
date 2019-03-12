#!/bin/bash

# ORYX_ALT_COMMIT_ID='???'
BUILD_DEST='/tmp/buildscriptgen'

# Cleanup 
rm -rf $BUILD_DEST && mkdir -p $BUILD_DEST
rm -rf /tmp/Oryx

# Fetch source code 
cd /tmp && git clone https://github.com/kichalla/Oryx.git
cd Oryx
#git checkout –q $ORYX_ALT_COMMIT_ID

# Temporary workaround to `/var/nuget` not being writable
export NUGET_PACKAGES=/tmp/nuget
mkdir -p $NUGET_PACKAGES

# Build 
cd src
GIT_COMMIT=$ORYX_ALT_COMMIT_ID \
    dotnet publish -r linux-x64 -o $BUILD_DEST -c Release BuildScriptGeneratorCli/BuildScriptGeneratorCli.csproj
echo

# Run 
oryx="$BUILD_DEST/GenerateBuildScript"
$oryx --version

#----------------------------------------------------------------

BUILD_DEST='/tmp/buildscriptgen'
oryx="$BUILD_DEST/GenerateBuildScript"
$oryx --version

tmpSrc="/tmp/src"
rm -rf $tmpSrc
mkdir -p $tmpSrc
echo
echo "Copying files from $DEPLOYMENT_SOURCE to $tmpSrc ..."
start=$SECONDS
# NOTE: The following should ideally be using something like KuduSync because between different
# git pushes by the end user stale files might be left over which is not correct
cp -rf $DEPLOYMENT_SOURCE/* $tmpSrc
end=$SECONDS
runtime=$((end-start))
echo "Duration: $runtime seconds."

echo
echo Kicking off build ...
start=$SECONDS
$oryx build $tmpSrc -l nodejs --language-version 10.14
end=$SECONDS
runtime=$((end-start))
echo "Duration: $runtime seconds."

echo
echo "Copying files from $tmpSrc to $DEPLOYMENT_TARGET ..."
start=$SECONDS
# Q: Shouldn't we clean the output directory first before copying? This is in the case of 2nd
# and there on builds
cp -rf $tmpSrc/* $DEPLOYMENT_TARGET
end=$SECONDS
runtime=$((end-start))
echo "Duration: $runtime seconds."
