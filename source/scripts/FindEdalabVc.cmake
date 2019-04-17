# - EDALab utility to configure VC++ flags.
# Written by using VC++ 2010 docs.
# Tested flags under Vc++ 2013.
#
# Input options (from EdalabCompiler):
#   COMPILER_CHECK_SWITCH_ENUMS
#   COMPILER_DEBUG_STL
#   COMPILER_FATAL_ERRORS
#   COMPILER_USE_PROFILER
#   COMPILER_VISIBILITY
#   COMPILER_WARNINGS_AS_ERRORS
#
# Implements:
#   _edalab_compiler_submodule_set_refresh_flags() -- from EdalabCompiler
#   _edalab_compiler_check_flag()                  -- from EdalabCompiler

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

option(COMPILER_VC_SHOW_INCLUDES "Show include dependencies." OFF)

# ###########################################################################
# Configuration.
# ###########################################################################

# Setting standard vars:
set(EdalabVc_VERSION_MAJOR 1)
set(EdalabVc_VERSION_MINOR 0)
set(EdalabVc_VERSION_PATCH 0)
set(EdalabVc_VERSION_STRING "FindEdalabVc.cmake verison: ${EdalabVc_VERSION_MAJOR}.${EdalabVc_VERSION_MINOR}.${EdalabVc_VERSION_PATCH}.")

# Setting up search mode:
set(EdalabVc_SEARCH_MODE "")
if(EdalabVc_FIND_REQUIRED)
  set(EdalabVc_SEARCH_MODE "REQUIRED")
elseif(EdalabVc_FIND_QUIETLY)
  set(EdalabVc_SEARCH_MODE "QUIET")
endif()

# Loading dependencies:
find_package(EdalabBase ${EdalabVc_SEARCH_MODE})
set(EdalabVc_INCLUDED ON)
if(NOT EdalabCompiler_INCLUDED)
  find_package(EdalabCompiler ${EdalabVc_SEARCH_MODE})
  find_package_handle_standard_args(EdalabVc DEFAULT_MSG EDALABCOMPILER_FOUND EDALABBASE_FOUND)
else(NOT EdalabCompiler_INCLUDED)
  find_package_handle_standard_args(EdalabVc DEFAULT_MSG EDALABBASE_FOUND)
endif(NOT EdalabCompiler_INCLUDED)

# Module configuration:
if(EDALABVC_FOUND)

  # Module initialization:
  edalab_initialize_module("EdalabVc" "${EdalabVc_SEARCH_MODE}")

endif(EDALABVC_FOUND)

# ###########################################################################
# Functions implementation.
# ###########################################################################

function(_edalab_compiler_submodule_set_refresh_flags REFRESH)

  if(NOT ("${COMPILER_VC_SHOW_INCLUDES_OLD}" STREQUAL "${COMPILER_VC_SHOW_INCLUDES}"))
    set(${REFRESH} ON PARENT_SCOPE)
  else()
    set(${REFRESH} OFF PARENT_SCOPE)
  endif()
  set(COMPILER_VC_SHOW_INCLUDES_OLD ${COMPILER_VC_SHOW_INCLUDES} CACHE INTERNAL "" FORCE)

endfunction(_edalab_compiler_submodule_set_refresh_flags)

