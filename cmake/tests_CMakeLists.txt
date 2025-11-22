# Tests directory CMakeLists.txt

# Test programs
add_executable(test_glmnet_wrapper test_glmnet_wrapper.f90)
target_link_libraries(test_glmnet_wrapper PRIVATE glmnet_wrapper)

# Add test
add_test(NAME test_glmnet_wrapper COMMAND test_glmnet_wrapper)

# Set test properties
set_tests_properties(test_glmnet_wrapper PROPERTIES
    PASS_REGULAR_EXPRESSION "All tests completed!"
    TIMEOUT 300
)

# Optional: benchmark if requested
if(BUILD_BENCHMARKS)
    add_executable(benchmark_test benchmark_ifx.f90)
    target_link_libraries(benchmark_test PRIVATE glmnet_wrapper)
endif()

message(STATUS "Test programs configured")
