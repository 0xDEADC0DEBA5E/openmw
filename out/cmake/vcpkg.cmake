set(VCPKG_BUILD_TYPE ${CMAKE_BUILD_TYPE_LOWER})

if (NOT DEFINED VCPKG_VERSION)
    set(VCPKG_VERSION "f8be6942c0c5abd48bb325726d57af9ac39e251d")
endif ()

if (EXISTS "$ENV{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake")
    file(TO_CMAKE_PATH $ENV{VCPKG_ROOT} VCPKG_ROOT)
    set(RPG_VCPKG_ROOT "${VCPKG_ROOT}")
    set(CMAKE_TOOLCHAIN_FILE "${VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake")
else ()
    if (NOT EXISTS "${OUT_PROJECT_DIR}/vcpkg/${PLATFORM}/scripts/buildsystems/vcpkg.cmake")
        find_package(Git REQUIRED)

        set( URL "https://github.com/microsoft/vcpkg.git" )
        set( DIRECTORY "${OUT_PROJECT_DIR}/vcpkg/${PLATFORM}" )

        if(EXISTS "${DIRECTORY}/.git")
            execute_process(
                    COMMAND "${GIT_EXECUTABLE}" -C "${DIRECTORY}" rev-parse --is-inside-work-tree
                    RESULT_VARIABLE RES
            )
            if(NOT RES EQUAL 0)
                message(FATAL_ERROR "Unable to clone '${URL}' to '${DIRECTORY}' because the path already exists and is not a Git repository")
            endif()
        else()
            message( STATUS ${GIT_EXECUITABLE} )
            execute_process(
                    COMMAND "${GIT_EXECUTABLE}" clone "${URL}" "${DIRECTORY}"
                    RESULT_VARIABLE RES
            )
            if(NOT RES EQUAL 0)
                message(FATAL_ERROR "Failed to clone '${URL}' (${RES})")
            endif()
        endif()
    endif ()
    set(RPG_VCPKG_ROOT "${OUT_PROJECT_DIR}/vcpkg/${PLATFORM}")
    set(CMAKE_TOOLCHAIN_FILE "${RPG_VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake")
endif ()



# Overlay ports include SQLite's MinGW Unicode entry-point fix and spirv-tools.
# spirv-tools forces a bare "-static" onto
# every MinGW link (upstream CMakeLists.txt). That flag selects the *static*
# libwinpthread, and mingw-w64 bundles that build it against UCRT while the gcc
# driver links msvcrt leave __intrinsic_setjmpex and __ms_vsnprintf unresolved,
# which kills the SPIRV-Tools-shared.dll link. The overlay is pinned to the same
# version as VCPKG_VERSION's baseline (1.4.341.0); re-seed it from
# out/vcpkg/${PLATFORM}/buildtrees/versioning_/versions/spirv-tools/ if that
# baseline moves, otherwise the overlay silently holds spirv-tools back.
set(VCPKG_OVERLAY_PORTS "${OUT_PROJECT_DIR}/cmake/vcpkg/ports")

set(DEP_FILE "${CMAKE_SOURCE_DIR}/dependencies.json")

if (NOT EXISTS "${DEP_FILE}")
    file(WRITE "${DEP_FILE}" "[]")
endif ()

file(READ "${DEP_FILE}" VCPKG_DEPENDENCIES)

configure_file("${OUT_PROJECT_DIR}/cmake/vcpkg/vcpkg.json.in" "${CMAKE_BINARY_DIR}/vcpkg.json" @ONLY)

set( VCPKG_MANIFEST_DIR "${CMAKE_BINARY_DIR}" )
