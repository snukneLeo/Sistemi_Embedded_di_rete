#############################################
# General install config.
#############################################
#
# @author Francesco Stefanni
#


#############################################
# Basic installs.
#############################################


# Install for basic headers.
# install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/include
#   DESTINATION .
#   FILES_MATCHING PATTERN "*.h"
#   PATTERN "*.hh"
#   PATTERN "*.hpp"
#   PATTERN "*.H"
#   PATTERN "*.HH"
#   PATTERN "*.i"
#   PATTERN "*.ii"
#   PATTERN ".svn" EXCLUDE
#   )

# # Install for doc.
# install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/doc ${CMAKE_CURRENT_SOURCE_DIR}/doc
#   DESTINATION .
#   OPTIONAL
#   )


#############################################
# Commands.
#############################################

function(add_install_doc_directories )
  install(DIRECTORY ${ARGV}
    DESTINATION .
    OPTIONAL
    )
endfunction(add_install_doc_directories)

function(add_install_doc_files )
  install(FILES ${ARGV}
    DESTINATION doc
    )
endfunction(add_install_doc_files)

function(add_install_doc_targets )
  install(TARGETS ${ARGV}
    DESTINATION doc
    )
endfunction(add_install_doc_targets)

function(add_install_exe_targets )
  install(TARGETS ${ARGV}
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    )
endfunction(add_install_exe_targets)

function(add_install_header_directories )
  install(DIRECTORY ${ARGV}
    DESTINATION .
    FILES_MATCHING PATTERN "*.h"
    PATTERN "*.hh"
    PATTERN "*.hpp"
    PATTERN "*.hxx"
    PATTERN "*.H"
    PATTERN "*.HH"
    PATTERN "*.i"
    PATTERN "*.ii"
    PATTERN ".svn" EXCLUDE
    )
endfunction(add_install_header_directories)

function(add_install_library_targets )
  install(TARGETS ${ARGV}
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    )
endfunction(add_install_library_targets)

# EOF
