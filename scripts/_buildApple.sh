mkdir build-MacOS-$abi-$buildType
cd build-MacOS-$abi-$buildType

# this is a comment

cmake ../aws-sdk-cpp/ -G Xcode -DTARGET_ARCH="APPLE" -DCMAKE_BUILD_TYPE=%buildType% -DBUILD_ONLY="kinesis;cognito-identity;cognito-sync;lambda" -DBUILD_SHARED_LIBS=0 -DCMAKE_INSTALL_BINDIR=%outputPath%/%buildType%/%abi%/bin -DCMAKE_INSTALL_LIBDIR=%outputPath%/%buildType%/%abi%/lib -DCMAKE_INSTALL_INCLUDEDIR=%outputPath%/%buildType%/%abi%/include -DENABLE_TESTING=0 -DNDK_DIR=%androidNDKPath%

xcodebuild -target ALL_BUILD

cd ..
