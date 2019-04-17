# - EDALab utility to configure GCC flags.
# Written by using GCC 4.9.2 docs.
# Tested flags under:
# - GCC 4.4.5.
# - MinGW 4.2.1
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
#   _edalab_compiler_submodule_set_flags()         -- from EdalabCompiler
#
# Functions:
#   edalab_gcc_set_exe_flags()
#
# Provides:
#   EdalabGcc_INCLUDED

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

option(COMPILER_GCC_NO_ACCESS_CONTROL "Remove access controls." OFF)
option(COMPILER_GCC_NEW_RETURN_NULL "Checks if new returns null." OFF)
option(COMPILER_GCC_NO_RTTI "Do not use RTTI" OFF)
option(COMPILER_GCC_STRICT_ABI "Use the most ABI conformant format." OFF)
option(COMPILER_GCC_SUGGEST_ATTRIBUTES "Suggest eventual attributes." OFF)
option(COMPILER_GCC_DEPRECATED_DECLARATIONS "Warn about deprecated declarations." ON)
mark_as_advanced(COMPILER_GCC_NO_ACCESS_CONTROL COMPILER_GCC_NEW_RETURN_NULL
  COMPILER_GCC_NO_RTTI COMPILER_GCC_STRICT_ABI COMPILER_GCC_SUGGEST_ATTRIBUTES
  COMPILER_GCC_DEPRECATED_DECLARATIONS)

edalab_add_combobox(COMPILER_GCC_TEMPLATE_MODEL "default;borland;cfront"
  "Sets flags about template generation. Can be: default, borland, cfront." ON "All" "default")

if("CMAKE_SYSTEM_NAME" STREQUAL "Windows")
  set(EDALAB_GCC_MINGW ON)
  set(EDALAB_GCC_NOT_MINGW OFF)
else("CMAKE_SYSTEM_NAME" STREQUAL "Windows")
  set(EDALAB_GCC_MINGW OFF)
  set(EDALAB_GCC_NOT_MINGW ON)
endif("CMAKE_SYSTEM_NAME" STREQUAL "Windows")

# ###########################################################################
# Configuration.
# ###########################################################################

# Setting standard vars:
set(EdalabGcc_VERSION_MAJOR 1)
set(EdalabGcc_VERSION_MINOR 0)
set(EdalabGcc_VERSION_PATCH 0)
set(EdalabGcc_VERSION_STRING "FindEdalabGcc.cmake verison: ${EdalabGcc_VERSION_MAJOR}.${EdalabGcc_VERSION_MINOR}.${EdalabGcc_VERSION_PATCH}.")

# Setting up search mode:
set(EdalabGcc_SEARCH_MODE "")
if(EdalabGcc_FIND_REQUIRED)
  set(EdalabGcc_SEARCH_MODE "REQUIRED")
elseif(EdalabGcc_FIND_QUIETLY)
  set(EdalabGcc_SEARCH_MODE "QUIET")
endif()

# Loading dependencies:
find_package(EdalabBase "${EdalabGcc_SEARCH_MODE}")
set(EdalabGcc_INCLUDED ON)
if(NOT EdalabCompiler_INCLUDED)
  find_package(EdalabCompiler ${EdalabGcc_SEARCH_MODE})
  find_package_handle_standard_args(EdalabGcc DEFAULT_MSG EDALABCOMPILER_FOUND EDALABBASE_FOUND)
else(NOT EdalabCompiler_INCLUDED)
  find_package_handle_standard_args(EdalabGcc DEFAULT_MSG EDALABBASE_FOUND)
endif(NOT EdalabCompiler_INCLUDED)

# Module configuration:
if(EDALABGCC_FOUND)

  # Module initialization:
  edalab_initialize_module("EdalabGcc" "${EdalabGcc_SEARCH_MODE}")

endif(EDALABGCC_FOUND)


# ###########################################################################
# Functions implementation.
# ###########################################################################

## Wrapper to the call of _edalab_compiler_add_flag().
## This is required since gcc ignores wrong parameters starting with "-Wno-".
##
function(_edalab_gcc_add_flag FLAG_KIND FLAG REQUIRED CHECK MANDATORY)
  if("${CMAKE_CXX_COMPILER_VERSION}" VERSION_LESS "4.7.4")
    # Workaround for Ubuntu/Gcc/CMake bug:
    if ("${FLAG}" STREQUAL "-Wnonnull")
      set(FLAG_KIND "c_basic")
    endif ("${FLAG}" STREQUAL "-Wnonnull")
  endif("${CMAKE_CXX_COMPILER_VERSION}" VERSION_LESS "4.7.4")

  if(REQUIRED)
    if(${FLAG} MATCHES "-Wno-.*")

      _edalab_compiler_get_lang("${FLAG_KIND}" LANG)

      if(CHECK)
        string(REGEX REPLACE "-Wno-" "-W" POSITIVE_FLAG "${FLAG}")
        _edalab_compiler_check_flag("${POSITIVE_FLAG}" "${LANG}" CXX_IS_SUPPORTED C_IS_SUPPORTED)
      else(CHECK)
        set(CXX_IS_SUPPORTED ON)
        set(C_IS_SUPPORTED ON)
      endif(CHECK)

      _edalab_compiler_eventually_add_flag("${FLAG_KIND}" "${FLAG}" "${LANG}"
        ${CXX_IS_SUPPORTED} ${C_IS_SUPPORTED} ${MANDATORY})

    else(${FLAG} MATCHES "-Wno-.*")

      edalab_compiler_add_flag(${FLAG_KIND} "${FLAG}" ${REQUIRED} ${CHECK} ${MANDATORY})

    endif(${FLAG} MATCHES "-Wno-.*")
  endif(REQUIRED)

endfunction(_edalab_gcc_add_flag )



