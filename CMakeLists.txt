# Copyright (C) 2021-2023 Istituto Italiano di Tecnologia (IIT). All rights reserved.
# This software may be modified and distributed under the terms of the MIT license

cmake_minimum_required(VERSION 3.16)

set(CASADI_UPSTREAM_VERSION 3.7.0)
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

if(NOT ${casadi_VERSION} VERSION_EQUAL ${CASADI_UPSTREAM_VERSION})
  message(STATUS "Wrong casadi found via find_matlab: ${casadi_VERSION}, while required is ${CASADI_UPSTREAM_VERSION}")
endif()

# Include support for casadi's deprecated features (to be removed in the next release)
# Note that this should match how the imported casadi is compiled and how the swig files
# are generated in the casadi tarball, but as we can't extract this easily, we just hardcode
# it to the same default value of casadi
option(WITH_DEPRECATED_FEATURES "Compile with syntax that is scheduled to be deprecated" ON)
if (WITH_DEPRECATED_FEATURES)
  add_definitions(-DWITH_DEPRECATED_FEATURES)
endif()

# This is required to make sure that mexFunction has the same visibility attributes in both mex.h
# and the casadi generated MATLAB files
# see https://github.com/ami-iit/casadi-matlab-bindings/pull/11#issuecomment-1500860511
add_definitions(-DMW_NEEDS_VERSION_H)

## Download casadi source code, to get the MATLAB generated files
include(FetchContent)
FetchContent_Declare(
  casadisourcecode
  URL      https://github.com/casadi/casadi/releases/download/${CASADI_UPSTREAM_VERSION}/casadi-${CASADI_UPSTREAM_VERSION}.tar.gz
  URL_HASH MD5=0034cce1dd8f3ea3ee91225fc0424426
)
FetchContent_GetProperties(casadisourcecode)
if(casadisourcecode_POPULATED)
  message(FATAL_ERROR "casadi-matlab-bindings: unexpected casadisourcecode_POPULATED variable already set")
endif()

FetchContent_Populate(casadisourcecode)

# Common C++ and MATLAB source files
set(MEX_FILES ${casadisourcecode_SOURCE_DIR}/swig/matlab/target/source/casadiMATLAB_wrap.cxx
              ${casadisourcecode_SOURCE_DIR}/swig/matlab/target/source/casadiMATLAB_wrap.h)

set(MATLAB_PACKAGE_LOCATION ${casadisourcecode_SOURCE_DIR}/swig/matlab/target/extra)
set(MATLAB_EXTRA_FILES_LOCATION ${casadisourcecode_SOURCE_DIR}/swig/matlab)
set(OCTAVE_ONLY_FILES_LOCATION ${casadisourcecode_SOURCE_DIR}/swig/octave)


if(CASADI_MATLAB_BINDINGS_USES_MATLAB)
  find_package(Matlab REQUIRED)
  if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.24")
    matlab_add_mex(
      NAME casadi_mex_matlab
      OUTPUT_NAME casadiMEX
      SRC ${MEX_FILES}
      NO_IMPLICIT_LINK_TO_MATLAB_LIBRARIES
      LINK_TO ${Matlab_MEX_LIBRARY} ${Matlab_MX_LIBRARY} casadi)
  else()
    matlab_add_mex(
      NAME casadi_mex_matlab
      OUTPUT_NAME casadiMEX
      SRC ${MEX_FILES}
      LINK_TO ${Matlab_MEX_LIBRARY} ${Matlab_MX_LIBRARY} casadi)
  endif()
  # Workaround for https://github.com/ami-iit/casadi-matlab-bindings/issues/5
  target_compile_definitions(casadi_mex_matlab PRIVATE HAVE_OCTAVE)
  # casadi does not export correctly the C++11 requirement, let's do it here
  # See https://github.com/robotology/robotology-superbuild/issues/753
  target_compile_features(casadi_mex_matlab PRIVATE cxx_std_11)
  install(
    TARGETS casadi_mex_matlab
    EXPORT ${PROJECT_NAME}
    DESTINATION ${CASADI_MATLAB_BINDINGS_INSTALL_MATLAB_LIBDIR})

  # Install MATLAB-files
  # Logic copied from https://github.com/casadi/casadi/blob/3.6.0/swig/matlab/CMakeLists.txt#L31

  # Install the generated front-end to ${MATLAB_PREFIX}
  install(DIRECTORY ${MATLAB_PACKAGE_LOCATION}/+casadi DESTINATION ${CASADI_MATLAB_BINDINGS_INSTALL_MATLAB_MFILESDIR})

  # Install MATLAB/Octave helper files
  install(FILES ${MATLAB_PACKAGE_LOCATION}/SwigRef.m DESTINATION ${CASADI_MATLAB_BINDINGS_INSTALL_MATLAB_MFILESDIR})
  install(FILES ${MATLAB_PACKAGE_LOCATION}/SwigMem.m DESTINATION ${CASADI_MATLAB_BINDINGS_INSTALL_MATLAB_MFILESDIR})
  install(FILES ${MATLAB_PACKAGE_LOCATION}/SwigGet.m DESTINATION ${CASADI_MATLAB_BINDINGS_INSTALL_MATLAB_MFILESDIR})
  install(FILES ${MATLAB_PACKAGE_LOCATION}/SwigStorage.m DESTINATION ${CASADI_MATLAB_BINDINGS_INSTALL_MATLAB_MFILESDIR})

  install(FILES ${MATLAB_EXTRA_FILES_LOCATION}/swig_typename_convertor_matlab2cpp.m
                ${MATLAB_EXTRA_FILES_LOCATION}/SwigType.m
                ${MATLAB_EXTRA_FILES_LOCATION}/returntypes_call.m
                ${MATLAB_EXTRA_FILES_LOCATION}/returntypes.m
    DESTINATION ${CASADI_MATLAB_BINDINGS_INSTALL_MATLAB_MFILESDIR})

  install(FILES ${MATLAB_EXTRA_FILES_LOCATION}/OptiCallbackHelper.m
    DESTINATION ${CASADI_MATLAB_BINDINGS_INSTALL_MATLAB_MFILESDIR}/+casadi)
