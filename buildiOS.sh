#!/bin/bash

# Based on build scripts from the following:
# https://github.com/aws/aws-sdk-cpp/issues/340 
# https://github.com/mologie/libtomcrypt-ios
# http://stackoverflow.com/a/27161949/5148626

# ------------------------------
#           README FIRST
# ------------------------------
#           DEPENDENCY
# - Need to build libcurl for iOS
# -- see project: https://github.com/gcesarmza/curl-android-ios
# -- Update to latest release of curl if necessary (run git clone https://github.com/curl/curl.git from inside this project)
# -- Before running the build script located in "curl-compile-scripts/build_iOS.h",
#    - Go to line containing .configure command
#      - add option "--without-zlib" to .configure command,
#      - make sure it has option "--with-darwinssl",
#      - and then run the build script
#
# ------------------------------
# Create DIR structure as follows
# ------------------------------
#
#  Workspace_dir    // name this whatever you like
#  |
#   -- aws-sdk-cpp  // Source dir
#  |
#   -- build
#  |   |
#  |    -- build.sh // (this script)
#  |
#  |-- buildOutput      // Automatically created. Will contain output
#  |
#  |-- aggregatedOutput // Automatically created. Will contain aggregated output (if last line is un-commented)
#  |
#   -- libcurl
#      |
#       -- lib/libcurl.a      // Note: This should contain a fatlib to support building arm64, armv7, armv7s
#      |
#       -- include/..         // libcurl headers
#
# ------------------------------
# Usage: Once libcurl is built/available place it in "libcurl" directory as shown above. Then:
#        1. Update following parameters in the script below as required:
#           - WORKSPACE - path to "Workspace_dir" mentioned above
#           - SDK_VERSION - Currently Set to 10.3
#           - MIN_VERSION - Currently Set to 10.0
#           - AWS cmake arguments as necessary in build_AWSRelease_bitcode() function.
#             Note: To disable bitcode, remove "-fembed-bitcode" from CMAKE_CXX_FLAGS
#
#           - If you want to aggregate build outputs into a fat lib, see function aggregate_libs()
#               - Add the necessary libraries in the components array
#               - uncomment last line: aggregate_libs "${WORKSPACE}/aggregatedOutput"
#
#        2. Place the build script in "Workspace_dir/build"
#
#        3. Run the following in terminal:
#               cd Workspace_dir/build
#               ./build.sh
#
# Output should be in Workspace_dir/buildOutput, if everything went well
# Aggregated lib should be in Workspace_dir/aggregatedOutput, if everything went well
# ------------------------------

set -x

# SDK Version
SDK_VERSION="14.5"
MIN_VERSION="10.0"

# Setup paths
# echo current directory is $(pwd)
WORKSPACE=$(pwd)
# ls ${WORKSPACE}


# XCode paths
DEVELOPER="/Applications/Xcode_12.5.app/Contents/Developer"
IPHONEOS_PLATFORM="${DEVELOPER}/Platforms/iPhoneOS.platform"
IPHONEOS_SDK="${IPHONEOS_PLATFORM}/Developer/SDKs/iPhoneOS${SDK_VERSION}.sdk"

IPHONESIMULATOR_PLATFORM="${DEVELOPER}/Platforms/iPhoneSimulator.platform"
IPHONESIMULATOR_SDK="${IPHONESIMULATOR_PLATFORM}/Developer/SDKs/iPhoneSimulator${SDK_VERSION}.sdk"

# Make sure things actually exist
if [ ! -d "$IPHONEOS_PLATFORM" ]; then
  echo "Cannot find $IPHONEOS_PLATFORM"
  exit 1
fi

if [ ! -d "$IPHONEOS_SDK" ]; then
  echo "Cannot find $IPHONEOS_SDK"
  exit 1
fi


if [ ! -d "$IPHONESIMULATOR_PLATFORM" ]; then
  echo "Cannot find $IPHONESIMULATOR_PLATFORM"
  exit 1
fi

if [ ! -d "$IPHONESIMULATOR_SDK" ]; then
  echo "Cannot find $IPHONESIMULATOR_SDK"
  exit 1
fi


pwd=`pwd`

