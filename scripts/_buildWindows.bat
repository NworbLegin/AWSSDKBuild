SETLOCAL EnableDelayedExpansion

set vsConfig=
if "%winType%"=="win32" (
	set vsConfig="Visual Studio 15"
)

if "%winType%"=="win64" (
	set vsConfig="Visual Studio 15 Win64"
)

echo config is set to %vsConfig%

mkdir build
cd build

set buildFolder=windows-%winType%-%buildType%
mkdir %buildFolder%
cd %buildFolder%

cmake ../../aws-sdk-cpp/ -G %vsConfig% -DCMAKE_BUILD_TYPE=%buildType% -DBUILD_ONLY="kinesis;cognito-identity;cognito-sync;lambda;pinpoint" -DBUILD_SHARED_LIBS=0 -DCMAKE_INSTALL_BINDIR=%outputPath%/%buildType%/%winType%/bin -DCMAKE_INSTALL_LIBDIR=%outputPath%/%buildType%/%winType%/lib -DCMAKE_INSTALL_INCLUDEDIR=%outputPath%/%buildType%/%winType%/include -DENABLE_TESTING=0 -DNDK_DIR=%androidNDKPath% -DCMAKE_INSTALL_PREFIX=%outputPath%/%buildType%/%winType%
msbuild INSTALL.vcxproj /p:Configuration=%buildType%

cd ..
cd ..

