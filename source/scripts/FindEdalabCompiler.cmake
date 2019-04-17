# - EDALab utility to set up compiler options.
# This module should be initialized as follows:
# find(EdalabCompiler)
# edalab_compiler_add_user_options(...)
# edalab_compiler_set_flags()
#
# Submodules must implement:
#   _edalab_compiler_submodule_set_refresh_flags()
#   _edalab_compiler_submodule_set_flags()
#
# Provided user functions:
#   edalab_compiler_add_user_options() - To add the user options, after this module loading.
#   edalab_compiler_add_flag()         - To add a compiler flag. Provided to submodules.
#   edalab_compiler_add_linker_flag()  - To add a linker flag. Provided to submodules.
#   edalab_compiler_set_flags()        - Global setup
#   edalab_compiler_set_target_flags() - Adds flags for specific targets.
#
# Provided internal functions:
#   _edalab_compiler_internal_initialization()
#   _edalab_compiler_check_flag()
#   _edalab_compiler_get_lang()
#
# Provided user options:
#   COMPILER_CHECK_SWITCH_ENUMS
#   COMPILER_C_STANDARD
#   COMPILER_CXX_STANDARD
#   COMPILER_DEBUG_STL
#   COMPILER_FATAL_ERRORS
#   COMPILER_USE_PROFILER
#   COMPILER_VISIBILITY
#   COMPILER_WARNINGS_AS_ERRORS
#
# Provided variables:
#   EdalabCompiler_C_IS_ENABLED
#   EdalabCompiler_CXX_IS_ENABLED
#   EdalabCompiler_INCLUDED

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
# Support functions.
# ###########################################################################


## @brief Completes module initialization.
##
function(_edalab_compiler_internal_initialization )

  # Checking the active languages:
  # - Get the list of languages:
  get_property(CURRENT_LANGUAGES GLOBAL PROPERTY ENABLED_LANGUAGES)
  # - Checking C:
  list(FIND CURRENT_LANGUAGES "C" MY_C_IS_ENABLED)
  if(${MY_C_IS_ENABLED} EQUAL -1)
    set(EdalabCompiler_C_IS_ENABLED OFF PARENT_SCOPE)
  else(${MY_C_IS_ENABLED} EQUAL -1)
    set(EdalabCompiler_C_IS_ENABLED ON PARENT_SCOPE)
  endif(${MY_C_IS_ENABLED} EQUAL -1)
  # - Checking C++:
  list(FIND CURRENT_LANGUAGES "CXX" MY_CXX_IS_ENABLED)
  if(${MY_CXX_IS_ENABLED} EQUAL -1)
    set(EdalabCompiler_CXX_IS_ENABLED OFF PARENT_SCOPE)
  else(${MY_CXX_IS_ENABLED} EQUAL -1)
    set(EdalabCompiler_CXX_IS_ENABLED ON PARENT_SCOPE)
  endif(${MY_CXX_IS_ENABLED} EQUAL -1)

  # Resetting internal cache vars:
  # - c_cxx_basic, c_cxx_mem, c_cxx_opt, c_cxx_debug.
  unset(EdalabCompiler_c_cxx_basic CACHE)
  unset(EdalabCompiler_c_cxx_mem CACHE)
  unset(EdalabCompiler_c_cxx_opt CACHE)
  unset(EdalabCompiler_c_cxx_debug CACHE)
  # - c_basic, c_mem, c_opt, c_debug.
  unset(EdalabCompiler_c_basic CACHE)
  unset(EdalabCompiler_c_mem CACHE)
  unset(EdalabCompiler_c_opt CACHE)
  unset(EdalabCompiler_c_debug CACHE)
  # - cxx_basic, cxx_mem, cxx_opt, cxx_debug.
  unset(EdalabCompiler_cxx_basic CACHE)
  unset(EdalabCompiler_cxx_mem CACHE)
  unset(EdalabCompiler_cxx_opt CACHE)
  unset(EdalabCompiler_cxx_debug CACHE)
  unset(EdalabCompiler_linker_all CACHE)
  unset(EdalabCompiler_linker_exe CACHE)
  unset(EdalabCompiler_linker_shared CACHE)
  unset(EdalabCompiler_linker_module CACHE)
  # - Standard CMake cache variables:
  unset(CMAKE_C_FLAGS CACHE)
  unset(CMAKE_C_FLAGS_DEBUG CACHE)
  unset(CMAKE_C_FLAGS_MINSIZEREL CACHE)
  unset(CMAKE_C_FLAGS_RELEASE CACHE)
  unset(CMAKE_C_FLAGS_RELWITHDEBINFO CACHE)
  unset(CMAKE_CXX_FLAGS CACHE)
  unset(CMAKE_CXX_FLAGS_DEBUG CACHE)
  unset(CMAKE_CXX_FLAGS_MINSIZEREL CACHE)
  unset(CMAKE_CXX_FLAGS_RELEASE CACHE)
  unset(CMAKE_CXX_FLAGS_RELWITHDEBINFO CACHE)

  # - Standard linker flags:
  unset(CMAKE_EXE_LINKER_FLAGS CACHE)
  unset(CMAKE_SHARED_LINKER_FLAGS CACHE)
  unset(CMAKE_MODULE_LINKER_FLAGS CACHE)
  unset(CMAKE_STATIC_LINKER_FLAGS CACHE)

