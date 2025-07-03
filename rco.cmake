include(ExternalProject)

if(NOT TARGET psp2cxml_tool)
    ExternalProject_Add(psp2cxml_tool
        GIT_REPOSITORY https://github.com/olebeck/psp2cxml-tool
        CMAKE_ARGS
            -DCMAKE_BUILD_TYPE=Release
            -DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/tools
        BUILD_ALWAYS 1
        INSTALL_COMMAND ""
    )

    ExternalProject_Get_Property(psp2cxml_tool BINARY_DIR)
    set(PSP2CXML_EXECUTABLE ${BINARY_DIR}/psp2cxml-tool)
endif()

function(get_rco_dependencies input deps_var)
    get_filename_component(input_abs "${input}" ABSOLUTE)
    get_filename_component(input_dir "${input_abs}" DIRECTORY)
    file(READ "${input}" xml_content)
    # all src attrs
    string(REGEX MATCHALL "src=\"[^\"]+\"" matches "${xml_content}")

    set(result)
    foreach(match IN LISTS matches)
        # src="thing" -> thing
        string(REGEX REPLACE "src=\"([^\"]+)\"" "\\1" path "${match}")
        list(APPEND result "${input_dir}/${path}")
    endforeach()

    set(${deps_var} "${result}" PARENT_SCOPE)
endfunction()


macro(make_rco input output)
    get_rco_dependencies(${input} deps)
    set(out ${CMAKE_CURRENT_BINARY_DIR}/${output})
    get_filename_component(input_abs "${input}" ABSOLUTE)
    get_filename_component(input_dir "${input_abs}" DIRECTORY)
    get_filename_component(input_noext ${input} NAME_WLE)
    set(temp_output ${input_noext}.rco)
    add_custom_command(
        OUTPUT ${out}
        DEPENDS psp2cxml_tool ${input} ${deps}
        COMMAND ${PSP2CXML_EXECUTABLE} ${input_abs}
        COMMAND mv ${input_dir}/${temp_output} ${out}
    )
    add_custom_target(${output}_target
        DEPENDS ${out}
    )
    set(${output}_target ${output}_target PARENT_SCOPE)
endmacro()
