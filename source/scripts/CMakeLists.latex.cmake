############################################################
# CMakeLists.latex.cmake
############################################################
#
# @author Francesco Stefanni
#
# Provides Latex commands.
#

############################################################
# Finding Latex
############################################################

find_program(LATEX_COMPILER latex
  PATHS $ENV{ProgramFiles}/MiKTeX\ 2.9/miktex/bin
  )

find_program(LATEX_BIBTEX_COMPILER bibtex
  PATHS $ENV{ProgramFiles}/MiKTeX\ 2.9/miktex/bin
  )

find_program(LATEX_DVIPS_CONVERTER dvips
  PATHS $ENV{ProgramFiles}/MiKTeX\ 2.9/miktex/bin
  )

find_program(LATEX_PS2PDF_CONVERTER ps2pdf
  PATHS $ENV{ProgramFiles}/MiKTeX\ 2.9/miktex/bin
  )

mark_as_advanced(LATEX_COMPILER LATEX_BIBTEX_COMPILER LATEX_DVIPS_CONVERTER LATEX_PS2PDF_CONVERTER)

############################################################
# Options
############################################################

option(LATEX_IS_REQUIRED "Latex is required." OFF)
option(LATEX_BIBTEX_IS_REQUIRED "Bibtex is required." OFF)
option(LATEX_DVIPS_IS_REQUIRED "dvips is required." OFF)
option(LATEX_PS2PDF_IS_REQUIRED "ps2pdf is required." OFF)
mark_as_advanced(LATEX_IS_REQUIRED
  LATEX_BIBTEX_IS_REQUIRED
  LATEX_DVIPS_IS_REQUIRED
  LATEX_PS2PDF_IS_REQUIRED)

############################################################
# Cheks
############################################################

if(LATEX_IS_REQUIRED)
  if(NOT LATEX_COMPILER)
    message(FATAL_ERROR "Latex not found, but required.")
  endif(NOT LATEX_COMPILER)
endif(LATEX_IS_REQUIRED)

if(LATEX_BIBTEX_IS_REQUIRED)
  if(NOT LATEX_BIBTEX_COMPILER)
    message(FATAL_ERROR "Bibtex not found, but required.")
  endif(NOT LATEX_BIBTEX_COMPILER)
endif(LATEX_BIBTEX_IS_REQUIRED)

if(LATEX_DVIPS_IS_REQUIRED)
  if(NOT LATEX_DVIPS_CONVERTER)
    message(FATAL_ERROR "Dvips not found, but required.")
  endif(NOT LATEX_DVIPS_CONVERTER)
endif(LATEX_DVIPS_IS_REQUIRED)

if(LATEX_PS2PDF_IS_REQUIRED)
  if(NOT LATEX_PS2PDF_CONVERTER)
    message(FATAL_ERROR "Ps2pdf not found, but required.")
  endif(NOT LATEX_PS2PDF_CONVERTER)
endif(LATEX_PS2PDF_IS_REQUIRED)


############################################################
# Configuration
############################################################