endfunction(_edalab_compiler_internal_initialization)


## @brief Checks if a flag is supported by current compiler.
## LANG can be: c, cxx, c_cxx.
##
## @param FLAG {String} The flag to be checked.
## @param LANG {String} The flag language.
## @param CXX_SUPPORTED {Bool} Output. If the flag is supported by C++.
## @param C_SUPPORTED {Bool} Output. If the flag is supported by C.
##
function(_edalab_compiler_check_flag FLAG LANG CXX_SUPPORTED C_SUPPORTED)

  edalab_reset_variable(SUPPORTED_C_FLAG)
  edalab_reset_variable(SUPPORTED_CXX_FLAG)

  if("${LANG}" STREQUAL "cxx")

    if(EdalabCompiler_CXX_IS_ENABLED)
      check_cxx_compiler_flag("${FLAG}" SUPPORTED_CXX_FLAG)
      set(SUPPORTED_C_FLAG OFF)
    else(EdalabCompiler_CXX_IS_ENABLED)
      set(SUPPORTED_CXX_FLAG ON)
      set(SUPPORTED_C_FLAG OFF)
   endif(EdalabCompiler_CXX_IS_ENABLED)

  elseif("${LANG}" STREQUAL "c")

    if(EdalabCompiler_C_IS_ENABLED)
      check_c_compiler_flag(${FLAG} SUPPORTED_C_FLAG)
      set(SUPPORTED_CXX_FLAG OFF)
    else(EdalabCompiler_C_IS_ENABLED)
      set(SUPPORTED_CXX_FLAG OFF)
      set(SUPPORTED_C_FLAG ON)
    endif(EdalabCompiler_C_IS_ENABLED)

  elseif("${LANG}" STREQUAL "c_cxx")

    if(EdalabCompiler_CXX_IS_ENABLED)
      check_cxx_compiler_flag(${FLAG} SUPPORTED_CXX_FLAG)
    else(EdalabCompiler_CXX_IS_ENABLED)
      set(SUPPORTED_CXX_FLAG ON)
    endif(EdalabCompiler_CXX_IS_ENABLED)

    if(EdalabCompiler_C_IS_ENABLED)
      check_c_compiler_flag(${FLAG} SUPPORTED_C_FLAG)
    else(EdalabCompiler_C_IS_ENABLED)
      set(SUPPORTED_C_FLAG ON)
    endif(EdalabCompiler_C_IS_ENABLED)

  else()

    edalab_error_message("[EdalabCompiler] Unsupported language.")

  endif()

  if(SUPPORTED_CXX_FLAG)
    set(${CXX_SUPPORTED} ON PARENT_SCOPE)
  else(SUPPORTED_CXX_FLAG)
    set(${CXX_SUPPORTED} OFF PARENT_SCOPE)
  endif(SUPPORTED_CXX_FLAG)

  if(SUPPORTED_C_FLAG)
    set(${C_SUPPORTED} ON PARENT_SCOPE)
  else(SUPPORTED_C_FLAG)
    set(${C_SUPPORTED} OFF PARENT_SCOPE)
  endif(SUPPORTED_C_FLAG)

endfunction(_edalab_compiler_check_flag)


