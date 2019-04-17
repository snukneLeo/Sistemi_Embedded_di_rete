# - EDALab utility to find and build Latex documentation.
#
# Provided user options:
#   DOC_LATEX_COMPILER_FLAGS
#   DOC_LATEX_DVIPS_FLAGS
#   DOC_LATEX_PS2PDF_FLAGS
#   DOC_LATEX_BIBTEX_FLAGS
#
# Provided functions:
#  edalab_latex_add_target() - Adds a latex documentation target.
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

# Under Windows shell, the syntax of equal symbol for parameters of ps2pdf is different:
# setting the appropriate symbol:
if("${CMAKE_SYSTEM_NAME}" STREQUAL "Windows")
  set(EdalabLatex_EQUAL_SYMBOL "\#" CACHE INTERNAL
    "The equal symbol for ps2pdf parameters, according with the OS.")
else("${CMAKE_SYSTEM_NAME}" STREQUAL "Windows")
  set(EdalabLatex_EQUAL_SYMBOL "=" CACHE INTERNAL
    "The equal symbol for ps2pdf parameters, according with the OS.")
endif("${CMAKE_SYSTEM_NAME}" STREQUAL "Windows")


set(DOC_LATEX_COMPILER_FLAGS
  -interaction=batchmode -halt-on-error -src -src-specials -file-line-error -parse-first-line
  CACHE STRING "Latex command options.")

set(DOC_LATEX_DVIPS_FLAGS
  -P pdf -Pdownload35 -D 8000 -R0 -z -G0
  CACHE STRING "dvips command options.")

set(DOC_LATEX_PS2PDF_FLAGS
  -dCompatibilityLevel${EdalabLatex_EQUAL_SYMBOL}1.4 -dMAxSubsetPct${EdalabLatex_EQUAL_SYMBOL}100 -dSubsetFonts${EdalabLatex_EQUAL_SYMBOL}true -dEmbedAllFonts${EdalabLatex_EQUAL_SYMBOL}true -dCompressFonts${EdalabLatex_EQUAL_SYMBOL}true
  CACHE STRING "ps2pdf command options.")

set(DOC_LATEX_BIBTEX_FLAGS
  -terse
  CACHE STRING "Bibtex command options.")

mark_as_advanced(DOC_LATEX_COMPILER_FLAGS DOC_LATEX_DVIPS_FLAGS DOC_LATEX_PS2PDF_FLAGS DOC_LATEX_BIBTEX_FLAGS)


# ###########################################################################
# Configuration.
# ###########################################################################

# Setting standard vars:
set(EdalabLatex_VERSION_MAJOR 1)
set(EdalabLatex_VERSION_MINOR 0)
set(EdalabLatex_VERSION_PATCH 0)
set(EdalabLatex_VERSION_STRING "FindEdalabLatex.cmake verison: ${EdalabLatex_VERSION_MAJOR}.${EdalabLatex_VERSION_MINOR}.${EdalabLatex_VERSION_PATCH}.")

# Setting up search mode:
set(EdalabLatex_SEARCH_MODE "")
if(EdalabLatex_FIND_REQUIRED)
  set(EdalabLatex_SEARCH_MODE "REQUIRED")
elseif(EdalabLatex_FIND_QUIETLY)
  set(EdalabLatex_SEARCH_MODE "QUIET")
endif()

# Under Windows, policy seems to not work otherwise:
if(POLICY CMP0054)
  cmake_policy(SET CMP0054 NEW)
endif(POLICY CMP0054)

# Loading dependencies:
find_package(EdalabBase ${EdalabLatex_SEARCH_MODE})
find_package(LATEX ${EdalabLatex_SEARCH_MODE})
if(NOT PS2PDF_CONVERTER)
  # @TODO Woraround for windows...
  # Standard Latex module seems bugged...
  set(PS2PDF_CONVERTER ps2pdf CACHE INTERNAL "Windows workaround." FORCE)
endif(NOT PS2PDF_CONVERTER)
find_package_handle_standard_args(EdalabLatex DEFAULT_MSG
  LATEX_COMPILER
  BIBTEX_COMPILER
  DVIPS_CONVERTER
  PS2PDF_CONVERTER
  EDALABBASE_FOUND
)

# Module configuration:
if(EDALABLATEX_FOUND)

  # Module initialization:
  edalab_initialize_module("EdalabLatex" "${EdalabLatex_SEARCH_MODE}")

endif(EDALABLATEX_FOUND)


# ###########################################################################
# Support functions.
# ###########################################################################


# ###########################################################################
# Functions.
# ###########################################################################


