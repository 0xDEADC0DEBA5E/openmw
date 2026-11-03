include_guard(GLOBAL)

if ("${USE_WASM}" STREQUAL "True")

    if (DEFINED ENV{EMSDK} )
        set(EMSDK "$ENV{EMSDK}")
    else ()
        # Define the directory to search
        set(SEARCH_DIR "${RUN_PROJECT_DIR}/dep/emscripten")

        # Automatically detect emsdk versions
        file(GLOB EMSDK_CANDIDATES "${SEARCH_DIR}/*")

        set(EMSDK_VERSIONS "")
        foreach (CANDIDATE ${EMSDK_CANDIDATES})
            if (IS_DIRECTORY "${CANDIDATE}")
                list(APPEND EMSDK_VERSIONS "${CANDIDATE}")
            endif ()
        endforeach ()

        if (NOT EMSDK_VERSIONS)
            message(FATAL_ERROR "No EMSDK found in '${RUN_PROJECT_DIR}/dep/emscripten'")
        endif ()

        list(POP_FRONT EMSDK_VERSIONS EMSDK)
    endif ()

    set(EMSCRIPTEN_ROOT "${EMSDK}/upstream/emscripten")
    set(ENV{EMSDK} "${EMSDK}")
    set(ENV{EM_CONFIG} "${EMSDK}/.emscripten")

    # Set Python path for Emscripten (uses bundled Python in emsdk)
    if (WIN32)
        set(ENV{EMSDK_PYTHON} "${EMSDK}/python/3.9.2-nuget_64bit/python.exe")
    endif ()

    set(VCPKG_TARGET_TRIPLET wasm32-emscripten)
    set(VCPKG_TARGET_TRIPLET_ARCH wasm32)

    set(CMAKE_C_COMPILER "${EMSCRIPTEN_ROOT}/emcc")
    set(CMAKE_CXX_COMPILER "${EMSCRIPTEN_ROOT}/em++")

    if (WIN32)
        set(CMAKE_C_COMPILER "${CMAKE_C_COMPILER}.bat")
        set(CMAKE_CXX_COMPILER "${CMAKE_CXX_COMPILER}.bat")
    endif ()

    set(VCPKG_CHAINLOAD_TOOLCHAIN_FILE "${EMSDK}/upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake" CACHE STRING "" FORCE)
endif ()