## @brief Given the flag kind, returns the referred language.
##
## @param FLAG_KIND {String} The flag kind.
## @param LANG {String} The resulting output language.
##
function(_edalab_compiler_get_lang FLAG_KIND LANG)
      if(("${FLAG_KIND}" STREQUAL "c_cxx_basic")
	  OR ("${FLAG_KIND}" STREQUAL "c_cxx_mem")
	  OR ("${FLAG_KIND}" STREQUAL "c_cxx_opt")
	  OR ("${FLAG_KIND}" STREQUAL "c_cxx_debug"))
    set(${LANG} "c_cxx" PARENT_SCOPE)
      elseif(("${FLAG_KIND}" STREQUAL "c_basic")
	  OR ("${FLAG_KIND}" STREQUAL "c_mem")
	  OR ("${FLAG_KIND}" STREQUAL "c_opt")
	  OR ("${FLAG_KIND}" STREQUAL "c_debug"))
    set(${LANG} "c" PARENT_SCOPE)
      elseif(("${FLAG_KIND}" STREQUAL "cxx_basic")
	  OR ("${FLAG_KIND}" STREQUAL "cxx_mem")
	  OR ("${FLAG_KIND}" STREQUAL "cxx_opt")
	  OR ("${FLAG_KIND}" STREQUAL "cxx_debug"))
    set(${LANG} "cxx" PARENT_SCOPE)
      else()
	edalab_error_message("[EdalabCompiler] Unknown flag kind (1): ${FLAG_KIND}.")
      endif()
endfunction(_edalab_compiler_get_lang )


## @brief Internal function to add a flag.
## The flag validity must have been tested yet.
##
## @param FLAG_KIND {String} The flag kind.
## @param FLAG {String} The flag to be added.
## @param LANG The language to which the flag refers to.
## @param CXX_IS_SUPPORTED {Bool} Flag supported by C++.
## @param C_IS_SUPPORTED {Bool} Flag supported by C++.
## @param MANDATORY {Bool} Flag must be valid.
##
function(_edalab_compiler_eventually_add_flag FLAG_KIND FLAG LANG CXX_IS_SUPPORTED C_IS_SUPPORTED MANDATORY)

    if(("${FLAG_KIND}" STREQUAL "c_cxx_basic")
	OR ("${FLAG_KIND}" STREQUAL "c_basic")
	OR ("${FLAG_KIND}" STREQUAL "cxx_basic"))
      set(KIND "basic")
    elseif(("${FLAG_KIND}" STREQUAL "c_cxx_mem")
	OR ("${FLAG_KIND}" STREQUAL "c_mem")
	OR ("${FLAG_KIND}" STREQUAL "cxx_mem"))
      set(KIND "mem")
    elseif(("${FLAG_KIND}" STREQUAL "c_cxx_opt")
	OR ("${FLAG_KIND}" STREQUAL "c_opt")
	OR ("${FLAG_KIND}" STREQUAL "cxx_opt"))
      set(KIND "opt")
    elseif(("${FLAG_KIND}" STREQUAL "c_cxx_debug")
	OR ("${FLAG_KIND}" STREQUAL "c_debug")
	OR ("${FLAG_KIND}" STREQUAL "cxx_debug"))
      set(KIND "debug")
    else()
      edalab_error_message("Unknown flag kind (2): ${FLAG_KIND}.")
    endif()

    if(("${LANG}" STREQUAL "c") AND C_IS_SUPPORTED)
      set(EdalabCompiler_${FLAG_KIND} "${EdalabCompiler_${FLAG_KIND}} ${FLAG}"
        CACHE INTERNAL "List of all set flags." FORCE)
    elseif(("${LANG}" STREQUAL "cxx") AND CXX_IS_SUPPORTED)
      set(EdalabCompiler_${FLAG_KIND} "${EdalabCompiler_${FLAG_KIND}} ${FLAG}"
        CACHE INTERNAL "List of all set flags." FORCE)
    elseif(("${LANG}" STREQUAL "c_cxx") AND C_IS_SUPPORTED AND CXX_IS_SUPPORTED)
      set(EdalabCompiler_${FLAG_KIND} "${EdalabCompiler_${FLAG_KIND}} ${FLAG}"
        CACHE INTERNAL "List of all set flags." FORCE)
    elseif(("${LANG}" STREQUAL "c_cxx") AND C_IS_SUPPORTED AND EdalabCompiler_C_IS_ENABLED)
      if(MANDATORY)
	edalab_error_message("[EdalabCompiler] Unsupported mandatory ${LANG} flag for C++: ${FLAG}.")
      else(MANDATORY)
	edalab_message("[EdalabCompiler] Flag supported only for C: ${FLAG}")
    set(EdalabCompiler_c_${KIND} "${EdalabCompiler_c_${KIND}} ${FLAG}"
          CACHE INTERNAL "List of all set flags." FORCE)
      endif(MANDATORY)
    elseif(("${LANG}" STREQUAL "c_cxx") AND CXX_IS_SUPPORTED AND EdalabCompiler_CXX_IS_ENABLED)
      if(MANDATORY)
	edalab_error_message("[EdalabCompiler] Unsupported mandatory ${LANG} flag for C: ${FLAG}.")
      else(MANDATORY)
	edalab_message("[EdalabCompiler] Flag supported only for C++: ${FLAG}")
    set(EdalabCompiler_cxx_${KIND} "${EdalabCompiler_cxx_${KIND}} ${FLAG}"
          CACHE INTERNAL "List of all set flags." FORCE)
      endif(MANDATORY)
    else()
      if(MANDATORY)
	edalab_error_message("[EdalabCompiler] Unsupported flag (${LANG}): ${FLAG}")
      else(MANDATORY)
	edalab_message("[EdalabCompiler] Unsupported flag (${LANG}): ${FLAG}")
      endif(MANDATORY)
    endif()
