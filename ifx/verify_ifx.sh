#!/bin/bash
# Intel ifx Installation and Setup Verification Script
# Tests if Intel Fortran Compiler is properly installed and configured

set -e

echo "=========================================="
echo "Intel ifx Verification Script"
echo "=========================================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

success_count=0
fail_count=0

# Function to print success
print_success() {
    echo -e "${GREEN}✓${NC} $1"
    ((success_count++))
}

# Function to print failure
print_failure() {
    echo -e "${RED}✗${NC} $1"
    ((fail_count++))
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Test 1: Check if ifx is in PATH
echo "Test 1: Checking for Intel Fortran Compiler (ifx)..."
if command -v ifx &> /dev/null; then
    print_success "ifx found in PATH"
    IFX_VERSION=$(ifx --version 2>&1 | head -1)
    echo "   Version: $IFX_VERSION"
else
    print_failure "ifx not found in PATH"
    echo ""
    echo "Solutions:"
    echo "  1. Source the Intel environment:"
    echo "     source /opt/intel/oneapi/setvars.sh"
    echo ""
    echo "  2. Or load the module (HPC systems):"
    echo "     module load intel"
    echo ""
    exit 1
fi
echo ""

# Test 2: Check ifx version
echo "Test 2: Checking ifx version..."
IFX_VERSION_MAJOR=$(ifx --version 2>&1 | grep -oP 'Version \K[0-9]+' | head -1)
if [ -z "$IFX_VERSION_MAJOR" ]; then
    print_warning "Could not determine ifx version"
elif [ "$IFX_VERSION_MAJOR" -ge 2021 ]; then
    print_success "ifx version is $IFX_VERSION_MAJOR (>= 2021)"
else
    print_warning "ifx version is $IFX_VERSION_MAJOR (< 2021, may have issues)"
fi
echo ""

# Test 3: Check for required files
echo "Test 3: Checking for required source files..."
if [ -f "glmnet.f" ]; then
    print_success "glmnet.f found"
else
    print_failure "glmnet.f not found"
fi

if [ -f "glmnet_wrapper.f90" ]; then
    print_success "glmnet_wrapper.f90 found"
else
    print_failure "glmnet_wrapper.f90 not found"
fi
echo ""

# Test 4: Test basic compilation
echo "Test 4: Testing basic compilation..."
cat > test_compile.f90 << 'EOF'
program test
  implicit none
  print *, 'Hello from Intel ifx'
end program test
EOF

if ifx -O2 test_compile.f90 -o test_compile 2>/dev/null; then
    print_success "Basic compilation works"
    if ./test_compile > /dev/null 2>&1; then
        print_success "Basic execution works"
    else
        print_failure "Compiled program failed to execute"
    fi
    rm -f test_compile test_compile.f90 test_compile.o
else
    print_failure "Basic compilation failed"
fi
echo ""

# Test 5: Check optimization flags
echo "Test 5: Testing optimization flags..."
cat > test_opt.f90 << 'EOF'
program test
  implicit none
  real :: x = 1.0
  print *, x
end program test
EOF

if ifx -O3 -xHost test_opt.f90 -o test_opt 2>/dev/null; then
    print_success "Optimization flags (-O3 -xHost) work"
    rm -f test_opt test_opt.f90 test_opt.o
else
    print_warning "Optimization flags may not work on this system"
    rm -f test_opt test_opt.f90 test_opt.o
fi
echo ""

# Test 6: Check for OpenMP support
echo "Test 6: Testing OpenMP support..."
cat > test_omp.f90 << 'EOF'
program test_omp
  use omp_lib
  implicit none
  !$OMP PARALLEL
  !$OMP MASTER
  print *, 'OpenMP threads:', omp_get_num_threads()
  !$OMP END MASTER
  !$OMP END PARALLEL
end program test_omp
EOF

if ifx -qopenmp test_omp.f90 -o test_omp 2>/dev/null; then
    print_success "OpenMP support available"
    rm -f test_omp test_omp.f90 test_omp.o
else
    print_warning "OpenMP support not available or not working"
    rm -f test_omp test_omp.f90 test_omp.o
fi
echo ""

# Test 7: Check for MKL
echo "Test 7: Testing Intel MKL support..."
if ifx -qmkl -V 2>&1 | grep -q "mkl"; then
    print_success "Intel MKL appears to be available"
else
    print_warning "Intel MKL may not be available"
fi
echo ""

# Test 8: Check environment variables
echo "Test 8: Checking Intel environment variables..."
if [ -n "$ONEAPI_ROOT" ]; then
    print_success "ONEAPI_ROOT is set: $ONEAPI_ROOT"
else
    print_warning "ONEAPI_ROOT not set (may not be needed)"
fi

if [ -n "$MKLROOT" ]; then
    print_success "MKLROOT is set: $MKLROOT"
else
    print_warning "MKLROOT not set (only needed for MKL)"
fi
echo ""

# Test 9: Compile glmnet_wrapper if files exist
if [ -f "glmnet.f" ] && [ -f "glmnet_wrapper.f90" ]; then
    echo "Test 9: Testing glmnet_wrapper compilation..."
    
    # Compile glmnet.f
    if ifx -O3 -std08 -warn nousage -c glmnet.f 2>/dev/null; then
        print_success "glmnet.f compiles"
    else
        print_failure "glmnet.f failed to compile"
    fi
    
    # Compile wrapper
    if ifx -O3 -xHost -fp-model precise -c glmnet_wrapper.f90 2>/dev/null; then
        print_success "glmnet_wrapper.f90 compiles"
    else
        print_failure "glmnet_wrapper.f90 failed to compile"
    fi
    
    # Create library
    if [ -f "glmnet.o" ] && [ -f "glmnet_wrapper.o" ]; then
        ar rcs libglmnet_wrapper.a glmnet.o glmnet_wrapper.o 2>/dev/null
        if [ -f "libglmnet_wrapper.a" ]; then
            print_success "Library libglmnet_wrapper.a created"
        fi
    fi
    
    # Clean up
    rm -f glmnet.o glmnet_wrapper.o glmnet_wrapper.mod libglmnet_wrapper.a
    echo ""
else
    print_warning "Test 9 skipped: glmnet source files not found"
    echo ""
fi

# Summary
echo "=========================================="
echo "Verification Summary"
echo "=========================================="
echo -e "${GREEN}Successful tests: $success_count${NC}"
if [ $fail_count -gt 0 ]; then
    echo -e "${RED}Failed tests: $fail_count${NC}"
fi
echo ""

if [ $fail_count -eq 0 ]; then
    echo -e "${GREEN}✓ All critical tests passed!${NC}"
    echo ""
    echo "Your Intel ifx installation is ready to use."
    echo ""
    echo "Next steps:"
    echo "  1. Build glmnet_wrapper: ./build_ifx.sh"
    echo "  2. Or use Makefile: make -f Makefile.ifx"
    echo "  3. Or compile directly: ifx -O3 -xHost glmnet.f glmnet_wrapper.f90 your_program.f90"
    echo ""
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    echo ""
    echo "Please fix the issues above before proceeding."
    echo ""
    echo "Common solutions:"
    echo "  - Source Intel environment: source /opt/intel/oneapi/setvars.sh"
    echo "  - Load Intel module: module load intel"
    echo "  - Install Intel oneAPI: https://www.intel.com/content/www/us/en/developer/tools/oneapi/"
    echo ""
    exit 1
fi
