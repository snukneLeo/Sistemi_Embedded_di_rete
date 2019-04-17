# - EDALab base utility for easy writing of CMake modules.
#
# Global variables:
#   EDALAB_SYSTEM_NAME: CMAKE_SYSTEM_NAME lowercase
#   EDALAB_SYSTEM_PROCESSOR: usually x86.
#   EDALAB_SYSTEM_WIDTH: 32, 64, etc.
#   EDALAB_SYSTEM_DIR: ${EDALAB_SYSTEMPROCESSOR}_${EDALAB_SYSTEM_WIDTH}
#   EDALAB_TAG default: stable
#
# Functions:
#   -- Message functions:
#   edalab_message()
#   edalab_error_message()
#   edalab_warning_message()
#   edalab_unique_warning_message()
#   edalab_print_dependency_variables()
#   -- Menu functions:
#   edalab_reset_option()
#   edalab_add_combobox()
#   edalab_add_radiobutton()
#   -- Variable functions:
#   edalab_reset_variable() -- Macro
#   edalab_set_once() -- Macro
#   edalab_get_filename_component()
#   edalab_manage_notfound() -- Macro
#   edalab_assure_vars()
#   edalab_parse_option()
#   edalab_parse_bool_option()
#   -- Module functions:
#   edalab_initialize_module()
#   edalab_is_module_loaded()
#   edalab_check_target_exists()
#   edalab_add_updatable_target()
#   edalab_add_cmake_update_scripts()
#   edalab_add_third_party_update_packages()
#   edalab_find_package()
#   edalab_find_path()
#   edalab_find_library()
#   edalab_find_program()
#   edalab_get_library_vars()
#   edalab_setup_standard_variables()
#   edalab_setup_package_libraries()
#   edalab_global_setup()
#
# Internal functions:
#   _edalab_initialize_global_properties()
#   _edalab_support_copy_package()
#===============================================================================
# Copyright 2012 EDALab s.r.l.
#
# Distributed under the OSI-approved BSD License (the "License");
# see accompanying file Copyright.txt for details.
# This software is distributed WITHOUT ANY WARRANTY; without even the
# implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the License for more information.
#
# @author Francesco Stefanni <francesco.stefanni@edalab.it>
#===============================================================================


# ##############################################################################
# User options.
# ##############################################################################

# ##############################################################################
# Configuration.
# ##############################################################################


set(EdalabBase_VERSION_MAJOR 2)
set(EdalabBase_VERSION_MINOR 0)
set(EdalabBase_VERSION_PATCH 0)
set(EdalabBase_VERSION_STRING "FindEdalabBase.cmake verison: "
  "${EdalabBase_VERSION_MAJOR}.${EdalabBase_VERSION_MINOR}.${EdalabBase_VERSION_PATCH}.")

# Setting policies:
if(POLICY CMP0054)
  cmake_policy(SET CMP0054 NEW)
endif(POLICY CMP0054)

# ##############################################################################
# Support functions.
# ##############################################################################

function(_edalab_support_copy_package CMD PACKAGE PLATFORM ARCH)
  set(SRC "${PROJECT_SOURCE_DIR}/../../third_party/sandbox/${PACKAGE}/${PLATFORM}/${ARCH}.tar.bz2")
  set(DST "${PROJECT_SOURCE_DIR}/third_party/${PACKAGE}/${PLATFORM}/")
  if(EXISTS "${SRC}")
    if(NOT (EXISTS "${DST}"))
      set(CMD_A COMMAND ${CMAKE_COMMAND} -E make_directory ${DST})
    endif(NOT (EXISTS "${DST}"))
    set(CMD_B COMMAND ${CMAKE_COMMAND} -E copy ${SRC} ${DST})
  endif(EXISTS "${SRC}")
  set(${CMD} ${CMD_A} ${CMD_B} PARENT_SCOPE)
endfunction(_edalab_support_copy_package)

# ##############################################################################
# Message functions.
# ##############################################################################

## @brief Prints an error message and exits.
##
## @others {String} The messages to be printed.
##
function(edalab_error_message)
  message(FATAL_ERROR "-- ERROR: " ${ARGN})
endfunction(edalab_error_message)


## @brief Prints a warning message.
##
## @others {String} The messages to be printed.
##
function(edalab_warning_message)
  message(WARNING "-- WARNING: " ${ARGN})
endfunction(edalab_warning_message)


## @brief Prints a unique warning message.
##
## @others {String} The messages to be printed.
##
function(edalab_unique_warning_message)
  set(MY_LIST ${EDALAB_BASE_UNIQUE_WARNING})
  list(FIND MY_LIST "${ARGV0}" RES)
  if("${RES}" STREQUAL "-1")
    message(WARNING "-- WARNING: " ${ARGN})
    list(APPEND MY_LIST "${ARGV0}")
    set(EDALAB_BASE_UNIQUE_WARNING ${MY_LIST}
      CACHE INTERNAL "EdalabBase var for unique warning printing." FORCE)
  endif("${RES}" STREQUAL "-1")
endfunction(edalab_unique_warning_message)

## @brief Prints an info.
##
## @others {String} The messages to be printed.
##
function(edalab_message)
  message("-- INFO: " ${ARGN})
endfunction(edalab_message)


## @brief Prints the standard variables for a given package name.
##
## @param NAME {String}: the name of the package.
##
function(edalab_print_dependency_variables NAME)
  message("${NAME}_INCLUDES:\n${${NAME}_INCLUDE_DIRS}\n\n")
  message("${NAME}_LIBRARIES:\n${${NAME}_LIBRARIES}\n\n")
  message("${NAME}_LIBRARY_DIRS:\n${${NAME}_LIBRARY_DIRS}\n\n")
  message("${NAME}_DEFINITIONS:\n${${NAME}_DEFINITIONS}\n\n")
  message("${NAME}_RUNTIME_LIBRARIES:\n${${NAME}_RUNTIME_LIBRARIES}\n\n")
  message("${NAME}_LINKED_STATIC_LIBRARIES:\n${${NAME}_LINKED_STATIC_LIBRARIES}\n\n")
  message("${NAME}_RUNTIME_DIRS:\n${${NAME}_RUNTIME_DIRS}\n\n")
endfunction(edalab_print_dependency_variables)

# ##############################################################################
# Menu functions
# ##############################################################################

## @brief Resets the given options.
##
## @param OPTION {Variable} The option name.
## @param DESCRIPTION {String} The option description.
## @param VALUE {Bool} The new option value.
## @param ADVANCED {Bool} If it is advanced.
##
function(edalab_reset_option OPTION DESCRIPTION VALUE ADVANCED)
  unset(${OPTION} CACHE)
  option(${OPTION} "${DESCRIPTION}" ${VALUE})
  if(ADVANCED)
    mark_as_advanced(${OPTION})
  endif(ADVANCED)
