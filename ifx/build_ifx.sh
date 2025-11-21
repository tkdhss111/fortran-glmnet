#!/bin/bash
# Build script for glmnet_wrapper using Intel Fortran Compiler (ifx)

set -e  # Exit on error

echo "========================================"
echo "glmnet_wrapper - Intel ifx Build Script"
echo "========================================"
echo ""

# Check if ifx is available
if ! command -v ifx &> /dev/null; then
    echo "ERROR: Intel Fortran Compiler (ifx) not found!"
    echo ""
    echo "Please install Intel oneAPI or source the environment:"
    echo "  source /opt/intel/oneapi/setvars.sh"
    echo ""
    echo "Or load the module:"
    echo "  module load intel"
    echo ""
    exit 1
fi

# Show ifx version
echo "Intel Fortran Compiler:"
ifx --version | head -2
echo ""

# Compiler and flags
FC=ifx
FFLAGS_GLMNET="-O3 -std08 -warn nousage"
FFLAGS_WRAPPER="-O3 -xHost -fp-model precise"
FFLAGS_APP="-O3 -xHost -fp-model precise"

# Files
GLMNET_SRC="glmnet.f"
WRAPPER_SRC="glmnet_wrapper.f90"
TEST_SRC="test_glmnet_wrapper.f90"
SIMPLE_SRC="simple_example.f90"

# Check for required files
echo "Checking for required files..."
if [ ! -f "$GLMNET_SRC" ]; then
    echo "ERROR: $GLMNET_SRC not found!"
    echo "Please provide the glmnet.f file."
    exit 1
fi

if [ ! -f "$WRAPPER_SRC" ]; then
    echo "ERROR: $WRAPPER_SRC not found!"
    exit 1
fi

echo "✓ All required files found"
echo ""

# Clean previous build
echo "Cleaning previous build..."
rm -f *.o *.mod *.a test_glmnet_wrapper simple_example
echo "✓ Clean complete"
echo ""

# Compile glmnet.f
echo "Compiling glmnet.f..."
$FC $FFLAGS_GLMNET -c $GLMNET_SRC
echo "✓ glmnet.o created"
echo ""

# Compile wrapper
echo "Compiling glmnet_wrapper.f90..."
$FC $FFLAGS_WRAPPER -c $WRAPPER_SRC
echo "✓ glmnet_wrapper.o created"
echo ""

# Create library
echo "Creating static library..."
ar rcs libglmnet_wrapper.a glmnet.o glmnet_wrapper.o
echo "✓ libglmnet_wrapper.a created"
echo ""

# Compile test program (if exists)
if [ -f "$TEST_SRC" ]; then
    echo "Compiling test program..."
    $FC $FFLAGS_APP $TEST_SRC libglmnet_wrapper.a -o test_glmnet_wrapper
    echo "✓ test_glmnet_wrapper created"
    echo ""
    
    # Run tests
    echo "Running tests..."
    echo "----------------------------------------"
    ./test_glmnet_wrapper | head -30
    echo "..."
    echo "----------------------------------------"
    echo "✓ Tests completed"
    echo ""
fi

# Compile simple example (if exists)
if [ -f "$SIMPLE_SRC" ]; then
    echo "Compiling simple example..."
    $FC $FFLAGS_APP $SIMPLE_SRC libglmnet_wrapper.a -o simple_example
    echo "✓ simple_example created"
    echo ""
fi

# Summary
echo "========================================"
echo "Build Summary"
echo "========================================"
echo "Compiler: Intel Fortran (ifx)"
echo "Optimization: -O3 -xHost"
echo "Library: libglmnet_wrapper.a"
if [ -f "test_glmnet_wrapper" ]; then
    echo "Test program: test_glmnet_wrapper"
fi
if [ -f "simple_example" ]; then
    echo "Example: simple_example"
fi
echo ""
echo "Usage:"
echo "  ifx -O3 your_program.f90 libglmnet_wrapper.a -o your_program"
echo ""
echo "✓ Build successful!"
echo "========================================"
