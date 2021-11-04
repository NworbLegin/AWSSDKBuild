echo "-- Update submodules --"
git submodule update --init --recursive

echo "-- Set up the NDK --"
mkdir NDK
cd NDK
mkdir Windows
cd Windows
wget https://dl.google.com/android/repository/android-ndk-r21e-windows-x86_64.zip --no-check-certificate
tar.exe -x -f android-ndk-r21e-windows-x86_64.zip
del android-ndk-r21e-windows-x86_64.zip
cd ..
cd ..


echo "-- Build AWSSDKCPP for Android --"

mkdir output
set curDir=%CD:\=/%
set outputPath=%curDir%/output/Android
set androidNDKPath=%curDir%/NDK/Windows/android-ndk-r21e

call "C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\Common7\Tools\VsDevCmd.bat"

rem ** CREATE ANDROID DEBUG arm64-v8a **
set abi=arm64-v8a
set buildType=Debug
rem call scripts/_buildAndroid.bat

rem ** CREATE ANDROID RELEASE arm64-v8a **
set abi=arm64-v8a
set buildType=Release
call scripts/_buildAndroid.bat


rem ** CREATE ANDROID DEBUG armeabi-v7a **
set abi=armeabi-v7a
set buildType=Debug
rem call scripts/_buildAndroid.bat


rem ** CREATE ANDROID RELEASE armeabi-v7a **
set abi=armeabi-v7a
set buildType=Release
call scripts/_buildAndroid.bat

pause