endfunction(edalab_reset_option)


## @brief Adds a user option, whose allowed values are taken from a list.
## It also assures a non-empty value.
##
## @param OPTION_NAME The option name.
## @param VALUES {List} List of allowed values.
## @param DESCRIPTION {String} The description.
## @param ADVANCED {Bool} ON if option is advanced.
## @optional <PLATFORM> DEFAULT_VALUE {String} A platform and the default value for it. Can be "All".
##
function(edalab_add_combobox OPTION_NAME VALUES DESCRIPTION ADVANCED)

  # Assuring a non-empty value:
  if("${${OPTION_NAME}}" STREQUAL "")
    unset(${OPTION_NAME} CACHE)
  endif("${${OPTION_NAME}}" STREQUAL "")

  # Parsing:
  set(PLATFORM "")
  foreach(i ${ARGN})
    if("${PLATFORM}" STREQUAL "")
      # Setting the platform:
      set(PLATFORM "${i}")
    else("${PLATFORM}" STREQUAL "")
      # Setting the option:
      if("${PLATFORM}" STREQUAL "All")
        set(${OPTION_NAME} "${i}" CACHE STRING "${DESCRIPTION}")
      elseif("${PLATFORM}" STREQUAL "${CMAKE_SYSTEM_NAME}")
        set(${OPTION_NAME} "${i}" CACHE STRING "${DESCRIPTION}")
      elseif(
          ("${PLATFORM}" STREQUAL "Linux")
          OR ("${PLATFORM}" STREQUAL "Windows"))
        # Other valid platforms, but not the current! Do nothing.
      else()
        edalab_error_message("Unsupported platform: ${PLATFORM}")
      endif()
      set(PLATFORM "")
    endif("${PLATFORM}" STREQUAL "")
  endforeach(i)

  if(ADVANCED)
    mark_as_advanced(${OPTION_NAME})
  endif(ADVANCED)

  # Sanity checks:
  # - Correct function call:
  if(NOT ("${PLATFORM}" STREQUAL ""))
    edalab_error_message("Incorrect arguments passed to function: ${PLATFORM}.")
  endif(NOT ("${PLATFORM}" STREQUAL ""))
  # - Correct value set by the user:
  list(FIND VALUES "${${OPTION_NAME}}" IS_OK)
  if("${IS_OK}" STREQUAL "-1")
    edalab_error_message("Incorrect value for option ${OPTION_NAME}: ${${OPTION_NAME}}")
  endif("${IS_OK}" STREQUAL "-1")

endfunction(edalab_add_combobox)


## @brief Adds a choice between exclusive boolean options.
## The GROUP_NAME variable must be unique.
##
## @param {Variable} GROUP_NAME The output variable where to store the name of
##     the option that is active.
## @param {Variable} DEFAULT_OPTION The default active option name.
## @param ADVANCED {Bool} True if options are advanced.
## @param DESCRIPTION {String} The description to be associated to each option.
## @optional {List} List of option variables.
##
function(edalab_add_radiobutton GROUP_NAME DEFAULT_OPTION ADVANCED DESCRIPTION)

  # Adding all options:
  foreach(i ${ARGN})
    if("${i}" STREQUAL "${DEFAULT_OPTION}")
      option(${i} "${DESCRIPTION}" ON)
    else("${i}" STREQUAL "${DEFAULT_OPTION}")
      option(${i} "${DESCRIPTION}" OFF)
    endif("${i}" STREQUAL "${DEFAULT_OPTION}")
    if(ADVANCED)
      mark_as_advanced(${i})
    endif(ADVANCED)
  endforeach(i)

  # Radiobutton behavior: only one active at a time.
  # - Setting OFF the last active:
  if(${GROUP_NAME})
    edalab_reset_option(${${GROUP_NAME}} "${DESCRIPTION}" OFF ${ADVANCED})
  endif(${GROUP_NAME})
  # - Checking which is active:
  foreach(i ${ARGN})
    if(${i})
      if(LAST)
        set(TOO_MANY ON)
        edalab_reset_option(${i} "${DESCRIPTION}" OFF ${ADVANCED})
      else(LAST)
        set(LAST ON)
        set(LAST_VAL ${i})
      endif(LAST)
    endif(${i})
  endforeach(i)
  # - Assuring the default in case of error:
  if(TOO_MANY)
    edalab_reset_option(${LAST_VAL} "${DESCRIPTION}" OFF ${ADVANCED})
    edalab_reset_option(${DEFAULT_OPTION} "${DESCRIPTION}" ON ${ADVANCED})
    unset(${GROUP_NAME} CACHE)
    set(${GROUP_NAME} ${DEFAULT_OPTION} CACHE INTERNAL "Used to store the last active value." FORCE)
  elseif(LAST)
    unset(${GROUP_NAME} CACHE)
    set(${GROUP_NAME} ${LAST_VAL} CACHE INTERNAL "Used to store the last active value." FORCE)
  else()
    edalab_reset_option(${DEFAULT_OPTION} "${DESCRIPTION}" ON ${ADVANCED})
    unset(${GROUP_NAME} CACHE)
    set(${GROUP_NAME} ${DEFAULT_OPTION} CACHE INTERNAL "Used to store the last active value." FORCE)
  endif()

endfunction(edalab_add_radiobutton)



# ##############################################################################
# Variable functions
# ##############################################################################


## @brief Completely removes a variable from the current scope and form the cache.
##
## @param The variable to remove.
macro(edalab_reset_variable VAR)
  unset(${VAR})
  unset(${VAR} CACHE)
endmacro(edalab_reset_variable VAR)


## @brief Sets the value, just once.
##
## @param VAR The variable.
## @param VALUE Its value.
## @param TYPE Its type, as in set() command.
## @param DOCSTRING Its doc string, as in set().
## @param ADVANCED {Bool} True if must be marked as advanced.
##
macro(edalab_set_once VAR VALUE TYPE DOCSTRING ADVANCED)
  if("${${VAR}_edalab_once}" STREQUAL "")
    set("${VAR}_edalab_once" ON CACHE INTERNAL "Once mechanism for ${VAR}" FORCE)
    edalab_reset_variable(${VAR})
    set("${VAR}" "${VALUE}" CACHE "${TYPE}" "${DOCSTRING}")
    if(${ADVANCED})
      mark_as_advanced("${VAR}")
    endif(${ADVANCED})
  endif("${${VAR}_edalab_once}" STREQUAL "")
endmacro(edalab_set_once)

