# Examples directory CMakeLists.txt

# Simple example
add_executable(simple_example simple_example.f90)
target_link_libraries(simple_example PRIVATE glmnet_wrapper)

# Advanced example (if OpenMP is enabled)
if(ENABLE_OPENMP)
    add_executable(advanced_example advanced_ifx_example.f90)
    target_link_libraries(advanced_example PRIVATE glmnet_wrapper)
    
    if(ENABLE_MKL AND MKL_FOUND)
        target_compile_definitions(advanced_example PRIVATE USE_MKL)
    endif()
endif()

# Benchmark example
if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/benchmark_ifx.f90)
    add_executable(benchmark_example benchmark_ifx.f90)
    target_link_libraries(benchmark_example PRIVATE glmnet_wrapper)
endif()

message(STATUS "Example programs configured")