function(_edalab_compiler_submodule_set_refresh_flags REFRESH)
  if(NOT ("${COMPILER_GCC_NO_ACCESS_CONTROL_OLD}" STREQUAL "${COMPILER_GCC_NO_ACCESS_CONTROL}"))
    set(${REFRESH} ON PARENT_SCOPE)
  elseif(NOT ("${COMPILER_GCC_NEW_RETURN_NULL_OLD}" STREQUAL "${COMPILER_GCC_NEW_RETURN_NULL}"))
    set(${REFRESH} ON PARENT_SCOPE)
  elseif(NOT ("${COMPILER_GCC_NO_RTTI_OLD}" STREQUAL "${COMPILER_GCC_NO_RTTI}"))
    set(${REFRESH} ON PARENT_SCOPE)
  elseif(NOT ("${COMPILER_GCC_STRICT_ABI_OLD}" STREQUAL "${COMPILER_GCC_STRICT_ABI}"))
    set(${REFRESH} ON PARENT_SCOPE)
  elseif(NOT ("${COMPILER_GCC_SUGGEST_ATTRIBUTES_OLD}" STREQUAL "${COMPILER_GCC_SUGGEST_ATTRIBUTES}"))
    set(${REFRESH} ON PARENT_SCOPE)
  elseif(NOT ("${COMPILER_GCC_DEPRECATED_DECLARATIONS_OLD}" STREQUAL "${COMPILER_GCC_DEPRECATED_DECLARATIONS}"))
    set(${REFRESH} ON PARENT_SCOPE)
  elseif(NOT ("${COMPILER_GCC_TEMPLATE_MODEL_OLD}" STREQUAL "${COMPILER_GCC_TEMPLATE_MODEL}"))
    set(${REFRESH} ON PARENT_SCOPE)
  else()
    set(${REFRESH} OFF PARENT_SCOPE)
  endif()
  set(COMPILER_GCC_NO_ACCESS_CONTROL_OLD ${COMPILER_GCC_NO_ACCESS_CONTROL} CACHE INTERNAL "" FORCE)
  set(COMPILER_GCC_NEW_RETURN_NULL_OLD ${COMPILER_GCC_NEW_RETURN_NULL} CACHE INTERNAL "" FORCE)
  set(COMPILER_GCC_NO_RTTI_OLD ${COMPILER_GCC_NO_RTTI} CACHE INTERNAL "" FORCE)
  set(COMPILER_GCC_STRICT_ABI_OLD ${COMPILER_GCC_STRICT_ABI} CACHE INTERNAL "" FORCE)
  set(COMPILER_GCC_SUGGEST_ATTRIBUTES_OLD ${COMPILER_GCC_SUGGEST_ATTRIBUTES} CACHE INTERNAL "" FORCE)
  set(COMPILER_GCC_DEPRECATED_DECLARATIONS_OLD ${COMPILER_GCC_DEPRECATED_DECLARATIONS} CACHE INTERNAL "" FORCE)
  set(COMPILER_GCC_TEMPLATE_MODEL_OLD ${COMPILER_GCC_TEMPLATE_MODEL} CACHE INTERNAL "" FORCE)
endfunction(_edalab_compiler_submodule_set_refresh_flags)