## @brief Wrapper for get_filename_component() for cmake compatiblity.
##
## @param OUT The output var.
## @param DIR The path to be analyzed.
## @param WHAT The component.
##
function(edalab_get_filename_component OUT DIR WHAT)
  if(("${WHAT}" STREQUAL "PATH") OR ("${WHAT}" STREQUAL "DIRECTORY"))
    if("${CMAKE_VERSION}" VERSION_LESS "2.8.12")
      get_filename_component(TMP "${DIR}" PATH)
    else("${CMAKE_VERSION}" VERSION_LESS "2.8.12")
      get_filename_component(TMP "${DIR}" DIRECTORY)
    endif("${CMAKE_VERSION}" VERSION_LESS "2.8.12")
  else(("${WHAT}" STREQUAL "PATH") OR ("${WHAT}" STREQUAL "DIRECTORY"))
      get_filename_component(TMP "${DIR}" ${WHAT})
  endif(("${WHAT}" STREQUAL "PATH") OR ("${WHAT}" STREQUAL "DIRECTORY"))
  set(${OUT} "${TMP}" PARENT_SCOPE)
endfunction(edalab_get_filename_component)

## @brief Sets the GLOBAL_OUT var to the content of LOCAL_OUT, or to GLOBAL_OUT-NOTFOUND.
##
## @param GLOBAL_OUT {Variable} The output variable.
## @param LOCAL_OUT {Variable} The inputput variable.
## @param CLEAR {Bool} ON if the local variable must be completely erased.
##
macro(edalab_manage_notfound GLOBAL_OUT LOCAL_OUT CLEAR)
  if(NOT ${LOCAL_OUT})
    set(${${GLOBAL_OUT}} "${${GLOBAL_OUT}}-NOTFOUND" PARENT_SCOPE)
  else(NOT ${LOCAL_OUT})
    set(${${GLOBAL_OUT}} ${${LOCAL_OUT}} PARENT_SCOPE)
  endif(NOT ${LOCAL_OUT})
  if(${CLEAR})
    unset(${LOCAL_OUT})
    unset(${LOCAL_OUT} CACHE)
  endif(${CLEAR})
endmacro(edalab_manage_notfound)

## @brief Assures given variables are not -NOTFOUND.
##
## @others The variables.
##
function(edalab_assure_vars )
  foreach(VAR ${ARGN})
    if(NOT(${VAR}))
      edalab_error_message("[EdalabBase] Variable \"${VAR}\" not found: \"${${VAR}}\"")
    endif(NOT(${VAR}))
  endforeach(VAR )
endfunction(edalab_assure_vars)

## @brief This functions searches and stores in OUT the value of option tag.
## Useful to parse options of functions.
##
## @param OUT {String}: the output value.
## @param OPTION_TAG {String}: the tag to be searched.
## @param OTHERS {StringList}: the other values.
## @param DEFAULT {String}: default value when option is not found.
## @others The list to be parsed.
##
function(edalab_parse_option OUT OPTION_TAG OTHERS DEFAULT)
  set(FOUND OFF)
  set(LST )
  set(${OUT} "${DEFAULT}" PARENT_SCOPE)
  foreach(v ${ARGN})
    if(FOUND)
      set(OUT "${v}" PARENT_SCOPE)
      set(FOUND OFF)
    elseif("${OPTION_TAG}" STREQUAL "${v}")
      set(FOUND ON)
    else()
      set(LST ${LST} ${v})
    endif()
  endforeach(v)
  set(${OTHERS} ${LST} PARENT_SCOPE)
endfunction(edalab_parse_option)

## @brief This functions searches and stores in OUT ON or OFF, whether the tag is found.
## Useful to parse options of functions.
##
## @param OUT {String}: the output value.
## @param OPTION_TAG {String}: the tag to be searched.
## @param OTHERS {StringList}: the other values.
## @param DEFAULT {String}: default value when option is not found.
## @others The list to be parsed.
##
function(edalab_parse_bool_option OUT OPTION_TAG OTHERS DEFAULT)
  set(LST )
  set(${OUT} "${DEFAULT}" PARENT_SCOPE)
  foreach(v ${ARGN})
    if("${OPTION_TAG}" STREQUAL "${v}")
      set(${OUT} "ON" PARENT_SCOPE)
    else()
      set(LST ${LST} ${v})
    endif()
  endforeach(v)
  set(${OTHERS} ${LST} PARENT_SCOPE)
endfunction(edalab_parse_bool_option)


# ###########################################################################
# Module functions.
# ###########################################################################

## @brief Standard initializations for each module.
##
## @param NAME {String} The module name.
## @param SEARCH_MODE {String} Module search mode.
##
function(edalab_initialize_module NAME SEARCH_MODE)
  set(EdalabBase_LOADED_MODULES ${EdalabBase_LOADED_MODULES} ${NAME})
  list(REMOVE_DUPLICATES EdalabBase_LOADED_MODULES)
  set(EdalabBase_LOADED_MODULES ${EdalabBase_LOADED_MODULES} CACHE INTERNAL "Loaded EDALab modules." FORCE)
endfunction(edalab_initialize_module)

## @brief Check whether a edalab module is loaded.
##
## @param OUT {Bool} The result.
## @param NAME {String} The module name.
##
function(edalab_is_module_loaded OUT NAME)
  list(FIND EdalabBase_LOADED_MODULES "${NAME}" TMP)
  if("${TMP}" STREQUAL "-1")
    set(${OUT} OFF PARENT_SCOPE)
  else("${TMP}" STREQUAL "-1")
    set(${OUT} ON PARENT_SCOPE)
  endif("${TMP}" STREQUAL "-1")
endfunction(edalab_is_module_loaded)


## @brief Check whether a target exists.
##
## @param {VarName} OUT THe result variable.
## @param {Name} TARGET The target to be checked.
##
function(edalab_check_target_exists OUT TARGET)
  if(POLICY CMP0045)
    cmake_policy(SET CMP0045 OLD)
    get_target_property(CHK ${TARGET} TYPE)
    cmake_policy(SET CMP0045 NEW)
  else(POLICY CMP0045)
    get_target_property(CHK ${TARGET} TYPE)
  endif(POLICY CMP0045)
  set(${OUT} ${CHK} PARENT_SCOPE)
endfunction(edalab_check_target_exists)