if(${CMAKE_SYSTEM_NAME} STREQUAL "Windows")
SET(EQ \# CACHE INTERNAL "")
else(${CMAKE_SYSTEM_NAME} STREQUAL "Windows")
SET(EQ = CACHE INTERNAL "")
endif(${CMAKE_SYSTEM_NAME} STREQUAL "Windows")


############################################################
# Support functions
############################################################

# Used to generate a target with suitable dependencies.
function(latex_generate_target TARGETNAME)

  if(LATEX_PS2PDF_CONVERTER)

    add_custom_target(${TARGETNAME} echo
      DEPENDS  ${OUT_DIR}/${OUT}.pdf
      )

  else(LATEX_PS2PDF_CONVERTER)

    if(LATEX_DVIPS_CONVERTER)
      add_custom_target(${TARGETNAME} echo
	DEPENDS ${OUT_DIR}/${OUT}.ps
	)

    else(LATEX_DVIPS_CONVERTER)

      # Only LATEX_COMPILER found.
      add_custom_target(${TARGETNAME} echo
	DEPENDS ${OUT_DIR}/${OUT}.log
	)

    endif(LATEX_DVIPS_CONVERTER)
  endif(LATEX_PS2PDF_CONVERTER)

  add_dependencies(doc ${TARGETNAME})

endfunction(latex_generate_target)

############################################################
# Commands
############################################################

#
# Adds a target which compiles a latex source with A4 format.
#
function(add_latex TARGETNAME IN OUT IN_DIR OUT_DIR BIBTEX)

  if(LATEX_COMPILER)

    file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/${OUT} ${OUT_DIR})

    add_custom_command(
      OUTPUT    ${CMAKE_CURRENT_BINARY_DIR}/${OUT}/${IN}.aux
      DEPENDS   ${IN_DIR}/${IN}.tex
      COMMAND   ${LATEX_COMPILER} -interaction=batchmode -halt-on-error -src -src-specials -file-line-error -parse-first-line -output-directory=${CMAKE_CURRENT_BINARY_DIR}/${OUT}/ ${IN_DIR}/${IN}.tex
      WORKING_DIRECTORY ${IN_DIR}
      COMMENT   "Latex (first pass): ${IN_DIR}/${IN}.tex --> ${OUT_DIR}/${IN}.aux"
      )

    SET(BIBTEX_DEP )
    if(LATEX_BIBTEX_COMPILER AND BIBTEX)
      SET(BIBTEX_DEP ${CMAKE_CURRENT_BINARY_DIR}/${OUT}/${IN}.bbl)
      add_custom_command(
	OUTPUT    ${CMAKE_CURRENT_BINARY_DIR}/${OUT}/${IN}.bbl
	DEPENDS   ${CMAKE_CURRENT_BINARY_DIR}/${OUT}/${IN}.aux
	COMMAND   ${LATEX_BIBTEX_COMPILER} -terse ${CMAKE_CURRENT_BINARY_DIR}/${OUT}/${IN}.aux
	WORKING_DIRECTORY ${IN_DIR}
	COMMENT   "Bibtex"
	)
    endif(LATEX_BIBTEX_COMPILER AND BIBTEX)

    add_custom_command(
      OUTPUT    ${CMAKE_CURRENT_BINARY_DIR}/${OUT}/${IN}.log
      DEPENDS   ${BIBTEX_DEP} ${CMAKE_CURRENT_BINARY_DIR}/${OUT}/${IN}.aux
      COMMAND   ${LATEX_COMPILER} -interaction=batchmode -halt-on-error -src -src-specials -file-line-error -parse-first-line -output-directory=${CMAKE_CURRENT_BINARY_DIR}/${OUT}/ ${IN_DIR}/${IN}.tex
      WORKING_DIRECTORY ${IN_DIR}
      COMMENT   "Latex (second pass)"
      )

    add_custom_command(
      OUTPUT    ${CMAKE_CURRENT_BINARY_DIR}/${OUT}/${IN}.dvi
      DEPENDS   ${BIBTEX_DEP} ${CMAKE_CURRENT_BINARY_DIR}/${OUT}/${IN}.log
      COMMAND   ${LATEX_COMPILER} -interaction=batchmode -halt-on-error -src -src-specials -file-line-error -parse-first-line -output-directory=${CMAKE_CURRENT_BINARY_DIR}/${OUT}/ ${IN_DIR}/${IN}.tex
      WORKING_DIRECTORY ${IN_DIR}
      COMMENT   "Latex (third pass)"
      )

    if(LATEX_DVIPS_CONVERTER)
      add_custom_command(
	OUTPUT    ${CMAKE_CURRENT_BINARY_DIR}/${OUT}/${OUT}.ps
	DEPENDS   ${CMAKE_CURRENT_BINARY_DIR}/${OUT}/${IN}.dvi
	COMMAND   ${LATEX_DVIPS_CONVERTER} -P pdf -Pdownload35 -D 8000 -R0 -z -G0 -t a4 -o ${CMAKE_CURRENT_BINARY_DIR}/${OUT}/${OUT}.ps ${CMAKE_CURRENT_BINARY_DIR}/${OUT}/${IN}.dvi
	WORKING_DIRECTORY ${IN_DIR}
	COMMENT   "dvi2ps"
	)

      if(LATEX_PS2PDF_CONVERTER)
	add_custom_command(
	  OUTPUT    ${OUT_DIR}/${OUT}.pdf
	  DEPENDS   ${CMAKE_CURRENT_BINARY_DIR}/${OUT}/${OUT}.ps
	  COMMAND   ${LATEX_PS2PDF_CONVERTER} -sPAPERSIZE${EQ}a4 -dPDFSETTINGS${EQ}/prepress -dCompatibilityLevel${EQ}1.4 -dMAxSubsetPct${EQ}100 -dSubsetFonts${EQ}true -dEmbedAllFonts${EQ}true -dCompressFonts${EQ}true ${CMAKE_CURRENT_BINARY_DIR}/${OUT}/${OUT}.ps ${OUT_DIR}/${OUT}.pdf
	  WORKING_DIRECTORY ${IN_DIR}
	  COMMENT   "ps2pdf"
	  )

      endif(LATEX_PS2PDF_CONVERTER)
    endif(LATEX_DVIPS_CONVERTER)
  endif(LATEX_COMPILER)

  latex_generate_target(${TARGETNAME})

endfunction(add_latex)


