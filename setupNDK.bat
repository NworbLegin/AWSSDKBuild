mkdir NDK
cd NDK
mkdir Windows
cd Windows
wget https://dl.google.com/android/repository/android-ndk-r19c-windows-x86_64.zip --no-check-certificate
tar.exe -x -f android-ndk-r19c-windows-x86_64.zip
del android-ndk-r19c-windows-x86_64.zip
cd ..
mkdir MacOS
cd MacOS
wget https://dl.google.com/android/repository/android-ndk-r19c-darwin-x86_64.zip --no-check-certificate
tar.exe -x -f android-ndk-r19c-darwin-x86_64.zip
del android-ndk-r19c-darwin-x86_64.zip
cd ..
cd ..