## @brief Adds a custom target whose executed commands can be added at different times.
##
## @param {Name} TARGET The target.
## @param {String} START_MSG The message to be print at beginning.
## @param {String} END_MSG The message to be print at ending.
##
function(edalab_add_updatable_target TARGET START_MSG END_MSG)
  edalab_check_target_exists(CHK ${TARGET})
  if(CHK)
    return()
  endif(CHK)
  add_custom_target(${TARGET}_start
    COMMAND ${CMAKE_COMMAND} -E echo "${START_MSG}"
  )
  add_custom_target(${TARGET}
    COMMAND ${CMAKE_COMMAND} -E echo "${END_MSG}"
  )
  add_dependencies(${TARGET} ${TARGET}_start)
  set_target_properties(${TARGET} PROPERTIES "edalab_counter" "0")
endfunction(edalab_add_updatable_target)

## @brief Adds some commands to an updatable custom target.
function(edalab_update_target TARGET)
  get_target_property(COUNTER ${TARGET} "edalab_counter")
  set_target_properties(${TARGET} PROPERTIES "edalab_counter" "0${COUNTER}")
  add_custom_target(${TARGET}_${COUNTER}
    ${ARGN}
  )
  add_dependencies(${TARGET} ${TARGET}_${COUNTER})
  add_dependencies(${TARGET}_${COUNTER} ${TARGET}_start)
endfunction(edalab_update_target)

## @brief Function used to simplify updating of duplicated scripts.
##
## @others {String} List of names of CMake scripts.
##
function(edalab_add_cmake_update_scripts)
  foreach(f ${ARGN})
    set(CMD COMMAND ${CMAKE_COMMAND} -E copy ${PROJECT_SOURCE_DIR}/../../build_utils/sandbox/scripts/${f} ${PROJECT_SOURCE_DIR}/scripts)
    set(CMD_LIST ${CMD_LIST} ${CMD})
  endforeach(f)

  edalab_add_updatable_target(update_cmake_scripts "Updating CMake scripts..." "Updating CMake scripts done.")
  edalab_update_target(update_cmake_scripts ${CMD_LIST})
endfunction(edalab_add_cmake_update_scripts)

## @brief Function used to simplify updating of duplicated third_party packages.
##
## @others {String} List of names of third_party packages.
##
function(edalab_add_third_party_update_packages)
  foreach(f ${ARGN})
    # Linux
    _edalab_support_copy_package(CMD_L64 ${f} Linux x86_64)
    _edalab_support_copy_package(CMD_L32 ${f} Linux x86_32)
    # Windows
    _edalab_support_copy_package(CMD_W64 ${f} Windows x86_64)
    _edalab_support_copy_package(CMD_W32 ${f} Windows x86_32)
    # Setting:
    set(CMD_LIST ${CMD_LIST} ${CMD_L64} ${CMD_L32} ${CMD_W64} ${CMD_W32})
  endforeach(f)

  edalab_add_updatable_target(update_third_party_packages
    "Updating third_party packages..." "Updating third_party packages done.")
  edalab_update_target(update_third_party_packages ${CMD_LIST})
endfunction(edalab_add_third_party_update_packages)


## @brief Finds a package, as the standard CMake find_package() command.
## In the parent scope sets <NAME>_FOUND.
## It also handles some standard FindXXX modules, which do not set the XXX_FOUND
## variable by themselves, by setting it.
## Finally, it also supports include() of non-Find modules.
##
## @param NAME {Name} The name of the package to be included.
## @others {StringList} The eventual optional parameters, as in standard find_package() command.
##
macro(edalab_find_package NAME)
  string(TOUPPER "${NAME}" UPPER_NAME)

  # Try search as Find module
  find_package(${NAME} ${ARGN} QUIET)

  # Try search as include package
  if(NOT ${UPPER_NAME}_FOUND)
    include(${NAME} OPTIONAL RESULT_VARIABLE ${UPPER_NAME}_FOUND)
  endif(NOT ${UPPER_NAME}_FOUND)

  # Special cases for packages without _FOUND var, and forcing error!
  if("${NAME}" STREQUAL "PackageHandleStandardArgs")
     find_package(${NAME} ${ARGN} REQUIRED)
     set(${UPPER_NAME}_FOUND ON PARENT_SCOPE)
  elseif("${NAME}" STREQUAL "CheckCCompilerFlag")
     mark_as_advanced(CheckCCompilerFlag_DIR)
  elseif("${NAME}" STREQUAL "CheckCXXCompilerFlag")
     mark_as_advanced(CheckCXXCompilerFlag_DIR)
  endif()


endmacro(edalab_find_package)


## @brief Searches for a file, also in Edalab standard paths.
##
## The PART_OF arguments is set by default when it is the empty string.
## Otherwise, it can be useful to find libraries of bigger projects.
## For example, to find a library named PocoXML.h, of the project Poco, it is possible to pass "Poco" as PART_OF.
##
## @param OUT {String} The eventually found path.
## @param FILENAME {String} The name of the file. E.g. "PocoXML"
## @param PART_OF {String} The name of the eventual project of the lib. E.g. "Poco".
## @others {Strings} Eventual HINTS for find_path().
##
function(edalab_find_path OUT FILENAME PART_OF)
  set(SRC_INSTALL_DIR "${PROJECT_SOURCE_DIR}/../../${FILENAME}/sandbox/obj_${EDALAB_SYSTEM_NAME}_${EDALAB_SYSTEM_WIDTH}/${PART_OF}-${EDALAB_TAG}-${EDALAB_SYSTEM_NAME}-${EDALAB_SYSTEM_DIR}")

  find_path(
    MYOUT
    NAMES ${FILENAME} ${FILENAME}.hh ${FILENAME}.h
    HINTS
    # User hints:
    ${ARGN}
    # Third party:
    "${PROJECT_SOURCE_DIR}/third_party/${PART_OF}/${CMAKE_SYSTEM_NAME}/${EDALAB_SYSTEM_DIR}"
    "${PROJECT_SOURCE_DIR}/../../third_party/sandbox/${PART_OF}/${CMAKE_SYSTEM_NAME}/${EDALAB_SYSTEM_DIR}"
    # Sources:
    "${SRC_INSTALL_DIR}"
    # Inside install dir:
    "${CMAKE_INSTALL_PREFIX}"
    PATH_SUFFIXES include "include/${PART_OF}"
  )

  edalab_manage_notfound(OUT MYOUT ON)
endfunction(edalab_find_path )



