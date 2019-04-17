# - EDALab utility to set up targets.
# Some provided functions do not follow usual conventions, to resamble more strictly CMake standard commands.
# For example, instead of edalab_target_add_library(), it is preferred edalab_add_library().
#
# Provided configuration options:
#
# Provided user options:
#
# Provided functions:
#   edalab_install_docs()
#   edalab_install_libraries()
#   edalab_install_targets()
#   edalab_install_headers()
#   edalab_install_etc_files()
#   edalab_install_configured_script()
#   edalab_add_library()
#   edalab_tag2version()
#   edalab_add_rc_file()

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


# ###########################################################################
# Configuration.
# ###########################################################################

# Setting standard vars:
set(EdalabTargets_VERSION_MAJOR 1)
set(EdalabTargets_VERSION_MINOR 0)
set(EdalabTargets_VERSION_PATCH 0)
set(EdalabTargets_VERSION_STRING "FindEdalabTarget.cmake verison: ${EdalabTarget_VERSION_MAJOR}.${EdalabTarget_VERSION_MINOR}.${EdalabTarget_VERSION_PATCH}.")

# Setting up search mode:
set(EdalabTargets_SEARCH_MODE "")
if(EdalabTargets_FIND_REQUIRED)
  set(EdalabTargets_SEARCH_MODE "REQUIRED")
elseif(EdalabTargets_FIND_QUIETLY)
  set(EdalabTargets_SEARCH_MODE "QUIET")
endif()

# Loading dependencies:
find_package(EdalabBase ${EdalabTarget_SEARCH_MODE})
find_package_handle_standard_args(EdalabTargets DEFAULT_MSG EDALABBASE_FOUND)

# Module configuration:
if(EDALABTARGETS_FOUND)

  # Module initialization:
  edalab_initialize_module("EdalabTargets" "${EdalabTargets_SEARCH_MODE}")

endif(EDALABTARGETS_FOUND)


# ###########################################################################
# Support functions.
# ###########################################################################


function(_edalab_install_file_dir_docs COMPONENT)
  foreach(cur ${ARGN})
    if(IS_DIRECTORY ${cur})
      install(DIRECTORY ${cur}
        DESTINATION doc
        COMPONENT ${COMPONENT}
        )
    elseif(EXISTS ${cur})
      # File:
      install(FILES ${cur}
        DESTINATION doc
        COMPONENT ${COMPONENT}
        )
    else()
      # A generated target: assuming file:
      install(FILES ${cur}
        OPTIONAL
        DESTINATION doc
        COMPONENT ${COMPONENT}
        )
    endif()
  endforeach(cur)
endfunction(_edalab_install_file_dir_docs)


# ###########################################################################
# Functions.
# ###########################################################################

## @brief Adds documentation targets, files and dirs.
## Diresctories will be added with all their sub-directories.
##
## @param COMPONENT The component name.
## @optional {List} The documentation targets, files and dirs.
##
function(edalab_install_docs COMPONENT)
  foreach(cur ${ARGN})
    if(TARGET ${cur})
      get_target_property(target_type ${cur} TYPE)
      if("${target_type}" STREQUAL "UTILITY")
        # Target generated via add_custom_target().
        get_target_property(target_name ${cur} OUTPUT_NAME)
        _edalab_install_file_dir_docs(${COMPONENT} ${target_name})
      else("${target_type}" STREQUAL "UTILITY")
        install(TARGETS ${cur}
          EXPORT ${CMAKE_PROJECT_NAME}_TARGETS
          DESTINATION doc
          COMPONENT ${COMPONENT}
          )
      endif("${target_type}" STREQUAL "UTILITY")
    else()
      _edalab_install_file_dir_docs(${COMPONENT} ${cur})
    endif()
  endforeach(cur)
endfunction(edalab_install_docs)


