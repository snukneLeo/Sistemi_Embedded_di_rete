# - EDALab utility to find and build Doxygen documentation.
#
# Provided configuration options:
#   EdalabDoxygen_NOT_DOC_TARGET - {Bool} If ON, the doxygen documentation will be not added
#       to doc target as default.
#
# Provided user options:
#   DOXYGEN_GENERATE_DEVELOPERS_DOCUMENTATION
#
# Provided functions:
#  edalab_doxygen_add_target() - Adds a doxygen documentation target.
#
# Required extra files:
#   ${PROJECT_SOURCE_DIR}/extra/Doxyfile.in & ${PROJECT_SOURCE_DIR}/extra/Doxyfile.dev.in
#

#=============================================================================
# Copyright 2012 EDALab s.r.l.
#
# Distributed under the OSI-approved BSD License (the "License");
# see accompanying file Copyright.txt for details.
# This software is distributed WITHOUT ANY WARRANTY; without even the
# implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the License for more information.
#=============================================================================


# ###########################################################################
# User options.
# ###########################################################################

option(DOC_DOXYGEN_GENERATE_DEVELOPERS_DOC
  "Generates Doxygen docs with developers configuration." OFF)
mark_as_advanced(DOC_DOXYGEN_GENERATE_DEVELOPERS_DOC)

# ###########################################################################
# Configuration.
# ###########################################################################

# Setting standard vars:
set(EdalabDoxygen_VERSION_MAJOR 1)
set(EdalabDoxygen_VERSION_MINOR 0)
set(EdalabDoxygen_VERSION_PATCH 0)
set(EdalabDoxygen_VERSION_STRING "FindEdalabDoxygen.cmake verison: ${EdalabDoxygen_VERSION_MAJOR}.${EdalabDoxygen_VERSION_MINOR}.${EdalabDoxygen_VERSION_PATCH}.")

# Setting up search mode:
set(EdalabDoxygen_SEARCH_MODE "")
if(EdalabDoxygen_FIND_REQUIRED)
  set(EdalabDoxygen_SEARCH_MODE "REQUIRED")
elseif(EdalabDoxygen_FIND_QUIETLY)
  set(EdalabDoxygen_SEARCH_MODE "QUIET")
endif()

# Loading dependencies:
find_package(EdalabBase ${EdalabDoxygen_SEARCH_MODE})
find_package(Doxygen ${EdalabDoxygen_SEARCH_MODE})
find_package_handle_standard_args(EdalabDoxygen DEFAULT_MSG DOXYGEN_FOUND EDALABBASE_FOUND)

# Module configuration:
if(EDALABDOXYGEN_FOUND)

  # Module initialization:
  edalab_initialize_module("EdalabDoxygen" "${EdalabDoxygen_SEARCH_MODE}")

endif(EDALABDOXYGEN_FOUND)


# ###########################################################################
# Support functions.
# ###########################################################################

# ###########################################################################
# Functions.
# ###########################################################################

## @brief Adds a separated Doxygen documentation.
## This is useful in case a project contains many libraries whose API must be documented separately.
##
## @param TARGET {String}: The name to be set as target.
## @param IN_DIR The rirectory containing the Doxyfile to configure.
## @param NAME {String}: The name to be set as documentation title.
## @param VERSION {String}: The documentation version.
## @optional {String}: list of directories to be searched for documentation generation.
##
function(edalab_doxygen_add_target TARGET IN_DIR NAME VERSION)
  if ("${IN_DIR}" STREQUAL "")
    if(EXISTS "${PROJECT_SOURCE_DIR}/extra/Doxyfile.in")
      set(IN_DIR "${PROJECT_SOURCE_DIR}/extra")
    elseif(EXISTS "${PROJECT_SOURCE_DIR}/../../build_utils/sandbox/extra/Doxyfile.in")
      set(IN_DIR "${PROJECT_SOURCE_DIR}/../../build_utils/sandbox/extra")
    else()
      edalab_error_message("[EdalabDoxygen] Cannot locate Doxyfile.in")
    endif()
  endif("${IN_DIR}" STREQUAL "")
  set(EDALAB_PROJECT_NAME "${NAME}")
  set(EDALAB_PROJECT_NUMBER "${VERSION}")
  foreach(f ${ARGN})
    set(EDALAB_INPUT "${EDALAB_INPUT} \"${f}\"")
  endforeach(f )

  # Adding doxygen targets:
  # - Standard:
  configure_file(
  ${IN_DIR}/Doxyfile.in
    ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile.${TARGET}
    @ONLY)

  add_custom_target(${TARGET}
    COMMAND ${DOXYGEN_EXECUTABLE} ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile.${TARGET}
    DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile.${TARGET}
    )
  # Custom targets do not set the OUTPUT_NAME property.
  # Let's set it to be able to correctly install the target.
  set_target_properties(${TARGET} PROPERTIES OUTPUT_NAME "${CMAKE_CURRENT_BINARY_DIR}/doc/${TARGET}")

  if(NOT EdalabDoxygen_NOT_DOC_TARGET)
    add_dependencies(doc ${TARGET})
  endif(NOT EdalabDoxygen_NOT_DOC_TARGET)

  # - Developers:
  if(DOC_DOXYGEN_GENERATE_DEVELOPERS_DOC)

    add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile.${TARGET}.dev
      COMMAND set(EDALAB_PROJECT_NAME "${NAME}")
      COMMAND set(EDALAB_PROJECT_NUMBER "${VERSION}")
      COMMAND set(EDALAB_INPUT "${ARGS}")
      COMMAND configure_file(
        ${PROJECT_SOURCE_DIR}/extra/Doxyfile.dev.in
        ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile.${TARGET}.dev
        @ONLY)
      DEPENDS ${PROJECT_SOURCE_DIR}/extra/Doxyfile.dev.in
      )

    add_custom_target(${TARGET}_dev
      COMMAND ${DOXYGEN_EXECUTABLE} ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile.${TARGET}.dev
      DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile.${TARGET}.dev
      )
    # Custom targets do not set the OUTPUT_NAME property.
    # Let's set it to be able to correctly install the target.
    set_target_properties(${TARGET} PROPERTIES OUTPUT_NAME "${CMAKE_CURRENT_BINARY_DIR}/doc/${TARGET}")

    if(NOT EdalabDoxygen_NOT_DOC_TARGET)
      add_dependencies(doc ${TARGET}_dev)
    endif(NOT EdalabDoxygen_NOT_DOC_TARGET)

  endif(DOC_DOXYGEN_GENERATE_DEVELOPERS_DOC)

endfunction( edalab_doxygen_add_target TARGET NAME VERSION)

# EOF