## @brief Searches for a program, also in Edalab standard paths.
##
## The PART_OF arguments is set by default when it is the empty string.
## Otherwise, it can be useful to find libraries of bigger projects.
## For example, to find a library named PocoXML.h, of the project Poco, it is possible to pass "Poco" as PART_OF.
##
## @param OUT {String} The eventually found executable.
## @param FILENAME {String} The name of the file. E.g. "a2tool"
## @param PART_OF {String} The name of the eventual project of the lib. E.g. "hifsuite".
## @others {Strings} Eventual HINTS for find_executable().
##
function(edalab_find_program OUT FILENAME PART_OF)
  set(SRC_INSTALL_DIR "${PROJECT_SOURCE_DIR}/../../${FILENAME}/sandbox/obj_${EDALAB_SYSTEM_NAME}_${EDALAB_SYSTEM_WIDTH}/${PART_OF}-${EDALAB_TAG}-${EDALAB_SYSTEM_NAME}-${EDALAB_SYSTEM_DIR}")

  find_program(
    MYOUT
    NAMES ${FILENAME} ${FILENAME}.exe
    HINTS
    # User hints:
    ${ARGN}
    # Third party:
    "${PROJECT_SOURCE_DIR}/third_party/${PART_OF}/${CMAKE_SYSTEM_NAME}/${EDALAB_SYSTEM_DIR}"
    "${PROJECT_SOURCE_DIR}/../../third_party/sandbox/${PART_OF}/${CMAKE_SYSTEM_NAME}/${EDALAB_SYSTEM_DIR}"
    # Sources:
    "${SRC_INSTALL_DIR}"
    # Inside install dir:
    "${CMAKE_INSTALL_PREFIX}"
    PATH_SUFFIXES bin "bin/${PART_OF}"
  )

  edalab_manage_notfound(OUT MYOUT ON)
endfunction(edalab_find_program )

## @brief Searches for a of library, also in Edalab standard paths.
##
## The PART_OF arguments is set by default when it is the empty string.
## Otherwise, it can be useful to find libraries of bigger projects.
## For example, to find a library named PocoXML, of the project Poco, it is possible to pass "Poco" as PART_OF.
##
## @param OUT {String} The eventually found library.
## @param LIBNAME {String} The name of the library.
## @param KIND {String} The preferred kind of the library: ANY, SHARED, STATIC, SHARED_ONLY, STATIC_ONLY.
## @param PART_OF {String} The name of the eventual project of the lib. E.g. "Poco".
## @others {Strings} Eventual HINTS for find_library().
##
function(edalab_find_library OUT LIBNAME KIND PART_OF)

  # Managing the KIND parameter:
  set(RESTORE_SUFFIX ${CMAKE_FIND_LIBRARY_SUFFIXES})
  if(("${CMAKE_SYSTEM_NAME}" STREQUAL "Windows") AND ("${CMAKE_HOST_SYSTEM_NAME}" STREQUAL "Linux"))
    # MinGW cross-compiling
    if("${KIND}" STREQUAL "ANY")
      # Leave the defaults.
    elseif("${KIND}" STREQUAL "SHARED")
      set(CMAKE_FIND_LIBRARY_SUFFIXES .dll .a)
    elseif("${KIND}" STREQUAL "STATIC")
      set(CMAKE_FIND_LIBRARY_SUFFIXES .a .dll)
    elseif("${KIND}" STREQUAL "SHARED_ONLY")
      set(CMAKE_FIND_LIBRARY_SUFFIXES .dll)
    elseif("${KIND}" STREQUAL "STATIC_ONLY")
      set(CMAKE_FIND_LIBRARY_SUFFIXES .a)
    else()
      # ERROR: wrong parameter!
      edalab_error_message("Wrong KIND parameter: ${KIND}")
    endif()
  elseif("${CMAKE_SYSTEM_NAME}" STREQUAL "Linux")
    # Linux:
    if("${KIND}" STREQUAL "ANY")
      # Leave the defaults.
    elseif("${KIND}" STREQUAL "SHARED")
      set(CMAKE_FIND_LIBRARY_SUFFIXES .so .a)
    elseif("${KIND}" STREQUAL "STATIC")
      set(CMAKE_FIND_LIBRARY_SUFFIXES .a .so)
    elseif("${KIND}" STREQUAL "SHARED_ONLY")
      set(CMAKE_FIND_LIBRARY_SUFFIXES .so)
    elseif("${KIND}" STREQUAL "STATIC_ONLY")
      set(CMAKE_FIND_LIBRARY_SUFFIXES .a)
    else()
      # ERROR: wrong parameter!
      edalab_error_message("Wrong KIND parameter: ${KIND}")
    endif()
  elseif("${CMAKE_SYSTEM_NAME}" STREQUAL "Windows")
    # Windows VC++:
    if("${KIND}" STREQUAL "ANY")
      set(CMAKE_FIND_LIBRARY_SUFFIXES .dll .lib)
    elseif("${KIND}" STREQUAL "SHARED")
      set(CMAKE_FIND_LIBRARY_SUFFIXES .dll .lib)
    elseif("${KIND}" STREQUAL "STATIC")
      set(CMAKE_FIND_LIBRARY_SUFFIXES .lib .dll)
    elseif("${KIND}" STREQUAL "SHARED_ONLY")
      set(CMAKE_FIND_LIBRARY_SUFFIXES .dll)
    elseif("${KIND}" STREQUAL "STATIC_ONLY")
      set(CMAKE_FIND_LIBRARY_SUFFIXES .lib)
    else()
      # ERROR: wrong parameter!
      edalab_error_message("Wrong KIND parameter: ${KIND}")
    endif()
  else()
      edalab_error_message("Unsupported platform: ${CMAKE_SYSTEM_NAME}")
  endif()

  set(SRC_INSTALL_DIR "${PROJECT_SOURCE_DIR}/../../${LIBNAME}/sandbox/obj_${EDALAB_SYSTEM_NAME}_${EDALAB_SYSTEM_WIDTH}/${PART_OF}-${EDALAB_TAG}-${EDALAB_SYSTEM_NAME}-${EDALAB_SYSTEM_DIR}")

  # Searching:
  find_library(
    MYOUT
    NAMES ${LIBNAME}
    HINTS
    # User hints:
    ${ARGN}
    # Third party:
    "${PROJECT_SOURCE_DIR}/third_party/${PART_OF}/${CMAKE_SYSTEM_NAME}/${EDALAB_SYSTEM_DIR}"
    "${PROJECT_SOURCE_DIR}/../../third_party/sandbox/${PART_OF}/${CMAKE_SYSTEM_NAME}/${EDALAB_SYSTEM_DIR}"
    # Sources:
    "${SRC_INSTALL_DIR}"
    # Inside install dir:
    "${CMAKE_INSTALL_PREFIX}"
    PATH_SUFFIXES bin lib
    )

  # Managing the KIND parameter:
  set(CMAKE_FIND_LIBRARY_SUFFIXES ${RESTORE_SUFFIX})

  # Finalizing the search:
  edalab_manage_notfound(OUT MYOUT ON)

endfunction(edalab_find_library )