endfunction(_edalab_compiler_eventually_add_flag )


function(_edalab_compiler_remove_single_flag LISTSTRING FLAG DOC)
  string(REPLACE "${FLAG}" "" ${LISTSTRING} "${${LISTSTRING}}")
  set(${LISTSTRING} "${${LISTSTRING}}" CACHE STRING "${DOC}" FORCE)

  #message("${LISTSTRING}: ${${LISTSTRING}}")

endfunction(_edalab_compiler_remove_single_flag)

# ###########################################################################
# Configuration.
# ###########################################################################

# Setting standard vars:
set(EdalabCompiler_VERSION_MAJOR 1)
set(EdalabCompiler_VERSION_MINOR 0)
set(EdalabCompiler_VERSION_PATCH 0)
set(EdalabCompiler_VERSION_STRING "FindEdalabCompiler.cmake verison: ${EdalabCompiler_VERSION_MAJOR}.${EdalabCompiler_VERSION_MINOR}.${EdalabCompiler_VERSION_PATCH}.")

# Setting up search mode:
set(EdalabCompiler_SEARCH_MODE "")
if(EdalabCompiler_FIND_REQUIRED)
  set(EdalabCompiler_SEARCH_MODE "REQUIRED")
elseif(EdalabCompiler_FIND_QUIETLY)
  set(EdalabCompiler_SEARCH_MODE "QUIET")
endif()

# Loading dependencies:
find_package(EdalabBase "${EdalabCompiler_SEARCH_MODE}")

if(CMAKE_COMPILER_IS_GNUCC OR CMAKE_COMPILER_IS_GNUCXX)
  if(NOT EdalabGcc_INCLUDED)
    find_package(EdalabGcc ${EdalabCompiler_SEARCH_MODE})
  endif(NOT EdalabGcc_INCLUDED)
  set(EdalabCompiler_SUPPORTED EdalabGcc_FOUND)
elseif(MSVC OR MSVC_IDE OR MSVC60 OR MSVC70 OR MSVC71 OR MSVC80 OR CMAKE_COMPILER_2005 OR MSVC90)
  if(NOT EdalabVc_INCLUDED)
    find_package(EdalabVc ${EdalabCompiler_SEARCH_MODE})
  endif(NOT EdalabVc_INCLUDED)
  set(EdalabCompiler_SUPPORTED EdalabVc_FOUND)
else()
  set(EdalabCompiler_SUPPORTED OFF)
endif()

find_package_handle_standard_args(EdalabCompiler DEFAULT_MSG
  EDALABBASE_FOUND
  EdalabCompiler_SUPPORTED
)

if(EDALABBASE_FOUND)

  # Including other support packages to check active languages:
  edalab_find_package(CheckCCompilerFlag)
  edalab_find_package(CheckCXXCompilerFlag)

  find_package_handle_standard_args(EdalabCompiler DEFAULT_MSG
    CHECKCCOMPILERFLAG_FOUND
    CHECKCXXCOMPILERFLAG_FOUND
    )
endif(EDALABBASE_FOUND)


# Module configuration:
if(EDALABCOMPILER_FOUND)

  # Module initialization:
  edalab_initialize_module("EdalabCompiler" EdalabCompiler_SEARCH_MODE)

endif(EDALABCOMPILER_FOUND)

