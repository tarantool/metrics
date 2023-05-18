cmake_minimum_required(VERSION 2.6 FATAL_ERROR)

project(metrics NONE)

## Install ####################################################################
###############################################################################

if(NOT DEFINED TARANTOOL_INSTALL_LUADIR)
    set(TARANTOOL_INSTALL_LUADIR "${PROJECT_SOURCE_DIR}/.rocks/share/tarantool")
endif()

install(
  DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/${PROJECT_NAME}
  DESTINATION ${TARANTOOL_INSTALL_LUADIR}
)

install(
  DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/${PROJECT_NAME}
  DESTINATION ${TARANTOOL_INSTALL_LUADIR}/override
)