## @brief Installs a list of binary targets.
##
## @param COMPONENT THe component name.
## @optional {List} The list of targets to be installed.
##
function(edalab_install_targets COMPONENT)
  # Searching for optional:
  set(IS_OPTIONAL )
  foreach(i ${ARGN})
    if("${i}" STREQUAL "OPTIONAL")
      set(IS_OPTIONAL "OPTIONAL")
    endif("${i}" STREQUAL "OPTIONAL")
  endforeach(i)

  foreach(i ${ARGN})
    if("${i}" STREQUAL "OPTIONAL")
      # skip
    else("${i}" STREQUAL "OPTIONAL")
      # For MinGW: forcing installing of .dll.a:
      if(EXISTS "${i}.a")
        edalab_install_libraries("${COMPONENT}" "${i}")
      endif(EXISTS "${i}.a")
      get_target_property(TMP ${i} TYPE)
      # Forcing under Windows to install DLL import part into same DLL dir,
      # and static lib under lib dir:
      if("${TMP}" STREQUAL "SHARED_LIBRARY")
        install(TARGETS ${i}
          ${IS_OPTIONAL}
          EXPORT ${CMAKE_PROJECT_NAME}_TARGETS
          RUNTIME DESTINATION bin
          LIBRARY DESTINATION lib
          ARCHIVE DESTINATION bin
          FRAMEWORK DESTINATION bin
          DESTINATION error_tgt_shared
          COMPONENT ${COMPONENT}
          )
      elseif("${TMP}" STREQUAL "STATIC_LIBRARY")
        install(TARGETS ${i}
          ${IS_OPTIONAL}
          EXPORT ${CMAKE_PROJECT_NAME}_TARGETS
          RUNTIME DESTINATION bin
          LIBRARY DESTINATION lib
          ARCHIVE DESTINATION lib
          FRAMEWORK DESTINATION lib
          DESTINATION error_tgt_static
          COMPONENT ${COMPONENT}
          )
      elseif("${TMP}" STREQUAL "EXECUTABLE")
        install(TARGETS ${i}
          ${IS_OPTIONAL}
          EXPORT ${CMAKE_PROJECT_NAME}_TARGETS
          RUNTIME DESTINATION bin
          LIBRARY DESTINATION lib
          ARCHIVE DESTINATION lib
          DESTINATION error_target_exe
          COMPONENT ${COMPONENT}
          )
      else()
        edalab_error_message("[EdalabTargets] Unsupported install type: ${TMP}.")
      endif()
    endif("${i}" STREQUAL "OPTIONAL")
  endforeach(i )
endfunction(edalab_install_targets)


## @brief Adds librareis to be installed.
## This is especially useful to install third-party DLL's.
##
## @param COMPONENT The component name.
## @optional {List} The libraries.
##
function(edalab_install_libraries COMPONENT)
  foreach(cur ${ARGN})
    if(TARGET ${cur})
      edalab_install_targets(${COMPONENT} ${cur})
    elseif(EXISTS ${cur})
      if("${CMAKE_SYSTEM_NAME}" STREQUAL "Windows")
        set(REG ".*\\.dll")
        set(DST "bin")
      else("${CMAKE_SYSTEM_NAME}" STREQUAL "Windows")
        set(REG ".*\\.so")
        set(DST "lib")
      endif ("${CMAKE_SYSTEM_NAME}" STREQUAL "Windows")
      string(REGEX MATCH ${REG} OUT "${cur}")
      if(NOT ("${OUT}" STREQUAL ""))
	# Shared lib: must be installed!
	install(PROGRAMS ${cur} DESTINATION ${DST}
          COMPONENT ${COMPONENT}
	  )
      endif(NOT ("${OUT}" STREQUAL ""))
    else()
      edalab_message_error("Unexpected library to be installed: ${cur}")
    endif()
  endforeach(cur)
endfunction(edalab_install_libraries)


