
####### Expanded from @PACKAGE_INIT@ by configure_package_config_file() #######
####### Any changes to this file will be overwritten by the next CMake run ####
####### The input file was glmnet_wrapper-config.cmake.in                            ########

get_filename_component(PACKAGE_PREFIX_DIR "${CMAKE_CURRENT_LIST_DIR}/../../../" ABSOLUTE)

macro(set_and_check _var _file)
  set(${_var} "${_file}")
  if(NOT EXISTS "${_file}")
    message(FATAL_ERROR "File or directory ${_file} referenced by variable ${_var} does not exist !")
  endif()
endmacro()

macro(check_required_components _NAME)
  foreach(comp ${${_NAME}_FIND_COMPONENTS})
    if(NOT ${_NAME}_${comp}_FOUND)
      if(${_NAME}_FIND_REQUIRED_${comp})
        set(${_NAME}_FOUND FALSE)
      endif()
    endif()
  endforeach()
endmacro()

####################################################################################

# glmnet_wrapper CMake configuration file

include(CMakeFindDependencyMacro)

# Find dependencies if they were used during build
if(OFF)
    find_dependency(OpenMP)
endif()

if(OFF)
    find_dependency(MKL CONFIG)
endif()

# Include targets
include("${CMAKE_CURRENT_LIST_DIR}/glmnet_wrapper-targets.cmake")

# Check that the targets were created
check_required_components(glmnet_wrapper)

# Set convenience variables
set(glmnet_wrapper_LIBRARIES glmnet_wrapper::glmnet_wrapper)
set(glmnet_wrapper_INCLUDE_DIRS "${PACKAGE_PREFIX_DIR}/include")

message(STATUS "glmnet_wrapper configuration loaded")
message(STATUS "  Version: 1.0.0")
message(STATUS "  Libraries: ${glmnet_wrapper_LIBRARIES}")
message(STATUS "  Include directories: ${glmnet_wrapper_INCLUDE_DIRS}")
