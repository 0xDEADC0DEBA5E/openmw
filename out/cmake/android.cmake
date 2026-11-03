include_guard(GLOBAL)

if ("${ANDROID}" STREQUAL "True" )
    set(ANDROID_NDK_HOME $ENV{ANDROID_NDK_HOME})

    if (${ANDROID_NDK_HOME} STREQUAL "")
        return()
    endif ()

    if (UNIX AND NOT APPLE)
        set(CMAKE_THREAD_LIBS_INIT "-lpthread")
        set(CMAKE_HAVE_THREADS_LIBRARY 1)
        set(CMAKE_USE_WIN32_THREADS_INIT 0)
        set(CMAKE_USE_PTHREADS_INIT 1)
        set(THREADS_PREFER_PTHREAD_FLAG ON)
    endif ()

    set(CMAKE_C_COMPILER_WORKS True)
    set(CMAKE_CXX_COMPILER_WORKS True)
    set(ANDROID_TOOLCHAIN clang)
    set(ANDROID_STL c++_static)
    set(ANDROID_USE_LEGACY_TOOLCHAIN_FILE False)
    set(VCPKG_CHAINLOAD_TOOLCHAIN_FILE "$ENV{ANDROID_NDK_HOME}/build/cmake/android.toolchain.cmake" CACHE STRING "" FORCE)

    # Execute command to list devices
    execute_process(
            COMMAND ""
            OUTPUT_VARIABLE ADB_OUTPUT
            RESULT_VARIABLE ADB_RESULT
            ERROR_QUIET
    )

    include("${OUT_PROJECT_DIR}/cmake/android/metaquest3.cmake")
endif ()