cmake_minimum_required(VERSION 3.25...4.0 FATAL_ERROR)

if(NOT DEFINED CMAKE_TOOLCHAIN_FILE)
  if(DEFINED ENV{VITASDK})
    set(CMAKE_TOOLCHAIN_FILE "$ENV{VITASDK}/share/vita.toolchain.cmake" CACHE PATH "toolchain file")
  else()
    message(FATAL_ERROR "Please define VITASDK to point to your SDK path!")
  endif()
endif()

project(ScePaf)
include("${VITASDK}/share/vita.cmake" REQUIRED)

include(FetchContent)
FetchContent_Declare(
    ScePaf_RE
    GIT_REPOSITORY "https://github.com/GrapheneCt/ScePaf-RE"
    GIT_TAG "b76d6ae00516b107d37e7e8a1a16211e3b729a07"
    UPDATE_DISCONNECTED TRUE
    EXCLUDE_FROM_ALL
    PATCH_COMMAND patch -p2 -i "${CMAKE_CURRENT_LIST_DIR}/ScePaf.patch" && patch -p1 -i "${CMAKE_CURRENT_LIST_DIR}/ScePaf-appsettings.patch"
)

FetchContent_MakeAvailable(ScePaf_RE)

set(SCEPAF_LIBRARIES
    ScePafCommon
    ScePafThread
    ScePafAutoTestTty
    ScePafMisc
    ScePafLowlayer
    ScePafWidget
    ScePafStdc
    ScePafGraphics
    ScePafResource
    ScePafToplevel
    SceAppSettings
    SceCommonGuiDialog
    ScePafWebMapView
    SceWebUIPlugin
)

file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/include)
file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/lib)
add_custom_command(
    OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/include/paf.h
    COMMAND cp -r ${scepaf_re_SOURCE_DIR}/include/ ${CMAKE_CURRENT_BINARY_DIR}
    COMMAND cp ${CMAKE_CURRENT_LIST_DIR}/include/map ${CMAKE_CURRENT_BINARY_DIR}/include/paf/std/map
    COMMAND cp ${CMAKE_CURRENT_LIST_DIR}/include/math.h ${CMAKE_CURRENT_BINARY_DIR}/include/paf/math/math.h
    COMMAND cp ${CMAKE_CURRENT_LIST_DIR}/include/declspec.h ${CMAKE_CURRENT_BINARY_DIR}/include/paf/declspec.h
)

foreach(library ${SCEPAF_LIBRARIES})
    set(emd ${scepaf_re_SOURCE_DIR}/lib/${library}.emd)
    set(yml ${CMAKE_CURRENT_BINARY_DIR}/${library}.yml)
    set(libbuilddir ${CMAKE_CURRENT_BINARY_DIR}/libbuild/${library})
    set(stub ${CMAKE_CURRENT_BINARY_DIR}/lib/lib${library}_stub.a)
    set(stub_weak ${CMAKE_CURRENT_BINARY_DIR}/lib/lib${library}_stub_weak.a)
    file(MAKE_DIRECTORY ${libbuilddir})
    add_custom_command(
        OUTPUT "${yml}"
        DEPENDS "${emd}"
        COMMAND python3 ${CMAKE_CURRENT_LIST_DIR}/emd2yml.py "${yml}" "${emd}"
        COMMENT "emd2yml ${library}"
    )
    add_custom_command(
        OUTPUT "${stub}" "${stub_weak}"
        DEPENDS "${yml}"
        COMMAND vita-libs-gen-2 --yml="${yml}" --output="./" --cmake=true
        COMMAND cmake . -B "build"
        COMMAND cmake --build "build"
        COMMAND cp "build/lib${library}_stub.a" "${stub}"
        COMMAND cp "build/lib${library}_stub_weak.a" "${stub_weak}"
        WORKING_DIRECTORY ${libbuilddir}
        COMMENT "vita-libs-gen ${library}"
    )
    list(APPEND SCEPAF_STUBS ${stub})
endforeach()

add_custom_target(
    paf_includes_copy ALL
    DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/include/paf.h
)

add_custom_target(
    paf_stubs_gen ALL
    DEPENDS ${SCEPAF_STUBS}
)

set(CMAKE_INSTALL_PREFIX "${CMAKE_BINARY_DIR}/package")

install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/include/ DESTINATION include)

foreach(library ${SCEPAF_LIBRARIES})
    set(stub "${CMAKE_CURRENT_BINARY_DIR}/lib/lib${library}_stub.a")
    set(stub_weak "${CMAKE_CURRENT_BINARY_DIR}/lib/lib${library}_stub_weak.a")
    install(FILES "${stub}" DESTINATION lib/ RENAME "lib${library}_stub.a")
    install(FILES "${stub_weak}" DESTINATION lib/ RENAME "lib${library}_stub_weak.a")
endforeach()

set(SCEPAF_PACKAGE_NAME ScePaf)
set(SCEPAF_PACKAGE_VERSION "1.0.0")
configure_file(
    ${CMAKE_CURRENT_LIST_DIR}/PackageCMakeLists.txt.in
    ${CMAKE_CURRENT_BINARY_DIR}/CMakeLists.txt @ONLY
)
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/CMakeLists.txt" DESTINATION .)
install(FILES "${CMAKE_CURRENT_LIST_DIR}/rco.cmake" DESTINATION .)

set(CPACK_GENERATOR "ZIP")
set(CPACK_ARCHIVE_FILE_NAME "${SCEPAF_PACKAGE_NAME}-${SCEPAF_PACKAGE_VERSION}")
set(CPACK_PACKAGE_FILE_NAME "${CPACK_ARCHIVE_FILE_NAME}")
set(CPACK_INSTALL_DIRECTORY ${CMAKE_INSTALL_PREFIX})
set(CPACK_INCLUDE_TOPLEVEL_DIRECTORY OFF)

include(CPack)