## @brief Checks if library is shared, and returns the link-time name and the run-time name.
##
## @param LIB The input lib name.
## @param LINK The link-time name.
## @param RUNTIME The run-time name.
## @param PATH Paths to link static libs.
## @param STATIC The library, when it is static.
## @param RPATH The paths for shared libs at runtime.
##
function(edalab_get_library_vars LIB LINK RUNTIME PATH STATIC RPATH)
  if("${LIB}" STREQUAL "")
    set(${LINK} "" PARENT_SCOPE)
    set(${RUNTIME} "" PARENT_SCOPE)
    set(${PATH} "" PARENT_SCOPE)
    set(${STATIC} "" PARENT_SCOPE)
    set(${RPATH} "" PARENT_SCOPE)
    return()
  endif("${LIB}" STREQUAL "")

  if(("${CMAKE_SYSTEM_NAME}" STREQUAL "Windows") AND ("${CMAKE_HOST_SYSTEM_NAME}" STREQUAL "Windows"))
    set(EXT ".*\\.dll$")
    set(M "\\.dll$")
    set(R ".lib")
  elseif(("${CMAKE_SYSTEM_NAME}" STREQUAL "Windows") AND ("${CMAKE_HOST_SYSTEM_NAME}" STREQUAL "Linux"))
    set(EXT ".*\\.dll$")
    set(M "\\.dll$")
    set(R ".dll.a")
  elseif("${CMAKE_SYSTEM_NAME}" STREQUAL "Linux")
    set(EXT ".*\\.so$")
    set(M "\\.so$")
    set(R ".so")
  else()
    edalab_error_message("[EdalabBase] OS not supported.")
  endif()

  string(REGEX MATCH ${EXT} IS_SHARED "${LIB}")
  unset(TMP_D)
  edalab_get_filename_component(TMP_D "${LIB}" PATH)

  if("${IS_SHARED}" STREQUAL "")
    # Static lib:
    unset(TMP_L)
    edalab_get_filename_component(TMP_L "${LIB}" NAME)
    set(${LINK} "${TMP_L}" PARENT_SCOPE)
    set(${RUNTIME} "" PARENT_SCOPE)
    set(${PATH} "${TMP_D}" PARENT_SCOPE)
    set(${STATIC} "${TMP_L}" PARENT_SCOPE)
    set(${RPATH} "" PARENT_SCOPE)
  else("${IS_SHARED}" STREQUAL "")
    # Shared lib:
    string(REGEX REPLACE ${M} ${R} L "${LIB}")
    if(EXISTS "${L}")
      set(${LINK} "${L}" PARENT_SCOPE)
    else(EXISTS "${L}")
      set(${LINK} "${LIB}" PARENT_SCOPE)
    endif(EXISTS "${L}")
    set(${RUNTIME} "${LIB}" PARENT_SCOPE)
    set(${PATH} "" PARENT_SCOPE)
    set(${STATIC} "" PARENT_SCOPE)
    set(${RPATH} "${TMP_D}" PARENT_SCOPE)
  endif("${IS_SHARED}" STREQUAL "")
endfunction(edalab_get_library_vars )

## @brief Sets up standard variables: <COMPONENT>_INCLUDE_DIRS, <COMPONENT>_LIBRARIES,
## <COMPONENT>_LIBRARY_DIRS, <COMPONENT>_RUNTIME_LIBRARIES, <COMPONENT>_DEFINITIONS, <COMPONENT>_LINKED_STATIC_LIBRARIES,.
## <COMPONENT>_RUNTIME_DIRS.
##
## @warning Assumes standard names of available variables.
## @param COMPONENT {String}: The component.
## @param LIBS {VarList}: The component libs.
## @param SRC_MODE {Bool}: True if setup as source COMPONENT to compile, false if setup as binary to be linked by third parties.
## @other {List}: List of libraries on which this COMPONENT depends.
##
function(edalab_setup_standard_variables COMPONENT LIBS SRC_MODE)
  edalab_get_library_vars("${${COMPONENT}}" C_L C_R C_D C_S C_RP)
  set(_INCLUDE_DIRS      ${${COMPONENT}_H})
  set(_LIBRARIES         ${C_L})
  set(_RUNTIME_LIBRARIES ${C_R})
  set(_LIBRARY_DIRS      ${C_D})
  if(${SRC_MODE})
    set(_DEFINITIONS )
  elseif("${C_S}" STREQUAL "")
    string(TOUPPER ${COMPONENT} CUPPER)
    set(_DEFINITIONS -DUSE_${CUPPER}_LIB)
  endif()
  set(_LINKED_STATIC_LIBRARIES)
  set(_RUNTIME_DIRS ${C_RP})

  foreach(LIB ${LIBS})
    # Managing current component:
    set(_INCLUDE_DIRS      ${_INCLUDE_DIRS} ${${LIB}_H})
    if(NOT ${SRC_MODE})
      edalab_get_library_vars("${${LIB}}" ${LIB}_L ${LIB}_R ${LIB}_D ${LIB}_S ${LIB}_RP)
      set(_LIBRARIES         ${_LIBRARIES} ${${LIB}_L})
      set(_LIBRARY_DIRS      ${_LIBRARY_DIRS}      ${${LIB}_D})
      set(_RUNTIME_LIBRARIES ${_RUNTIME_LIBRARIES} ${${LIB}_R})
      #set(_LINKED_STATIC_LIBRARIES ${_LINKED_STATIC_LIBRARIES} ${${LIB}_S} ${${LIB}_LINKED_STATIC_LIBRARIES})
      if("${${LIB}_S}" STREQUAL "")
        string(TOUPPER ${LIB} LIBUPPER)
        set(_DEFINITIONS     ${_DEFINITIONS} -DUSE_${LIBUPPER}_LIB)
      endif("${${LIB}_S}" STREQUAL "")
      set(_RUNTIME_DIRS ${_RUNTIME_DIRS} ${${LIB}_RP})
    endif(NOT ${SRC_MODE})
  endforeach(LIB ${LIBS})

  # Managing dependencies:
  foreach(d ${ARGN})
    set(_INCLUDE_DIRS            ${_INCLUDE_DIRS}            ${${d}_INCLUDE_DIRS})
    if (${SRC_MODE})
      set(_LIBRARIES               ${_LIBRARIES}               ${${d}_LIBRARIES})
    endif (${SRC_MODE})
    set(_LIBRARY_DIRS            ${_LIBRARY_DIRS}            ${${d}_LIBRARY_DIRS})
    set(_RUNTIME_LIBRARIES       ${_RUNTIME_LIBRARIES}       ${${d}_RUNTIME_LIBRARIES})
    set(_DEFINITIONS             ${_DEFINITIONS}             ${${d}_DEFINITIONS})
    set(_RUNTIME_DIRS            ${_RUNTIME_DIRS}            ${${d}_RUNTIME_DIRS})
    #set(_LINKED_STATIC_LIBRARIES ${_LINKED_STATIC_LIBRARIES} ${${d}_LINKED_STATIC_LIBRARIES})
    if(NOT ${SRC_MODE})
      foreach(L ${${d}_LIBRARIES})
        edalab_get_library_vars("${L}" L_L L_R L_D L_S L_RP)
        #set(_LINKED_STATIC_LIBRARIES ${_LINKED_STATIC_LIBRARIES} ${L_S})
        set(_RUNTIME_DIRS ${_RUNTIME_DIRS} ${L_RP})
      endforeach(L)
    endif(NOT ${SRC_MODE})
  endforeach(d )

  if(_INCLUDE_DIRS)
    list(REMOVE_DUPLICATES _INCLUDE_DIRS)
  endif(_INCLUDE_DIRS)
  if(_LIBRARY_DIRS)
    list(REMOVE_DUPLICATES _LIBRARY_DIRS)
  endif(_LIBRARY_DIRS)
  if(_RUNTIME_LIBRARIES)
    list(REMOVE_DUPLICATES _RUNTIME_LIBRARIES)
  endif(_RUNTIME_LIBRARIES)
  if(_DEFINITIONS)
    list(REMOVE_DUPLICATES _DEFINITIONS)
  endif(_DEFINITIONS)
  if(_LINKED_STATIC_LIBRARIES)
    list(REMOVE_DUPLICATES _LINKED_STATIC_LIBRARIES)
  endif(_LINKED_STATIC_LIBRARIES)
  if(_RUNTIME_DIRS)
    list(REMOVE_DUPLICATES _RUNTIME_DIRS)
  endif(_RUNTIME_DIRS)

  if(_LIBRARIES)
    list(REVERSE _LIBRARIES)
    list(REMOVE_DUPLICATES _LIBRARIES)
    if(_LINKED_STATIC_LIBRARIES)
      list(REMOVE_ITEM _LIBRARIES ${_LINKED_STATIC_LIBRARIES})
    endif(_LINKED_STATIC_LIBRARIES)
    list(REVERSE _LIBRARIES)
  endif(_LIBRARIES)

  # Exporting to parent:
  set(${COMPONENT}_INCLUDE_DIRS            ${_INCLUDE_DIRS}            PARENT_SCOPE)
  set(${COMPONENT}_LIBRARIES               ${_LIBRARIES}               PARENT_SCOPE)
  set(${COMPONENT}_LIBRARY_DIRS            ${_LIBRARY_DIRS}            PARENT_SCOPE)
  set(${COMPONENT}_RUNTIME_LIBRARIES       ${_RUNTIME_LIBRARIES}       PARENT_SCOPE)
  set(${COMPONENT}_DEFINITIONS             ${_DEFINITIONS}             PARENT_SCOPE)
  set(${COMPONENT}_LINKED_STATIC_LIBRARIES ${_LINKED_STATIC_LIBRARIES} PARENT_SCOPE)
  set(${COMPONENT}_RUNTIME_DIRS            ${_RUNTIME_DIRS}            PARENT_SCOPE)