## @brief Installs a list of header targets, dirs or files.
##
## @param COMPONENT The component name.
## @optional {List} The list of headers to be installed.
##
function(edalab_install_headers COMPONENT)
  foreach(cur ${ARGN})
    if(TARGET ${cur})
      install(TARGETS ${cur}
        EXPORT ${CMAKE_PROJECT_NAME}_TARGETS
        DESTINATION include
        COMPONENT ${COMPONENT}
        )
    elseif(IS_DIRECTORY "${cur}")
      install(DIRECTORY "${cur}"
        DESTINATION .
        COMPONENT ${COMPONENT}
        FILES_MATCHING
        PATTERN "*.h"
        PATTERN "*.hh"
        PATTERN "*.hpp"
        PATTERN "*.hxx"
        PATTERN "*.H"
        PATTERN "*.HH"
        PATTERN "*.i"
        PATTERN "*.ii"
        PATTERN ".svn" EXCLUDE
        )
    elseif(EXISTS "${cur}")
      # File:
      install(FILES ${cur}
        DESTINATION include
        COMPONENT ${COMPONENT}
        )
    else()
      edalab_error_message("[EdalabTargets] Unexpected header component: ${cur}.")
    endif()
  endforeach(cur )
endfunction(edalab_install_headers)


## @brief Installs a configured scripts.
##
## @param FULL_IN {File} The input file.
## @param OUT {File} The output file.
## @param THIS_INSTALL_DIR {Directory} The destination directory.
##
function(edalab_install_configured_script FULL_IN OUT THIS_INSTALL_DIR )
  configure_file(${FULL_IN} ${CMAKE_CURRENT_BINARY_DIR}/${OUT} @ONLY)
  install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${OUT}
    DESTINATION ${THIS_INSTALL_DIR}
    PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_EXECUTE GROUP_READ WORLD_EXECUTE WORLD_READ
    )
endfunction(edalab_install_configured_script)


## @brief Installs a list of etc targets, dirs or files.
##
## @param COMPONENT The component name.
## @optional {List} The list of etc files to be installed.
##
function(edalab_install_etc_files COMPONENT)
  foreach(cur ${ARGN})
    if(TARGET ${cur})
      install(TARGETS ${cur}
        EXPORT ${CMAKE_PROJECT_NAME}_TARGETS
        DESTINATION etc
        COMPONENT ${COMPONENT}
        )
    elseif(IS_DIRECTORY "${cur}")
      install(DIRECTORY "${cur}"
        DESTINATION etc
        COMPONENT ${COMPONENT}
        FILES_MATCHING
        PATTERN "*"
        PATTERN ".svn" EXCLUDE
        )
    elseif(EXISTS "${cur}")
      # File:
      install(FILES ${cur}
        DESTINATION etc
        COMPONENT ${COMPONENT}
        )
    else()
      edalab_error_message("[EdalabTargets] Unexpected etc component: ${cur}.")
    endif()
  endforeach(cur )
endfunction(edalab_install_etc_files)

