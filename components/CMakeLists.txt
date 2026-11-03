# Compatibility entry point for the legacy top-level CMake file.
set(OUT_PROJECT_DIR "${CMAKE_SOURCE_DIR}/out")
set(ENGINE_SOURCE_DIR "${CMAKE_SOURCE_DIR}/src/engine/cpp/src")
if(NOT DEFINED RPG)
    set(RPG morrowind)
endif()
add_subdirectory("${CMAKE_SOURCE_DIR}/src/engine" "${CMAKE_CURRENT_BINARY_DIR}/engine")