function(_edalab_compiler_submodule_set_flags )

  #####################################################
  # C & C++
  #####################################################
  edalab_compiler_add_flag("c_cxx_basic" "/Wall" ON OFF OFF)
  edalab_compiler_add_flag("c_cxx_basic" "/W4" ON OFF OFF)
  edalab_compiler_add_flag("c_cxx_basic" "/EHsc" ON OFF OFF)
  edalab_compiler_add_flag("c_cxx_basic" "/GR" ON OFF OFF)

  edalab_compiler_add_flag("c_cxx_basic" "/WX" ${COMPILER_WARNINGS_AS_ERRORS} OFF OFF)
  # Avoids warnings about printf & co.
  # add_definitions(-D_CRT_SECURE_NO_WARNINGS)
  edalab_compiler_add_flag("c_cxx_basic" "-D_CRT_SECURE_NO_WARNINGS" ON OFF OFF)

  edalab_compiler_add_flag("c_cxx_mem" "/Os" ON OFF OFF)

  edalab_compiler_add_flag("c_cxx_opt" "/Ox" ON OFF OFF)

  edalab_compiler_add_flag("c_cxx_debug" "/Od" ON OFF OFF)
  edalab_compiler_add_flag("c_cxx_debug" "/Gs" ON OFF OFF)
  edalab_compiler_add_flag("c_cxx_debug" "/Gm" ON OFF OFF)
  edalab_compiler_add_flag("c_cxx_debug" "/Zi" ON OFF OFF)
  edalab_compiler_add_flag("c_cxx_debug" "/RTC1" ON OFF OFF)
  edalab_compiler_add_flag("c_cxx_debug" "/showIncludes" ${COMPILER_VC_SHOW_INCLUDES} OFF OFF)

  # CMake bug: on Win64 wrong machine. Try to fix.
  #if(("${EDALAB_SYSTEM_WIDTH}" STREQUAL "64") AND USER_FORCE_ACTUAL)
  if("${EDALAB_SYSTEM_WIDTH}" STREQUAL "64")
  	edalab_compiler_add_linker_flag("all" "/MACHINE:x64" ON OFF OFF)
  endif("${EDALAB_SYSTEM_WIDTH}" STREQUAL "64")
  #endif(("${EDALAB_SYSTEM_WIDTH}" STREQUAL "64") AND USER_FORCE_ACTUAL)

  # Removing INCREMENTAL flag
  edalab_compiler_remove_linker_flag("all" "/INCREMENTAL:NO")
  edalab_compiler_remove_linker_flag("all" "/INCREMENTAL:YES")
  edalab_compiler_remove_linker_flag("all" "/INCREMENTAL")

  # Some exports could be duplicated along different libs or exe
  # (e.g. STL exporting). So let's try:
  # set_target_properties(${name} PROPERTIES LINK_FLAGS "/FORCE:MULTIPLE")
  # set_target_properties(${name}_static PROPERTIES LINK_FLAGS "/FORCE:MULTIPLE")
  # edalab_compiler_add_linker_flag("all" "/FORCE:MULTIPLE" ON OFF OFF)
  edalab_compiler_add_linker_flag("all" "/FORCE" ON OFF OFF)

  # Since FORCE is used, a warning is raised due to ignored INCREMENTAL linking.
  # This flag avoids such a warning:
  #edalab_compiler_add_linker_flag("all" "/INCREMENTAL:NO" ON OFF OFF)

  #####################################################
  # C
  #####################################################

  if("${COMPILER_C_STANDARD}" STREQUAL "OFF")
    # No standard set.
  elseif("${COMPILER_C_STANDARD}" STREQUAL "89")
    edalab_compiler_add_flag("c_basic" "/Za" ON ON ON)
  elseif("${COMPILER_C_STANDARD}" STREQUAL "99")
    # Nothig to do.
  elseif("${COMPILER_C_STANDARD}" STREQUAL "11")
    # Nothig to do.
  else()
    edalab_error_message("Unknown C standard: ${COMPILER_C_STANDARD}")
  endif()

  #####################################################
  # C++
  #####################################################

  if("${COMPILER_CXX_STANDARD}" STREQUAL "OFF")
    # No standard set.
  elseif("${COMPILER_CXX_STANDARD}" STREQUAL "98")
    edalab_compiler_add_flag("cxx_basic" "/Za" ON ON ON)
  elseif("${COMPILER_CXX_STANDARD}" STREQUAL "11")
    # Nothig to do.
  else()
    edalab_error_message("Unknown C++ standard: ${COMPILER_CXX_STANDARD}")
  endif()

endfunction(_edalab_compiler_submodule_set_flags )

# EOF
