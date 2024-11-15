cmake_minimum_required(VERSION 3.10)

project(
  "OTPless Erlang"
  VERSION 27.0.0
  DESCRIPTION "A distribution of Erlang without the OTP framework."
  HOMEPAGE_URL "https://www.otpless-erlang.org"
  LANGUAGES C
)

# Find the Perl interpreter (the build process generates some C source files
# using Perl scripts).
find_package(Perl REQUIRED)

# Print out some CMake variables for debugging/development purposes.

message(STATUS "CMAKE_CROSSCOMPILING = ${CMAKE_CROSSCOMPILING}")
message(STATUS "CMAKE_CROSSCOMPILING_EMULATOR = ${CMAKE_CROSSCOMPILING_EMULATOR}")

message(STATUS "CMAKE_GENERATOR = ${CMAKE_GENERATOR}")
message(STATUS "CMAKE_GENERATOR_INSTANCE = ${CMAKE_GENERATOR_INSTANCE}")
message(STATUS "CMAKE_GENERATOR_PLATFORM = ${CMAKE_GENERATOR_PLATFORM}")
message(STATUS "CMAKE_GENERATOR_TOOLSET = ${CMAKE_GENERATOR_TOOLSET}")

message(STATUS "CMAKE_HOST = ${CMAKE_HOST}")
message(STATUS "CMAKE_HOST_NAME = ${CMAKE_HOST_NAME}")
message(STATUS "CMAKE_HOST_PROCESSOR = ${CMAKE_HOST_PROCESSOR}")
message(STATUS "CMAKE_HOST_VERSION = ${CMAKE_HOST_VERSION}")

message(STATUS "CMAKE_SYSTEM = ${CMAKE_SYSTEM}")
message(STATUS "CMAKE_SYSTEM_NAME = ${CMAKE_SYSTEM_NAME}")
message(STATUS "CMAKE_SYSTEM_PROCESSOR = ${CMAKE_SYSTEM_PROCESSOR}")
message(STATUS "CMAKE_SYSTEM_VERSION = ${CMAKE_SYSTEM_VERSION}")

message(STATUS "CMAKE_HOST_UNIX = ${CMAKE_HOST_UNIX}")
message(STATUS "CMAKE_HOST_WIN32 = ${CMAKE_HOST_WIN32}")
message(STATUS "CMAKE_LIBRARY_ARCHITECTURE = ${CMAKE_LIBRARY_ARCHITECTURE}")
message(STATUS "CMAKE_LIBRARY_ARCHITECTURE_REGEX = ${CMAKE_LIBRARY_ARCHITECTURE_REGEX}")

message(STATUS "ANDROID = ${ANDROID}")
message(STATUS "APPLE = ${APPLE}")
message(STATUS "CYGWIN = ${CYGWIN}")
message(STATUS "IOS = ${IOS}")
message(STATUS "LINUX = ${LINUX}")
message(STATUS "MINGW = ${MINGW}")
message(STATUS "MSVC = ${MSVC}")
message(STATUS "MSVC_IDE = ${MSVC_IDE}")
message(STATUS "MSVC_TOOLSET_VERSION = ${MSVC_TOOLSET_VERSION}")
message(STATUS "MSVC_VERSION = ${MSVC_VERSION}")
message(STATUS "MSYS = ${MSYS}")
message(STATUS "UNIX = ${UNIX}")
message(STATUS "WIN32 = ${WIN32}")
message(STATUS "XCODE = ${XCODE}")
message(STATUS "XCODE_VERSION = ${XCODE_VERSION}")

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

