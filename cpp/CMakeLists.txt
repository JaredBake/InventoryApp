cmake_minimum_required(VERSION 3.14)
project(inventory_ffi VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

option(ENABLE_SANITIZERS "Enable ASan/UBSan for native targets" OFF)

# ── shared library used by Flutter FFI ───────────────────────────────────────
add_library(inventory SHARED
    src/inventory_api.cpp
)

target_include_directories(inventory
    PUBLIC  include
)

if(ENABLE_SANITIZERS)
    if(CMAKE_CXX_COMPILER_ID MATCHES "Clang|GNU")
        target_compile_options(inventory PRIVATE -fsanitize=address,undefined -fno-omit-frame-pointer)
        target_link_options(inventory PRIVATE -fsanitize=address,undefined)
    endif()
endif()

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
    if(ENABLE_SANITIZERS)
        if(CMAKE_CXX_COMPILER_ID MATCHES "Clang|GNU")
            target_compile_options(inventory_tests PRIVATE -fsanitize=address,undefined -fno-omit-frame-pointer)
            target_link_options(inventory_tests PRIVATE -fsanitize=address,undefined)
        endif()
    endif()
endif()
