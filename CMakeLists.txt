cmake_minimum_required(VERSION 3.20)

foreach(policy CMP0135 CMP0177 CMP0207)
    if(POLICY ${policy})
        cmake_policy(SET ${policy} NEW)
    endif()
endforeach()

set(RPG morrowind)
set(RPG_VERSION "0.53.0")

set(EASY_INCLUDE "${OUT_PROJECT_DIR}/cmake/project.cmake")

# Keep the source layout independent of the build and install directories.
set(DEV_PROJECT_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
set(OUT_PROJECT_DIR "${DEV_PROJECT_DIR}/out")
set(SRC_PROJECT_DIR "${DEV_PROJECT_DIR}/src")
set(DOC_PROJECT_DIR "${DEV_PROJECT_DIR}/doc")

string(TOLOWER "${CMAKE_BUILD_TYPE}" CMAKE_BUILD_TYPE_LOWER)

include("${OUT_PROJECT_DIR}/cmake/platform.cmake")
include("${OUT_PROJECT_DIR}/cmake/vcpkg.cmake")
project(${RPG} VERSION ${RPG_VERSION} LANGUAGES C CXX)

if(NOT DEFINED CMAKE_CXX_STANDARD)
    set(CMAKE_CXX_STANDARD 26)
endif()
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

add_subdirectory(src)
