############################################################
# FindBazaar.cmake
############################################################
#
# @author Francesco Stefanni
#


#
# Locates Bazaar.
#
# Sets:
# - BZR_FOUND
# - BZR_EXECUTABLE
# - get_bzr_revno <dir>: BZR_REV_VERSION & IS_BZR_PROJECT
#

SET(BZR_FOUND FALSE)

FIND_PROGRAM(BZR_EXECUTABLE bzr
  DOC "bazaar command line client")
MARK_AS_ADVANCED(BZR_EXECUTABLE)

IF(BZR_EXECUTABLE)
  SET(BZR_FOUND TRUE)

  MACRO(get_bzr_revno dir )

    execute_process(
      COMMAND ${BZR_EXECUTABLE} revno
      WORKING_DIRECTORY ${dir}
      OUTPUT_VARIABLE BZR_REV_VERSION
      ERROR_VARIABLE BZR_REV_ERROR
      OUTPUT_STRIP_TRAILING_WHITESPACE)

    if(BZR_REV_ERROR)
      SET(IS_BZR_PROJECT FALSE)
    else()
      SET(IS_BZR_PROJECT TRUE)
    endif()

  ENDMACRO(get_bzr_revno)
ENDIF(BZR_EXECUTABLE)