# ###########################################################################
# Functions.
# ###########################################################################

## @brief Adds the user options, with specified default values.
##
## @param C_STD {String} Can be: OFF 89 99 or 11.
## @param CXX_STD {String} Can be: OFF 98 or 11.
## @param WARNS {Bool} "Warnings as errors" default.
## @param ENUMS {Bool} "Check switch enum" default.
##
function(edalab_compiler_add_user_options C_STD CXX_STD WARNS ENUMS)

  edalab_add_combobox(COMPILER_C_STANDARD "OFF;89;99;11" "C standard. OFF 89 99 or 11." ON "All" "${C_STD}")
  edalab_add_combobox(COMPILER_CXX_STANDARD "OFF;98;11" "C++ Standard. Can be: OFF 89 99 or 11." ON "All" "${CXX_STD}")

  option(COMPILER_CHECK_SWITCH_ENUMS "Sets to perform strinct enum checks." ${ENUMS})
  option(COMPILER_DEBUG_STL "Allows debugging of STL usage." OFF)
  option(COMPILER_FATAL_ERRORS "Stops compiling at first error." OFF)
  option(COMPILER_USE_PROFILER "Adds profiling infos." OFF)
  option(COMPILER_USE_VISIBILITY "Use visibility extensions to hide non-exported symbols." ON)
  option(COMPILER_WARNINGS_AS_ERRORS "Treats warnings as errors." ${WARNS})

  mark_as_advanced(
    COMPILER_C_STANDARD
    COMPILER_CXX_STANDARD
    COMPILER_CHECK_SWITCH_ENUMS
    COMPILER_DEBUG_STL
    COMPILER_FATAL_ERRORS
    COMPILER_USE_PROFILER
    COMPILER_USE_VISIBILITY
    COMPILER_WARNINGS_AS_ERRORS
    )

endfunction(edalab_compiler_add_user_options)