endfunction(edalab_setup_standard_variables )

macro(edalab_export_standard_variables COMPONENT)
  # Exporting to parent:
  set(${COMPONENT}_INCLUDE_DIRS            ${${COMPONENT}_INCLUDE_DIRS}            PARENT_SCOPE)
  set(${COMPONENT}_LIBRARIES               ${${COMPONENT}_LIBRARIES}               PARENT_SCOPE)
  set(${COMPONENT}_LIBRARY_DIRS            ${${COMPONENT}_LIBRARY_DIRS}            PARENT_SCOPE)
  set(${COMPONENT}_RUNTIME_LIBRARIES       ${${COMPONENT}_RUNTIME_LIBRARIES}       PARENT_SCOPE)
  set(${COMPONENT}_DEFINITIONS             ${${COMPONENT}_DEFINITIONS}             PARENT_SCOPE)
  set(${COMPONENT}_LINKED_STATIC_LIBRARIES ${${COMPONENT}_LINKED_STATIC_LIBRARIES} PARENT_SCOPE)
  set(${COMPONENT}_RUNTIME_DIRS            ${${COMPONENT}_RUNTIME_DIRS}            PARENT_SCOPE)
endmacro(edalab_export_standard_variables )

## @brief Composes standard variables of libs.
##
## @param NAME THis libraries package name.
## @others The libs.
##
function(edalab_setup_package_libraries NAME)
  foreach(VAR ${ARGN})
    set(_INCLUDE_DIRS            ${_INCLUDE_DIRS}            ${${VAR}_INCLUDE_DIRS}           )
    set(_LIBRARIES               ${_LIBRARIES}               ${${VAR}_LIBRARIES}              )
    set(_LIBRARY_DIRS            ${_LIBRARY_DIRS}            ${${VAR}_LIBRARY_DIRS}           )
    set(_RUNTIME_LIBRARIES       ${_RUNTIME_LIBRARIES}       ${${VAR}_RUNTIME_LIBRARIES}      )
    set(_DEFINITIONS             ${_DEFINITIONS}             ${${VAR}_DEFINITIONS}            )
    set(_LINKED_STATIC_LIBRARIES ${_LINKED_STATIC_LIBRARIES} ${${VAR}_LINKED_STATIC_LIBRARIES})
    set(_RUNTIME_DIRS            ${_RUNTIME_DIRS}            ${${VAR}_RUNTIME_DIRS}           )
  endforeach(VAR )

  if(_INCLUDE_DIRS)
    list(REMOVE_DUPLICATES _INCLUDE_DIRS)
  endif(_INCLUDE_DIRS)
  if(_LIBRARY_DIRS)
    list(REMOVE_DUPLICATES _LIBRARY_DIRS)
  endif(_LIBRARY_DIRS)
  if(_RUNTIME_LIBRARIES)
    list(REMOVE_DUPLICATES _RUNTIME_LIBRARIES)
  endif(_RUNTIME_LIBRARIES)
  if(_DEFINITIONS)
    list(REMOVE_DUPLICATES _DEFINITIONS)
  endif(_DEFINITIONS)
  if(_LINKED_STATIC_LIBRARIES)
    list(REMOVE_DUPLICATES _LINKED_STATIC_LIBRARIES)
  endif(_LINKED_STATIC_LIBRARIES)
  if(_RUNTIME_DIRS)
    list(REMOVE_DUPLICATES _RUNTIME_DIRS)
  endif(_RUNTIME_DIRS)

  if(_LIBRARIES)
    list(REVERSE _LIBRARIES)
    list(REMOVE_DUPLICATES _LIBRARIES)
    list(REVERSE _LIBRARIES)
  endif(_LIBRARIES)

  set(${NAME}_INCLUDE_DIRS            ${_INCLUDE_DIRS}            PARENT_SCOPE)
  set(${NAME}_LIBRARIES               ${_LIBRARIES}               PARENT_SCOPE)
  set(${NAME}_LIBRARY_DIRS            ${_LIBRARY_DIRS}            PARENT_SCOPE)
  set(${NAME}_RUNTIME_LIBRARIES       ${_RUNTIME_LIBRARIES}       PARENT_SCOPE)
  set(${NAME}_DEFINITIONS             ${_DEFINITIONS}             PARENT_SCOPE)
  set(${NAME}_LINKED_STATIC_LIBRARIES ${_LINKED_STATIC_LIBRARIES} PARENT_SCOPE)
  set(${NAME}_RUNTIME_DIRS            ${_RUNTIME_DIRS}            PARENT_SCOPE)
