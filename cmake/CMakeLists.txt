cmake_minimum_required(VERSION 3.15)
project(glmnet_wrapper
    VERSION 1.0.0
    LANGUAGES Fortran
    DESCRIPTION "Modern Fortran wrapper for glmnet elastic net regression"
)

# Set default build type to Release if not specified
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release" "RelWithDebInfo" "MinSizeRel")
endif()

# Options
option(BUILD_TESTING "Build test programs" ON)
option(BUILD_EXAMPLES "Build example programs" ON)
option(BUILD_SHARED_LIBS "Build shared libraries" OFF)
option(ENABLE_OPENMP "Enable OpenMP support" OFF)
option(ENABLE_MKL "Enable Intel MKL (Intel compilers only)" OFF)
option(ENABLE_IPO "Enable interprocedural optimization" OFF)

# Print configuration
message(STATUS "===========================================")
message(STATUS "  glmnet_wrapper Configuration")
message(STATUS "===========================================")
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "Fortran compiler: ${CMAKE_Fortran_COMPILER_ID}")
message(STATUS "Fortran compiler version: ${CMAKE_Fortran_COMPILER_VERSION}")
message(STATUS "Build testing: ${BUILD_TESTING}")
message(STATUS "Build examples: ${BUILD_EXAMPLES}")
message(STATUS "Shared libraries: ${BUILD_SHARED_LIBS}")
message(STATUS "OpenMP: ${ENABLE_OPENMP}")
message(STATUS "Intel MKL: ${ENABLE_MKL}")
message(STATUS "IPO: ${ENABLE_IPO}")
message(STATUS "===========================================")

# Detect compiler and set appropriate flags
if(CMAKE_Fortran_COMPILER_ID MATCHES "GNU")
    set(FORTRAN_COMPILER_NAME "gfortran")
    include(cmake/CompilerFlags_GNU.cmake)
elseif(CMAKE_Fortran_COMPILER_ID MATCHES "Intel")
    set(FORTRAN_COMPILER_NAME "ifx/ifort")
    include(cmake/CompilerFlags_Intel.cmake)
else()
    message(WARNING "Unsupported Fortran compiler: ${CMAKE_Fortran_COMPILER_ID}")
    message(WARNING "Using generic compiler flags")
    set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -O2")
endif()

# Enable IPO if requested and supported
if(ENABLE_IPO)
    include(CheckIPOSupported)
    check_ipo_supported(RESULT ipo_supported OUTPUT ipo_error)
    if(ipo_supported)
        message(STATUS "IPO/LTO enabled")
        set(CMAKE_INTERPROCEDURAL_OPTIMIZATION TRUE)
    else()
        message(WARNING "IPO/LTO not supported: ${ipo_error}")
    endif()
endif()

# OpenMP support
if(ENABLE_OPENMP)
    find_package(OpenMP REQUIRED)
    if(OpenMP_Fortran_FOUND)
        message(STATUS "OpenMP version: ${OpenMP_Fortran_VERSION}")
    endif()
endif()

# Intel MKL support (Intel compilers only)
if(ENABLE_MKL)
    if(CMAKE_Fortran_COMPILER_ID MATCHES "Intel")
        find_package(MKL CONFIG)
        if(MKL_FOUND)
            message(STATUS "Intel MKL found")
        else()
            message(WARNING "Intel MKL not found, continuing without MKL")
            set(ENABLE_MKL OFF)
        endif()
    else()
        message(WARNING "MKL option only works with Intel compilers")
        set(ENABLE_MKL OFF)
    endif()
endif()

# Add subdirectories
add_subdirectory(src)

if(BUILD_TESTING)
    enable_testing()
    add_subdirectory(tests)
endif()

if(BUILD_EXAMPLES)
    add_subdirectory(examples)
endif()

# Installation
include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

# Install library
install(TARGETS glmnet_wrapper
    EXPORT glmnet_wrapper-targets
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

# Install Fortran module files
install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/src/
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
    FILES_MATCHING PATTERN "*.mod"
)

# Create and install package config files
configure_package_config_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/cmake/glmnet_wrapper-config.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/glmnet_wrapper-config.cmake
    INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/glmnet_wrapper
)

write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/glmnet_wrapper-config-version.cmake
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion
)

install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/glmnet_wrapper-config.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/glmnet_wrapper-config-version.cmake
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/glmnet_wrapper
)

install(EXPORT glmnet_wrapper-targets
    FILE glmnet_wrapper-targets.cmake
    NAMESPACE glmnet_wrapper::
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/glmnet_wrapper
)

# Print summary
message(STATUS "===========================================")
message(STATUS "  Configuration Summary")
message(STATUS "===========================================")
message(STATUS "Install prefix: ${CMAKE_INSTALL_PREFIX}")
message(STATUS "Library directory: ${CMAKE_INSTALL_LIBDIR}")
message(STATUS "Include directory: ${CMAKE_INSTALL_INCLUDEDIR}")
message(STATUS "")
message(STATUS "To build:")
message(STATUS "  mkdir build && cd build")
message(STATUS "  cmake ..")
message(STATUS "  cmake --build .")
message(STATUS "")
message(STATUS "To install:")
message(STATUS "  cmake --install . [--prefix /path/to/install]")
message(STATUS "===========================================")
