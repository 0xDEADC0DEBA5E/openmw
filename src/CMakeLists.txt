set(ENGINE_PROJECT_DIR "${CMAKE_CURRENT_SOURCE_DIR}/engine")
set(TES3_PROJECT_DIR "${CMAKE_CURRENT_SOURCE_DIR}/tes3")
set(LAUNCHER_PROJECT_DIR "${CMAKE_CURRENT_SOURCE_DIR}/launcher")

add_subdirectory(engine)

if(BUILD_OPENMW OR BUILD_OPENMW_TESTS)
    add_subdirectory(tes3)
endif()

if(BUILD_LAUNCHER)
    add_subdirectory(launcher)
endif()