# Determine the target architcture (either 'x86' or 'arm').
if(CMAKE_SYSTEM_NAME MATCHES "Linux")
  if(CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64")
    set(ERLANG_TARGET_ARCH "x86")
  elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64")
    set(ERLANG_TARGET_ARCH "arm")
  endif()
elseif(CMAKE_SYSTEM_NAME MATCHES "Darwin")
  # We imply ARM64.
  set(ERLANG_TARGET_ARCH "arm")
elseif(CMAKE_SYSTEM_NAME MATCHES "Windows")
  # We rely on CMAKE_GENERATOR_PLATFORM instead of CMAKE_SYSTEM_PROCESSOR
  # because CMake is improperly setting this value. (When cross-compiling for
  # Windows ARM64, the value is AMD64).
  if(CMAKE_GENERATOR_PLATFORM MATCHES "x64")
    set(ERLANG_TARGET_ARCH "x86")
  elseif(CMAKE_GENERATOR_PLATFORM MATCHES "ARM64")
    set(ERLANG_TARGET_ARCH "arm")
  endif()
elseif(CMAKE_SYSTEM_NAME MATCHES "Android")
  if(CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64")
    set(ERLANG_TARGET_ARCH "x86")
  elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64")
    set(ERLANG_TARGET_ARCH "arm")
  endif()
elseif(CMAKE_SYSTEM_NAME MATCHES "iOS")
  # We imply ARM64. Note that the CMAKE_SYSTEM_PROCESSOR variable is not even
  # set.
  set(ERLANG_TARGET_ARCH "arm")
endif()
if (ERLANG_TARGET_ARCH STREQUAL "x86")
  message(STATUS "Erlang will be compiled for an x86-based system")
elseif (ERLANG_TARGET_ARCH STREQUAL "arm")
  message(STATUS "Erlang will be compiled for an ARM-based system")
else()
  message(FATAL_ERROR "The target architecture could not be determined")
endif()

# Generate the 'erl_int_sizes_config.h' file (from its .h.in template).
include(CheckTypeSize)
check_type_size("char" SIZEOF_CHAR)
check_type_size("short" SIZEOF_SHORT)
check_type_size("int" SIZEOF_INT)
check_type_size("long" SIZEOF_LONG)
check_type_size("long long" SIZEOF_LONG_LONG)
check_type_size("void*" SIZEOF_VOID_P)

configure_file(
  ${CMAKE_SOURCE_DIR}/erts/include/erl_int_sizes_config.h.in
  ${CMAKE_BINARY_DIR}/erts/include/erl_int_sizes_config.h
)

# Define the 'beam_makeops' target which invokes the 'beam_makeops' Perl script
# to generate *.h and *.c files from *.tab files.
file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/emulator)
set(OPCODE_TABLES
  ${CMAKE_SOURCE_DIR}/lib/compiler/src/genop.tab
  ${CMAKE_SOURCE_DIR}/erts/emulator/beam/predicates.tab
  ${CMAKE_SOURCE_DIR}/erts/emulator/beam/generators.tab
)
if (ERLANG_BUILD_FLAVOR STREQUAL "jit")
  list(APPEND OPCODE_TABLES
    ${CMAKE_SOURCE_DIR}/erts/emulator/beam/jit/${ERLANG_TARGET_ARCH}/ops.tab
    ${CMAKE_SOURCE_DIR}/erts/emulator/beam/jit/${ERLANG_TARGET_ARCH}/predicates.tab
    ${CMAKE_SOURCE_DIR}/erts/emulator/beam/jit/${ERLANG_TARGET_ARCH}/generators.tab
  )
elseif (ERLANG_BUILD_FLAVOR STREQUAL "emu")
  list(APPEND OPCODE_TABLES
    ${CMAKE_SOURCE_DIR}/erts/emulator/beam/emu/ops.tab
    ${CMAKE_SOURCE_DIR}/erts/emulator/beam/emu/predicates.tab
    ${CMAKE_SOURCE_DIR}/erts/emulator/beam/emu/generators.tab
    ${CMAKE_SOURCE_DIR}/erts/emulator/beam/emu/macros.tab
    ${CMAKE_SOURCE_DIR}/erts/emulator/beam/emu/instrs.tab
    ${CMAKE_SOURCE_DIR}/erts/emulator/beam/emu/arith_instrs.tab
    ${CMAKE_SOURCE_DIR}/erts/emulator/beam/emu/bif_instrs.tab
    ${CMAKE_SOURCE_DIR}/erts/emulator/beam/emu/bs_instrs.tab
    ${CMAKE_SOURCE_DIR}/erts/emulator/beam/emu/float_instrs.tab
    ${CMAKE_SOURCE_DIR}/erts/emulator/beam/emu/map_instrs.tab
    ${CMAKE_SOURCE_DIR}/erts/emulator/beam/emu/msg_instrs.tab
    ${CMAKE_SOURCE_DIR}/erts/emulator/beam/emu/select_instrs.tab
    ${CMAKE_SOURCE_DIR}/erts/emulator/beam/emu/trace_instrs.tab
  )
endif()
if (ERLANG_BUILD_FLAVOR STREQUAL "jit")
  set(IS_USING_JIT yes)
else()
  set(IS_USING_JIT no)
endif()
set(BEAM_MAKEOPTS_ARGS
  -wordsize 64
  -code-model @CODE_MODEL@
  -outdir ${CMAKE_BINARY_DIR}/emulator
  -jit ${IS_USING_JIT}
  -DUSE_VM_PROBES=0
  -emulator ${OPCODE_TABLES}
)
add_custom_command(
  OUTPUT beam_makeops.txt
  COMMAND perl erts/emulator/utils/beam_makeops ${BEAM_MAKEOPTS_ARGS}
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)
add_custom_target(beam_makeops ALL DEPENDS beam_makeops.txt)

add_library(erlang SHARED main.c)
set_target_properties(erlang PROPERTIES VERSION ${PROJECT_VERSION})
set_target_properties(erlang PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

install(TARGETS erlang LIBRARY DESTINATION lib)
