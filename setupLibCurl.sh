mkdir -p libcurl
cd libcurl

# clone the curl-android-ios git repo
git clone https://github.com/NworbLegin/curl-android-ios.git

cd curl-android-ios

# init and update submodules
git submodule init && git submodule update

cd curl-compile-scripts

# build curl for all iOS targets
./build_iOS.sh

# back to curl-android-ios folder
cd ..

# back to libcurl folder
cd ..

# make the output folders include and lib
mkdir -p include
mkdir -p lib

# copy the include folder from curl-android-ios/prebuilt-with-ssl/ios
cp -R curl-android-ios/prebuilt-with-ssl/ios/include/* include

# copy the libcurl.a file from curl-android-ios/prebuilt-with-ssl/ios
cp curl-android-ios/prebuilt-with-ssl/ios/libcurl.a lib/libcurl.a



# back to workspace folder
cd ..



