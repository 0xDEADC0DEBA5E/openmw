# This file runs before project(): select tools using the host, not the target.
if (CMAKE_HOST_SYSTEM_NAME STREQUAL "Linux")
    set(VCPKG_HOST_TRIPLET x64-linux)
    set(VCPKG_DEFAULT_HOST_TRIPLET x64-linux)
    set(VCPKG_HOST_TRIPLET_ARCH x64)
    set(VCPKG_DEFAULT_HOST_TRIPLET_ARCH x64)

    if ("${CMAKE_SYSTEM_NAME}" STREQUAL "Windows")
        set(CMAKE_SYSTEM_PROCESSOR AMD64)
        # Paths may vary slightly depending on your Linux distribution
        set(CMAKE_C_COMPILER /usr/bin/x86_64-w64-mingw32-gcc)
        set(CMAKE_CXX_COMPILER /usr/bin/x86_64-w64-mingw32-g++)
        set(CMAKE_RC_COMPILER /usr/bin/x86_64-w64-mingw32-windres)

        set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
        set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
        set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
        set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

        set(VCPKG_DEFAULT_TRIPLET x64-mingw-dynamic)
        set(VCPKG_TARGET_TRIPLET x64-mingw-dynamic)
        set(VCPKG_DEFAULT_TRIPLET_ARCH x64)
        set(VCPKG_TARGET_TRIPLET_ARCH x64)

        # Cross-compiling from Linux: vcpkg's post-build applocal DLL deployment runs
        # powershell.exe, which isn't available on this host. Disable it.
        set(VCPKG_APPLOCAL_DEPS OFF)
    elseif ("${CMAKE_SYSTEM_NAME}" STREQUAL "Linux")
        set(VCPKG_DEFAULT_TRIPLET x64-linux)
        set(VCPKG_TARGET_TRIPLET x64-linux)
        set(VCPKG_DEFAULT_TRIPLET_ARCH x64)
        set(VCPKG_TARGET_TRIPLET_ARCH x64)
    endif ()
elseif (CMAKE_HOST_WIN32)
    if ("${CMAKE_SYSTEM_NAME}" STREQUAL "Windows")
        include("${OUT_PROJECT_DIR}/cmake/mingw.cmake")

        set(CMAKE_C_COMPILER "${RPG_MINGW_CC}")
        set(CMAKE_CXX_COMPILER "${RPG_MINGW_CXX}")
        set(CMAKE_RC_COMPILER "${RPG_MINGW_RC}")

        set(VCPKG_DEFAULT_TRIPLET x64-mingw-dynamic)
        set(VCPKG_TARGET_TRIPLET x64-mingw-dynamic)
        set(VCPKG_DEFAULT_TRIPLET_ARCH x64)
        set(VCPKG_TARGET_TRIPLET_ARCH x64)
    elseif ("${CMAKE_SYSTEM_NAME}" STREQUAL "Linux")
        set(VCPKG_DEFAULT_TRIPLET x64-linux)
        set(VCPKG_TARGET_TRIPLET x64-linux)
        set(VCPKG_DEFAULT_TRIPLET_ARCH x64)
        set(VCPKG_TARGET_TRIPLET_ARCH x64)
    endif ()
endif()
