# - EDALab utility to find and build Scnsl.
#
# Provided configuration options:
#
# Provided user options:
#
# Provided functions:
#

#=============================================================================
# Copyright 2015 EDALab s.r.l.
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

# For each trace, which maximum verbosity level shall be used.
# From 0 (no trace) to 5 (max verbosity).

set(SCNSL_INFO 5 CACHE STRING "Verbosity level for infos. (0 to 5)")
set(SCNSL_LOG 5 CACHE STRING "Verbosity level for logs. (0 to 5)")
set(SCNSL_DBG 5 CACHE STRING "Verbosity level for debugs. (0 to 5)")

set(SCNSL_WARNING 5 CACHE STRING "Verbosity level for warnings. (0 to 5)")
set(SCNSL_ERROR 5 CACHE STRING "Verbosity level for errors. (0 to 5)")
set(SCNSL_FATAL 5 CACHE STRING "Verbosity level for fatals. (0 to 5)")

mark_as_advanced(FORCE SCNSL_INFO SCNSL_LOG SCNSL_DBG SCNSL_WARNING SCNSL_ERROR SCNSL_FATAL)



# ###########################################################################
# Configuration.
# ###########################################################################

# Setting standard vars:
set(Scnsl_VERSION_MAJOR 1)
set(Scnsl_VERSION_MINOR 0)
set(Scnsl_VERSION_PATCH 0)
set(Scnsl_VERSION_STRING "FindScnsl.cmake verison: ${Scnsl_VERSION_MAJOR}.${Scnsl_VERSION_MINOR}.${Scnsl_VERSION_PATCH}.")

# Setting up search mode:
set(Scnsl_SEARCH_MODE "")
if(Scnsl_FIND_REQUIRED)
  set(Scnsl_SEARCH_MODE "REQUIRED")
elseif(Scnsl_FIND_QUIETLY)
  set(Scnsl_SEARCH_MODE "QUIET")
endif()

# Loading dependencies:
find_package(EdalabBase ${Scnsl_SEARCH_MODE})
find_package(EdalabSystemC ${Scnsl_SEARCH_MODE})
find_package_handle_standard_args(Scnsl DEFAULT_MSG
  EDALABSYSTEMC_FOUND
  EDALABBASE_FOUND
)

# Module configuration:
if(SCNSL_FOUND)

  # Module initialization:
  edalab_initialize_module("Scnsl" "${Scnsl_SEARCH_MODE}")

endif(SCNSL_FOUND)


# ###########################################################################
# Support functions.
# ###########################################################################

# ###########################################################################
# Functions.
# ###########################################################################

## @brief Setups binaries for using SCNSL.
macro(scnsl_setup_bins)

  edalab_find_library(Scnsl "scnsl" "ANY" "scnsl")
  edalab_find_path(Scnsl_H "scnsl" "scnsl")
  edalab_assure_vars(Scnsl Scnsl_H)

  if("${CMAKE_SYSTEM_NAME}" STREQUAL "Linux")
    edalab_find_library(Scnsl_DL "dl" "SHARED" "")
    edalab_assure_vars(Scnsl_DL)
  endif("${CMAKE_SYSTEM_NAME}" STREQUAL "Linux")

  set(Scnsl_LIBRARIES
    ${Scnsl_LIBRARIES}
    "${Scnsl_DL}"
    )

  edalab_setup_standard_variables(Scnsl "" OFF EdalabSystemC)

  add_definitions(
    -DSCNSL_INFO=${SCNSL_INFO}
    -DSCNSL_LOG=${SCNSL_LOG}
    -DSCNSL_DBG=${SCNSL_DBG}
    -DSCNSL_WARNING=${SCNSL_WARNING}
    -DSCNSL_ERROR=${SCNSL_ERROR}
    -DSCNSL_FATAL=${SCNSL_FATAL}
    )

endmacro(scnsl_setup_bins)


## @brief Setups sources for building SCNSL.
function(scnsl_setup_srcs)

  #find_package(EdalabLatex    REQUIRED)
  #find_package(EdalabDoxygen  REQUIRED)
  find_package(EdalabTargets  REQUIRED)
  find_package(EdalabCompiler REQUIRED)

  edalab_set_once(CMAKE_INSTALL_PREFIX
    "scnsl-${EDALAB_TAG}-${EDALAB_SYSTEM_NAME}-${EDALAB_SYSTEM_DIR}"
    "PATH"
    "CMake install dir."
    "ON"
  )

  if ("${CMAKE_SYSTEM_NAME}" STREQUAL "Windows")
    edalab_compiler_add_user_options("OFF" "OFF" "OFF" "ON")
  else ("${CMAKE_SYSTEM_NAME}" STREQUAL "Windows")
    edalab_compiler_add_user_options("99" "98" "OFF" "ON")
  endif ("${CMAKE_SYSTEM_NAME}" STREQUAL "Windows")
  edalab_compiler_set_flags()

  edalab_setup_standard_variables(Scnsl "" ON EdalabSystemC)
  edalab_export_standard_variables(Scnsl)

  if("${CMAKE_SYSTEM_NAME}" STREQUAL "Linux")
    edalab_find_library(Scnsl_DL "dl" "SHARED" "")
    edalab_assure_vars(Scnsl_DL)
  endif("${CMAKE_SYSTEM_NAME}" STREQUAL "Linux")

  set(Scnsl_LIBRARIES
    ${Scnsl_LIBRARIES}
    "${Scnsl_DL}"
    )

  edalab_global_setup(Scnsl)

  add_definitions(
    -DSCNSL_INFO=${SCNSL_INFO}
    -DSCNSL_LOG=${SCNSL_LOG}
    -DSCNSL_DBG=${SCNSL_DBG}
    -DSCNSL_WARNING=${SCNSL_WARNING}
    -DSCNSL_ERROR=${SCNSL_ERROR}
    -DSCNSL_FATAL=${SCNSL_FATAL}
    )

  # Adding custom target, to simplify mainteinance of duplicated CMake scripts:
  edalab_add_cmake_update_scripts(
    FindEdalabBase.cmake
    FindEdalabDoxygen.cmake
    FindEdalabLatex.cmake
    FindEdalabTargets.cmake
    FindScnsl.cmake
    FindEdalabCompiler.cmake
    FindEdalabGcc.cmake
    FindEdalabSystemC.cmake
    FindEdalabVc.cmake
  )

endfunction(scnsl_setup_srcs)

# EOF
