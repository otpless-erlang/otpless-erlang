cmake_minimum_required(VERSION 3.10)

project(erlang VERSION 1.0)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED True)

add_library(erlang SHARED main.c)
set_target_properties(erlang PROPERTIES VERSION ${PROJECT_VERSION})
set_target_properties(erlang PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
