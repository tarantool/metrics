cmake_minimum_required(VERSION 3.10...3.31 FATAL_ERROR)

project(metrics NONE)

# Fix problem with old third_party dependencies
set(CMAKE_POLICY_VERSION_MINIMUM 3.5)

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