#
# Adds a target which compiles a latex source, in any format.
#
function(add_unformatted_latex TARGETNAME IN OUT IN_DIR OUT_DIR BIBTEX)

  # copy & paste of add_latex, but without:
  # - dvips: -t a4
  # - ps2pdf: -sPAPERSIZE=a4

  if(LATEX_COMPILER)

    file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/${OUT} ${OUT_DIR})

    add_custom_command(
      OUTPUT    ${CMAKE_CURRENT_BINARY_DIR}/${OUT}/${IN}.aux
      DEPENDS   ${IN_DIR}/${IN}.tex
      COMMAND   ${LATEX_COMPILER} -interaction=batchmode -halt-on-error -src -src-specials -file-line-error -parse-first-line -output-directory=${CMAKE_CURRENT_BINARY_DIR}/${OUT}/${IN}.tex
      WORKING_DIRECTORY ${IN_DIR}
      COMMENT   "Latex (first pass)"
      )

    SET(BIBTEX_DEP )
    if(LATEX_BIBTEX_COMPILER AND BIBTEX)
      SET(BIBTEX_DEP ${CMAKE_CURRENT_BINARY_DIR}/${OUT}/${IN}.bbl)
      add_custom_command(
	OUTPUT    ${CMAKE_CURRENT_BINARY_DIR}/${OUT}/${IN}.bbl
	DEPENDS   ${CMAKE_CURRENT_BINARY_DIR}/${OUT}/${IN}.aux
	COMMAND   ${LATEX_BIBTEX_COMPILER} -terse ${CMAKE_CURRENT_BINARY_DIR}/${OUT}/${IN}.aux
	WORKING_DIRECTORY ${IN_DIR}
	COMMENT   "Bibtex"
	)
    endif(LATEX_BIBTEX_COMPILER AND BIBTEX)

    add_custom_command(
      OUTPUT    ${CMAKE_CURRENT_BINARY_DIR}/${OUT}/${IN}.log
      DEPENDS   ${BIBTEX_DEP} ${CMAKE_CURRENT_BINARY_DIR}/${OUT}/${IN}.aux
      COMMAND   ${LATEX_COMPILER} -interaction=batchmode -halt-on-error -src -src-specials -file-line-error -parse-first-line -output-directory=${CMAKE_CURRENT_BINARY_DIR}/${OUT} ${IN_DIR}/${IN}.tex
      WORKING_DIRECTORY ${IN_DIR}
      COMMENT   "Latex (second pass)"
      )

    add_custom_command(
      OUTPUT    ${CMAKE_CURRENT_BINARY_DIR}/${OUT}/${IN}.dvi
      DEPENDS   ${BIBTEX_DEP} ${CMAKE_CURRENT_BINARY_DIR}/${OUT}/${IN}.log
      COMMAND   ${LATEX_COMPILER} -interaction=batchmode -halt-on-error -src -src-specials -file-line-error -parse-first-line -output-directory=${CMAKE_CURRENT_BINARY_DIR}/${OUT} ${IN_DIR}/${IN}.tex
      WORKING_DIRECTORY ${IN_DIR}
      COMMENT   "Latex (third pass)"
      )

    if(LATEX_DVIPS_CONVERTER)
      add_custom_command(
	OUTPUT    ${CMAKE_CURRENT_BINARY_DIR}/${OUT}/${OUT}.ps
	DEPENDS   ${CMAKE_CURRENT_BINARY_DIR}/${OUT}/${IN}.dvi
	COMMAND   ${LATEX_DVIPS_CONVERTER} -P pdf -Pdownload35 -D 8000 -R0 -z -G0 -o ${CMAKE_CURRENT_BINARY_DIR}/${OUT}/${OUT}.ps ${CMAKE_CURRENT_BINARY_DIR}/${OUT}/${IN}.dvi
	WORKING_DIRECTORY ${IN_DIR}
	COMMENT   "dvi2ps"
	)

      if(LATEX_PS2PDF_CONVERTER)
	add_custom_command(
	  OUTPUT    ${OUT_DIR}/${OUT}.pdf
	  DEPENDS   ${CMAKE_CURRENT_BINARY_DIR}/${OUT}/${OUT}.ps
	  COMMAND   ${LATEX_PS2PDF_CONVERTER} -dPDFSETTINGS=/prepress -dCompatibilityLevel=1.4 -dMAxSubsetPct=100 -dSubsetFonts=true -dEmbedAllFonts=true -dCompressFonts=true ${CMAKE_CURRENT_BINARY_DIR}/${OUT}/${OUT}.ps ${OUT_DIR}/${OUT}.pdf
	  WORKING_DIRECTORY ${IN_DIR}
	  COMMENT   "ps2pdf"
	  )

      endif(LATEX_PS2PDF_CONVERTER)
    endif(LATEX_DVIPS_CONVERTER)
  endif(LATEX_COMPILER)

  latex_generate_target(${TARGETNAME})

endfunction(add_unformatted_latex)
