# Compiler flags for GNU Fortran (gfortran)

message(STATUS "Configuring for GNU Fortran (gfortran)")

# Base flags for all build types
# Note: Do NOT use -fimplicit-none globally as glmnet.f uses implicit typing
set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -ffree-line-length-none")

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

message(STATUS "GNU Fortran flags configured")
