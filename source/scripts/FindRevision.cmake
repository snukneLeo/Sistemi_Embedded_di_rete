############################################################
# FindRevision.cmake
############################################################
#
# @author Francesco Stefanni
#

#
# Finds the revision of a project.
#
# find_revision( DIR result )
#

###################################################
# FindRevision
###################################################

function(find_revision DIR result)

  find_package(CVS)
  if(CVS_FOUND)

    # ???
    # CVS Has per-file revision.
    # I do not know the command to extract the version...

  endif(CVS_FOUND)

  find_package(Subversion)
  if(SUBVERSION_FOUND)
    # Svn function has a bug:
    # it is impossible to test if there is a dir.
    if(EXISTS "${DIR}/.svn")
      Subversion_WC_INFO(${DIR} Project)
      SET(SVN_REV_VERSION ${Project_WC_REVISION})
    else()
      SET(${Project_WC_REVISION} FALSE)
    endif()
  endif(SUBVERSION_FOUND)



  find_package(Git)
  if(GIT_FOUND)

    # Git does not have ID's...
    # Try with SHA1

    execute_process(
      COMMAND ${GIT_EXECUTABLE} rev-parse HEAD
      WORKING_DIRECTORY ${DIR}
      OUTPUT_VARIABLE GIT_REV_VERSION
      ERROR_VARIABLE GIT_REV_ERROR
      OUTPUT_STRIP_TRAILING_WHITESPACE)

    if(GIT_REV_ERROR)
      SET(GIT_REV_VERSION FALSE)
    endif()

  endif()

  find_package(Bazaar)
  if(BZR_FOUND)
    get_bzr_revno(${DIR})
  endif(BZR_FOUND)

  # For Hg, should work something like:
  # either: hg head
  # or: hg parents
  # followed by a portable: grep changeset | sed -e "s/changeset *//g" | sed -e "s/:.*//g"

  # Setting the output:
  if (${Project_WC_REVISION})
    SET(${result} ${Project_WC_REVISION} PARENT_SCOPE)
  elseif( GIT_REV_VERSION )
    SET(${result} ${GIT_REV_VERSION} PARENT_SCOPE)
  elseif( IS_BZR_PROJECT )
    SET(${result} ${BZR_REV_VERSION} PARENT_SCOPE)
  else()
    SET(${result} FALSE PARENT_SCOPE)
  endif()

endfunction(find_revision)
