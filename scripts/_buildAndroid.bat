echo _buildAndroid cd=%CD%

mkdir build
cd build
mkdir android-%abi%-%buildType%
cd android-%abi%-%buildType%

cmake ../../aws-sdk-cpp/ -G "NMake Makefiles" -DTARGET_ARCH=ANDROID -DANDROID_ABI=%abi% -DCMAKE_BUILD_TYPE=%buildType% -DBUILD_ONLY="kinesis;cognito-identity;cognito-sync;lambda;s3;apigateway;identity-management" -DENABLE_TESTING=0 -DBUILD_SHARED_LIBS=0 -DCMAKE_INSTALL_BINDIR=%outputPath%/%buildType%/%abi%/bin -DCMAKE_INSTALL_LIBDIR=%outputPath%/%buildType%/%abi%/lib -DCMAKE_INSTALL_INCLUDEDIR=%outputPath%/%buildType%/%abi%/include -DENABLE_TESTING=0 -DNDK_DIR=%androidNDKPath%

rem ** BUILD ANDROID DEBUG OUTPUT **
cmake --build .
cmake --build . --target install

rem ** Copy extern folder with curl, ssl etc
set externalOutputPath=%outputpath:/=\%\%buildType%\%abi%\external
echo externalOutputPath = %externalOutputPath%
mkdir %externalOutputPath%
xcopy /e /y /q external %externalOutputPath% 

xcopy /e /y /q .deps\install\lib\*.a %outputPath:/=\%\%buildType%\%abi%\lib
mkdir %outputPath:/=\%\%buildType%\%abi%\install
xcopy /e /y /q .deps\install\include %outputPath:/=\%\%buildType%\%abi%\include


cd ..
cd ..