endif()

if(CASADI_MATLAB_BINDINGS_USES_OCTAVE)
  find_package(Octave REQUIRED)

  add_library(casadi_mex_octave MODULE  ${MEX_FILES})
  target_compile_definitions(casadi_mex_octave PRIVATE HAVE_OCTAVE)
  # casadi does not export correctly the C++11 requirement, let's do it here
  # See https://github.com/robotology/robotology-superbuild/issues/753
  target_compile_features(casadi_mex_octave PRIVATE cxx_std_11)
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

  # Install MATLAB-files
  # Logic copied from https://github.com/casadi/casadi/blob/3.6.0/swig/matlab/CMakeLists.txt#L31

  # Install the generated front-end to ${MATLAB_PREFIX}
  install(DIRECTORY ${MATLAB_PACKAGE_LOCATION}/+casadi DESTINATION ${CASADI_MATLAB_BINDINGS_INSTALL_MATLAB_MFILESDIR})

  # Install MATLAB/Octave helper files
  install(FILES ${MATLAB_PACKAGE_LOCATION}/SwigRef.m DESTINATION ${CASADI_MATLAB_BINDINGS_INSTALL_MATLAB_MFILESDIR})
  install(FILES ${MATLAB_PACKAGE_LOCATION}/SwigMem.m DESTINATION ${CASADI_MATLAB_BINDINGS_INSTALL_MATLAB_MFILESDIR})
  install(FILES ${MATLAB_PACKAGE_LOCATION}/SwigGet.m DESTINATION ${CASADI_MATLAB_BINDINGS_INSTALL_MATLAB_MFILESDIR})
  install(FILES ${MATLAB_PACKAGE_LOCATION}/SwigStorage.m DESTINATION ${CASADI_MATLAB_BINDINGS_INSTALL_MATLAB_MFILESDIR})

  install(FILES ${MATLAB_EXTRA_FILES_LOCATION}/swig_typename_convertor_matlab2cpp.m
                ${MATLAB_EXTRA_FILES_LOCATION}/SwigType.m
                ${MATLAB_EXTRA_FILES_LOCATION}/returntypes_call.m
                ${MATLAB_EXTRA_FILES_LOCATION}/returntypes.m
    DESTINATION ${CASADI_MATLAB_BINDINGS_OCTAVE_MFILESDIR})

  install(FILES ${MATLAB_EXTRA_FILES_LOCATION}/OptiCallbackHelper.m
    DESTINATION ${CASADI_MATLAB_BINDINGS_OCTAVE_MFILESDIR}/+casadi)

  install(
    FILES ${OCTAVE_ONLY_FILES_LOCATION}/import.m
    DESTINATION ${CASADI_MATLAB_BINDINGS_OCTAVE_MFILESDIR}/octave-extra)
endif()

include(AddUninstallTarget)