# ----------------------------------
# To build arm64, armv7, armv7s
# ----------------------------------
build_AWSRelease_bitcode()
{
	export ARCH=$1
	export DBGREL="Release"
	export BUILD_FOLDER=build/iOS-$ARCH-$DBGREL

    # Build intermediates dir
    mkdir -p $BUILD_FOLDER
    cd $BUILD_FOLDER

    # Cleanup
    rm -r ./*

	export SDK=$2

    export CC="$(xcrun -sdk iphoneos -find clang)"
    export CPP="$CC -E"
    export CFLAGS="-arch ${ARCH} -isysroot $SDK -miphoneos-version-min=$MIN_VERSION"
    export AR=$(xcrun -sdk iphoneos -find ar)
    export RANLIB=$(xcrun -sdk iphoneos -find ranlib)
    export CPPFLAGS="-arch ${ARCH} -isysroot $SDK -miphoneos-version-min=$MIN_VERSION"
    export LDFLAGS="-arch ${ARCH} -isysroot $SDK"

    BUILD_OUTPUT="${WORKSPACE}/output/iOS/${ARCH}/${DBGREL}"
    mkdir -p $BUILD_OUTPUT

    echo $CMAKE_CXX_FLAGS

    cmake -Wno-dev \
        -DCMAKE_OSX_SYSROOT="$IPHONEOS_SDK" \
        -DCMAKE_OSX_ARCHITECTURES=$ARCH \
        -DCMAKE_SYSTEM_NAME="Darwin" \
		-DENABLE_TESTING=0 \
		-DBUILD_ONLY="kinesis;cognito-identity;cognito-sync;lambda;s3;apigateway;identity-management" \
        -DCMAKE_SHARED_LINKER_FLAGS="-framework Foundation -lz -framework Security" \
        -DCMAKE_EXE_LINKER_FLAGS="-framework Foundation -framework Security" \
        -DCMAKE_PREFIX_PATH="$WORKSPACE/libcurl/" \
        -DBUILD_SHARED_LIBS=OFF \
        -DCUSTOM_MEMORY_MANAGEMENT=0 \
        -DCMAKE_BUILD_TYPE=$DBGREL \
        -DCMAKE_INSTALL_PREFIX="$BUILD_OUTPUT" \
        -DCMAKE_CXX_FLAGS="-std=c++11 -stdlib=libc++ -miphoneos-version-min=$MIN_VERSION" \
		-DSTATIC_LINKING=1 \
		-DTARGET_ARCH=APPLE \
		-DCMAKE_CXX_FLAGS=-O3 \
		-DCPP_STANDARD=14 \
		-DENABLE_CURL_CLIENT=Yes \
		-DCURL_INCLUDE_DIR=${WORKSPACE}/openssl_curl_for_ios_android.20170105/output/ios/curl-ios-$ARCH/include \
		-DCURL_LIBRARY=${WORKSPACE}/openssl_curl_for_ios_android.20170105/output/ios/curl-ios-$ARCH/lib/libcurl.a \
		-DCMAKE_IOS_DEPLOYMENT_TARGET=“12” \
		-DENABLE_OPENSSL_ENCRYPTION=Yes \
		-DOPENSSL_CRYPTO_LIBRARY=${WORKSPACE}/openssl_curl_for_ios_android.20170105/output/ios/openssl-ios-$ARCH/lib/libcrypto.a \
		-DOPENSSL_SSL_LIBRARY=${WORKSPACE}/openssl_curl_for_ios_android.20170105/output/ios/openssl-ios-$ARCH/lib/libssl.a \
		-DOPENSSL_INCLUDE_DIR=${WORKSPACE}/openssl_curl_for_ios_android.20170105/output/ios/openssl-ios-$ARCH/include \
        $WORKSPACE/aws-sdk-cpp
    make -j 8
    make install

    # Go back
    cd ..
	cd ..
}


# ----------------------------------
# To build arm64, armv7, armv7s
# ----------------------------------
build_AWSDebug_bitcode()
{
	export ARCH=$1
	export DBGREL="Debug"
	export BUILD_FOLDER=build/iOS-$ARCH-$DBGREL

    # Build intermediates dir
    mkdir -p $BUILD_FOLDER
    cd $BUILD_FOLDER

    # Cleanup
    rm -r ./*

	export SDK=$2

    export CC="$(xcrun -sdk iphoneos -find clang)"
    export CPP="$CC -E"
    export CFLAGS="-arch ${ARCH} -isysroot $SDK -miphoneos-version-min=$MIN_VERSION"
    export AR=$(xcrun -sdk iphoneos -find ar)
    export RANLIB=$(xcrun -sdk iphoneos -find ranlib)
    export CPPFLAGS="-arch ${ARCH} -isysroot $SDK -miphoneos-version-min=$MIN_VERSION"
    export LDFLAGS="-arch ${ARCH} -isysroot $SDK"

    BUILD_OUTPUT="${WORKSPACE}/output/iOS/${ARCH}/${DBGREL}"
    mkdir -p $BUILD_OUTPUT

    echo $CMAKE_CXX_FLAGS

    cmake -Wno-dev \
        -DCMAKE_OSX_SYSROOT="$IPHONEOS_SDK" \
        -DCMAKE_OSX_ARCHITECTURES=$ARCH \
        -DCMAKE_SYSTEM_NAME="Darwin" \
		-DENABLE_TESTING=0 \
		-DBUILD_ONLY="kinesis;cognito-identity;cognito-sync;lambda;s3;apigateway;identity-management" \
        -DCMAKE_SHARED_LINKER_FLAGS="-framework Foundation -lz -framework Security" \
        -DCMAKE_EXE_LINKER_FLAGS="-framework Foundation -framework Security" \
        -DCMAKE_PREFIX_PATH="$WORKSPACE/libcurl/" \
        -DBUILD_SHARED_LIBS=OFF \
        -DCUSTOM_MEMORY_MANAGEMENT=0 \
        -DCMAKE_BUILD_TYPE=$DBGREL \
        -DCMAKE_INSTALL_PREFIX="$BUILD_OUTPUT" \
        -DCMAKE_CXX_FLAGS="-std=c++11 -stdlib=libc++ -miphoneos-version-min=$MIN_VERSION" \
        $WORKSPACE/aws-sdk-cpp
    make -j 8
    make install

    # Go back
    cd ..
	cd ..
}




# ----------------------------------
# To build i386, x86_64 (fails currently)
# ----------------------------------
build_AWSRelease_Simulator_bitcode()
{
    export ARCH=$1
	export DBGREL="Release"
	export BUILD_FOLDER=build/iOS-$ARCH-$DBGREL

    # Build intermediates dir
    mkdir -p $BUILD_FOLDER
    cd $BUILD_FOLDER

    # Cleanup
    rm -r ./*

    export SDK=$2

    export CC="$(xcrun -sdk iphonesimulator -find clang)"
    export CPP="$CC -E"
    export CFLAGS="-arch ${ARCH} -isysroot $SDK -miphoneos-version-min=$MIN_VERSION"
    export AR=$(xcrun -sdk iphonesimulator -find ar)
    export RANLIB=$(xcrun -sdk iphonesimulator -find ranlib)
    export CPPFLAGS="-arch ${ARCH} -isysroot $SDK -miphoneos-version-min=$MIN_VERSION -Wno-error"
    export LDFLAGS="-arch ${ARCH} -isysroot $SDK"

    BUILD_OUTPUT="${WORKSPACE}/output/iOS/${ARCH}/${DBGREL}"
    mkdir -p $BUILD_OUTPUT

    echo $CMAKE_CXX_FLAGS

    cmake -Wno-dev \
    -DCMAKE_OSX_SYSROOT=$IPHONESIMULATOR_SDK \
    -DCMAKE_OSX_ARCHITECTURES=$ARCH \
    -DCMAKE_SYSTEM_NAME="Darwin" \
	-DENABLE_TESTING=0 \
	-DBUILD_ONLY="kinesis;cognito-identity;cognito-sync;lambda;s3;apigateway;identity-management" \
    -DCMAKE_SHARED_LINKER_FLAGS="-framework Foundation -lz -framework Security" \
    -DCMAKE_EXE_LINKER_FLAGS="-framework Foundation -framework Security" \
    -DCMAKE_PREFIX_PATH="$WORKSPACE/libcurl/" \
    -DBUILD_SHARED_LIBS=OFF \
    -DCUSTOM_MEMORY_MANAGEMENT=0 \
    -DCMAKE_BUILD_TYPE=$DBGREL \
    -DCMAKE_INSTALL_PREFIX="$BUILD_OUTPUT" \
    -DCMAKE_CXX_FLAGS="-std=c++11 -stdlib=libc++ -miphoneos-version-min=$MIN_VERSION" \
	-DSTATIC_LINKING=1 \
	-DTARGET_ARCH=APPLE \
	-DCMAKE_CXX_FLAGS=-O3 \
	-DCPP_STANDARD=14 \
	-DENABLE_CURL_CLIENT=Yes \
	-DCURL_INCLUDE_DIR=${WORKSPACE}/openssl_curl_for_ios_android.20170105/output/ios/curl-ios-$ARCH/include \
	-DCURL_LIBRARY=${WORKSPACE}/openssl_curl_for_ios_android.20170105/output/ios/curl-ios-$ARCH/lib/libcurl.a \
	-DCMAKE_IOS_DEPLOYMENT_TARGET=“12” \
	-DENABLE_OPENSSL_ENCRYPTION=Yes \
	-DOPENSSL_CRYPTO_LIBRARY=${WORKSPACE}/openssl_curl_for_ios_android.20170105/output/ios/openssl-ios-$ARCH/lib/libcrypto.a \
	-DOPENSSL_SSL_LIBRARY=${WORKSPACE}/openssl_curl_for_ios_android.20170105/output/ios/openssl-ios-$ARCH/lib/libssl.a \
	-DOPENSSL_INCLUDE_DIR=${WORKSPACE}/openssl_curl_for_ios_android.20170105/output/ios/openssl-ios-$ARCH/include \
    $WORKSPACE/aws-sdk-cpp
    make -j 8
    make install

    # Go back
    cd ..
	cd ..
}


# ----------------------------------
# To build i386, x86_64 (fails currently)
# ----------------------------------
build_AWSDebug_Simulator_bitcode()
{
    export ARCH=$1
	export DBGREL="Debug"
	export BUILD_FOLDER=build/iOS-$ARCH-$DBGREL

    # Build intermediates dir
    mkdir -p $BUILD_FOLDER
    cd $BUILD_FOLDER

    # Cleanup
    rm -r ./*

    export SDK=$2

    export CC="$(xcrun -sdk iphonesimulator -find clang)"
    export CPP="$CC -E"
    export CFLAGS="-arch ${ARCH} -isysroot $SDK -miphoneos-version-min=$MIN_VERSION"
    export AR=$(xcrun -sdk iphonesimulator -find ar)
    export RANLIB=$(xcrun -sdk iphonesimulator -find ranlib)
    export CPPFLAGS="-arch ${ARCH} -isysroot $SDK -miphoneos-version-min=$MIN_VERSION -Wno-error"
    export LDFLAGS="-arch ${ARCH} -isysroot $SDK"

    BUILD_OUTPUT="${WORKSPACE}/output/iOS/${ARCH}/${DBGREL}"
    mkdir -p $BUILD_OUTPUT

    echo $CMAKE_CXX_FLAGS

    cmake -Wno-dev \
    -DCMAKE_OSX_SYSROOT=$IPHONESIMULATOR_SDK \
    -DCMAKE_OSX_ARCHITECTURES=$ARCH \
    -DCMAKE_SYSTEM_NAME="Darwin" \
	-DENABLE_TESTING=0 \
	-DBUILD_ONLY="kinesis;cognito-identity;cognito-sync;lambda;s3;apigateway;identity-management" \
    -DCMAKE_SHARED_LINKER_FLAGS="-framework Foundation -lz -framework Security" \
    -DCMAKE_EXE_LINKER_FLAGS="-framework Foundation -framework Security" \
    -DCMAKE_PREFIX_PATH="$WORKSPACE/libcurl/" \
    -DBUILD_SHARED_LIBS=OFF \
    -DCUSTOM_MEMORY_MANAGEMENT=0 \
    -DCMAKE_BUILD_TYPE=$DBGREL \
    -DCMAKE_INSTALL_PREFIX="$BUILD_OUTPUT" \
    -DCMAKE_CXX_FLAGS="-std=c++11 -stdlib=libc++ -miphoneos-version-min=$MIN_VERSION" \
    $WORKSPACE/aws-sdk-cpp
    make -j 8
    make install

    # Go back
    cd ..
	cd ..
}

# ---------------------------------------------------
# Function to aggregate build outputs into a fat lib
# ---------------------------------------------------
aggregate_release_libs() {
    set +x
    AGG_OUTPUT_DIR=$1
	export DBGREL="Release"

    # Aggregate library and include files
    mkdir -p ${AGG_OUTPUT_DIR}/include
    mkdir -p ${AGG_OUTPUT_DIR}/lib

    cp -r ${WORKSPACE}/output/iOS/arm64/${DBGREL}/include/* ${AGG_OUTPUT_DIR}/include/

    ## declare an array variable with required aws components
    ## This is an example. Change as required
    declare -a components=( "libaws-cpp-sdk-access-management"
                            "libaws-cpp-sdk-cognito-identity"
                            "libaws-cpp-sdk-cognito-sync"
							"libaws-cpp-sdk-core"
                            "libaws-cpp-sdk-iam"
                            "libaws-cpp-sdk-kinesis"
                            "libaws-cpp-sdk-lambda"
							"libaws-cpp-sdk-apigateway"
							"libaws-cpp-sdk-s3"
							"libaws-cpp-sdk-identity-management"
							"libaws-c-auth"
							"libaws-c-cal"
							"libaws-c-common"
							"libaws-c-compression"
							"libaws-c-event-stream"
							"libaws-c-http"
							"libaws-c-io"
							"libaws-c-mqtt"
							"libaws-c-s3"
							"libaws-crt-cpp"
							"libaws-checksums"
                            )

    ## now loop through the above array
    for component in "${components[@]}"
    do
        LIBNAME="${component}.a"
        echo "--------- Aggregating $LIBNAME ---------"
        xcrun -sdk iphoneos lipo \
        "${WORKSPACE}/output/iOS/arm64/${DBGREL}/lib/${LIBNAME}" \
        "${WORKSPACE}/output/iOS/armv7/${DBGREL}/lib/${LIBNAME}" \
        "${WORKSPACE}/output/iOS/x86_64/${DBGREL}/lib/${LIBNAME}" \
        -create -output ${AGG_OUTPUT_DIR}/lib/${LIBNAME}

        # verify arch
        echo "- Running lipo info for $LIBNAME:"
        lipo -info ${AGG_OUTPUT_DIR}/lib/${LIBNAME}
        echo "--------------------------------------------------"
    done

    echo "--------------------------------------------------"
    echo "Aggregated output location: ${AGG_OUTPUT_DIR}"
    echo "--------------------------------------------------"
}

# ---------------------------------------------------
# Function to aggregate build outputs into a fat lib
# ---------------------------------------------------
aggregate_debug_libs() {
    set +x
    AGG_OUTPUT_DIR=$1
	export DBGREL="Debug"

    # Aggregate library and include files
    mkdir -p ${AGG_OUTPUT_DIR}/include
    mkdir -p ${AGG_OUTPUT_DIR}/lib

    cp -r ${WORKSPACE}/output/iOS/arm64/${DBGREL}/include/* ${AGG_OUTPUT_DIR}/include/

    ## declare an array variable with required aws components
    ## This is an example. Change as required
    declare -a components=( "access-management"
                            "cognito-identity"
                            "cognito-sync"
							"core"
                            "iam"
                            "kinesis"
                            "lambda"
                            )

    ## now loop through the above array
    for component in "${components[@]}"
    do
        LIBNAME="libaws-cpp-sdk-${component}.a"
        echo "--------- Aggregating $LIBNAME ---------"
        xcrun -sdk iphoneos lipo \
        "${WORKSPACE}/output/iOS/arm64/${DBGREL}/lib/${LIBNAME}" \
        "${WORKSPACE}/output/iOS/armv7/${DBGREL}/lib/${LIBNAME}" \
        "${WORKSPACE}/output/iOS/x86_64/${DBGREL}/lib/${LIBNAME}" \
        -create -output ${AGG_OUTPUT_DIR}/lib/${LIBNAME}

        # verify arch
        echo "- Running lipo info for $LIBNAME:"
        lipo -info ${AGG_OUTPUT_DIR}/lib/${LIBNAME}
        echo "--------------------------------------------------"
    done

    echo "--------------------------------------------------"
    echo "Aggregated output location: ${AGG_OUTPUT_DIR}"
    echo "--------------------------------------------------"
}

## Build release configuration
build_AWSRelease_bitcode "arm64" "${IPHONEOS_SDK}"
build_AWSRelease_bitcode "armv7" "${IPHONEOS_SDK}"
#build_AWSRelease_bitcode "armv7s" "${IPHONEOS_SDK}"
#build_AWSRelease_Simulator_bitcode "i386" "${IPHONESIMULATOR_SDK}"
build_AWSRelease_Simulator_bitcode "x86_64" "${IPHONESIMULATOR_SDK}"

## Build debug configuration
#build_AWSDebug_bitcode "arm64" "${IPHONEOS_SDK}"
#build_AWSDebug_bitcode "armv7" "${IPHONEOS_SDK}"
#build_AWSDebug_bitcode "armv7s" "${IPHONEOS_SDK}"
#build_AWSDebug_Simulator_bitcode "i386" "${IPHONESIMULATOR_SDK}"
#build_AWSDebug_Simulator_bitcode "x86_64" "${IPHONESIMULATOR_SDK}"

## Aggregate into a fat lib. Argument provided here is the output directory
aggregate_release_libs "${WORKSPACE}/output/iOS/fatlib/release"
#aggregate_debug_libs "${WORKSPACE}/output/iOS/fatlib/debug"