endfunction(edalab_setup_package_libraries)


## @brief Sets up the global configuration to compile a component.
##
## @param NAME {String} The component.
##
macro(edalab_global_setup NAME)
  include_directories(SYSTEM ${${NAME}_INCLUDE_DIRS})
  link_libraries(${${NAME}_LIBRARIES})
  link_directories(${${NAME}_LIBRARY_DIRS})
  add_definitions(${${NAME}_DEFINITIONS})
endmacro(edalab_global_setup NAME)


# ###########################################################################
# Internal functions.
# ###########################################################################

## @brief Performs some basic global initializations.
## Currently it does the following actions:
## - Checks the cmake version.
## - Loads standard basic modules.
## - Assures the doc target.
## - Marks as advanced or hides some standard variables.
## - Moves some standard vars to advanced or to internal (e.g. CMAKE_INSTALL_PREFIX as advanced).
## - Sets some architecture infos (EDALAB_SYSTEM_NAME, EDALAB_SYSTEM_PROCESSOR, EDALAB_SYSTEM_WIDTH).
## - Assures default build type.
## - Sets some policies
##
## @private
##
function(_edalab_initialize_global_properties)

  # Checking cmake version:
  cmake_minimum_required(VERSION 2.8.11)
  # Fixing support cmake files.
  #if(CMAKE_VERSION VERSION_LESS "3.2.2")
  #  set(CMAKE_MODULE_PATH
  #    ${CMAKE_MODULE_PATH}
  #    "${PROJECT_SOURCE_DIR}/cmake_fix_support")
  #endif(CMAKE_VERSION VERSION_LESS "3.2.2")

  # Loading required standard support modules:
  find_package(PackageHandleStandardArgs REQUIRED)

  # This module standard variables managing:
  set(FAKE TRUE)
  find_package_handle_standard_args(EdalabBase DEFAULT_MSG FAKE)
  set(EDALABBASE_FOUND ${EDALABBASE_FOUND} PARENT_SCOPE)

  # Assuring the exsistance of doc target:
  edalab_check_target_exists(DOC_TARGET doc)
  if(NOT DOC_TARGET)
    add_custom_target(doc)
  endif(NOT DOC_TARGET)
  # Cleanup $build/doc on "make clean"
  #set_property(DIRECTORY APPEND PROPERTY ADDITIONAL_MAKE_CLEAN_FILES doc)

  # Moving some standard vars:
  mark_as_advanced(CMAKE_INSTALL_PREFIX)

  # Setting architecture infos:
  # - Sanity checks:
  if("${CMAKE_SYSTEM_NAME}" STREQUAL "")
    edalab_error_message("CMAKE_SYSTEM_NAME not set.")
  elseif("${CMAKE_SYSTEM_PROCESSOR}" STREQUAL "")
    edalab_error_message("CMAKE_SYSTEM_PROCESSOR not set.")
  endif()
  # - OS name:
  string(TOLOWER "${CMAKE_SYSTEM_NAME}" TMP_OUT)
  set(EDALAB_SYSTEM_NAME "${TMP_OUT}" PARENT_SCOPE)
  # - System procesor and width:
  if(("${CMAKE_SYSTEM_PROCESSOR}" STREQUAL "x86_64")
      OR ("${CMAKE_SYSTEM_PROCESSOR}" STREQUAL "AMD64")
      OR ("${CMAKE_SYSTEM_PROCESSOR}" STREQUAL "i686")
      OR ("${CMAKE_SYSTEM_PROCESSOR}" STREQUAL "x86")
     )
    set(EDALAB_SYSTEM_PROCESSOR "x86" PARENT_SCOPE)
  else()
    # The current processor type is unknown.
    message(FATAL_ERROR "Unexpected processor type: ${CMAKE_SYSTEM_PROCESSOR}")
  endif()

  #if("${CMAKE_SIZEOF_VOID_P}" STREQUAL "1")
  #  set(EDALAB_SYSTEM_WIDTH "8" PARENT_SCOPE)
  #if("${CMAKE_SIZEOF_VOID_P}" STREQUAL "2")
  #  set(EDALAB_SYSTEM_WIDTH "16" PARENT_SCOPE)
  #else
  if("${CMAKE_SIZEOF_VOID_P}" STREQUAL "4")
    set(EDALAB_SYSTEM_WIDTH "32" PARENT_SCOPE)
  elseif("${CMAKE_SIZEOF_VOID_P}" STREQUAL "8")
    set(EDALAB_SYSTEM_WIDTH "64" PARENT_SCOPE)
  else()
    # The current width is unknown.
    message(FATAL_ERROR "Unexpected CMAKE_SIZEOF_VOID_P vallue: ${CMAKE_SIZEOF_VOID_P}")
  endif()

  set(EDALAB_SYSTEM_DIR "${EDALAB_SYSTEM_PROCESSOR}_${EDALAB_SYSTEM_WIDTH}" PARENT_SCOPE)

  set(EDALAB_TAG "stable" CACHE STRING "Default tag.")

  # Assuring the default build type.
  edalab_add_combobox(CMAKE_BUILD_TYPE
    "Debug;Release;RelWithDebInfo;MinSizeRel"
    "Choose the type of build, options are: Debug Release RelWithDebInfo MinSizeRel."
    OFF
    "All" "Release")
endfunction(_edalab_initialize_global_properties)


# ###########################################################################
# Final setup steps.
# ###########################################################################

# Global inits:
_edalab_initialize_global_properties(EdalabBase_SEARCH_MODE)

# This module standard edalab initialization:
edalab_initialize_module("EdalabBase" "${EdalabBase_SEARCH_MODE}")

# EOF