## @brief Performs the flag setting.
##
function(edalab_compiler_set_flags)

  if(NOT ("${COMPILER_CHECK_SWITCH_ENUMS_OLD}" STREQUAL "${COMPILER_CHECK_SWITCH_ENUMS}"))
    set(REFRESH ON)
  elseif(NOT ("${COMPILER_DEBUG_STL_OLD}" STREQUAL "${COMPILER_DEBUG_STL}"))
    set(REFRESH ON)
  elseif(NOT ("${COMPILER_FATAL_ERRORS_OLD}" STREQUAL "${COMPILER_FATAL_ERRORS}"))
    set(REFRESH ON)
  elseif(NOT ("${COMPILER_USE_PROFILER_OLD}" STREQUAL "${COMPILER_USE_PROFILER}"))
    set(REFRESH ON)
  elseif(NOT ("${COMPILER_USE_VISIBILITY_OLD}" STREQUAL "${COMPILER_USE_VISIBILITY}"))
    set(REFRESH ON)
  elseif(NOT ("${COMPILER_WARNINGS_AS_ERRORS_OLD}" STREQUAL "${COMPILER_WARNINGS_AS_ERRORS}"))
    set(REFRESH ON)
  else()
    set(REFRESH OFF)
  endif()
  _edalab_compiler_submodule_set_refresh_flags(SUB_REFRESH)

  set(COMPILER_CHECK_SWITCH_ENUMS_OLD ${COMPILER_CHECK_SWITCH_ENUMS} CACHE INTERNAL "" FORCE)
  set(COMPILER_DEBUG_STL_OLD ${COMPILER_DEBUG_STL} CACHE INTERNAL "" FORCE)
  set(COMPILER_FATAL_ERRORS_OLD ${COMPILER_FATAL_ERRORS} CACHE INTERNAL "" FORCE)
  set(COMPILER_USE_PROFILER_OLD ${COMPILER_USE_PROFILER} CACHE INTERNAL "" FORCE)
  set(COMPILER_USE_VISIBILITY_OLD ${COMPILER_USE_VISIBILITY} CACHE INTERNAL "" FORCE)
  set(COMPILER_WARNINGS_AS_ERRORS_OLD ${COMPILER_WARNINGS_AS_ERRORS} CACHE INTERNAL "" FORCE)

  if(("${REFRESH}" STREQUAL "OFF") AND ("${SUB_REFRESH}" STREQUAL "OFF"))
    return()
  endif(("${REFRESH}" STREQUAL "OFF") AND ("${SUB_REFRESH}" STREQUAL "OFF"))

  _edalab_compiler_internal_initialization()
  _edalab_compiler_submodule_set_flags()

  #### Compiler:

  # None:
  set(CMAKE_C_FLAGS "${EdalabCompiler_c_cxx_basic} ${EdalabCompiler_c_basic}"
    CACHE STRING "C None flags.")
  set(CMAKE_CXX_FLAGS "${EdalabCompiler_c_cxx_basic} ${EdalabCompiler_cxx_basic}"
    CACHE STRING "C++ None flags.")

  # Debug:
  set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS} ${EdalabCompiler_c_cxx_debug} ${EdalabCompiler_c_debug}"
    CACHE STRING "C Debug flags.")
  set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS} ${EdalabCompiler_c_cxx_debug} ${EdalabCompiler_cxx_debug}"
    CACHE STRING "C++ Debug flags.")

  # Release:
  set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS} -DNDEBUG ${EdalabCompiler_c_cxx_opt} ${EdalabCompiler_c_opt}"
    CACHE STRING "C Release flags.")
  set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS} -DNDEBUG ${EdalabCompiler_c_cxx_opt} ${EdalabCompiler_cxx_opt}"
    CACHE STRING "C++ Release flags.")

  # RelWithDebInfo:
  set(CMAKE_C_FLAGS_RELWITHDEBINFO "${CMAKE_C_FLAGS} ${EdalabCompiler_c_cxx_debug} ${EdalabCompiler_c_debug} ${EdalabCompiler_c_cxx_opt} ${EdalabCompiler_c_opt}"
    CACHE STRING "C RelWithDebInfo flags.")
  set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "${CMAKE_CXX_FLAGS} ${EdalabCompiler_c_cxx_debug} ${EdalabCompiler_cxx_debug} ${EdalabCompiler_cxx_opt} ${EdalabCompiler_cxx_opt}"
    CACHE STRING "C++ RelWithDebInfo flags.")

  # MinSizeRel:
  set(CMAKE_C_FLAGS_MINSIZEREL "${CMAKE_C_FLAGS} -DNDEBUG ${EdalabCompiler_c_cxx_mem} ${EdalabCompiler_c_mem}"
    CACHE STRING "C MinSizeRel flags.")
  set(CMAKE_CXX_FLAGS_MINSIZEREL "${CMAKE_CXX_FLAGS} -DNDEBUG ${EdalabCompiler_c_cxx_mem} ${EdalabCompiler_cxx_mem}"
    CACHE STRING "C++ MinSizeRel flags.")

  mark_as_advanced(CMAKE_C_FLAGS CMAKE_CXX_FLAGS
    CMAKE_C_FLAGS_DEBUG CMAKE_CXX_FLAGS_DEBUG
    CMAKE_C_FLAGS_RELEASE CMAKE_CXX_FLAGS_RELEASE
    CMAKE_C_FLAGS_RELWITHDEBINFO CMAKE_CXX_FLAGS_RELWITHDEBINFO
    CMAKE_C_FLAGS_MINSIZEREL CMAKE_CXX_FLAGS_MINSIZEREL)

  #### Linker:

  set(CMAKE_EXE_LINKER_FLAGS    "${CMAKE_EXE_LINKER_FLAGS}    ${EdalabCompiler_linker_all} ${EdalabCompiler_linker_exe}" CACHE STRING "Exe flags.")
  set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} ${EdalabCompiler_linker_all} ${EdalabCompiler_linker_shared}" CACHE STRING "Shared flags.")
  set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} ${EdalabCompiler_linker_all} ${EdalabCompiler_linker_module}" CACHE STRING "Module flags.")
  set(CMAKE_STATIC_LINKER_FLAGS "${CMAKE_STATIC_LINKER_FLAGS} ${EdalabCompiler_linker_all} ${EdalabCompiler_linker_static}" CACHE STRING "Static flags.")

endfunction(edalab_compiler_set_flags)


