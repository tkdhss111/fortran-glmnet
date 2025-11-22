# Compiler flags for GNU Fortran (gfortran)

message(STATUS "Configuring for GNU Fortran (gfortran)")

# Base flags for all build types
set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -fimplicit-none -ffree-line-length-none")

# Debug flags
set(CMAKE_Fortran_FLAGS_DEBUG "-g -O0 -fcheck=all -fbacktrace -Wall -Wextra -pedantic")
message(STATUS "Debug flags: ${CMAKE_Fortran_FLAGS_DEBUG}")

# Release flags
set(CMAKE_Fortran_FLAGS_RELEASE "-O3 -march=native -mtune=native -funroll-loops")
message(STATUS "Release flags: ${CMAKE_Fortran_FLAGS_RELEASE}")

# Release with debug info
set(CMAKE_Fortran_FLAGS_RELWITHDEBINFO "-O2 -g -march=native")
message(STATUS "RelWithDebInfo flags: ${CMAKE_Fortran_FLAGS_RELWITHDEBINFO}")

# Minimum size release
set(CMAKE_Fortran_FLAGS_MINSIZEREL "-Os")
message(STATUS "MinSizeRel flags: ${CMAKE_Fortran_FLAGS_MINSIZEREL}")

# Additional optimization flags for Release builds
if(CMAKE_BUILD_TYPE STREQUAL "Release")
    # Add vectorization info (optional)
    if(CMAKE_Fortran_COMPILER_VERSION VERSION_GREATER_EQUAL 9.0)
        set(CMAKE_Fortran_FLAGS_RELEASE "${CMAKE_Fortran_FLAGS_RELEASE} -fopt-info-vec-optimized")
    endif()
    
    # Fast math (use with caution)
    # set(CMAKE_Fortran_FLAGS_RELEASE "${CMAKE_Fortran_FLAGS_RELEASE} -ffast-math")
endif()

message(STATUS "GNU Fortran flags configured")
