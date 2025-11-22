#!/bin/bash
# Setup script to create CMake directory structure and copy files

set -e

echo "=========================================="
echo "  glmnet_wrapper CMake Setup"
echo "=========================================="
echo ""

# Check if we're in the right directory
if [ ! -f "glmnet_wrapper.f90" ]; then
    echo "ERROR: glmnet_wrapper.f90 not found!"
    echo "Please run this script from the directory containing glmnet_wrapper.f90"
    exit 1
fi

echo "Creating directory structure..."

# Create directories
mkdir -p src
mkdir -p tests
mkdir -p examples
mkdir -p cmake
mkdir -p build

echo "✓ Directories created"
echo ""

# Move/copy source files
echo "Organizing source files..."

# Copy source files to src/
if [ -f "glmnet.f" ]; then
    cp glmnet.f src/
    echo "✓ Copied glmnet.f to src/"
else
    echo "⚠ glmnet.f not found - you'll need to add it to src/ manually"
fi

if [ -f "glmnet_wrapper.f90" ]; then
    cp glmnet_wrapper.f90 src/
    echo "✓ Copied glmnet_wrapper.f90 to src/"
fi

# Copy test files to tests/
if [ -f "test_glmnet_wrapper.f90" ]; then
    cp test_glmnet_wrapper.f90 tests/
    echo "✓ Copied test_glmnet_wrapper.f90 to tests/"
fi

# Copy example files to examples/
for example in simple_example.f90 benchmark_ifx.f90 advanced_ifx_example.f90; do
    if [ -f "$example" ]; then
        cp "$example" examples/
        echo "✓ Copied $example to examples/"
    fi
done

echo ""

# Copy CMake files
echo "Setting up CMake files..."

# Main CMakeLists.txt
if [ -f "CMakeLists.txt" ]; then
    echo "✓ CMakeLists.txt already exists"
else
    echo "⚠ You need to create CMakeLists.txt in the root directory"
fi

# Subdirectory CMakeLists.txt files
if [ -f "src_CMakeLists.txt" ]; then
    cp src_CMakeLists.txt src/CMakeLists.txt
    echo "✓ Created src/CMakeLists.txt"
fi

if [ -f "tests_CMakeLists.txt" ]; then
    cp tests_CMakeLists.txt tests/CMakeLists.txt
    echo "✓ Created tests/CMakeLists.txt"
fi

if [ -f "examples_CMakeLists.txt" ]; then
    cp examples_CMakeLists.txt examples/CMakeLists.txt
    echo "✓ Created examples/CMakeLists.txt"
fi

# Compiler flags files
for flags_file in cmake_CompilerFlags_GNU.cmake cmake_CompilerFlags_Intel.cmake cmake_glmnet_wrapper-config.cmake.in; do
    if [ -f "$flags_file" ]; then
        target_name=$(echo $flags_file | sed 's/cmake_//')
        cp "$flags_file" "cmake/$target_name"
        echo "✓ Created cmake/$target_name"
    fi
done

echo ""

# Show directory structure
echo "=========================================="
echo "  Directory Structure"
echo "=========================================="
tree -L 2 -I 'build' 2>/dev/null || find . -maxdepth 2 -type f -name "*.txt" -o -name "*.cmake" -o -name "*.f90" -o -name "*.f" | sort

echo ""
echo "=========================================="
echo "  Next Steps"
echo "=========================================="
echo ""
echo "1. Verify that all files are in the correct directories:"
echo "   - src/: glmnet.f, glmnet_wrapper.f90"
echo "   - tests/: test_glmnet_wrapper.f90"
echo "   - examples/: simple_example.f90, etc."
echo "   - cmake/: CompilerFlags_*.cmake"
echo ""
echo "2. Build the project:"
echo "   cd build"
echo "   cmake .."
echo "   cmake --build ."
echo ""
echo "3. Run tests:"
echo "   ctest"
echo ""
echo "4. For detailed instructions, see CMAKE_GUIDE.md"
echo ""
echo "=========================================="
echo "  Setup Complete!"
echo "=========================================="