## Adds a compiler flag. Useful for submodules.
## Possible values for FLAG_KIND are:
## - c_cxx_basic, c_cxx_mem, c_cxx_opt, c_cxx_debug.
## - c_basic, c_mem, c_opt, c_debug.
## - cxx_basic, cxx_mem, cxx_opt, cxx_debug.
##
## @param FLAG_KIND ${String} The kind of flag.
## @param FLAG {String} The string representing the flag.
## @param REQUIRED Wheter to actually add the flag.
## @param CHECK {Bool} ON if compiler support check is required.
## @param MANDATORY {Bool} ON if in case of non-supported flag, an error generation is required.
##
function(edalab_compiler_add_flag FLAG_KIND FLAG REQUIRED CHECK MANDATORY)

  if(REQUIRED)

    _edalab_compiler_get_lang("${FLAG_KIND}" LANG)

    if(CHECK)
      _edalab_compiler_check_flag("${FLAG}" "${LANG}" CXX_IS_SUPPORTED C_IS_SUPPORTED)
    else(CHECK)
      set(CXX_IS_SUPPORTED ON)
      set(C_IS_SUPPORTED ON)
    endif(CHECK)

    _edalab_compiler_eventually_add_flag("${FLAG_KIND}" "${FLAG}" "${LANG}"
      ${CXX_IS_SUPPORTED} ${C_IS_SUPPORTED} ${MANDATORY})

  endif(REQUIRED)

endfunction(edalab_compiler_add_flag)


## Adds a linker flag. Useful for submodules.
## Possible values for FLAG_KIND are:
## - all exec shared module static
##
## @param FLAG_KIND ${String} The kind of flag.
## @param FLAG {String} The string representing the flag.
## @param REQUIRED Wheter to actually add the flag.
## @param CHECK {Bool} ON if compiler support check is required.
## @param MANDATORY {Bool} ON if in case of non-supported flag, an error generation is required.
##
function(edalab_compiler_add_linker_flag FLAG_KIND FLAG REQUIRED CHECK MANDATORY)

  if(NOT
      (("${FLAG_KIND}" STREQUAL "all")
        OR ("${FLAG_KIND}" STREQUAL "shared")
        OR ("${FLAG_KIND}" STREQUAL "module")
        OR ("${FLAG_KIND}" STREQUAL "static")
        OR ("${FLAG_KIND}" STREQUAL "exe"))
      )
    edalab_error_message("Unknown flag kind: ${FLAG_KIND}.")
  endif()

  if(REQUIRED)
    if(CHECK)
      _edalab_compiler_check_flag("${FLAG}" "c_cxx" CXX_IS_SUPPORTED C_IS_SUPPORTED)
    else(CHECK)
      set(C_IS_SUPPORTED ON)
      set(CXX_IS_SUPPORTED ON)
    endif(CHECK)

    if(MANDATORY AND ((NOT C_IS_SUPPORTED) OR (NOT CXX_IS_SUPPORTED)))
      edalab_error_message("Unsupported mandatory ${LANG} flag: ${FLAG}.")
    endif(MANDATORY AND ((NOT C_IS_SUPPORTED) OR (NOT CXX_IS_SUPPORTED)))

    if(C_IS_SUPPORTED AND CXX_IS_SUPPORTED)
      set(EdalabCompiler_linker_${FLAG_KIND} "${EdalabCompiler_linker_${FLAG_KIND}} ${FLAG}"
        CACHE INTERNAL "List of all linker set flags." FORCE)
    endif(C_IS_SUPPORTED AND CXX_IS_SUPPORTED)
  endif(REQUIRED)

endfunction(edalab_compiler_add_linker_flag)

