cmake_minimum_required(VERSION 3.22.1)
project("dartnative_share" C CXX)

add_library(dartnative_share SHARED
    src/main/cpp/dn_share_bridge.cpp
)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_library(log-lib log)
find_library(android-lib android)

target_link_libraries(dartnative_share
    ${log-lib}
    ${android-lib}
)
