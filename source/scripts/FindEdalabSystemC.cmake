# - EDALab utility to find SYSTEMC libraries.
#
# Provided option to be set before this module inclusion:
#   EdalabSystemC_USE_AMS
#
# Provided user variables:
#   EdalabSystemC_INCLUDE_DIRS
#   EdalabSystemC_LIBRARIES
#   EdalabSystemC_LIBRARY_DIRS
#   EdalabSystemC_RUNTIME_LIBRARIES
#   EdalabSystemC_DEFINITIONS
#   EdalabSystemC_LINKED_STATIC_LIBRARIES
#   EdalabSystemC_RUNTIME_DIRS
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


# ###########################################################################
# Configuration.
# ###########################################################################

# Setting standard vars:
set(EdalabSystemC_VERSION_MAJOR 1)
set(EdalabSystemC_VERSION_MINOR 0)
set(EdalabSystemC_VERSION_PATCH 0)
set(EdalabSystemC_VERSION_STRING "FindEdalabSystemC.cmake verison: ${EdalabSystemC_VERSION_MAJOR}.${EdalabSystemC_VERSION_MINOR}.${EdalabSystemC_VERSION_PATCH}.")

# Setting up search mode:
set(EdalabSystemC_SEARCH_MODE "")
if(EdalabSystemC_FIND_REQUIRED)
  set(EdalabSystemC_SEARCH_MODE "REQUIRED")
elseif(EdalabSystemC_FIND_QUIETLY)
  set(EdalabSystemC_SEARCH_MODE "QUIET")
endif()

# Loading dependencies:
find_package(EdalabBase ${EdalabSystemC_SEARCH_MODE})
find_package_handle_standard_args(EdalabSystemC DEFAULT_MSG EDALABBASE_FOUND)
if(EDALABBASE_FOUND)

  # Searching SYSTEMC libs and headers, in order:
  # - SystemC: under Windows with VC++
  # - (lib)systemc: under Linux or with MinGW
  edalab_find_library(EdalabSystemC "SystemC;systemc" "ANY" "systemc")

  # Searching for headers:
  edalab_find_path(EdalabSystemC_H "systemc" "systemc")
  edalab_find_path(EdalabSystemCTlm_H "tlm.h" "systemc")

  if(EdalabSystemC_USE_AMS)
    edalab_find_path(EdalabSystemCAMS_H "systemc-ams" "systemc-ams")
    edalab_find_library(EdalabSystemCAMS "systemc-ams;systemc_ams" "ANY" "systemc-ams")
    set(EdalabSystemCAMS_H_F ${EdalabSystemCAMS_H})
    set(EdalabSystemCAMS_F ${EdalabSystemCAMS})
  else(EdalabSystemC_USE_AMS)
    set(EdalabSystemCAMS_H_F ON)
    set(EdalabSystemCAMS_F ON)
  endif(EdalabSystemC_USE_AMS)

  find_package_handle_standard_args(EdalabSystemC DEFAULT_MSG
    EdalabSystemC
    EdalabSystemC_H
    EdalabSystemCTlm_H
    EdalabSystemCAMS_F
    EdalabSystemCAMS_H_F
    )

endif(EDALABBASE_FOUND)

# Module configuration:
if(EDALABSYSTEMC_FOUND)

  # Module initialization:
  edalab_initialize_module("EdalabSystemC" "${EdalabSystemC_SEARCH_MODE}")
  edalab_message("SystemC lib: ${EdalabSystemC}")

  if("${CMAKE_SYSTEM_NAME}" STREQUAL "Linux")
    edalab_find_library(EdalabSystemC_PTHREAD "pthread" "SHARED" "")
    edalab_assure_vars(EdalabSystemC_PTHREAD)
  endif("${CMAKE_SYSTEM_NAME}" STREQUAL "Linux")

  edalab_setup_standard_variables(EdalabSystemC "" OFF)
  edalab_setup_standard_variables(EdalabSystemCAMS "" OFF)
  edalab_setup_package_libraries(EdalabSystemC EdalabSystemCAMS EdalabSystemC)

  # Setting vars:
  set(EdalabSystemC_INCLUDE_DIRS
    ${EdalabSystemC_INCLUDE_DIRS}
    "${EdalabSystemCTlm_H}"
    )
  set(EdalabSystemC_LIBRARIES
    ${EdalabSystemC_LIBRARIES}
    "${EdalabSystemC_PTHREAD}"
    )

  #edalab_print_dependency_variables("EdalabSystemC")
endif(EDALABSYSTEMC_FOUND)


# EOF

