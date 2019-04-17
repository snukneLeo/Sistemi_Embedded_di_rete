#####################################################
# GCC CMake file definitions.
#####################################################
#
# @author Francesco Stefanni
#
# Written by using gcc 4.6.0 docs.
# Tested flags under gcc 4.4.4.
#
# Input options:
# - COMPILER_WARNINGS_AS_ERRORS
# - COMPILER_FATAL_ERRORS
# - COMPILER_VISIBILITY
# - USE_C_ANSI_STANDARD
# - USE_CXX_ANSI_STANDARD
# - USE_CXX_0X_STANDARD
#





if(CMAKE_COMPILER_IS_GNUCC OR CMAKE_COMPILER_IS_GNUCXX)

  #####################################################
  # C & C++
  #####################################################

  # add_flag(BASIC_C_CXX_FLAGS "-Waggregate-return" ON OFF)
  add_flag(BASIC_C_CXX_FLAGS "-Wall" ON OFF)
  add_flag(BASIC_C_CXX_FLAGS "-Wcast-align" ON OFF)
  add_flag(BASIC_C_CXX_FLAGS "-Wcast-qual" ON OFF)
  add_flag(BASIC_C_CXX_FLAGS "-Wconversion" ON OFF)
  add_flag(BASIC_C_CXX_FLAGS "-Wsign-conversion" ON OFF)
  add_flag(BASIC_C_CXX_FLAGS "-Wdouble-promotion" ON "C_CXX")
  add_flag(BASIC_C_CXX_FLAGS "-Wendif-labels" ON OFF)
  add_flag(BASIC_C_CXX_FLAGS "-Wextra" ON OFF)
  add_flag(BASIC_C_CXX_FLAGS "-Wfloat-equal" ON OFF)
  add_flag(BASIC_C_CXX_FLAGS "-Wformat=2" ON OFF)
  add_flag(BASIC_C_CXX_FLAGS "-Wformat-nonliteral" ON OFF)
  add_flag(BASIC_C_CXX_FLAGS "-Wformat-security" ON OFF)
  add_flag(BASIC_C_CXX_FLAGS "-Wformat-y2k" ON OFF)
  add_flag(BASIC_C_CXX_FLAGS "-Winit-self" ON OFF)
  add_flag(BASIC_C_CXX_FLAGS "-Wlogical-op" ON OFF)
  add_flag(BASIC_C_CXX_FLAGS "-Wmissing-format-attribute" ON OFF)
  add_flag(BASIC_C_CXX_FLAGS "-Wno-long-long" ON OFF)
  add_flag(BASIC_C_CXX_FLAGS "-Wno-variadic-macros" ON OFF)
  add_flag(BASIC_C_CXX_FLAGS "-Wredundant-decls" ON OFF)
  add_flag(BASIC_C_CXX_FLAGS "-Wshadow" ON OFF)
  add_flag(BASIC_C_CXX_FLAGS "-Wstack-protector" ON OFF)
  add_flag(BASIC_C_CXX_FLAGS "-Wstrict-aliasing=3" ON OFF)
  add_flag(BASIC_C_CXX_FLAGS "-Wstrict-overflow=5" ON OFF)
  add_flag(BASIC_C_CXX_FLAGS "-Wswitch-default" ON OFF)
  add_flag(BASIC_C_CXX_FLAGS "-Wswitch-enum" ON OFF)
  add_flag(BASIC_C_CXX_FLAGS "-Wtrampolines" ON "C_CXX")
  add_flag(BASIC_C_CXX_FLAGS "-Wundef" ON OFF)
  add_flag(BASIC_C_CXX_FLAGS "-Wunknown-pragmas" ON OFF)
  add_flag(BASIC_C_CXX_FLAGS "-Wunsafe-loop-optimizations" ON OFF)
  add_flag(BASIC_C_CXX_FLAGS "-Wunused" ON OFF)
  add_flag(BASIC_C_CXX_FLAGS "-Wunused-macros" ON OFF)
  add_flag(BASIC_C_CXX_FLAGS "-Wunused-parameter" ON OFF)
  add_flag(BASIC_C_CXX_FLAGS "-Wwrite-strings" ON OFF)

  #### Options:

  add_flag(BASIC_C_CXX_FLAGS "-Werror" ${COMPILER_WARNINGS_AS_ERRORS} OFF)
  add_flag(BASIC_C_CXX_FLAGS "-Wfatal-error" ${COMPILER_FATAL_ERRORS} OFF)
  add_flag(BASIC_C_CXX_FLAGS "-fvisibility=hidden" ${COMPILER_VISIBILITY} OFF)

  #### Other flags:

  add_flag(C_CXX_MEM_FLAGS "-Wpacked" ON OFF)
  add_flag(C_CXX_MEM_FLAGS "-Wpadded" ON OFF)
  add_flag(C_CXX_MEM_FLAGS "-Winline" ON OFF)
  add_flag(C_CXX_MEM_FLAGS "-Os" ON OFF)

  add_flag(C_CXX_OPT_FLAGS "-O3" ON OFF)
  add_flag(C_CXX_OPT_FLAGS "-Winline" ON OFF)

  add_flag(C_CXX_DEB_FLAGS "-ggdb" ON OFF)
  add_flag(C_CXX_DEB_FLAGS "-pg" ON OFF)

  #####################################################
  # C
  #####################################################

  add_flag(BASIC_C_FLAGS "-Wbad-function-cast" ON OFF)
  add_flag(BASIC_C_FLAGS "-Wc++-compat" ON OFF)
  add_flag(BASIC_C_FLAGS "-Wdeclaration-after-statement" ON OFF)
  add_flag(BASIC_C_FLAGS "-Wmissing-declarations" ON OFF)
  add_flag(BASIC_C_FLAGS "-Wmissing-prototypes" ON OFF)
  add_flag(BASIC_C_FLAGS "-Wnested-externs" ON OFF)
  add_flag(BASIC_C_FLAGS "-Wold-style-definition" ON OFF)
  add_flag(BASIC_C_FLAGS "-Wstrict-prototypes" ON OFF)
  add_flag(BASIC_C_FLAGS "-Wtraditional-conversion" ON OFF)
  add_flag(BASIC_C_FLAGS "-Wunsuffixed-float-constants" ON OFF)

  # add_flag(C_MEM_FLAGS )

  # add_flag(C_OPT_FLAGS )

  # add_flag(C_DEB_FLAGS )

  #### Options:

  add_flag(BASIC_C_FLAGS "-ansi" ${USE_C_ANSI_STANDARD} ON)
  add_flag(BASIC_C_FLAGS "-pedantic" ${USE_C_ANSI_STANDARD} ON)


  #####################################################
  # C++
  #####################################################

  add_flag(BASIC_CXX_FLAGS "-fno-gnu-keywords" ON OFF)
  add_flag(BASIC_CXX_FLAGS "-Wctor-dtor-privacy" ON OFF)
  add_flag(BASIC_CXX_FLAGS "-Weffc++" ON OFF)
  add_flag(BASIC_CXX_FLAGS "-Wold-style-cast" ON OFF)
  add_flag(BASIC_CXX_FLAGS "-Woverloaded-virtual" ON OFF)
  add_flag(BASIC_CXX_FLAGS "-Wsign-promo" ON OFF)
  add_flag(BASIC_CXX_FLAGS "-Wstrict-null-sentinel" ON OFF)

  add_flag(CXX_MEM_FLAGS "-fno-implicit-templates" ON OFF)
  add_flag(CXX_MEM_FLAGS "-fno-implicit-inline-templates" ON OFF)
  add_flag(CXX_MEM_FLAGS "-fno-implement-inlines" ON OFF)

  add_flag(CXX_OPT_FLAGS "-fstrict-enums" ON "CXX")

  # add_flag(CXX_DEB_FLAGS  ON OFF)

  #### Options:

  add_flag(BASIC_CXX_FLAGS "-ansi" ${USE_CXX_ANSI_STANDARD} OFF)
  add_flag(BASIC_CXX_FLAGS "-pedantic" ${USE_CXX_ANSI_STANDARD} OFF)

  add_flag(BASIC_CXX_FLAGS "-std=c++0x" ${USE_CXX_0X_STANDARD} OFF)
  add_flag(BASIC_CXX_FLAGS "-pedantic" ${USE_CXX_0X_STANDARD} OFF)
  add_flag(BASIC_CXX_FLAGS "-fnothrow-opt" ${USE_CXX_0X_STANDARD} ON)

endif(CMAKE_COMPILER_IS_GNUCC OR CMAKE_COMPILER_IS_GNUCXX)
