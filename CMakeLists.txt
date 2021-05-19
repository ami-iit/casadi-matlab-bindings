# Copyright (C) 2021 Istituto Italiano di Tecnologia (IIT). All rights reserved.
# This software may be modified and distributed under the terms of the MIT license

cmake_minimum_required(VERSION 3.16)

set(CASADI_UPSTREAM_VERSION 3.5.5)
set(CASADI_MATLAB_BINDINGS_REVISION 0)
set(CASADI_MATLAB_BINDINGS_VERSION "${CASADI_UPSTREAM_VERSION}.${CASADI_MATLAB_BINDINGS_REVISION}")
project(casadi-matlab-bindings
  LANGUAGES C CXX
  VERSION ${CASADI_MATLAB_BINDINGS_VERSION})

include(GNUInstallDirs)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${CMAKE_INSTALL_BINDIR}")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${CMAKE_INSTALL_LIBDIR}")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${CMAKE_INSTALL_LIBDIR}")

option(BUILD_SHARED_LIBS "Build libraries as shared as opposed to static" ON)
option(CASADI_MATLAB_BINDINGS_USES_MATLAB "Do you want to create the MATLAB bindings" ON)
option(CASADI_MATLAB_BINDINGS_USES_OCTAVE "Do you want to create the Octave bindings" OFF)

set(CASADI_MATLAB_BINDINGS_INSTALL_MATLAB_LIBDIR "mex" CACHE
    STRING "Location (relative to the install prefix) in which the Matlab mex libraries are installed.")
set(CASADI_MATLAB_BINDINGS_INSTALL_MATLAB_MFILESDIR "mex" CACHE
    STRING "Location (relative to the install prefix) in which the Matlab .m files are installed.")
set(CASADI_MATLAB_BINDINGS_OCTAVE_LIBDIR "octave" CACHE
    STRING "Location (relative to the install prefix) in which the Octave mex libraries are installed.")
set(CASADI_MATLAB_BINDINGS_OCTAVE_MFILESDIR "octave" CACHE
    STRING "Location (relative to the install prefix) in which the Octave .m files are installed.")

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/ycm-0.12)
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/cmake-proposed)

# Enable RPATH support for installed binaries and libraries
include(AddInstallRPATHSupport)
add_install_rpath_support(BIN_DIRS "${CMAKE_INSTALL_FULL_BINDIR}"
  LIB_DIRS "${CMAKE_INSTALL_FULL_LIBDIR}"
  INSTALL_NAME_DIR "${CMAKE_INSTALL_FULL_LIBDIR}"
  USE_LINK_PATH)

# Encourage user to specify a build type (e.g. Release, Debug, etc.), otherwise set it to Release.
if(NOT CMAKE_CONFIGURATION_TYPES)
  if(NOT CMAKE_BUILD_TYPE)
    message(STATUS "Setting build type to 'Release' as none was specified.")
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY VALUE "Release")
  endif()
endif()

## Find casadi dependency
find_package(casadi REQUIRED)

# Common C++ and MATLAB source files
set(MEX_FILES ${CMAKE_CURRENT_SOURCE_DIR}/autogenerated/cxx/casadiMATLAB_wrap.cxx
              ${CMAKE_CURRENT_SOURCE_DIR}/autogenerated/cxx/casadiMATLAB_wrap.h)

file(GLOB MATLAB_FILES_IN_ROOT_DIR ${CMAKE_CURRENT_SOURCE_DIR}/autogenerated/matlab/*.m)

if(CASADI_MATLAB_BINDINGS_USES_MATLAB)
  find_package(Matlab REQUIRED)
  matlab_add_mex(
      NAME casadi_mex_matlab
      OUTPUT_NAME casadiMEX
      SRC ${MEX_FILES}
      NO_IMPLICIT_LINK_TO_MATLAB_LIBRARIES
      LINK_TO ${Matlab_MEX_LIBRARY} ${Matlab_MX_LIBRARY} casadi)
  # Workaround for https://github.com/dic-iit/casadi-matlab-bindings/issues/5
  target_compile_definitions(casadi_mex_matlab PRIVATE HAVE_OCTAVE)
  install(
    TARGETS casadi_mex_matlab
    EXPORT ${PROJECT_NAME}
    DESTINATION ${CASADI_MATLAB_BINDINGS_INSTALL_MATLAB_LIBDIR})
  install(
    FILES ${MATLAB_FILES_IN_ROOT_DIR}
    DESTINATION ${CASADI_MATLAB_BINDINGS_INSTALL_MATLAB_MFILESDIR})
  install(
    DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/autogenerated/matlab/+casadi
    DESTINATION ${CASADI_MATLAB_BINDINGS_INSTALL_MATLAB_MFILESDIR})
endif()

if(CASADI_MATLAB_BINDINGS_USES_OCTAVE)
  find_package(Octave REQUIRED)

  add_library(casadi_mex_octave MODULE  ${MEX_FILES})
  target_compile_definitions(casadi_mex_octave PRIVATE HAVE_OCTAVE)
  set_target_properties(casadi_mex_octave PROPERTIES DEBUG_POSTFIX "")
  target_include_directories(casadi_mex_octave PUBLIC ${OCTAVE_INCLUDE_DIRS})
  target_link_libraries(casadi_mex_octave ${OCTAVE_LIBRARIES} casadi)
  if(APPLE)
    set_target_properties(casadi_mex_octave PROPERTIES LINK_FLAGS "-undefined dynamic_lookup")
  endif()
  set_target_properties(casadi_mex_octave
    PROPERTIES OUTPUT_NAME casadiMEX
               PREFIX ""
               SUFFIX .mex)
  install(
    TARGETS casadi_mex_octave
    EXPORT ${PROJECT_NAME}
    DESTINATION ${CASADI_MATLAB_BINDINGS_INSTALL_OCTAVE_LIBDIR})
  install(
    FILES ${MATLAB_FILES_IN_ROOT_DIR}
    DESTINATION ${CASADI_MATLAB_BINDINGS_INSTALL_MATLAB_MFILESDIR})
  install(
    DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/autogenerated/matlab/+casadi
    DESTINATION ${CASADI_MATLAB_BINDINGS_INSTALL_MATLAB_MFILESDIR})
  install(
    DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/autogenerated/matlab/octave-extra
    DESTINATION ${CASADI_MATLAB_BINDINGS_INSTALL_MATLAB_MFILESDIR})
endif()

include(AddUninstallTarget)