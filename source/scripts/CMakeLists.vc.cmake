#####################################################
# CMake file definitions for VC++.
#####################################################
#
# @author Francesco Stefanni
#
# Written by using VC++ 2005 docs.
#
# Input options:
# - COMPILER_WARNINGS_AS_ERRORS
# - USE_C_ANSI_STANDARD
# - USE_CXX_ANSI_STANDARD
#


if(MSVC OR MSVC_IDE OR MSVC60 OR MSVC70 OR MSVC71 OR MSVC80 OR CMAKE_COMPILER_2005 OR MSVC90)

  #####################################################
  # C & C++
  #####################################################

  add_flag(BASIC_C_CXX_FLAGS "/Wall" ON OFF)
  add_flag(BASIC_C_CXX_FLAGS "/W4" ON OFF)

  add_flag(BASIC_C_CXX_FLAGS "/WX" ${WARNINGS_AS_ERRORS} OFF)

  add_flag(BASIC_C_CXX_FLAGS "/Za" ${USE_C_ANSI_STANDARD} OFF)
  add_flag(BASIC_C_CXX_FLAGS "/Za" ${USE_CXX_ANSI_STANDARD} OFF)

  add_flag(C_CXX_MEM_FLAGS "/Os" ON OFF)

  add_flag(C_CXX_OPT_FLAGS "/Ox" ON OFF)

  add_flag(C_CXX_DEB_FLAGS "/Gs" ON OFF)
  add_flag(C_CXX_DEB_FLAGS "/GZ" ON OFF)
  add_flag(C_CXX_DEB_FLAGS "/Wp64" ON OFF)
  add_flag(C_CXX_DEB_FLAGS "/Zi" ON OFF)

  #####################################################
  # C
  #####################################################


  #####################################################
  # C++
  #####################################################


endif(MSVC OR MSVC_IDE OR MSVC60 OR MSVC70 OR MSVC71 OR MSVC80 OR CMAKE_COMPILER_2005 OR MSVC90)
