# CMake Build System for glmnet_wrapper

## Complete CMake Guide

This document explains how to build glmnet_wrapper using CMake with both GNU gfortran and Intel ifx compilers.

---

## Directory Structure

To use the CMake build system, organize your files as follows:

```
glmnet_wrapper/
├── CMakeLists.txt                  # Main CMake file
├── README.md
├── src/
│   ├── CMakeLists.txt             # Source directory CMake
│   ├── glmnet.f                   # Original glmnet code
│   └── glmnet_wrapper.f90         # Wrapper module
├── tests/
│   ├── CMakeLists.txt             # Tests directory CMake
│   └── test_glmnet_wrapper.f90    # Test program
├── examples/
│   ├── CMakeLists.txt             # Examples directory CMake
│   ├── simple_example.f90
│   ├── benchmark_ifx.f90
│   └── advanced_ifx_example.f90
└── cmake/
    ├── CompilerFlags_GNU.cmake     # GNU compiler flags
    ├── CompilerFlags_Intel.cmake   # Intel compiler flags
    └── glmnet_wrapper-config.cmake.in  # Package config template
```

---

## Quick Start

### Basic Build (Out-of-Source)

```bash
# Create build directory
mkdir build
cd build

# Configure
cmake ..

# Build
cmake --build .

# Run tests
ctest --output-on-failure

# Install (optional)
cmake --install . --prefix /path/to/install
```

---

## Configuration Options

### Build Type

```bash
# Debug build (for development)
cmake -DCMAKE_BUILD_TYPE=Debug ..

# Release build (optimized, recommended)
cmake -DCMAKE_BUILD_TYPE=Release ..

# Release with debug info
cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo ..

# Minimum size release
cmake -DCMAKE_BUILD_TYPE=MinSizeRel ..
```

### Features

```bash
# Enable OpenMP
cmake -DENABLE_OPENMP=ON ..

# Enable Intel MKL (Intel compilers only)
cmake -DENABLE_MKL=ON ..

# Enable IPO/LTO
cmake -DENABLE_IPO=ON ..

# Build shared library (default is static)
cmake -DBUILD_SHARED_LIBS=ON ..

# Disable tests
cmake -DBUILD_TESTING=OFF ..

# Disable examples
cmake -DBUILD_EXAMPLES=OFF ..
```

### Combined Options

```bash
# Maximum performance with Intel ifx
cmake -DCMAKE_BUILD_TYPE=Release \
      -DENABLE_OPENMP=ON \
      -DENABLE_MKL=ON \
      -DENABLE_IPO=ON \
      ..

# Development build with gfortran
cmake -DCMAKE_BUILD_TYPE=Debug \
      -DCMAKE_Fortran_COMPILER=gfortran \
      ..
```

---

## Compiler Selection

### GNU gfortran

```bash
# Automatic (if gfortran is default)
cmake ..

# Explicit
cmake -DCMAKE_Fortran_COMPILER=gfortran ..

# With specific version
cmake -DCMAKE_Fortran_COMPILER=gfortran-13 ..
```

### Intel ifx (LLVM-based, recommended)

```bash
# Source Intel environment first
source /opt/intel/oneapi/setvars.sh

# Configure
cmake -DCMAKE_Fortran_COMPILER=ifx ..
```

### Intel ifort (classic)

```bash
# Source Intel environment
source /opt/intel/oneapi/setvars.sh

# Configure
cmake -DCMAKE_Fortran_COMPILER=ifort ..
```

---

## Complete Build Examples

### Example 1: Basic gfortran build

```bash
mkdir build && cd build
cmake -DCMAKE_Fortran_COMPILER=gfortran \
      -DCMAKE_BUILD_TYPE=Release \
      ..
cmake --build .
ctest
```

### Example 2: Intel ifx with all optimizations

```bash
# Source Intel compiler
source /opt/intel/oneapi/setvars.sh

# Build
mkdir build && cd build
cmake -DCMAKE_Fortran_COMPILER=ifx \
      -DCMAKE_BUILD_TYPE=Release \
      -DENABLE_OPENMP=ON \
      -DENABLE_MKL=ON \
      -DENABLE_IPO=ON \
      ..
cmake --build . --parallel

# Run tests
ctest --output-on-failure

# Install
sudo cmake --install . --prefix /usr/local
```

### Example 3: Debug build for development

