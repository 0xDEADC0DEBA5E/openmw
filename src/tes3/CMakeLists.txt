# Build the existing game until its implementation is moved from apps/openmw.
add_subdirectory("${DEV_PROJECT_DIR}/apps/openmw" "${CMAKE_CURRENT_BINARY_DIR}/openmw")
add_library(${RPG}-tes3 ALIAS openmw-lib)
