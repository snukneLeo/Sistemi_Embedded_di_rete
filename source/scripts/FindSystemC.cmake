############################################################
# FindSystemC.cmake
############################################################
#
# @author Francesco Stefanni
#
#
# Finds SystemC.
#

############################################################
# Functions:
############################################################

function(find_systemc LIB INCLUDE_PATH)
  find_library(${LIB} systemc)
  find_path(${INCLUDE_PATH} systemc)
  if(NOT ${LIB})
    message(FATAL_ERROR "SystemC library not found.")
  endif(NOT ${LIB})
  if(NOT ${INCLUDE_PATH})
    message(FATAL_ERROR "SystemC library headers not found.")
  endif(NOT ${INCLUDE_PATH})
endfunction(find_systemc)

function(find_systemc_tlm INCLUDE_PATH)
  find_path(${INCLUDE_PATH} tlm.h)
  if(NOT ${INCLUDE_PATH})
    message(FATAL_ERROR "SystemC TLM library headers not found.")
  endif(NOT ${INCLUDE_PATH})
endfunction(find_systemc_tlm)


# EOF