function(edalab_compiler_remove_linker_flag FLAG_KIND FLAG)
	  if(NOT
      (("${FLAG_KIND}" STREQUAL "all")
        OR ("${FLAG_KIND}" STREQUAL "shared")
        OR ("${FLAG_KIND}" STREQUAL "module")
        OR ("${FLAG_KIND}" STREQUAL "static")
        OR ("${FLAG_KIND}" STREQUAL "exe"))
      )
    edalab_error_message("Unknown flag kind: ${FLAG_KIND}.")
  endif()

  _edalab_compiler_remove_single_flag(
    EdalabCompiler_linker_${FLAG_KIND} "${FLAG}" "")

  _edalab_compiler_remove_single_flag(
    ORIGINAL_CMAKE_EXE_LINKER_FLAGS "${FLAG}" "")
  _edalab_compiler_remove_single_flag(
    ORIGINAL_CMAKE_SHARED_LINKER_FLAGS "${FLAG}" "")
  _edalab_compiler_remove_single_flag(
    ORIGINAL_CMAKE_MODULE_LINKER_FLAGS "${FLAG}" "")
  _edalab_compiler_remove_single_flag(
    ORIGINAL_CMAKE_STATIC_LINKER_FLAGS "${FLAG}" "")

  set(ORIGINAL_CMAKE_EXE_LINKER_FLAGS
    "${ORIGINAL_CMAKE_EXE_LINKER_FLAGS}" CACHE INTERNAl "" FORCE)
  set(ORIGINAL_CMAKE_SHARED_LINKER_FLAGS
    "${ORIGINAL_CMAKE_SHARED_LINKER_FLAGS}" CACHE INTERNAl "" FORCE)
  set(ORIGINAL_CMAKE_MODULE_LINKER_FLAGS
    "${ORIGINAL_CMAKE_MODULE_LINKER_FLAGS}" CACHE INTERNAl "" FORCE)
  set(ORIGINAL_CMAKE_STATIC_LINKER_FLAGS
    "${ORIGINAL_CMAKE_STATIC_LINKER_FLAGS}" CACHE INTERNAl "" FORCE)

  _edalab_compiler_remove_single_flag(
    CMAKE_EXE_LINKER_FLAGS_DEBUG "${FLAG}" "")
  _edalab_compiler_remove_single_flag(
    CMAKE_EXE_LINKER_FLAGS_MINSIZEREL "${FLAG}" "")
  _edalab_compiler_remove_single_flag(
    CMAKE_EXE_LINKER_FLAGS_RELEASE "${FLAG}" "")
  _edalab_compiler_remove_single_flag(
    CMAKE_EXE_LINKER_FLAGS_RELWITHDEBINFO "${FLAG}" "")

  _edalab_compiler_remove_single_flag(
    CMAKE_MODULE_LINKER_FLAGS_DEBUG "${FLAG}" "")
  _edalab_compiler_remove_single_flag(
    CMAKE_MODULE_LINKER_FLAGS_MINSIZEREL "${FLAG}" "")
  _edalab_compiler_remove_single_flag(
    CMAKE_MODULE_LINKER_FLAGS_RELEASE "${FLAG}" "")
  _edalab_compiler_remove_single_flag(
    CMAKE_MODULE_LINKER_FLAGS_RELWITHDEBINFO "${FLAG}" "")

  _edalab_compiler_remove_single_flag(
    CMAKE_SHARED_LINKER_FLAGS_DEBUG "${FLAG}" "")
  _edalab_compiler_remove_single_flag(
    CMAKE_SHARED_LINKER_FLAGS_MINSIZEREL "${FLAG}" "")
  _edalab_compiler_remove_single_flag(
    CMAKE_SHARED_LINKER_FLAGS_RELEASE "${FLAG}" "")
  _edalab_compiler_remove_single_flag(
    CMAKE_SHARED_LINKER_FLAGS_RELWITHDEBINFO "${FLAG}" "")

  _edalab_compiler_remove_single_flag(
    CMAKE_STATIC_LINKER_FLAGS_DEBUG "${FLAG}" "")
  _edalab_compiler_remove_single_flag(
    CMAKE_STATIC_LINKER_FLAGS_MINSIZEREL "${FLAG}" "")
  _edalab_compiler_remove_single_flag(
    CMAKE_STATIC_LINKER_FLAGS_RELEASE "${FLAG}" "")
  _edalab_compiler_remove_single_flag(
    CMAKE_STATIC_LINKER_FLAGS_RELWITHDEBINFO "${FLAG}" "")

endfunction(edalab_compiler_remove_linker_flag)


## @brief Adds a list fo flags for a list of targets.
##
## SYNOPSYS:
## <list of targets> COMPILE_FLAGS <FLAGS>
##
function(edalab_compiler_set_target_flags)
  set(IS_FLAG OFF)
  foreach(e ${ARGN})
    if("${e}" STREQUAL "COMPILE_FLAGS")
      set(IS_FLAG ON)
    elseif(${IS_FLAG})
      set(OPTIONS ${OPTIONS} ${e})
    else()
      set(TGT ${TGT} ${e})
    endif()
  endforeach(e )
  if("${CMAKE_VERSION}" VERSION_LESS "2.8.12")
    set_target_properties(${TGT} PROPERTIES COMPILE_FLAGS ${OPTIONS})
  else("${CMAKE_VERSION}" VERSION_LESS "2.8.12")
    foreach(e ${TGT})
      target_compile_options(${e} PUBLIC ${OPTIONS})
    endforeach(e )
  endif("${CMAKE_VERSION}" VERSION_LESS "2.8.12")
endfunction(edalab_compiler_set_target_flags)

# EOF