## @brief Adds the building of a library.
## By default compiles both static and shared versions.
## The static library target will have a "_static" suffix.
## The shared libs are compiled by defining the flag -DCOMPILE_<NAME>_LIBRARY (all in uppercase).
## No definitions are added for static libraries.
##
## @param NAME {String} The name of the target.
## @others The usual add_library() parameters.
##
function(edalab_add_library NAME)

  # Checking for library type specifiers:
  list(FIND ARGN "MODULE" MODULE)
  list(FIND ARGN "SHARED" SHARED)
  list(FIND ARGN "STATIC" STATIC)
  list(REMOVE_ITEM ARGN "MODULE" "SHARED" "STATIC")
  # Setting specifiers to ON, if none is set, otherwise setting them according with the user parameters:
  if(("${MODULE}" STREQUAL "-1") AND ("${SHARED}" STREQUAL "-1") AND ("${STATIC}" STREQUAL "-1"))
    set(MODULE ON)
    set(SHARED ON)
    set(STATIC ON)
  else(("${MODULE}" STREQUAL "-1") AND ("${SHARED}" STREQUAL "-1") AND ("${STATIC}" STREQUAL "-1"))
    if("${MODULE}" STREQUAL "-1")
      set(MODULE OFF)
    else("${MODULE}" STREQUAL "-1")
      set(MODULE ON)
    endif("${MODULE}" STREQUAL "-1")
    if("${SHARED}" STREQUAL "-1")
      set(SHARED OFF)
    else("${SHARED}" STREQUAL "-1")
      set(SHARED ON)
    endif("${SHARED}" STREQUAL "-1")
    if("${STATIC}" STREQUAL "-1")
      set(STATIC OFF)
    else("${STATIC}" STREQUAL "-1")
      set(STATIC ON)
    endif("${STATIC}" STREQUAL "-1")
  endif(("${MODULE}" STREQUAL "-1") AND ("${SHARED}" STREQUAL "-1") AND ("${STATIC}" STREQUAL "-1"))

  string(TOUPPER "${NAME}" UPPERNAME)

  # Adding libs:

  # Adding shared lib:
  if(SHARED)
    add_library(${NAME} SHARED ${ARGN})
    set_target_properties(${NAME} PROPERTIES COMPILE_DEFINITIONS ${COMPILE_DEFINITIONS}
      COMPILE_${UPPERNAME}_LIB=1)
  endif(SHARED)

  # Adding static lib:
  if(STATIC)
    add_library(${NAME}_static STATIC ${ARGN})
    set_target_properties(${NAME}_static PROPERTIES OUTPUT_NAME "${NAME}")
    set_target_properties(${NAME}_static PROPERTIES ARCHIVE_OUTPUT_DIRECTORY "${NAME}_static")
    if("${CMAKE_SYSTEM_NAME}" STREQUAL "Linux")
      set_target_properties(${NAME}_static PROPERTIES PREFIX "lib")
    endif("${CMAKE_SYSTEM_NAME}" STREQUAL "Linux")
  endif(STATIC)

  # For the moment, ignoring the MODULE directive.

endfunction(edalab_add_library )

## @brief Adds the building of an executable.
## Params are the same of cmake command "add_executable".
##
## @param NAME {String} The name of the target.
## @others The usual add_executable() parameters.
##
function(edalab_add_executable NAME)
  add_executable(${NAME} ${ARGN})
  edalab_is_module_loaded(RES "EdalabGcc")
  if(${RES})
    edalab_gcc_set_exe_flags(${NAME})
  endif(${RES})
endfunction(edalab_add_executable)