function(_edalab_compiler_submodule_set_flags )

  #####################################################
  # Internal settings
  #####################################################

  _edalab_compiler_check_flag("-fvisibility=default" "c_cxx" V_CXX_IS_SUPPORTED V_C_IS_SUPPORTED)

  if (${V_C_IS_SUPPORTED})
    set(EdalabGcc_C_VISIBILITY "-fvisibility=default" CACHE INTERNAL "Visibility for C executables." FORCE)
  else (${V_C_IS_SUPPORTED})
    set(EdalabGcc_C_VISIBILITY "" CACHE INTERNAL "Visibility for C executables." FORCE)
  endif (${V_C_IS_SUPPORTED})

  if (${V_CXX_IS_SUPPORTED})
    set(EdalabGcc_CXX_VISIBILITY "-fvisibility=default" CACHE INTERNAL "Visibility for C++ executables." FORCE)
  else (${V_CXX_IS_SUPPORTED})
    set(EdalabGcc_CXX_VISIBILITY "" CACHE INTERNAL "Visibility for C++ executables." FORCE)
  endif (${V_CXX_IS_SUPPORTED})

  #####################################################
  # C & C++
  #####################################################

  # Not required by CMake.
  # _edalab_gcc_add_flag("c_cxx_basic" "-c" ON OFF OFF)

  #### OPTIONS TO CONTROL DIAGNOSTIC MESSAGES FORMATTING.
  # -fmessage-length=n
  # -fdiagnostics-show-location=[once|every-line]
  # -fno-diagnostics-show-option -fno-diagnostics-show-caret

  #### OPTIONS TO REQUEST OR SUPPRESS WARNINGS.
  # -fsyntax-only  -fmax-errors=n  -Wpedantic
  # -pedantic-errors
  # -w  -Wextra  -Wall  -Waddress  -Waggregate-return
  # -Waggressive-loop-optimizations -Warray-bounds
  # -Wno-attributes -Wno-builtin-macro-redefined
  # -Wc++-compat -Wc++11-compat -Wcast-align  -Wcast-qual
  # -Wchar-subscripts -Wclobbered  -Wcomment
  # -Wconversion  -Wcoverage-mismatch  -Wno-cpp  -Wno-deprecated
  # -Wno-deprecated-declarations -Wdisabled-optimization
  # -Wno-div-by-zero -Wdouble-promotion -Wempty-body  -Wenum-compare
  # -Wno-endif-labels -Werror  -Werror=*
  # -Wfatal-errors  -Wfloat-equal  -Wformat  -Wformat=2
  # -Wno-format-contains-nul -Wno-format-extra-args -Wformat-nonliteral
  # -Wformat-security  -Wformat-y2k
  # -Wframe-larger-than=len -Wno-free-nonheap-object -Wjump-misses-init
  # -Wignored-qualifiers
  # -Wimplicit  -Wimplicit-function-declaration  -Wimplicit-int
  # -Winit-self  -Winline -Wmaybe-uninitialized
  # -Wno-int-to-pointer-cast -Wno-invalid-offsetof
  # -Winvalid-pch -Wlarger-than=len  -Wunsafe-loop-optimizations
  # -Wlogical-op -Wlong-long
  # -Wmain -Wmaybe-uninitialized -Wmissing-braces  -Wmissing-field-initializers
  # -Wmissing-include-dirs
  # -Wno-mudflap
  # -Wno-multichar  -Wnonnull  -Wno-overflow
  # -Woverlength-strings  -Wpacked  -Wpacked-bitfield-compat  -Wpadded
  # -Wparentheses  -Wpedantic-ms-format -Wno-pedantic-ms-format
  # -Wpointer-arith  -Wno-pointer-to-int-cast
  # -Wredundant-decls  -Wno-return-local-addr
  # -Wreturn-type  -Wsequence-point  -Wshadow
  # -Wsign-compare  -Wsign-conversion  -Wsizeof-pointer-memaccess
  # -Wstack-protector -Wstack-usage=len -Wstrict-aliasing
  # -Wstrict-aliasing=n  -Wstrict-overflow -Wstrict-overflow=n
  # -Wsuggest-attribute=[pure|const|noreturn|format]
  # -Wmissing-format-attribute
  # -Wswitch  -Wswitch-default  -Wswitch-enum -Wsync-nand
  # -Wsystem-headers  -Wtrampolines  -Wtrigraphs  -Wtype-limits  -Wundef
  # -Wuninitialized  -Wunknown-pragmas  -Wno-pragmas
  # -Wunsuffixed-float-constants  -Wunused  -Wunused-function
  # -Wunused-label  -Wunused-local-typedefs -Wunused-parameter
  # -Wno-unused-result -Wunused-value  -Wunused-variable
  # -Wunused-but-set-parameter -Wunused-but-set-variable
  # -Wuseless-cast -Wvariadic-macros -Wvector-operation-performance
  # -Wvla -Wvolatile-register-var  -Wwrite-strings -Wzero-as-null-pointer-constant
  # -Wdate-time


  #### C AND OBJECTIVE-C-ONLY WARNING OPTIONS
  # -Wbad-function-cast  -Wmissing-declarations
  # -Wmissing-parameter-type  -Wmissing-prototypes  -Wnested-externs
  # -Wold-style-declaration  -Wold-style-definition
  # -Wstrict-prototypes  -Wtraditional  -Wtraditional-conversion
  # -Wdeclaration-after-statement -Wpointer-sign

  _edalab_gcc_add_flag("c_cxx_basic" "-Werror" ${COMPILER_WARNINGS_AS_ERRORS} OFF OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wfatal-error" ${COMPILER_FATAL_ERRORS} OFF OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wall" ON OFF OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wextra" ON OFF OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wchar-subscripts" ON OFF OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wcomment" ON OFF OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wdouble-promotion" ON ON OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wformat=2" ON OFF OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wnonnull" ON ON OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Winit-self" ON OFF OFF)
  _edalab_gcc_add_flag("c_basic" "-Wimplicit-int" ON OFF OFF)
  _edalab_gcc_add_flag("c_basic" "-Wimplicit-function-declaration" ON OFF OFF)
  _edalab_gcc_add_flag("c_basic" "-Wimplicit" ON OFF OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wno-ignored-qualifiers" ON ${EDALAB_GCC_MINGW} OFF) # Flag is: -Wignored-qualifiers
  _edalab_gcc_add_flag("c_cxx_basic" "-Wmain" ON ${EDALAB_GCC_MINGW} OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wmissing-braces" ON OFF OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wmissing-include-dirs" ON OFF OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wparentheses" ON OFF OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wsequence-point" ON OFF OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wreturn-local-addr" ON ON OFF) # Flag is: -Wno-return-local-addr
  _edalab_gcc_add_flag("c_cxx_basic" "-Wreturn-type" ON OFF OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wdate-time" ON ON OFF)

  if(EDALAB_GCC_MINGW)
    _edalab_gcc_add_flag("c_cxx_basic" "-Wswitch" OFF OFF OFF)
    _edalab_gcc_add_flag("c_cxx_basic" "-Wswitch-default" OFF OFF OFF)
    _edalab_gcc_add_flag("c_cxx_basic" "-Wswitch-enum" OFF OFF OFF)
  else(EDALAB_GCC_MINGW)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wswitch" ON OFF OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wswitch-default" ON OFF OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wswitch-enum" ${COMPILER_CHECK_SWITCH_ENUMS} OFF OFF)
  endif(EDALAB_GCC_MINGW)

  _edalab_gcc_add_flag("c_cxx_basic" "-Wunused-but-set-parameter" ON ON OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wunused-but-set-variable" ON ON OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wunused-function" ON OFF OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wunused-label" ON OFF OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wunused-local-typedefs" ON ON OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wunused-parameter" ON OFF OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wunused-variable" ON OFF OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wunused-value" ON OFF OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wunused" ON OFF OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wuninitialized" ${EDALAB_GCC_NOT_MINGW} OFF OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wmaybe-uninitialized" ON ON OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wunknown-pragmas" ON OFF OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wstrict-aliasing" ON OFF OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wstrict-overflow=5" ON OFF OFF)

  #########
  _edalab_gcc_add_flag("c_cxx_basic" "-Wsuggest-attribute=pure" ${COMPILER_GCC_SUGGEST_ATTRIBUTES} ON OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wsuggest-attribute=const" ${COMPILER_GCC_SUGGEST_ATTRIBUTES} ON OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wsuggest-attribute=noreturn" ${COMPILER_GCC_SUGGEST_ATTRIBUTES} ON OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wsuggest-attribute=format" ${COMPILER_GCC_SUGGEST_ATTRIBUTES} ON OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wmissing-format-attribute" ${COMPILER_GCC_SUGGEST_ATTRIBUTES} OFF OFF)
  #########

  _edalab_gcc_add_flag("c_cxx_basic" "-Warray-bounds" ON ${EDALAB_GCC_MINGW} OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wdiv-by-zero" ON OFF OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wtrampolines" ON ON OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wfloat-equal" ON OFF OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wundef" ON OFF OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wendif-labels" ON OFF OFF) # Flag is: -Wno-endif-labels
  _edalab_gcc_add_flag("c_cxx_basic" "-Wshadow" ON OFF OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wfree-nonheap-object" ON ON OFF) # Flag is: -Wno-free-nonheap-object
  _edalab_gcc_add_flag("c_cxx_basic" "-Wunsafe-loop-optimizations" ON OFF OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wpointer-arith" ON OFF OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wtype-limits" ON ${EDALAB_GCC_MINGW} OFF)
  _edalab_gcc_add_flag("c_basic" "-Wbad-function-cast" ON OFF OFF)
  _edalab_gcc_add_flag("c_basic" "-Wc++-compat" ON OFF OFF)
  _edalab_gcc_add_flag("cxx_basic" "-Wc++11-compat" ON ON OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wcast-qual" ON OFF OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wcast-align" ON OFF OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wwrite-strings" ON OFF OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wclobbered" ON ${EDALAB_GCC_MINGW} OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wconversion" ON OFF OFF)
  _edalab_gcc_add_flag("cxx_basic" "-Wconversion-null" ON ON OFF) # Flag is: -Wno-conversion-null
  if((NOT ("${COMPILER_CXX_STANDARD}" STREQUAL "OFF")) AND (NOT ("${COMPILER_CXX_STANDARD}" STREQUAL "98")))
    # Checking only when nullptr is available, due to a bug/unuseful implementation of this warning in gcc.
    _edalab_gcc_add_flag("cxx_basic" "-Wzero-as-null-pointer-constant" ON ON OFF)
  endif((NOT ("${COMPILER_CXX_STANDARD}" STREQUAL "OFF")) AND (NOT ("${COMPILER_CXX_STANDARD}" STREQUAL "98")))
  _edalab_gcc_add_flag("cxx_basic" "-Wuseless-cast" ON ON OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wempty-body" ON ${EDALAB_GCC_MINGW} OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wenum-compare" ON ${EDALAB_GCC_MINGW} OFF)
  _edalab_gcc_add_flag("c_basic" "-Wjump-misses-init" ON OFF OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wsign-compare" ON OFF OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wsign-conversion" ON ${EDALAB_GCC_MINGW} OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wsizeof-pointer-memaccess" ON ON OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Waddress" ON OFF OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wlogical-op" ON ${EDALAB_GCC_MINGW} OFF)
  # _edalab_gcc_add_flag("c_cxx_basic" "-Waggregate-return" ON OFF OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wno-aggressive-loop-optimizations" ON ON OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wattributes" ON OFF OFF) # Flag is: -Wno-attributes
  _edalab_gcc_add_flag("c_cxx_basic" "-Wbuiltin-macro-redefined" ON ${EDALAB_GCC_MINGW} OFF) # Flag is: -Wno-builtin-macro-redefined
  _edalab_gcc_add_flag("c_basic" "-Wstrict-prototypes" ON OFF OFF)
  _edalab_gcc_add_flag("c_basic" "-Wold-style-declaration" ON OFF OFF)
  _edalab_gcc_add_flag("c_basic" "-Wold-style-definition" ON OFF OFF)
  _edalab_gcc_add_flag("c_basic" "-Wmissing-parameter-type" ON OFF OFF)
  _edalab_gcc_add_flag("c_basic" "-Wmissing-prototypes" ON OFF OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wmissing-declarations" ON ${EDALAB_GCC_MINGW} OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wmissing-field-initializers" ON OFF OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wmultichar" ON OFF OFF) # Flag is: -Wno-multichar
  _edalab_gcc_add_flag("c_cxx_basic" "-Wnormalized=nfc" ON OFF OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wdeprecated" ON OFF OFF) # Flag is: -Wno-deprecated
  if(${COMPILER_GCC_DEPRECATED_DECLARATIONS})
    _edalab_gcc_add_flag("c_cxx_basic" "-Wdeprecated-declarations" ON OFF OFF) # Flag is: -Wno-deprecated-declarations
  else(${COMPILER_GCC_DEPRECATED_DECLARATIONS})
    _edalab_gcc_add_flag("c_cxx_basic" "-Wno-deprecated-declarations" OFF OFF OFF) # Flag is: -Wno-deprecated-declarations
  endif(${COMPILER_GCC_DEPRECATED_DECLARATIONS})
  _edalab_gcc_add_flag("c_cxx_basic" "-Woverflow" ON OFF OFF) # Flag is: -Wno-overflow
  _edalab_gcc_add_flag("c_basic" "-Woverride-init" ON OFF OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wpacked" ON OFF OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wno-packed-bitfield-compat" ON ${EDALAB_GCC_MINGW} OFF) # Flag is: -Wpacked-bitfield-compat
  _edalab_gcc_add_flag("c_cxx_mem" "-Wpadded" ON OFF OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wredundant-decls" ON OFF OFF)
  _edalab_gcc_add_flag("c_basic" "-Wnested-externs" ON OFF OFF)
  _edalab_gcc_add_flag("cxx_basic" "-Winherited-variadic-ctor" ON ON OFF) # Flag is: -Wno-inherited-variadic-ctor
  _edalab_gcc_add_flag("c_cxx_basic" "-Winline" ON OFF OFF)
  _edalab_gcc_add_flag("cxx_basic" "-Winvalid-offsetof" ON OFF OFF) # Flag is: -Wno-invalid-offsetof
  _edalab_gcc_add_flag("c_cxx_basic" "-Wint-to-pointer-cast" ON ON OFF) # Flag is: -Wno-int-to-pointer-cast
  _edalab_gcc_add_flag("c_basic" "-Wpointer-to-int-cast" ON OFF OFF) # Flag is: -Wno-pointer-to-int-cast
  _edalab_gcc_add_flag("c_cxx_basic" "-Winvalid-pch" ON OFF OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wno-long-long" ON OFF OFF) # Flag is: -Wlong-long
  _edalab_gcc_add_flag("c_cxx_basic" "-Wno-variadic-macros" ON OFF OFF) # Flag is: -Wvariadic-macros
  _edalab_gcc_add_flag("c_cxx_basic" "-Wvarargs" ON ON OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wvector-operation-performance" ON ON OFF)
  _edalab_gcc_add_flag("cxx_basic" "-Wvirtual-move-assign" ON ON OFF) # Flag is: -Wno-virtual-move-assign
  _edalab_gcc_add_flag("c_cxx_basic" "-Wvla" ON ${EDALAB_GCC_MINGW} OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wvolatile-register-var" ON OFF OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wdisabled-optimization" ON OFF OFF)
  _edalab_gcc_add_flag("c_basic" "-Wpointer-sign" ON OFF OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Wstack-protector" ON OFF OFF)
  _edalab_gcc_add_flag("c_cxx_basic" "-Woverlength-strings" ON OFF OFF)
  _edalab_gcc_add_flag("c_basic" "-Wunsuffixed-float-constants" ON OFF OFF)


  #### OPTIONS FOR DEBUGGING YOUR PROGRAM OR GCC.
  # -dletters  -dumpspecs  -dumpmachine  -dumpversion
  # -fsanitize=style
  # -fdbg-cnt-list -fdbg-cnt=counter-value-list
  # -fdisable-ipa-pass_name
  # -fdisable-rtl-pass_name
  # -fdisable-rtl-pass-name=range-list
  # -fdisable-tree-pass_name
  # -fdisable-tree-pass-name=range-list
  # -fdump-noaddr -fdump-unnumbered -fdump-unnumbered-links
  # -fdump-translation-unit[-n]
  # -fdump-class-hierarchy[-n]
  # -fdump-ipa-all -fdump-ipa-cgraph -fdump-ipa-inline
  # -fdump-passes
  # -fdump-statistics
  # -fdump-tree-all
  # -fdump-tree-original[-n]
  # -fdump-tree-optimized[-n]
  # -fdump-tree-cfg -fdump-tree-alias
  # -fdump-tree-ch
  # -fdump-tree-ssa[-n] -fdump-tree-pre[-n]
  # -fdump-tree-ccp[-n] -fdump-tree-dce[-n]
  # -fdump-tree-gimple[-raw] -fdump-tree-mudflap[-n]
  # -fdump-tree-dom[-n]
  # -fdump-tree-dse[-n]
  # -fdump-tree-phiprop[-n]
  # -fdump-tree-phiopt[-n]
  # -fdump-tree-forwprop[-n]
  # -fdump-tree-copyrename[-n]
  # -fdump-tree-nrv -fdump-tree-vect
  # -fdump-tree-sink
  # -fdump-tree-sra[-n]
  # -fdump-tree-forwprop[-n]
  # -fdump-tree-fre[-n]
  # -fdump-tree-vrp[-n]
  # -ftree-vectorizer-verbose=n
  # -fdump-tree-storeccp[-n]
  # -fdump-final-insns=file
  # -fcompare-debug[=opts]  -fcompare-debug-second
  # -feliminate-dwarf2-dups -fno-eliminate-unused-debug-types
  # -feliminate-unused-debug-symbols -femit-class-debug-always
  # -fenable-kind-pass
  # -fenable-kind-pass=range-list
  # -fdebug-types-section -fmem-report-wpa
  # -fmem-report -fpre-ipa-mem-report -fpost-ipa-mem-report -fprofile-arcs
  # -fopt-info
  # -fopt-info-options[=file]
  # -frandom-seed=string -fsched-verbose=n
  # -fsel-sched-verbose -fsel-sched-dump-cfg -fsel-sched-pipelining-verbose
  # -fstack-usage  -ftest-coverage  -ftime-report -fvar-tracking
  # -fvar-tracking-assignments  -fvar-tracking-assignments-toggle
  # -g  -glevel  -gtoggle  -gcoff  -gdwarf-version
  # -ggdb  -grecord-gcc-switches  -gno-record-gcc-switches
  # -gstabs  -gstabs+  -gstrict-dwarf  -gno-strict-dwarf
  # -gvms  -gxcoff  -gxcoff+
  # -fno-merge-debug-strings -fno-dwarf2-cfi-asm
  # -fdebug-prefix-map=old=new
  # -femit-struct-debug-baseonly -femit-struct-debug-reduced
  # -femit-struct-debug-detailed[=spec-list]
  # -p  -pg  -print-file-name=library  -print-libgcc-file-name
  # -print-multi-directory  -print-multi-lib  -print-multi-os-directory
  # -print-prog-name=program  -print-search-dirs  -Q
  # -print-sysroot -print-sysroot-headers-suffix
  # -save-temps -save-temps=cwd -save-temps=obj -time[=file]


  _edalab_gcc_add_flag("c_cxx_debug" "-ggdb3" ON OFF OFF)
#  _edalab_gcc_add_flag("c_cxx_opt" "-ggdb3" ON OFF OFF)
  _edalab_gcc_add_flag("c_cxx_debug" "-pg" ${COMPILER_USE_PROFILER} OFF OFF)


  # See Options that Control Optimization.

  # -faggressive-loop-optimizations -falign-functions[=n]
  # -falign-jumps[=n]
  # -falign-labels[=n] -falign-loops[=n]
  # -fassociative-math -fauto-inc-dec -fbranch-probabilities
  # -fbranch-target-load-optimize -fbranch-target-load-optimize2
  # -fbtr-bb-exclusive -fcaller-saves
  # -fcheck-data-deps -fcombine-stack-adjustments -fconserve-stack
  # -fcompare-elim -fcprop-registers -fcrossjumping
  # -fcse-follow-jumps -fcse-skip-blocks -fcx-fortran-rules
  # -fcx-limited-range
  # -fdata-sections -fdce -fdelayed-branch
  # -fdelete-null-pointer-checks -fdevirtualize -fdse
  # -fearly-inlining -fipa-sra -fexpensive-optimizations -ffat-lto-objects
  # -ffast-math -ffinite-math-only -ffloat-store -fexcess-precision=style
  # -fforward-propagate -ffp-contract=style -ffunction-sections
  # -fgcse -fgcse-after-reload -fgcse-las -fgcse-lm -fgraphite-identity
  # -fgcse-sm -fhoist-adjacent-loads -fif-conversion
  # -fif-conversion2 -findirect-inlining
  # -finline-functions -finline-functions-called-once -finline-limit=n
  # -finline-small-functions -fipa-cp -fipa-cp-clone
  # -fipa-pta -fipa-profile -fipa-pure-const -fipa-reference
  # -fira-algorithm=algorithm
  # -fira-region=region -fira-hoist-pressure
  # -fira-loop-pressure -fno-ira-share-save-slots
  # -fno-ira-share-spill-slots -fira-verbose=n
  # -fivopts -fkeep-inline-functions -fkeep-static-consts
  # -floop-block -floop-interchange -floop-strip-mine -floop-nest-optimize
  # -floop-parallelize-all -flto -flto-compression-level
  # -flto-partition=alg -flto-report -fmerge-all-constants
  # -fmerge-constants -fmodulo-sched -fmodulo-sched-allow-regmoves
  # -fmove-loop-invariants fmudflap -fmudflapir -fmudflapth -fno-branch-count-reg
  # -fno-default-inline
  # -fno-defer-pop -fno-function-cse -fno-guess-branch-probability
  # -fno-inline -fno-math-errno -fno-peephole -fno-peephole2
  # -fno-sched-interblock -fno-sched-spec -fno-signed-zeros
  # -fno-toplevel-reorder -fno-trapping-math -fno-zero-initialized-in-bss
  # -fomit-frame-pointer -foptimize-register-move -foptimize-sibling-calls
  # -fpartial-inlining -fpeel-loops -fpredictive-commoning
  # -fprefetch-loop-arrays -fprofile-report
  # -fprofile-correction -fprofile-dir=path -fprofile-generate
  # -fprofile-generate=path
  # -fprofile-use -fprofile-use=path -fprofile-values
  # -freciprocal-math -free -fregmove -frename-registers -freorder-blocks
  # -freorder-blocks-and-partition -freorder-functions
  # -frerun-cse-after-loop -freschedule-modulo-scheduled-loops
  # -frounding-math -fsched2-use-superblocks -fsched-pressure
  # -fsched-spec-load -fsched-spec-load-dangerous
  # -fsched-stalled-insns-dep[=n] -fsched-stalled-insns[=n]
  # -fsched-group-heuristic -fsched-critical-path-heuristic
  # -fsched-spec-insn-heuristic -fsched-rank-heuristic
  # -fsched-last-insn-heuristic -fsched-dep-count-heuristic
  # -fschedule-insns -fschedule-insns2 -fsection-anchors
  # -fselective-scheduling -fselective-scheduling2
  # -fsel-sched-pipelining -fsel-sched-pipelining-outer-loops
  # -fshrink-wrap -fsignaling-nans -fsingle-precision-constant
  # -fsplit-ivs-in-unroller -fsplit-wide-types -fstack-protector
  # -fstack-protector-all -fstrict-aliasing -fstrict-overflow
  # -fthread-jumps -ftracer -ftree-bit-ccp
  # -ftree-builtin-call-dce -ftree-ccp -ftree-ch
  # -ftree-coalesce-inline-vars -ftree-coalesce-vars -ftree-copy-prop
  # -ftree-copyrename -ftree-dce -ftree-dominator-opts -ftree-dse
  # -ftree-forwprop -ftree-fre -ftree-loop-if-convert
  # -ftree-loop-if-convert-stores -ftree-loop-im
  # -ftree-phiprop -ftree-loop-distribution -ftree-loop-distribute-patterns
  # -ftree-loop-ivcanon -ftree-loop-linear -ftree-loop-optimize
  # -ftree-parallelize-loops=n -ftree-pre -ftree-partial-pre -ftree-pta
  # -ftree-reassoc -ftree-sink -ftree-slsr -ftree-sra
  # -ftree-switch-conversion -ftree-tail-merge
  # -ftree-ter -ftree-vect-loop-version -ftree-vectorize -ftree-vrp
  # -funit-at-a-time -funroll-all-loops -funroll-loops
  # -funsafe-loop-optimizations -funsafe-math-optimizations -funswitch-loops
  # -fvariable-expansion-in-unroller -fvect-cost-model -fvpt -fweb
  # -fwhole-program -fwpa -fuse-ld=linker -fuse-linker-plugin
  # --param name=value
  # -O  -O0  -O1  -O2  -O3  -Os -Ofast -Og

  _edalab_gcc_add_flag("c_cxx_opt" "-O3" ON OFF OFF)
  _edalab_gcc_add_flag("c_cxx_mem" "-Os" ON OFF OFF)
  _edalab_gcc_add_flag("c_cxx_debug" "-Og" ON ON OFF)



  #### SEE OPTIONS FOR CODE GENERATION CONVENTIONS.
  # -fcall-saved-reg  -fcall-used-reg
  # -ffixed-reg  -fexceptions
  # -fnon-call-exceptions  -fdelete-dead-exceptions  -funwind-tables
  # -fasynchronous-unwind-tables
  # -finhibit-size-directive  -finstrument-functions
  # -finstrument-functions-exclude-function-list=sym,sym,...
  # -finstrument-functions-exclude-file-list=file,file,...
  # -fno-common  -fno-ident
  # -fpcc-struct-return  -fpic  -fPIC -fpie -fPIE
  # -fno-jump-tables
  # -frecord-gcc-switches
  # -freg-struct-return  -fshort-enums
  # -fshort-double  -fshort-wchar
  # -fverbose-asm  -fpack-struct[=n]  -fstack-check
  # -fstack-limit-register=reg  -fstack-limit-symbol=sym
  # -fno-stack-limit -fsplit-stack
  # -fleading-underscore  -ftls-model=model
  # -fstack-reuse=reuse_level
  # -ftrapv  -fwrapv  -fbounds-check
  # -fvisibility -fstrict-volatile-bitfields -fsync-libcalls
  if(NOT (EDALAB_GCC_MINGW))
    _edalab_gcc_add_flag("c_cxx_basic" "-fvisibility=hidden" ${COMPILER_USE_VISIBILITY} OFF OFF)
  else(NOT (EDALAB_GCC_MINGW))
    _edalab_gcc_add_flag("c_cxx_basic" "-fvisibility=hidden" OFF OFF OFF)
  endif(NOT (EDALAB_GCC_MINGW))
  # _edalab_gcc_add_flag("c_cxx_basic" "-fpic" ON OFF OFF)


  #####################################################
  # C
  #####################################################

  #### OPTIONS CONTROLLING C DIALECT
  # -ansi  -std=standard  -fgnu89-inline
  # -aux-info filename -fallow-parameterless-variadic-functions
  # -fno-asm  -fno-builtin  -fno-builtin-function
  # -fhosted  -ffreestanding -fopenmp -fms-extensions -fplan9-extensions
  # -trigraphs  -traditional  -traditional-cpp
  # -fallow-single-precision  -fcond-mismatch -flax-vector-conversions
  # -fsigned-bitfields  -fsigned-char
  # -funsigned-bitfields  -funsigned-char

  if("${COMPILER_C_STANDARD}" STREQUAL "OFF")
    # No standard set.
  elseif("${COMPILER_C_STANDARD}" STREQUAL "89")
    _edalab_gcc_add_flag("c_basic" "-std=c89" ON OFF OFF)
    _edalab_gcc_add_flag("c_basic" "-pedantic" ON OFF OFF)
  elseif("${COMPILER_C_STANDARD}" STREQUAL "99")
    _edalab_gcc_add_flag("c_basic" "-std=c99" ON OFF OFF)
    _edalab_gcc_add_flag("c_basic" "-pedantic" ON OFF OFF)
  elseif("${COMPILER_C_STANDARD}" STREQUAL "11")
    _edalab_gcc_add_flag("c_basic" "-std=c11" ON ON OFF)
    _edalab_gcc_add_flag("c_basic" "-pedantic" ON ON OFF)
  else()
    edalab_error_message("Unknown C standard: ${COMPILER_C_STANDARD}")
  endif()

  _edalab_gcc_add_flag("c_basic" "-fno-ms-extensions" ON OFF OFF) # Option is -fms-extensions


  #####################################################
  # C++
  #####################################################

  #### OPTIONS CONTROLLING C++ DIALECT.
  # -fabi-version=n  -fno-access-control  -fcheck-new
  # -fconstexpr-depth=n  -ffriend-injection
  # -fno-elide-constructors
  # -fno-enforce-eh-specs
  # -ffor-scope  -fno-for-scope  -fno-gnu-keywords
  # -fno-implicit-templates
  # -fno-implicit-inline-templates
  # -fno-implement-inlines  -fms-extensions
  # -fno-nonansi-builtins  -fnothrow-opt  -fno-operator-names
  # -fno-optional-diags  -fpermissive
  # -fno-pretty-templates
  # -frepo  -fno-rtti  -fstats  -ftemplate-backtrace-limit=n
  # -ftemplate-depth=n
  # -fno-threadsafe-statics -fuse-cxa-atexit  -fno-weak  -nostdinc++
  # -fno-default-inline  -fvisibility-inlines-hidden
  # -fvisibility-ms-compat
  # -fext-numeric-literals
  # -Wabi  -Wconversion-null  -Wctor-dtor-privacy
  # -Wdelete-non-virtual-dtor -Wliteral-suffix -Wnarrowing
  # -Wnoexcept -Wnon-virtual-dtor  -Wreorder
  # -Weffc++  -Wstrict-null-sentinel
  # -Wno-non-template-friend  -Wold-style-cast
  # -Woverloaded-virtual  -Wno-pmf-conversions
  # -Wsign-promo

  _edalab_gcc_add_flag("cxx_basic" "-fabi-version=0" ${COMPILER_GCC_STRICT_ABI} OFF OFF)

  if("${COMPILER_CXX_STANDARD}" STREQUAL "OFF")
    # No standard set.
  elseif("${COMPILER_CXX_STANDARD}" STREQUAL "98")
    _edalab_gcc_add_flag("cxx_basic" "-std=c++98" ON OFF OFF)
    _edalab_gcc_add_flag("cxx_basic" "-pedantic" ON OFF OFF)
  elseif("${COMPILER_CXX_STANDARD}" STREQUAL "11")
    _edalab_gcc_add_flag("cxx_basic" "-std=c++11" ON ON OFF)
    _edalab_gcc_add_flag("cxx_basic" "-pedantic" ON OFF OFF)
    _edalab_gcc_add_flag("cxx_opt" "-fnothrow-opt" ON ON OFF)
  else()
    edalab_error_message("Unknown C++ standard: ${COMPILER_CXX_STANDARD}")
  endif()

  _edalab_gcc_add_flag("cxx_debug" "-fno-access-control" ${COMPILER_GCC_NO_ACCESS_CONTROL} OFF OFF)
  _edalab_gcc_add_flag("cxx_debug" "-fcheck-new" ${COMPILER_GCC_NEW_RETURN_NULL} OFF OFF)
  _edalab_gcc_add_flag("cxx_basic" "-fno-gnu-keywords" ON OFF OFF)

  if("${COMPILER_GCC_TEMPLATE_MODEL}" STREQUAL "cfront")
    _edalab_gcc_add_flag("cxx_basic" "-fno-implicit-templates" ON OFF OFF)
    _edalab_gcc_add_flag("cxx_basic" "-fno-implicit-inline-templates" ON OFF OFF)
  elseif("${COMPILER_GCC_TEMPLATE_MODEL}" STREQUAL "borland")
    _edalab_gcc_add_flag("cxx_basic" "-frepo" ON OFF OFF)
  endif()

  #_edalab_gcc_add_flag("cxx_basic" "-fvisibility-ms-compat" ${EDALAB_GCC_MINGW} ON OFF) # Seems unsupported by this version of MinGW...

  _edalab_gcc_add_flag("cxx_mem" " -fno-implement-inlines" ON OFF OFF)
  #_edalab_gcc_add_flag("cxx_basic" "-fms-extensions" ON OFF OFF)
  _edalab_gcc_add_flag("cxx_basic" "-foptional-diags" ON OFF OFF) # Option is: -fno-optional-diags
  _edalab_gcc_add_flag("cxx_basic" "-fno-rtti" ${COMPILER_GCC_NO_RTTI} OFF OFF)
  _edalab_gcc_add_flag("cxx_basic" "-Wabi" ${COMPILER_GCC_STRICT_ABI} OFF OFF)

  _edalab_gcc_add_flag("cxx_basic" "-Wctor-dtor-privacy" ON OFF OFF)
  _edalab_gcc_add_flag("cxx_basic" "-Wdelete-non-virtual-dtor" ON ON OFF) # -Wall
  _edalab_gcc_add_flag("cxx_basic" "-Wliteral-suffix" ON ON OFF) # on by default
  _edalab_gcc_add_flag("cxx_basic" "-Wnarrowing" ON ON OFF) # -Wall
  _edalab_gcc_add_flag("cxx_basic" "-Wnoexcept" ON ON OFF)
  _edalab_gcc_add_flag("cxx_basic" "-Wnon-virtual-dtor" ON OFF OFF) # -Weffc++
  _edalab_gcc_add_flag("cxx_basic" "-Wreorder" ON OFF OFF) # -Wall
  _edalab_gcc_add_flag("cxx_basic" "-Weffc++" ON OFF OFF)
  _edalab_gcc_add_flag("cxx_basic" "-fno-ext-numeric-literals" ON ON OFF) # Flag is: -fext-numeric-literals
  _edalab_gcc_add_flag("cxx_basic" "-Wstrict-null-sentinel" ON OFF OFF)
  _edalab_gcc_add_flag("cxx_basic" "-Wnon-template-friend" ON OFF OFF) # Flag is: -Wno-non-template-friend
  _edalab_gcc_add_flag("cxx_basic" "-Wold-style-cast" ON OFF OFF)
  _edalab_gcc_add_flag("cxx_basic" "-Woverloaded-virtual" ON OFF OFF)
  _edalab_gcc_add_flag("cxx_basic" "-Wpmf-conversions" ON OFF OFF) # Flag is: -Wno-pmf-conversions
  _edalab_gcc_add_flag("cxx_basic" "-Wsign-promo" ON OFF OFF)


  ###########

  # Adding instead of defining, to allow easy overriding, even if it is a macro:
  _edalab_gcc_add_flag("cxx_debug" "-D_GLIBCXX_DEBUG" ${COMPILER_DEBUG_STL} OFF OFF)

  ########### Workaround for linker under Debian:
  edalab_compiler_add_linker_flag("exe" "-Wl,--as-needed" ON OFF OFF)
  edalab_compiler_add_linker_flag("shared" "-Wl,--as-needed" ON OFF OFF)
  edalab_compiler_add_linker_flag("module" "-Wl,--as-needed" ON OFF OFF)

  # Workaround for MinGW:
  if("${CMAKE_SYSTEM_NAME}" STREQUAL "Windows")
    edalab_compiler_add_linker_flag("exe" "-Wl,--allow-multiple-definition" ON OFF OFF)
    edalab_compiler_add_linker_flag("shared" "-Wl,--allow-multiple-definition" ON OFF OFF)
    edalab_compiler_add_linker_flag("module" "-Wl,--allow-multiple-definition" ON OFF OFF)
  endif("${CMAKE_SYSTEM_NAME}" STREQUAL "Windows")

endfunction(_edalab_compiler_submodule_set_flags )



# ###########################################################################
# Functions.
# ###########################################################################

## @brief Sets special flags for executables.
##
## @param NAME The target name.
##
function(edalab_gcc_set_exe_flags NAME)
  if((NOT ("${EdalabGcc_C_VISIBILITY}" STREQUAL "")) OR (NOT ("${EdalabGcc_CXX_VISIBILITY}" STREQUAL "")))
    edalab_compiler_set_target_flags(${NAME} COMPILE_FLAGS -fvisibility=default)
  endif((NOT ("${EdalabGcc_C_VISIBILITY}" STREQUAL "")) OR (NOT ("${EdalabGcc_CXX_VISIBILITY}" STREQUAL "")))
endfunction(edalab_gcc_set_exe_flags)

# EOF
