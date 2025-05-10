cmake_minimum_required(VERSION 2.6 FATAL_ERROR)
project(metrics-rs NONE)

if (NOT DEFINED CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Release")
endif()
if (NOT DEFINED TARANTOOL_INSTALL_LIBDIR)
    message(SEND_ERROR "TARANTOOL_INSTALL_LIBDIR is not defined")
endif()

set(RUST_BUILD_DIR ${CMAKE_CURRENT_SOURCE_DIR}/target/${CMAKE_BUILD_TYPE})

find_program(CARGO cargo)
add_custom_target(metrics-rs ALL
    COMMAND ${CARGO} build --profile "${CMAKE_BUILD_TYPE}"
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)

install(
    FILES ${RUST_BUILD_DIR}/libmetrics_rs${CMAKE_SHARED_LIBRARY_SUFFIX}
    RENAME metrics_rs${CMAKE_SHARED_LIBRARY_SUFFIX}
    DESTINATION ${TARANTOOL_INSTALL_LIBDIR}
)
