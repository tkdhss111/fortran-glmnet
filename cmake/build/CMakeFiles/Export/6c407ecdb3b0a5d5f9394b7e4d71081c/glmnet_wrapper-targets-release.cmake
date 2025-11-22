#----------------------------------------------------------------
# Generated CMake target import file for configuration "Release".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "glmnet_wrapper::glmnet_wrapper" for configuration "Release"
set_property(TARGET glmnet_wrapper::glmnet_wrapper APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(glmnet_wrapper::glmnet_wrapper PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_RELEASE "Fortran"
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/libglmnet_wrapper.a"
  )

list(APPEND _cmake_import_check_targets glmnet_wrapper::glmnet_wrapper )
list(APPEND _cmake_import_check_files_for_glmnet_wrapper::glmnet_wrapper "${_IMPORT_PREFIX}/lib/libglmnet_wrapper.a" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
