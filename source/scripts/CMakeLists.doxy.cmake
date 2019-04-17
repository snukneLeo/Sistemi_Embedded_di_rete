#############################################
# General doxygen config.
#############################################
#
# @author Francesco Stefanni
#
# Provides:
# - target doxygen as required target by doc (DOC_TARGET).

#############################################
# User options.
#############################################


option(DOXYGEN_IS_REQUIRED "Doxygen documentation generation is a required feature." OFF)
mark_as_advanced(FORCE DOXYGEN_IS_REQUIRED)

# Adding the kind of doc option.
option(DOXIGEN_GENERATE_DEVELOPERS_DOC "Generates Doxygen docs with developers configuration." OFF)
mark_as_advanced(FORCE DOXIGEN_GENERATE_DEVELOPERS_DOC)


#############################################
# Module code.
#############################################

# Workaround for Cmake < 2.8.3
set_list_dir(${CMAKE_CURRENT_LIST_FILE})

# Checking if doxygen is installed:
find_package(Doxygen)

if (DOXYGEN_FOUND STREQUAL "NO")
  if (DOXYGEN_IS_REQUIRED)
    message(FATAL_ERROR "Doxygen not found.")
  else (DOXYGEN_IS_REQUIRED)
    message(WARNING "Doxygen not found.")
  endif (DOXYGEN_IS_REQUIRED)
else (DOXYGEN_FOUND STREQUAL "NO")

  # Prepare doxygen configuration file
  if (DOXIGEN_GENERATE_DEVELOPERS_DOC STREQUAL "NO")
    # configure_file(${CMAKE_CURRENT_SOURCE_DIR}/extra/Doxyfile.in ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile)
    configure_file(${CMAKE_CURRENT_LIST_DIR}/../extra/Doxyfile.in ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile)
  else(DOXIGEN_GENERATE_DEVELOPERS_DOC STREQUAL "NO")
    # configure_file(${CMAKE_CURRENT_SOURCE_DIR}/extra/Doxyfile.dev.in ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile)
    configure_file(${CMAKE_CURRENT_LIST_DIR}/../extra/Doxyfile.dev.in ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile)
  endif(DOXIGEN_GENERATE_DEVELOPERS_DOC STREQUAL "NO")

  # Add doxygen as target
  add_custom_target(doxygen ${DOXYGEN_EXECUTABLE} ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile)

  # Cleanup $build/doc on "make clean"
  set_property(DIRECTORY APPEND PROPERTY ADDITIONAL_MAKE_CLEAN_FILES doc)

  # Add doxygen as dependency to doc-target
  get_target_property(DOC_TARGET doc TYPE)
  if(NOT DOC_TARGET)
    add_custom_target(doc)
  endif(NOT DOC_TARGET)
  add_dependencies(doc doxygen)

endif(DOXYGEN_FOUND STREQUAL "NO")