## @brief Adds a target which compiles a latex source and generates a PDF via DVI -> PS -> PDF.
##
## @param TARGET {String} The target name.
## @param IN {String} Main input file name, without extension.
## @param IN_DIR {Path} The path to the input file.
## @param OUT_DIR {Path} The path where to generate the output.
## @optional BIBTEX to use also BibTEX. Must be followed by the name of the bibtex source file, without extension.
## @optional UNFORMATTED to avoid forcing of A4 format.
## @optional NODOC to avoid the adding of this target as dependency of doc target.
##
function(edalab_latex_add_target TARGET IN IN_DIR OUT_DIR )

  # OUT_DIR can be relative, and in this case, by default,
  # it will be relative to IN_DIR, since we *must* use IN_DIR as WORKING DIRECTORY.
  # Fixing this, making it relative to CMAKE_CURRENT_BINARY_DIR,
  # which is the expected default behavior.
  if(IS_ABSOLUTE "${OUT_DIR}")
  else(IS_ABSOLUTE "${OUT_DIR}")
    set(OUT_DIR "${CMAKE_CURRENT_BINARY_DIR}/${OUT_DIR}")
  endif(IS_ABSOLUTE "${OUT_DIR}")

  # Options checking:
  set(BIBTEX OFF)
  set(BIBTEXPARAM OFF)
  set(BIBTEXFILE "")
  set(UNFORMATTED OFF)
  set(NODOC OFF)
  foreach(i ${ARGN})
    if("${i}" STREQUAL "BIBTEX")
      set(BIBTEX ON)
      set(BIBTEXPARAM ON)
    elseif("${i}" STREQUAL "UNFORMATTED")
      set(UNFORMATTED ON)
    elseif("${i}" STREQUAL "NODOC")
      set(NODOC ON)
    elseif(BIBTEXPARAM)
      set(BIBTEXFILE "${i}")
      set(BIBTEXPARAM OFF)
    else()
      # error:
      edalab_error_message("[EdalabLatex] Unrecognized option: ${i}.")
    endif()
  endforeach(i)

  if(BIBTEX AND ("${BIBTEXFILE}" STREQUAL ""))
      # error:
      edalab_error_message("[EdalabLatex] Unspecified BibTEX source file.")
  endif(BIBTEX AND ("${BIBTEXFILE}" STREQUAL ""))

  if(UNFORMATTED)
    set(DVIPS_EXTRA )
    set(PSPDF_EXTRA )
  else(UNFORMATTED)
    set(DVIPS_EXTRA -t a4)
    set(PSPDF_EXTRA -sPAPERSIZE${EdalabLatex_EQUAL_SYMBOL}a4)
  endif(UNFORMATTED)

  # Adding support commands, assuring also target dir:

  add_custom_command(
    OUTPUT  ${OUT_DIR}/${IN}.aux
    DEPENDS ${IN_DIR}/${IN}.tex
    COMMAND ${CMAKE_COMMAND} -E make_directory ${OUT_DIR}
    COMMAND ${LATEX_COMPILER} ${DOC_LATEX_COMPILER_FLAGS} -output-directory=${OUT_DIR} ${IN_DIR}/${IN}.tex
    WORKING_DIRECTORY ${IN_DIR}
    COMMENT "Latex (first pass): ${IN_DIR}/${IN}.tex --> ${OUT_DIR}/${IN}.aux"
    )

  set(BIBTEX_DEP )
  if(BIBTEX)
    set(BIBTEX_DEP ${OUT_DIR}/${IN}.bbl)
    add_custom_command(
      OUTPUT  ${OUT_DIR}/${IN}.bbl
      DEPENDS ${OUT_DIR}/${IN}.aux
      COMMAND ${CMAKE_COMMAND} -E copy ${IN_DIR}/${BIBTEXFILE}.bib ${OUT_DIR}
      COMMAND ${BIBTEX_COMPILER} ${DOC_LATEX_BIBTEX_FLAGS} ${IN}.aux
      WORKING_DIRECTORY ${OUT_DIR}
      COMMENT "Bibtex"
      )
  endif(BIBTEX)

  add_custom_command(
    OUTPUT    ${OUT_DIR}/${IN}.log
    DEPENDS   ${BIBTEX_DEP} ${OUT_DIR}/${IN}.aux
    COMMAND   ${LATEX_COMPILER} ${DOC_LATEX_COMPILER_FLAGS} -output-directory=${OUT_DIR} ${IN_DIR}/${IN}.tex
    WORKING_DIRECTORY ${IN_DIR}
    COMMENT   "Latex (second pass)"
    )

  add_custom_command(
    OUTPUT    ${OUT_DIR}/${IN}.dvi
    DEPENDS   ${BIBTEX_DEP} ${OUT_DIR}/${IN}.log
    COMMAND   ${LATEX_COMPILER} ${DOC_LATEX_COMPILER_FLAGS} -output-directory=${OUT_DIR} ${IN_DIR}/${IN}.tex
    WORKING_DIRECTORY ${IN_DIR}
    COMMENT   "Latex (third pass)"
    )

  add_custom_command(
    OUTPUT  ${OUT_DIR}/${TARGET}.ps
    DEPENDS ${OUT_DIR}/${IN}.dvi
    COMMAND ${DVIPS_CONVERTER} ${DVIPS_EXTRA} ${DOC_LATEX_DVIPS_FLAGS} -o ${OUT_DIR}/${TARGET}.ps ${OUT_DIR}/${IN}.dvi
    WORKING_DIRECTORY ${IN_DIR}
    COMMENT "dvi2ps"
    )

  add_custom_command(
    OUTPUT  ${OUT_DIR}/${TARGET}.pdf
    DEPENDS ${OUT_DIR}/${TARGET}.ps
    COMMAND ${PS2PDF_CONVERTER} ${PS2PDF_EXTRA} ${DOC_LATEX_PS2PDF_FLAGS} ${OUT_DIR}/${TARGET}.ps ${OUT_DIR}/${TARGET}.pdf
    WORKING_DIRECTORY ${IN_DIR}
    COMMENT "ps2pdf"
    )

  # Adding target:
  add_custom_target(${TARGET} echo
    DEPENDS  ${OUT_DIR}/${TARGET}.pdf
    )
  # Custom targets do not set the OUTPUT_NAME property.
  # Let's set it to be able to correctly install the target.
  set_target_properties(${TARGET} PROPERTIES OUTPUT_NAME "${OUT_DIR}/${TARGET}.pdf")

  # Eventually adding dependency to doc target:
  if(NOT NODOC)
    add_dependencies(doc ${TARGET})
  endif(NOT NODOC)


endfunction(edalab_latex_add_target)

# EOF
