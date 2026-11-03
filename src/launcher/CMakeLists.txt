# Build the functional Qt launcher rather than the cpp/src placeholder.
add_subdirectory("${DEV_PROJECT_DIR}/apps/launcher" "${CMAKE_CURRENT_BINARY_DIR}/launcher")

add_custom_target(run
    COMMAND "$<TARGET_FILE:openmw-launcher>"
    WORKING_DIRECTORY "$<TARGET_FILE_DIR:openmw-launcher>"
    DEPENDS openmw-launcher
    USES_TERMINAL
)
