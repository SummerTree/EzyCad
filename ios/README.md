# EzyCad iOS Build Guide

This document describes how to build EzyCad for iOS devices.

## Prerequisites

### Required Tools
- **Xcode** (latest version from Mac App Store)
- **CMake** 3.14.0 or later
- **Apple Developer Account** (for device deployment)

### Required Dependencies
- **Open CASCADE Technology (OCCT) 7.9.1+** compiled for iOS
- iOS SDK 14.0 or later

## Building Open CASCADE for iOS

EzyCad requires OCCT compiled for iOS. Follow these steps to build OCCT:

### 1. Clone OCCT Repository

```bash
git clone https://github.com/Open-Cascade-SAS/OCCT.git
cd OCCT
git checkout V7_9_1
```

### 2. Configure for iOS

Create a build directory and configure with CMake:

```bash
mkdir build_ios && cd build_ios
cmake .. \
    -DCMAKE_TOOLCHAIN_FILE=<path_to_ios_toolchain> \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=14.0 \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_MODULE_DISABLE_Draw=TRUE \
    -DBUILD_MODULE_DISABLE_Qt=FALSE \
    -DBUILD_MODULE_DISABLE_Tcl=FALSE \
    -DBUILD_MODULE_DISABLE_Tk=FALSE \
    -DUSE_VIRTUALGL=FALSE \
    -DUSE_GL2PS=FALSE \
    -DINSTALL_TCL_TEST_FILES=FALSE \
    -DINSTALL_PYTHON_TEST_FILES=FALSE
```

### 3. Build OCCT

```bash
make -j$(sysctl -n hw.ncpu)
make install
```

Set the installation path:
```bash
export OpenCASCADE_DIR=/path/to/occt/install
```

## Building EzyCad for iOS

### 1. Clone EzyCad Repository

```bash
git clone https://github.com/your-repo/EzyCad.git
cd EzyCad
```

### 2. Configure with CMake for iOS

```bash
mkdir build_ios && cd build_ios
cmake .. \
    -DCMAKE_TOOLCHAIN_FILE=cmake/ios.toolchain.cmake \
    -DIOS_DEPLOYMENT_TARGET=14.0 \
    -DIOS_PLATFORM=OS64 \
    -DOpenCASCADE_DIR=$OpenCASCADE_DIR \
    -DCMAKE_BUILD_TYPE=Release
```

### 3. Build

```bash
make -j$(sysctl -n hw.ncpu)
```

### 4. Generate Xcode Project (Alternative)

For development with Xcode:

```bash
cmake .. \
    -GXcode \
    -DCMAKE_TOOLCHAIN_FILE=cmake/ios.toolchain.cmake \
    -DIOS_DEPLOYMENT_TARGET=14.0 \
    -DIOS_PLATFORM=OS64 \
    -DOpenCASCADE_DIR=$OpenCASCADE_DIR
```

Then open the generated `.xcodeproj` in Xcode.

## Running on iOS Device

### Simulator (Quick Test)

```bash
xcrun simctl list devices
xcrun simctl boot <device_id>
xcrun simctl install <device_id> build/EzyCad.app
xcrun simctl launch <device_id> com.ezycad.EzyCad
```

### Physical Device

1. Open `EzyCad.xcodeproj` in Xcode
2. Select your target device
3. Configure signing (Team ID)
4. Build and Run (Cmd+R)

## Project Structure for iOS

```
EzyCad/
├── src/
│   ├── ios_window.h          # iOS window abstraction
│   ├── ios_window.mm         # iOS window implementation
│   ├── platform_window.h     # Cross-platform window abstraction
│   ├── ios_main.mm           # iOS app entry point
│   └── ios_main_loop.mm      # iOS main loop
├── cmake/
│   └── ios.toolchain.cmake   # CMake toolchain for iOS
└── res/                      # Resources (copied to bundle)
```

## iOS-Specific Considerations

### Supported Features

| Feature | Status | Notes |
|---------|--------|-------|
| 2D/3D Viewing | Supported | Full OpenGL ES 2.0 support |
| Sketch Creation | Supported | Touch-based input |
| Extrude/Cut | Supported | |
| Boolean Operations | Supported | |
| File Import (STEP/PLY) | Supported | |
| File Export (STEP/STL) | Supported | |
| Undo/Redo | Supported | |
| Lua Scripting | Supported | |
| Python Scripting | Not Supported | iOS sandboxing |

### Known Limitations

1. **Python Console Disabled**: Due to iOS sandboxing restrictions, the Python console is not available on iOS.

2. **External File Access**: File operations are limited to app sandbox. Use the iOS Files app integration for document access.

3. **Memory Constraints**: iOS devices have limited memory. Large models may experience performance issues.

4. **No Keyboard**: Touch-only input. Some keyboard shortcuts are not available.

### Performance Tips

- Use lower polygon counts for mobile models
- Enable view clipping for large assemblies
- Use simplified representations for complex parts

## Troubleshooting

### CMake Cannot Find iOS SDK

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
xcrun --sdk iphoneos --show-sdk-path
```

### OpenGL ES Context Creation Fails

Ensure EAGLContext is properly initialized:
```objc
EAGLContext* context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
[EAGLContext setCurrentContext:context];
```

### OCCT Linker Errors

Ensure OCCT was built with the same compiler flags:
- `-fexceptions`
- `-fobjc-arc` (for Objective-C++ interop)

### Memory Warnings

Monitor memory usage and implement proper cleanup:
```objc
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Clear caches and non-essential resources
}
```

## Further Development

### Adding Touch Gestures

The iOS implementation supports basic touch input. To add gesture recognizers:

```objc
UIPinchGestureRecognizer* pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
[self.view addGestureRecognizer:pinch];
```

### Custom UI Controls

ImGui handles most UI. For native iOS controls, integrate via Metal or add custom OpenGL ES rendering.

## License

Same as main EzyCad project. See LICENSE file.
