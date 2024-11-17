cmake_minimum_required(VERSION 3.20)

include(CheckTypeSize)
include(CheckIncludeFile)

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

# Generate the 'config.h' file (from its .in.h template).
set(ASSUMED_CACHE_LINE_SIZE 64)
if(CMAKE_C_BYTE_ORDER MATCHES BIG_ENDIAN)
  message(STATUS "Erlang will be compiled for a big endian system")
  set(ERTS_ENDIANNESS 1)
elseif(CMAKE_C_BYTE_ORDER MATCHES LITTLE_ENDIAN)
  message(STATUS "Erlang will be compiled for a little endian system")
  set(ERTS_ENDIANNESS -1)
else()
  message(FATAL_ERROR "The endianess could not be determined")
  set(ERTS_ENDIANNESS 0)
endif()

check_type_size("AO_t" SIZEOF_AO_T)
check_type_size("off_t" SIZEOF_OFF_T)
check_type_size("size_t" SIZEOF_SIZE_T)
check_type_size("suseconds_t" SIZEOF_SUSECONDS_T)
check_type_size("time_t" SIZEOF_TIME_T)
check_type_size("_Float16" SIZEOF__FLOAT16)
check_type_size("__int128_t" SIZEOF___INT128_T)
check_type_size("__int64" SIZEOF___INT64)

check_include_file(pthread.h ETHR_HAVE_PTHREAD_H)
check_include_file(sched.h ETHR_HAVE_SCHED_H)
check_include_file(sys/time.h ETHR_HAVE_SYS_TIME_H)
check_include_file(arpa/nameser.h HAVE_ARPA_NAMESER_H)
check_include_file(curses.h HAVE_CURSES_H)
check_include_file(dirent.h HAVE_DIRENT_H)
check_include_file(dlfcn.h HAVE_DLFCN_H)
check_include_file(elf.h HAVE_ELF_H)
check_include_file(fcntl.h HAVE_FCNTL_H)
check_include_file(ieeefp.h HAVE_IEEEFP_H)
check_include_file(ifaddrs.h HAVE_IFADDRS_H)
check_include_file(inttypes.h HAVE_INTTYPES_H)
check_include_file(langinfo.h HAVE_LANGINFO_H)
check_include_file(libdlpi.h HAVE_LIBDLPI_H)
check_include_file(libutil.h HAVE_LIBUTIL_H)
check_include_file(limits.h HAVE_LIMITS_H)
check_include_file(linux/errqueue.h HAVE_LINUX_ERRQUEUE_H)
check_include_file(linux/falloc.h HAVE_LINUX_FALLOC_H)
check_include_file(linux/types.h HAVE_LINUX_TYPES_H)
check_include_file(lttng/tracepoint-event.h HAVE_LTTNG_TRACEPOINT_EVENT_H)
check_include_file(lttng/tracepoint.h HAVE_LTTNG_TRACEPOINT_H)
check_include_file(malloc.h HAVE_MALLOC_H)
check_include_file(ndir.h HAVE_NDIR_H)
check_include_file(netpacket/packet.h HAVE_NETPACKET_PACKET_H)
check_include_file(net/errno.h HAVE_NET_ERRNO_H)
check_include_file(net/if_dl.h HAVE_NET_IF_DL_H)
check_include_file(poll.h HAVE_POLL_H)
check_include_file(pthread.h HAVE_PTHREAD_H)
check_include_file(pty.h HAVE_PTY_H)
check_include_file(sched.h HAVE_SCHED_H)
check_include_file(netinet/sctp.h HAVE_SCTP_H)
check_include_file(sdkddkver.h HAVE_SDKDDKVER_H)
check_include_file(setns.h HAVE_SETNS_H)
check_include_file(stdint.h HAVE_STDINT_H)
check_include_file(stdio.h HAVE_STDIO_H)
check_include_file(stdlib.h HAVE_STDLIB_H)
check_include_file(strings.h HAVE_STRINGS_H)
check_include_file(string.h HAVE_STRING_H)
check_include_file(syslog.h HAVE_SYSLOG_H)
check_include_file(systemd/sd-daemon.h HAVE_SYSTEMD_SD_DAEMON_H)
check_include_file(sys/devpoll.h HAVE_SYS_DEVPOLL_H)
check_include_file(sys/dir.h HAVE_SYS_DIR_H)
check_include_file(sys/epoll.h HAVE_SYS_EPOLL_H)
check_include_file(sys/event.h HAVE_SYS_EVENT_H)
check_include_file(sys/ioctl.h HAVE_SYS_IOCTL_H)
check_include_file(sys/mman.h HAVE_SYS_MMAN_H)
check_include_file(sys/ndir.h HAVE_SYS_NDIR_H)
check_include_file(sys/resource.h HAVE_SYS_RESOURCE_H)
check_include_file(sys/sdt.h HAVE_SYS_SDT_H)
check_include_file(sys/socketio.h HAVE_SYS_SOCKETIO_H)
check_include_file(sys/socket.h HAVE_SYS_SOCKET_H)
check_include_file(sys/sockio.h HAVE_SYS_SOCKIO_H)
check_include_file(sys/stat.h HAVE_SYS_STAT_H)
check_include_file(sys/stropts.h HAVE_SYS_STROPTS_H)
check_include_file(sys/sysctl.h HAVE_SYS_SYSCTL_H)
check_include_file(sys/timerfd.h HAVE_SYS_TIMERFD_H)
check_include_file(sys/time.h HAVE_SYS_TIME_H)
check_include_file(sys/types.h HAVE_SYS_TYPES_H)
check_include_file(sys/uio.h HAVE_SYS_UIO_H)
check_include_file(sys/un.h HAVE_SYS_UN_H)
check_include_file(sys/wait.h HAVE_SYS_WAIT_H)
check_include_file(termcap.h HAVE_TERMCAP_H)
check_include_file(term.h HAVE_TERM_H)
check_include_file(unistd.h HAVE_UNISTD_H)
check_include_file(util.h HAVE_UTIL_H)
check_include_file(utmp.h HAVE_UTMP_H)
check_include_file(windows.h HAVE_WINDOWS_H)
check_include_file(winsock2.h HAVE_WINSOCK2_H)
check_include_file(ws2tcpip.h HAVE_WS2TCPIP_H)

configure_file(
  ${CMAKE_SOURCE_DIR}/erts/config.h.in
  ${CMAKE_BINARY_DIR}/erts/config.h
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

# Define the 'liberts_internal' target that compiles the liberts_internal
# library.
set(LIBERTS_INTERNAL_SRC
  ${CMAKE_SOURCE_DIR}/erts/lib_src/common/erl_printf_format.c
  ${CMAKE_SOURCE_DIR}/erts/lib_src/common/erl_printf.c
  ${CMAKE_SOURCE_DIR}/erts/lib_src/common/erl_misc_utils.c
)
add_library(erts_internal STATIC ${LIBERTS_INTERNAL_SRC})
target_compile_definitions(erts_internal PRIVATE HAVE_CONFIG_H)
target_include_directories(erts_internal PRIVATE
  ${CMAKE_BINARY_DIR}/erts/
  ${CMAKE_BINARY_DIR}/erts/include/
  ${CMAKE_SOURCE_DIR}/erts/include/internal
)

add_library(erlang SHARED main.c)
set_target_properties(erlang PROPERTIES VERSION ${PROJECT_VERSION})
set_target_properties(erlang PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

install(TARGETS erlang LIBRARY DESTINATION lib)
