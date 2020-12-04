#!/bin/bash

set -e 

mkdir -p NDK/MacOS

cd NDK/MacOS

wget https://dl.google.com/android/repository/android-ndk-r19c-darwin-x86_64.zip --no-check-certificate
tar -x -f android-ndk-r19c-darwin-x86_64.zip
rm android-ndk-r19c-darwin-x86_64.zip

cd ..
cd ..