#############################################
# General CMake skeleton.
#############################################
#
# @author Francesco Stefanni
#

#
# HOWTO
#
# To configure these CMakeLists to your project,
# just check the vars in this files, and adapt the .deps.txt file.
#
# Sections in this file:
# - General.
# - Inclusions.
# - Svn.
# - Install.
# - CPack.
# - Doxygen.
#

#############################################
# General stuff.
#############################################

cmake_minimum_required(VERSION 2.8)
project(scnsl_test CXX)

cmake_policy(SET CMP0054 OLD) 
cmake_policy(SET CMP0045 OLD)

# Setting the default build type:
SET(CMAKE_BUILD_TYPE Debug CACHE STRING
  "Choose the type of build, options are: None Debug Release RelWithDebInfo MinSizeRel." FORCE)

SET(CMAKE_INSTALL_PREFIX ~/scnsl_${CMAKE_SYSTEM_PROCESSOR}/ CACHE PATH "Default install directory." FORCE)

# As default, create shared libs.
SET(BUILD_SHARED_LIBS ON CACHE BOOL "Chooses the type of libs." FORCE)

# Adding a target doc.
get_target_property(DOC_TARGET doc TYPE)
if(NOT DOC_TARGET)
  add_custom_target(doc)
endif(NOT DOC_TARGET)


#############################################
# Inclusions.
#############################################

# Setting extra modules path:
SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${PROJECT_SOURCE_DIR}/scripts)

# Including general support:
include(${PROJECT_SOURCE_DIR}/scripts/CMakeLists.support.txt)

# Including common definitions and settings.
include(${PROJECT_SOURCE_DIR}/scripts/CMakeLists.defs.txt)


#############################################
# SCNSL.
#############################################

find_path(SCNSL_INCLUDE scnsl.hh
  PATHS $ENV{SCNSL_HOME}/include)
find_library(LIB_SCNSL scnsl
  PATHS $ENV{SCNSL_HOME}/lib)
mark_as_advanced(SCNSL_INCLUDE LIB_SCNSL)

#############################################
# Other support libs:
#############################################

find_library(LIB_DL dl)
mark_as_advanced(LIB_DL)

find_library(LIB_PTHREAD pthread)
mark_as_advanced(LIB_PTHREAD)


#############################################
# SystemC.
#############################################

find_package(SystemC)
find_systemc(LIB_SYSTEMC SYSTEMC_INCLUDE)
find_systemc_tlm(SYSTEMC_TLM_INCLUDE)

mark_as_advanced(LIB_SYSTEMC SYSTEMC_INCLUDE SYSTEMC_TLM_INCLUDE)

#############################################
# Revision.
#############################################

find_package(Revision)
find_revision(${PROJECT_SOURCE_DIR} SOURCES_REVISION)
if(NOT SOURCES_REVISION)
  SET(SOURCES_REVISION 0)
endif(NOT SOURCES_REVISION)

#message("REVISION NUMBER: ${SOURCES_REVISION}")

#############################################
# Install.
#############################################


include(CMakeLists.install)


#############################################
# Targets.
#############################################

# Including targets and dependencies.
include(${PROJECT_SOURCE_DIR}/CMakeLists.deps.txt)


#############################################
# CTest.
#############################################

include(CTest)

# Setting tests:

# ENABLE_TESTING()
#${EXECUTABLE_OUTPUT_PATH}/${t}

execute_process(
  COMMAND cmake -E make_directory regression
  COMMAND cmake -E make_directory results
  )

foreach( t ${TEST_TARGETS} )
  if ("" MATCHES "${${t}_RANGE}")
    message("Adding regression test: ${t}.")
    add_test(
      NAME "${t}"
      COMMAND cmake -D t:string=${t} -D TEST_PROGRAM:string=${EXECUTABLE_OUTPUT_PATH}/${t} -D GOLDEN_DIR:string=${PROJECT_SOURCE_DIR}/golden_models -P ${PROJECT_SOURCE_DIR}/../scripts/CMakeLists.reg.txt
      )
  else()
    message("Adding regression test: ${t} as multiple.")
    foreach(ti ${${t}_RANGE})
      add_test(
	NAME "${t}_${ti}"
	COMMAND cmake -D t:string=${t} -D ti:string=${ti} -D TEST_PROGRAM:string=${EXECUTABLE_OUTPUT_PATH}/${t} -D GOLDEN_DIR:string=${PROJECT_SOURCE_DIR}/golden_models -P ${PROJECT_SOURCE_DIR}/../scripts/CMakeLists.reg.txt
	)
    endforeach()
  endif()
endforeach()


#############################################
# CPack.
#############################################


# The copyright owner.
SET(CPACK_PACKAGE_VENDOR "D. Quaglia, F.Stefanni")


SET(CPACK_PACKAGE_VERSION_MAJOR 1)
SET(CPACK_PACKAGE_VERSION_MINOR 0)
SET(CPACK_PACKAGE_VERSION_PATCH ${SOURCES_REVISION})

SET(VERSION "${CPACK_PACKAGE_VERSION_MAJOR}.${CPACK_PACKAGE_VERSION_MINOR}.${CPACK_PACKAGE_VERSION_PATCH}")

SET(CPACK_GENERATOR "DEB;TGZ;") # RPM
# set(CPACK_DEBIAN_PACKAGE_DEPENDS "libc6 (>= 2.3.6), libgcc1 (>= 1:4.1)")
SET(CPACK_PACKAGE_CONTACT "info@edalab.it")
SET(CPACK_DEBIAN_PACKAGE_MAINTAINER "Francesco Stefanni")

SET(CPACK_PACKAGE_DESCRIPTION_FILE ${CMAKE_CURRENT_SOURCE_DIR}/doc/DESCRIPTION.txt)

SET(CPACK_PACKAGE_NAME "${PROJECT_NAME}")
SET(CPACK_PACKAGE_DESCRIPTION_SUMMARY "The SystemC Simulation Library.")
SET(CPACK_PACKAGE_FILE_NAME "${PROJECT_NAME}-${VERSION}")
SET(CPACK_PACKAGE_INSTALL_DIRECTORY ${CMAKE_INSTALL_PREFIX})

SET(CPACK_RESOURCE_FILE_LICENSE ${CMAKE_CURRENT_SOURCE_DIR}/doc/LICENSE.txt)
SET(CPACK_RESOURCE_FILE_README ${CMAKE_CURRENT_SOURCE_DIR}/doc/README.txt)
SET(CPACK_RESOURCE_FILE_WELCOME ${CMAKE_CURRENT_SOURCE_DIR}/doc/WELCOME.txt)

# CPACK_MONOLITHIC_INSTALL - Disables the component-based
# installation mechanism, so that all components are always installed.


# CPACK_GENERATOR - List of CPack generators to use. If not
#    specified, CPack will create a set of options (e.g.,
#    CPACK_BINARY_NSIS) allowing the user to enable/disable individual
#    generators.


# CPACK_PACKAGE_EXECUTABLES - Lists each of the executables along
# with a text label, to be used to create Start Menu shortcuts on
# Windows. For example, setting this to the list ccmake;CMake will
# create a shortcut named "CMake" that will execute the installed
# executable ccmake.


# include(CPack)

#############################################
# Doxygen.
#############################################

# No docygen doc generation for tests.
# include(CMakeLists.doxy)
#file(MAKE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/doc)

#### EOF ####
