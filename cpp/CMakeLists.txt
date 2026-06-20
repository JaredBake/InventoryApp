cmake_minimum_required(VERSION 3.14)
project(inventory_ffi VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ── shared library used by Flutter FFI ───────────────────────────────────────
add_library(inventory SHARED
    src/inventory_api.cpp
)

target_include_directories(inventory
    PUBLIC  include
)

# Strip unused symbols on non-Debug builds
if(NOT CMAKE_BUILD_TYPE STREQUAL "Debug")
    if(UNIX AND NOT APPLE)
        target_link_options(inventory PRIVATE -Wl,--strip-all)
    endif()
endif()

# ── standalone CLI test target (not shipped in app) ──────────────────────────
option(BUILD_TESTS "Build C++ unit tests" OFF)

if(BUILD_TESTS)
    add_executable(inventory_tests
        tests/inventory_tests.cpp
    )
    target_include_directories(inventory_tests PRIVATE include)
    target_link_libraries(inventory_tests PRIVATE inventory)
endif()
