cmake_minimum_required(VERSION 3.10)

project(
  "OTPless Erlang"
  VERSION 27.0.0
  DESCRIPTION "A distribution of Erlang without the OTP framework."
  HOMEPAGE_URL "https://www.otpless-erlang.org"
  LANGUAGES C
)

set(ERLANG_BUILD_TYPE "release"
  CACHE
  STRING "The build type (either 'release' or 'debug')."
)
if(ERLANG_BUILD_TYPE STREQUAL "release")
  set(CMAKE_BUILD_TYPE "Release" CACHE STRING "" FORCE)
elseif(ERLANG_BUILD_TYPE STREQUAL "debug")
  set(CMAKE_BUILD_TYPE "Debug" CACHE STRING "" FORCE)
else()
  set(CMAKE_BUILD_TYPE "Release" CACHE STRING "" FORCE)
endif()

set(ERLANG_BUILD_FLAVOR "jit"
  CACHE
  STRING "The build flavor (either 'emu' or 'jit'). It should be JIT by default unless not supported by the platform."
)

add_library(erlang SHARED main.c)
set_target_properties(erlang PROPERTIES VERSION ${PROJECT_VERSION})
set_target_properties(erlang PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

install(TARGETS erlang LIBRARY DESTINATION lib)
