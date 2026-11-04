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

if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE RelWithDebInfo CACHE STRING "Build configuration" FORCE)
endif()
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

if(CMAKE_SYSTEM_NAME MATCHES "^(Linux|Windows)$")
    include(CheckCXXSourceCompiles)
    include(CMakePushCheckState)
    cmake_push_check_state(RESET)
    set(CMAKE_REQUIRED_FLAGS "-std=c++26 -freflection")
    check_cxx_source_compiles("#include <meta>
        constexpr auto type = ^^int;
        static_assert(type == ^^int);
        int main() { return 0; }" RPG_HAS_CXX26_REFLECTION)
    cmake_pop_check_state()
    if(NOT RPG_HAS_CXX26_REFLECTION)
        message(FATAL_ERROR "The engine requires a C++26 reflection compiler (GCC 16+ with -freflection).")
    endif()
endif()

# The upstream setup supplies the feature options, generated headers, resources,
# helper macros and application targets used by the reorganized src tree.
set(OpenMW_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
set(OpenMW_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}")
set(ENGINE_SOURCE_DIR "${SRC_PROJECT_DIR}/engine/cpp/src")
if(VCPKG_TARGET_TRIPLET STREQUAL "x64-linux")
    set(OSG_STATIC ON CACHE BOOL "Link static OpenSceneGraph")
    set(MYGUI_STATIC ON CACHE BOOL "Link static MyGUI")
endif()
include("${OUT_PROJECT_DIR}/cmake/OpenMW.cmake")
