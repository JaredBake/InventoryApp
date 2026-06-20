cmake_minimum_required(VERSION 3.10.2)
project(inventory_ffi)

# Build the shared library from the C++ sources in the project root cpp/ dir.
# This file lives in android/app/ so the path goes up two levels.
add_library(inventory SHARED
    ../../cpp/src/inventory_api.cpp
)

target_include_directories(inventory
    PRIVATE ../../cpp/include
)

# Link the Android logging library (useful for debug prints)
find_library(log-lib log)
target_link_libraries(inventory ${log-lib})
