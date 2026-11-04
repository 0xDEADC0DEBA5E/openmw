# CMAKE_SYSTEM_NAME is normally initialized by project(), which runs after this
# file so that the selected compiler and vcpkg triplet can be set first.
if (NOT CMAKE_SYSTEM_NAME)
    set(CMAKE_SYSTEM_NAME "${CMAKE_HOST_SYSTEM_NAME}")
endif ()

set(NATIVE "False")
set(WEB "False")
set(MOBILE "False")
set(PLATFORM ${CMAKE_SYSTEM_NAME})
string(TOLOWER "${CMAKE_SYSTEM_NAME}" CMAKE_SYSTEM_NAME_LOWER)

# Explicitly selecting the host OS is still a native build. In particular, Qt
# must be allowed to run the native tools with -DCMAKE_SYSTEM_NAME=Linux.
if(CMAKE_SYSTEM_NAME STREQUAL CMAKE_HOST_SYSTEM_NAME AND NOT CMAKE_SYSTEM_PROCESSOR)
    set(CMAKE_CROSSCOMPILING FALSE)
    cmake_host_system_information(RESULT CMAKE_SYSTEM_PROCESSOR QUERY OS_PLATFORM)
endif()

if (CMAKE_SYSTEM_NAME STREQUAL "Web")
    set(WEB "True")
    include("${OUT_PROJECT_DIR}/cmake/wasm.cmake")
elseif (CMAKE_SYSTEM_NAME STREQUAL "Linux")
    set(NATIVE "True")
    include("${OUT_PROJECT_DIR}/cmake/gcc.cmake")
elseif (CMAKE_SYSTEM_NAME STREQUAL "Windows")
    set(NATIVE "True")
    include("${OUT_PROJECT_DIR}/cmake/gcc.cmake")
elseif (CMAKE_SYSTEM_NAME STREQUAL "MacOS")
    set(NATIVE "True")
    message( FATAL_ERROR "No MacOS support yet" )
elseif (CMAKE_SYSTEM_NAME STREQUAL "Android")
    set(MOBILE "True")
    include("${OUT_PROJECT_DIR}/cmake/android.cmake")
elseif (CMAKE_SYSTEM_NAME STREQUAL "iOS")
    set(MOBILE "True")
    message( FATAL_ERROR "No iOS support yet" )
endif ()
