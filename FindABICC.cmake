# Distributed under the BSD License.
#[[.rst:
FindABICC
-------------

This module finds the abi-compliance-checker utility and define help function

Result variables
^^^^^^^^^^^^^^^^

This module will define the following variables:

``ABICC_FOUND``
True if the system has the abi-compliance-checker executable

Cache variables
^^^^^^^^^^^^^^^

``ABICC_EXECUTABLE``
Path to abi-compliance-checker executable

Functions
^^^^^^^^^

::

function CREATE_TARGET_ABI_DUMP(target PUBLIC_HEADERS ... [ALL] [CAN_FAILURE] [OUTPUT output] [TARGET tgt] [OPTIONS ...])
        create target <tgt> (<target>-abi-dump by default) for create ABI dump.
        If <output> is not specified, the ${CMAKE_CURRENT_BINARY_DIR}/<target>.ABI-<version>.dump
        will be created. If <ALL> is specified target will be addeted to ALL
        metatarget. Options may be given to abi-compliance-checker after OPTIONS.
#]]

find_program(ABICC_EXECUTABLE abi-compliance-checker)
mark_as_advanced(ABICC_EXECUTABLE)

include(FindPackageHandleStandardArgs)

find_package_handle_standard_args(ABICC DEFAULT_MSG ABICC_EXECUTABLE)

if(NOT COMMAND cmake_parse_arguments)
    include(CMakeParseArguments)
endif()

function(CREATE_TARGET_ABI_DUMP TARGET)

    cmake_parse_arguments(ABICC "ALL;CAN_FAILURE" "OUTPUT;TARGET" "PUBLIC_HEADERS;OPTIONS" ${ARGN})
    if(NOT TARGET ${TARGET})
        message(WARNING "Target ${TARGET} not exists. ABI dump will not be generated.")
        return()
    endif()

    get_target_property(target_type ${TARGET} TYPE)

    if(NOT target_type STREQUAL "SHARED_LIBRARY")
        message(WARNING "Target ${TARGET} is not shared library. ABI dump will not be generated.")
        return()
    endif()

    get_target_property(target_version ${TARGET} VERSION)
    if(NOT target_version)
        message(AUTHOR_WARNING "Not found version for ${TARGET}, use 0.0.1 for ABI dump")
        set(target_version "0.0.1")
    endif()

    if(NOT ABICC_OUTPUT)
        set(ABICC_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${TARGET}.ABI-${target_version}.dump)
    endif()

    if(NOT ABICC_TARGET)
        set(ABICC_TARGET ${TARGET}-abi-dump)
    endif()

    if(ABICC_ALL)
        set(ABICC_ALL "ALL")
    else()
        set(ABICC_ALL "")
    endif()

    if(ABICC_CAN_FAILURE)
        set(return_code_wrap " || exit 0")
    endif()

    get_target_property(target_include_directories ${TARGET} INCLUDE_DIRECTORIES)
    foreach(dir ${target_include_directories})
        set(gcc_options "${gcc_options} -I${dir}")
    endforeach()

    list(APPEND ABICC_OPTIONS -gcc-options "${gcc_options}")

    if(ABICC_PUBLIC_HEADERS)
        foreach(header ${ABICC_PUBLIC_HEADERS})
            if(IS_ABSOLUTE ${header})
                list(APPEND public_headers_full ${header})
            elseif(EXISTS ${CMAKE_CURRENT_BINARY_DIR}/${header})
                list(APPEND public_headers_full ${CMAKE_CURRENT_BINARY_DIR}/${header})
            elseif(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/${header})
                list(APPEND public_headers_full ${CMAKE_CURRENT_SOURCE_DIR}/${header})
            else()
                message(AUTHOR_WARNING "CREATE_TARGET_ABI_DUMP: can not find ${header}")
            endif()
        endforeach()
        set(dump_config ${CMAKE_CURRENT_BINARY_DIR}/${TARGET}.ABI-${target_version}.xml)
        file(GENERATE 
            OUTPUT  ${dump_config}
            CONTENT "<version>${target_version}</version>\n<headers>$<JOIN:${public_headers_full},\n>\n</headers><libs>$<TARGET_FILE:${TARGET}></libs>"
            )
    else()
        message(SEND_ERROR "Please specify public headers for create ABI dump")
        return()
    endif()

    add_custom_command(
        OUTPUT ${ABICC_OUTPUT}
        COMMAND ${ABICC_EXECUTABLE} -dump-path ${ABICC_OUTPUT}
            -lib ${TARGET}
            -dump ${dump_config}
            ${ABICC_OPTIONS} ${return_code_wrap}
        DEPENDS ${TARGET} ${dump_config}
        VERBATIM
    )
    add_custom_target(${ABICC_TARGET}
        ${ABICC_ALL}
        DEPENDS ${ABICC_OUTPUT}
        VERBATIM
    )
    add_dependencies(${ABICC_TARGET} ${TARGET})
endfunction()
