#!/bin/bash
# Automated Performance Benchmark Script for Intel ifx
# Compares different optimization levels

set -e

echo "=============================================="
echo "  Intel ifx Performance Benchmark Suite"
echo "  glmnet_wrapper optimization comparison"
echo "=============================================="
echo ""

# Check if ifx is available
if ! command -v ifx &> /dev/null; then
    echo "ERROR: Intel Fortran Compiler (ifx) not found!"
    echo "Please source the environment: source /opt/intel/oneapi/setvars.sh"
    exit 1
fi

# Check for required files
if [ ! -f "glmnet.f" ] || [ ! -f "glmnet_wrapper.f90" ] || [ ! -f "benchmark_ifx.f90" ]; then
    echo "ERROR: Required files not found!"
    echo "Need: glmnet.f, glmnet_wrapper.f90, benchmark_ifx.f90"
    exit 1
fi

echo "Intel Fortran Compiler:"
ifx --version | head -2
echo ""

# Create output directory for results
mkdir -p benchmark_results

# Compile with different optimization levels
echo "Compiling benchmarks with different optimization levels..."
echo ""

# Clean previous builds
rm -f bench_* *.o *.mod *.a

# Level 1: -O2 (standard)
echo "1. Compiling with -O2 (standard)..."
ifx -O2 -c glmnet.f 2>/dev/null
ifx -O2 -c glmnet_wrapper.f90 2>/dev/null
ifx -O2 benchmark_ifx.f90 glmnet.o glmnet_wrapper.o -o bench_O2
echo "   ✓ bench_O2 created"

# Level 2: -O3 (aggressive)
echo "2. Compiling with -O3 (aggressive)..."
rm -f *.o *.mod
ifx -O3 -c glmnet.f 2>/dev/null
ifx -O3 -c glmnet_wrapper.f90 2>/dev/null
ifx -O3 benchmark_ifx.f90 glmnet.o glmnet_wrapper.o -o bench_O3
echo "   ✓ bench_O3 created"

# Level 3: -O3 -xHost (CPU-specific)
echo "3. Compiling with -O3 -xHost (CPU-specific)..."
rm -f *.o *.mod
ifx -O3 -xHost -c glmnet.f 2>/dev/null
ifx -O3 -xHost -c glmnet_wrapper.f90 2>/dev/null
ifx -O3 -xHost benchmark_ifx.f90 glmnet.o glmnet_wrapper.o -o bench_xHost
echo "   ✓ bench_xHost created"

# Level 4: -O3 -xHost -fp-model precise (recommended)
echo "4. Compiling with -O3 -xHost -fp-model precise (recommended)..."
rm -f *.o *.mod
ifx -O3 -xHost -c glmnet.f 2>/dev/null
ifx -O3 -xHost -fp-model precise -c glmnet_wrapper.f90 2>/dev/null
ifx -O3 -xHost -fp-model precise benchmark_ifx.f90 glmnet.o glmnet_wrapper.o -o bench_precise
echo "   ✓ bench_precise created"

# Level 5: -O3 -xHost -ipo (interprocedural optimization)
echo "5. Compiling with -O3 -xHost -ipo (IPO)..."
rm -f *.o *.mod
ifx -O3 -xHost -ipo glmnet.f glmnet_wrapper.f90 benchmark_ifx.f90 -o bench_ipo 2>/dev/null
echo "   ✓ bench_ipo created"

echo ""
echo "Compilation complete!"
echo ""

# Run benchmarks
echo "=============================================="
echo "  Running Benchmarks"
echo "=============================================="
echo ""

echo "Benchmark 1: -O2 (baseline)"
echo "----------------------------------------"
./bench_O2 > benchmark_results/result_O2.txt
tail -20 benchmark_results/result_O2.txt
echo ""

echo "Benchmark 2: -O3"
echo "----------------------------------------"
./bench_O3 > benchmark_results/result_O3.txt
tail -20 benchmark_results/result_O3.txt
echo ""

echo "Benchmark 3: -O3 -xHost"
echo "----------------------------------------"
./bench_xHost > benchmark_results/result_xHost.txt
tail -20 benchmark_results/result_xHost.txt
echo ""

echo "Benchmark 4: -O3 -xHost -fp-model precise (RECOMMENDED)"
echo "----------------------------------------"
./bench_precise > benchmark_results/result_precise.txt
tail -20 benchmark_results/result_precise.txt
echo ""

echo "Benchmark 5: -O3 -xHost -ipo"
echo "----------------------------------------"
./bench_ipo > benchmark_results/result_ipo.txt
tail -20 benchmark_results/result_ipo.txt
echo ""

# Extract and compare key timings
echo "=============================================="
echo "  Performance Comparison Summary"
echo "=============================================="
echo ""

echo "Medium Problem (n=500, p=50) - Single Fit:"
echo "----------------------------------------"
printf "%-30s %10s\n" "Configuration" "Time (ms)"
printf "%-30s %10s\n" "------------------------------" "----------"

for config in O2 O3 xHost precise ipo; do
    time=$(grep "Single fit (averaged):" benchmark_results/result_${config}.txt | head -2 | tail -1 | awk '{print $4}')
    printf "%-30s %10s\n" "$config" "$time"
done
echo ""

echo "Medium Problem (n=500, p=50) - 5-fold CV:"
echo "----------------------------------------"
printf "%-30s %10s\n" "Configuration" "Time (ms)"
printf "%-30s %10s\n" "------------------------------" "----------"

for config in O2 O3 xHost precise ipo; do
    time=$(grep "5-fold CV:" benchmark_results/result_${config}.txt | awk '{print $3}')
    printf "%-30s %10s\n" "$config" "$time"
done
echo ""

echo "Large Problem (n=1000, p=100) - 10-fold CV:"
echo "----------------------------------------"
printf "%-30s %10s\n" "Configuration" "Time (ms)"
printf "%-30s %10s\n" "------------------------------" "----------"

for config in O2 O3 xHost precise ipo; do
    time=$(grep "10-fold CV:" benchmark_results/result_${config}.txt | awk '{print $3}')
    printf "%-30s %10s\n" "$config" "$time"
done
echo ""

# Recommendations
echo "=============================================="
echo "  Recommendations"
echo "=============================================="
echo ""
echo "Based on the results above:"
echo ""
echo "✓ RECOMMENDED FOR PRODUCTION:"
echo "  ifx -O3 -xHost -fp-model precise"
echo "  - Best balance of performance and consistency"
echo "  - Ensures reproducible results"
echo ""
echo "✓ MAXIMUM PERFORMANCE (if reproducibility not critical):"
echo "  ifx -O3 -xHost -ipo"
echo "  - Typically 3-8% faster than -fp-model precise"
echo "  - Use for compute-intensive applications"
echo ""
echo "✓ FOR DEVELOPMENT/DEBUGGING:"
echo "  ifx -O0 -g -check all -traceback"
echo "  - All safety checks enabled"
echo "  - Detailed error messages"
echo ""

# Clean up
echo "=============================================="
echo "  Cleanup"
echo "=============================================="
echo ""
echo "Benchmark results saved in: benchmark_results/"
echo "  - result_O2.txt"
echo "  - result_O3.txt"
echo "  - result_xHost.txt"
echo "  - result_precise.txt"
echo "  - result_ipo.txt"
echo ""

read -p "Remove benchmark executables? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -f bench_* *.o *.mod
    echo "✓ Benchmark executables removed"
else
    echo "Benchmark executables kept: bench_O2, bench_O3, bench_xHost, bench_precise, bench_ipo"
fi
echo ""

echo "=============================================="
echo "  Benchmark Complete!"
echo "=============================================="