```bash
mkdir build-debug && cd build-debug
cmake -DCMAKE_BUILD_TYPE=Debug \
      -DCMAKE_Fortran_COMPILER=gfortran \
      ..
cmake --build .

# Run test with debugger
gdb ./tests/test_glmnet_wrapper
```

### Example 4: Multiple configurations

```bash
# Release build
mkdir build-release && cd build-release
cmake -DCMAKE_BUILD_TYPE=Release ..
cmake --build .
cd ..

# Debug build
mkdir build-debug && cd build-debug
cmake -DCMAKE_BUILD_TYPE=Debug ..
cmake --build .
cd ..
```

---

## Installation

### System-wide installation

```bash
cd build
sudo cmake --install .
```

Default locations:
- Library: `/usr/local/lib/libglmnet_wrapper.a`
- Modules: `/usr/local/include/*.mod`
- CMake files: `/usr/local/lib/cmake/glmnet_wrapper/`

### Custom installation prefix

```bash
cmake --install . --prefix $HOME/local
```

Locations:
- Library: `$HOME/local/lib/libglmnet_wrapper.a`
- Modules: `$HOME/local/include/*.mod`
- CMake files: `$HOME/local/lib/cmake/glmnet_wrapper/`

### Using installed library

After installation, use in your project:

```cmake
find_package(glmnet_wrapper REQUIRED)
target_link_libraries(your_target PRIVATE glmnet_wrapper::glmnet_wrapper)
```

---

## Testing

### Run all tests

```bash
cd build
ctest
```

### Verbose test output

```bash
ctest --output-on-failure --verbose
```

### Run specific test

```bash
ctest -R test_glmnet_wrapper
```

### Run with parallelism

```bash
ctest --parallel 4
```

---

## Building Examples

Examples are built automatically if `BUILD_EXAMPLES=ON` (default).

After building:

```bash
cd build

# Run simple example
./examples/simple_example

# Run benchmark
./examples/benchmark_example

# Run advanced example (if OpenMP enabled)
export OMP_NUM_THREADS=4
./examples/advanced_example
```

---

## Advanced Usage

### Cross-compilation

```bash
cmake -DCMAKE_Fortran_COMPILER=/path/to/cross-compiler \
      -DCMAKE_SYSTEM_NAME=Linux \
      -DCMAKE_SYSTEM_PROCESSOR=x86_64 \
      ..
```

### Parallel build

```bash
cmake --build . --parallel 8
# Or with make
make -j8
```

### Verbose build

```bash
cmake --build . --verbose
# Or with make
make VERBOSE=1
```

### Specify generator

```bash
# Ninja (faster than Make)
cmake -G Ninja ..
ninja

# Unix Makefiles
cmake -G "Unix Makefiles" ..
make

# Xcode (macOS)
cmake -G Xcode ..
open glmnet_wrapper.xcodeproj
```

---

## Compiler Flags

### View compiler flags

```bash
cmake -L ..  # List cache variables
cmake -LA .. # List all variables
```

### Override flags

```bash
# Override all flags
cmake -DCMAKE_Fortran_FLAGS="-O2 -g" ..

# Add to existing flags
cmake -DCMAKE_Fortran_FLAGS="${CMAKE_Fortran_FLAGS} -ffast-math" ..
```

### CPU-specific optimization (gfortran)

```bash
cmake -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_Fortran_FLAGS_RELEASE="-O3 -march=skylake" \
      ..
```

### CPU-specific optimization (ifx)

```bash
cmake -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_Fortran_FLAGS_RELEASE="-O3 -xCORE-AVX512" \
      ..
```

---

## Troubleshooting

### Problem: CMake can't find Fortran compiler

**Solution**: Specify compiler explicitly
```bash
cmake -DCMAKE_Fortran_COMPILER=/path/to/gfortran ..
```

### Problem: Intel compiler not found

**Solution**: Source Intel environment
```bash
source /opt/intel/oneapi/setvars.sh
cmake -DCMAKE_Fortran_COMPILER=ifx ..
```

### Problem: MKL not found

**Solution**: Make sure MKL is installed and environment is sourced
```bash
source /opt/intel/oneapi/setvars.sh
cmake -DENABLE_MKL=ON ..
```

### Problem: Build fails with legacy Fortran errors

**Solution**: Update CMakeLists.txt to use appropriate legacy flags for glmnet.f

