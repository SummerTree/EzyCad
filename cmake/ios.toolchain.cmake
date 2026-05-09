# iOS toolchain for EzyCad
# Usage:
#   cmake .. -DCMAKE_TOOLCHAIN_FILE=ios.toolchain.cmake -DIOS_DEPLOYMENT_TARGET=14.0

set(CMAKE_SYSTEM_NAME iOS)
set(CMAKE_SYSTEM_VERSION 14.0)
set(CMAKE_XCODE_GENERATOR "Xcode")

# Target architecture
if(NOT DEFINED IOS_PLATFORM)
    set(IOS_PLATFORM "OS64")
endif()

if(IOS_PLATFORM STREQUAL "OS64")
    set(IOS_ARCH arm64)
    set(CMAKE_OSX_ARCHITECTURES arm64)
elseif(IOS_PLATFORM STREQUAL "SIMULATOR")
    set(IOS_ARCH x86_64)
    set(CMAKE_OSX_ARCHITECTURES x86_64)
endif()

# Find iOS SDK
set(CMAKE_OSX_SYSROOT $(shell xcrun --sdk iphoneos --show-sdk-path 2>/dev/null || echo "iphoneos"))
set(CMAKE_OSX_DEPLOYMENT_TARGET ${IOS_DEPLOYMENT_TARGET})

# Force compilers to clang for iOS
set(CMAKE_C_COMPILER clang)
set(CMAKE_CXX_COMPILER clang++)

# Strip debug symbols for release builds
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,-dead_strip")
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,-dead_strip")

# Find OpenCASCADE for iOS
if(NOT DEFINED OpenCASCADE_DIR)
    # Default OCCT installation path
    set(OpenCASCADE_DIR "/usr/local/opencascade")
endif()

message(STATUS "iOS Build Configuration:")
message(STATUS "  Platform: ${IOS_PLATFORM}")
message(STATUS "  Architecture: ${IOS_ARCH}")
message(STATUS "  Deployment Target: ${CMAKE_OSX_DEPLOYMENT_TARGET}")
message(STATUS "  Sysroot: ${CMAKE_OSX_SYSROOT}")
message(STATUS "  OpenCASCADE: ${OpenCASCADE_DIR}")
