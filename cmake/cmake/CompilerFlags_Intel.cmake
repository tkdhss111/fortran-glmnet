# Compiler flags for Intel Fortran (ifx/ifort)

message(STATUS "Configuring for Intel Fortran (${CMAKE_Fortran_COMPILER_ID})")

# Detect if using classic ifort or new ifx
if(CMAKE_Fortran_COMPILER MATCHES "ifx")
    set(USING_IFX TRUE)
    message(STATUS "Using Intel ifx (LLVM-based compiler)")
else()
    set(USING_IFX FALSE)
    message(STATUS "Using Intel ifort (classic compiler)")
endif()

# Base flags for all build types
set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -warn all")

# Debug flags
set(CMAKE_Fortran_FLAGS_DEBUG "-g -O0 -check all -traceback -fpe0")
message(STATUS "Debug flags: ${CMAKE_Fortran_FLAGS_DEBUG}")

# Release flags - optimized for Intel CPUs
if(USING_IFX)
    # Intel ifx flags (LLVM-based)
    set(CMAKE_Fortran_FLAGS_RELEASE "-O3 -xHost -fp-model precise")
else()
    # Intel ifort flags (classic)
    set(CMAKE_Fortran_FLAGS_RELEASE "-O3 -xHost -fp-model precise")
endif()
message(STATUS "Release flags: ${CMAKE_Fortran_FLAGS_RELEASE}")

# Release with debug info
set(CMAKE_Fortran_FLAGS_RELWITHDEBINFO "-O2 -g -xHost")
message(STATUS "RelWithDebInfo flags: ${CMAKE_Fortran_FLAGS_RELWITHDEBINFO}")

# Minimum size release
set(CMAKE_Fortran_FLAGS_MINSIZEREL "-Os")
message(STATUS "MinSizeRel flags: ${CMAKE_Fortran_FLAGS_MINSIZEREL}")

# Additional optimization options for Release
if(CMAKE_BUILD_TYPE STREQUAL "Release")
    # Interprocedural optimization (if not using CMake IPO)
    if(NOT ENABLE_IPO)
        # IPO can be added here: -ipo
    endif()
    
    # Vectorization reports (optional, generates .optrpt files)
    # set(CMAKE_Fortran_FLAGS_RELEASE "${CMAKE_Fortran_FLAGS_RELEASE} -qopt-report=5 -qopt-report-phase=vec")
    
    # Fast math option (use with caution)
    # set(CMAKE_Fortran_FLAGS_RELEASE "${CMAKE_Fortran_FLAGS_RELEASE} -fp-model fast=2")
endif()

# CPU-specific optimization hints
if(CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64|AMD64")
    message(STATUS "x86_64 architecture detected")
    # You can add specific CPU flags here if needed
    # For example: -xCORE-AVX2, -xCORE-AVX512, etc.
endif()

message(STATUS "Intel Fortran flags configured")
