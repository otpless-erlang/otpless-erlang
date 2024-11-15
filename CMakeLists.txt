cmake_minimum_required(VERSION 3.10)

project(
  "OTPless Erlang"
  VERSION 27.0.0
  DESCRIPTION "A distribution of Erlang without the OTP framework."
  HOMEPAGE_URL "https://www.otpless-erlang.org"
  LANGUAGES C
)

add_library(erlang SHARED main.c)
set_target_properties(erlang PROPERTIES VERSION ${PROJECT_VERSION})
set_target_properties(erlang PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

install(TARGETS erlang LIBRARY DESTINATION lib)