## @brief Translates a tag to a binary version.
## The input tag must be of four dots, and only with letters
## a, b, c, i, r.
##
## @param OUT The output variable.
## @param TAG {String} The input tag.
##
function(edalab_tag2version OUT TAG)
  # As convention: stable is four zeros:
  string(REPLACE "stable" "0.0.0.0" AAA "${TAG}")
  # Always trunkating the name. E.g. 2014.12.0-crux --> 2014.12.0
  string(REGEX REPLACE "-.*" ".0" AAA "${AAA}")
  # Dots are not allowed, commas are used instead:
  string(REPLACE "." "," AAA "${AAA}")

  string(REPLACE "A" "65"  AAA "${AAA}")
  string(REPLACE "B" "66"  AAA "${AAA}")
  string(REPLACE "C" "67"  AAA "${AAA}")
  string(REPLACE "D" "68"  AAA "${AAA}")
  string(REPLACE "E" "69"  AAA "${AAA}")
  string(REPLACE "F" "70"  AAA "${AAA}")
  string(REPLACE "G" "71"  AAA "${AAA}")
  string(REPLACE "H" "72"  AAA "${AAA}")
  string(REPLACE "I" "73"  AAA "${AAA}")
  string(REPLACE "J" "74"  AAA "${AAA}")
  string(REPLACE "K" "75"  AAA "${AAA}")
  string(REPLACE "L" "76"  AAA "${AAA}")
  string(REPLACE "M" "77"  AAA "${AAA}")
  string(REPLACE "N" "78"  AAA "${AAA}")
  string(REPLACE "O" "79"  AAA "${AAA}")
  string(REPLACE "P" "80"  AAA "${AAA}")
  string(REPLACE "Q" "81"  AAA "${AAA}")
  string(REPLACE "R" "82"  AAA "${AAA}")
  string(REPLACE "S" "83"  AAA "${AAA}")
  string(REPLACE "T" "84"  AAA "${AAA}")
  string(REPLACE "U" "85"  AAA "${AAA}")
  string(REPLACE "V" "86"  AAA "${AAA}")
  string(REPLACE "W" "87"  AAA "${AAA}")
  string(REPLACE "X" "88"  AAA "${AAA}")
  string(REPLACE "Y" "89"  AAA "${AAA}")
  string(REPLACE "Z" "90"  AAA "${AAA}")

  string(REPLACE "a" "97"  AAA "${AAA}")
  string(REPLACE "b" "98"  AAA "${AAA}")
  string(REPLACE "c" "99"  AAA "${AAA}")
  string(REPLACE "d" "100"  AAA "${AAA}")
  string(REPLACE "e" "101"  AAA "${AAA}")
  string(REPLACE "f" "102"  AAA "${AAA}")
  string(REPLACE "g" "103"  AAA "${AAA}")
  string(REPLACE "h" "104"  AAA "${AAA}")
  string(REPLACE "i" "105" AAA "${AAA}")
  string(REPLACE "j" "106" AAA "${AAA}")
  string(REPLACE "k" "107" AAA "${AAA}")
  string(REPLACE "l" "108" AAA "${AAA}")
  string(REPLACE "m" "109" AAA "${AAA}")
  string(REPLACE "n" "110" AAA "${AAA}")
  string(REPLACE "o" "111" AAA "${AAA}")
  string(REPLACE "p" "112" AAA "${AAA}")
  string(REPLACE "q" "113" AAA "${AAA}")
  string(REPLACE "r" "114" AAA "${AAA}")
  string(REPLACE "s" "115" AAA "${AAA}")
  string(REPLACE "t" "116" AAA "${AAA}")
  string(REPLACE "u" "117" AAA "${AAA}")
  string(REPLACE "v" "118" AAA "${AAA}")
  string(REPLACE "w" "119" AAA "${AAA}")
  string(REPLACE "x" "120" AAA "${AAA}")
  string(REPLACE "y" "121" AAA "${AAA}")
  string(REPLACE "z" "122" AAA "${AAA}")

  set(${OUT} "${AAA}" PARENT_SCOPE)
endfunction(edalab_tag2version )


## @brief Adds a resource file.
## The input tag must be of four dots, and only with letters
## a, b, c, i, r.
##
## @param OUT The output variable.
## @param FULL_IN Full path to input resource file.
## @param FileDescription The brief description. E.g. hif2sc.
## @param InternalName The internal name of the project. E.g. HIFSuite.
## @param OriginalFileName The original file name. E.g. hif2sc.
## @param ProductName The product name. E.g. hif2sc.
## @param ProductVersion The product tag. E.g. 2013.3.4.a
##
function(edalab_add_rc_file OUT FULL_IN
    FileDescription InternalName OriginalFileName ProductName ProductVersion)

  edalab_tag2version(BinaryFileVersion "${ProductVersion}")

  configure_file("${FULL_IN}" "${CMAKE_CURRENT_BINARY_DIR}/resource.rc" @ONLY)

  if("${CMAKE_SYSTEM_NAME}" STREQUAL "Windows")
    enable_language(RC)
    set(${OUT} "${CMAKE_CURRENT_BINARY_DIR}/resource.rc" PARENT_SCOPE)
  else("${CMAKE_SYSTEM_NAME}" STREQUAL "Windows")
    set(${OUT} "" PARENT_SCOPE)
  endif("${CMAKE_SYSTEM_NAME}" STREQUAL "Windows")
endfunction(edalab_add_rc_file )

# EOF