### Problem: Tests fail

**Solution**: Run with verbose output
```bash
ctest --output-on-failure --verbose
```

---

## Performance Comparison

### Benchmark different configurations

```bash
# gfortran Release
mkdir build-gfortran && cd build-gfortran
cmake -DCMAKE_Fortran_COMPILER=gfortran -DCMAKE_BUILD_TYPE=Release ..
cmake --build .
./examples/benchmark_example > results_gfortran.txt
cd ..

# ifx Release
source /opt/intel/oneapi/setvars.sh
mkdir build-ifx && cd build-ifx
cmake -DCMAKE_Fortran_COMPILER=ifx -DCMAKE_BUILD_TYPE=Release ..
cmake --build .
./examples/benchmark_example > results_ifx.txt
cd ..

# Compare results
diff results_gfortran.txt results_ifx.txt
```

---

## Integration with Other Projects

### Using CMake FetchContent

```cmake
include(FetchContent)

FetchContent_Declare(
    glmnet_wrapper
    GIT_REPOSITORY https://github.com/your/glmnet_wrapper.git
    GIT_TAG        v1.0.0
)

FetchContent_MakeAvailable(glmnet_wrapper)

target_link_libraries(your_target PRIVATE glmnet_wrapper::glmnet_wrapper)
```

### Using add_subdirectory

```cmake
add_subdirectory(external/glmnet_wrapper)
target_link_libraries(your_target PRIVATE glmnet_wrapper::glmnet_wrapper)
```

### Using find_package (after installation)

```cmake
find_package(glmnet_wrapper REQUIRED)
target_link_libraries(your_target PRIVATE glmnet_wrapper::glmnet_wrapper)
```

---

## CMake Presets (CMake 3.19+)

Create `CMakePresets.json`:

```json
{
  "version": 3,
  "cmakeMinimumRequired": {
    "major": 3,
    "minor": 19,
    "patch": 0
  },
  "configurePresets": [
    {
      "name": "default",
      "hidden": true,
      "generator": "Ninja",
      "binaryDir": "${sourceDir}/build/${presetName}",
      "cacheVariables": {
        "CMAKE_EXPORT_COMPILE_COMMANDS": "ON"
      }
    },
    {
      "name": "release-gfortran",
      "inherits": "default",
      "cacheVariables": {
        "CMAKE_BUILD_TYPE": "Release",
        "CMAKE_Fortran_COMPILER": "gfortran"
      }
    },
    {
      "name": "release-ifx",
      "inherits": "default",
      "cacheVariables": {
        "CMAKE_BUILD_TYPE": "Release",
        "CMAKE_Fortran_COMPILER": "ifx",
        "ENABLE_OPENMP": "ON",
        "ENABLE_MKL": "ON"
      }
    },
    {
      "name": "debug",
      "inherits": "default",
      "cacheVariables": {
        "CMAKE_BUILD_TYPE": "Debug"
      }
    }
  ]
}
```

Usage:
```bash
cmake --preset release-gfortran
cmake --build build/release-gfortran
```

---

## Summary

### Recommended Builds

**For development (gfortran)**:
```bash
cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_Fortran_COMPILER=gfortran ..
```

**For production (gfortran)**:
```bash
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_Fortran_COMPILER=gfortran ..
```

**For maximum performance (Intel ifx)**:
```bash
source /opt/intel/oneapi/setvars.sh
cmake -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_Fortran_COMPILER=ifx \
      -DENABLE_OPENMP=ON \
      -DENABLE_MKL=ON \
      -DENABLE_IPO=ON \
      ..
```

---

## Quick Reference

| Task | Command |
|------|---------|
| **Configure** | `cmake ..` |
| **Build** | `cmake --build .` |
| **Test** | `ctest` |
| **Install** | `cmake --install .` |
| **Clean** | `cmake --build . --target clean` |
| **Reconfigure** | `cmake .` |
| **Full rebuild** | `rm -rf * && cmake .. && cmake --build .` |

---

## Support

- CMake documentation: https://cmake.org/documentation/
- CMake tutorial: https://cmake.org/cmake/help/latest/guide/tutorial/
- CMake Fortran: https://cmake.org/cmake/help/latest/command/project.html#fortran

---

**The CMake build system provides a modern, portable, and flexible way to build glmnet_wrapper!** 🎯
