CMAKE_MINIMUM_REQUIRED(VERSION 3.20)

include_guard(GLOBAL)

set(CMAKE_BUILD_WITH_INSTALL_RPATH ON)

# Linux linker. Every module carries the whole engine, so a debug module is ~360 MB,
# and GNU ld takes ~4 min to link librpg-mod-exoa.so (under WSL, from /mnt/c) where
# lld takes ~8 s on the same objects. Use mold or lld when the toolchain has one;
# -DRPG_LINKER=bfd (or any -fuse-ld= name) picks one, -DRPG_LINKER=default leaves
# the compiler's. Not on Windows: lld's MinGW driver has no --exclude-libs, which
# keeps the DLLs under PE's 65535-export limit (see PROJECT_TEMPLATE).
set(RPG_LINKER "auto" CACHE STRING "Linux linker: auto (mold, else lld, else the compiler's), default, or a -fuse-ld= name")
set(RPG_FUSE_LD "")
if (UNIX AND NOT APPLE AND NOT ANDROID AND NOT EMSCRIPTEN)
    if (RPG_LINKER STREQUAL "auto")
        include(CheckLinkerFlag)
        foreach (ld mold lld)
            check_linker_flag(CXX "-fuse-ld=${ld}" RPG_HAS_LINKER_${ld})
            if (RPG_HAS_LINKER_${ld})
                set(RPG_FUSE_LD "-fuse-ld=${ld}")
                break()
            endif ()
        endforeach ()
    elseif (NOT RPG_LINKER STREQUAL "default")
        set(RPG_FUSE_LD "-fuse-ld=${RPG_LINKER}")
    endif ()
    if (RPG_FUSE_LD)
        message(STATUS "Linker: ${RPG_FUSE_LD}")
    endif ()
endif ()

# ccache, when it's installed and no launcher was chosen already: a TU here takes
# 10-60 s, so one rebuilt for nothing (a reconfigure, a branch switch, a header
# touched and reverted) is worth skipping. -DRPG_CCACHE=OFF turns it off.
option(RPG_CCACHE "Compile through ccache when it's found" ON)
set(RPG_COMPILER_LAUNCHER "")
if (RPG_CCACHE AND NOT CMAKE_CXX_COMPILER_LAUNCHER)
    find_program(RPG_CCACHE_PROGRAM ccache)
    if (RPG_CCACHE_PROGRAM)
        set(RPG_COMPILER_LAUNCHER "${RPG_CCACHE_PROGRAM}")
        message(STATUS "ccache: ${RPG_CCACHE_PROGRAM}")
    endif ()
endif ()

# What a project passes on to whatever links it, at @p SCOPE: PUBLIC when it's built
# here, INTERFACE when it's imported (an imported target takes nothing else). One
# list for both, so a prebuilt library asks its users for exactly what its source
# build would have. Reads PROJECT_TEMPLATE's variables.
function(_PROJECT_TEMPLATE_USAGE SCOPE)
    target_compile_options( ${TARGET} ${SCOPE} "--std=c++26" -freflection )

    # A single translation unit here instantiates enough templates to blow past the
    # ~32k section limit of the default PE/COFF object format -- Anvil.cpp alone
    # emits ~45k COMDAT sections at -g, and the engine totals ~680k. Past the limit
    # the assembler does not error; it silently drops COMDATs, so their symbols end
    # up neither defined nor undefined and the link fails with a wall of "undefined
    # reference" to std::promise/_Destroy/_Tuple_impl plus "relocation truncated to
    # fit". The bigobj format widens the section-count field and fixes it.
    if ("${CMAKE_SYSTEM_NAME}" STREQUAL "Windows" AND CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        target_compile_options( ${TARGET} ${SCOPE} -Wa,-mbig-obj )
    endif ()

    # (No -flto=auto here: nothing is compiled with -flto, so at link it only ran the
    # LTO plugin over plain objects -- ~70 s of every Linux debug link, same output.)
    if (UNIX AND NOT APPLE)
        target_link_options( ${TARGET} ${SCOPE} -rdynamic )
    endif ()

    target_link_libraries( ${TARGET} ${SCOPE} ${EXE_ARG_SHARED_LINK} )

    if (EMSCRIPTEN AND NOT ANDROID)
        target_compile_options(${TARGET} ${SCOPE} -sUSE_PTHREADS=1)
        target_link_options(${TARGET} ${SCOPE} -sUSE_PTHREADS=1)
    elseif (WIN32 AND NOT ANDROID )
        target_link_libraries( ${TARGET} ${SCOPE} ${EXE_ARG_WIN_LINK} )
    elseif (UNIX AND NOT APPLE AND NOT ANDROID )
        target_link_options( ${TARGET} ${SCOPE} -fPIC )
        target_link_libraries( ${TARGET} ${SCOPE} dl pthread ${EXE_ARG_LINUX_LINK} )
    endif ()

    if (EXE_ARG_DEFINITIONS)
        target_compile_definitions( ${TARGET} ${SCOPE} ${EXE_ARG_DEFINITIONS} )
    endif ()
endfunction()

# Defines the target MODULE for a project (the engine, a mod, the launcher, ...).
#
# With its SOURCE_DIR (cpp/src) present, it's compiled from source. Without one, the
# library or executable a source build left in the project's
# bin/<platform>/<build>/ is imported in its place, with INCLUDE_DIR (cpp/api) for
# its headers -- e.g. a mod shipped without sources, or the engine as an SDK.
#
# DEFINITIONS / INCLUDES: compile definitions and include directories passed on to
# whatever links it (PUBLIC; on an imported target, the INTERFACE it's limited to).
function(PROJECT_TEMPLATE)
    set(ARGS_FLAGS EXECUTABLE SHARED GLOB_SOURCES GLOB_INCLUDES LINK_STATIC)
    set(ARGS_VARIABLES MODULE PROJECT_DIR SOURCE_DIR INCLUDE_DIR VCPKG_VERSION VERSION)
    set(ARGS_ARRAYS SOURCE_FILES FIND_LIBRARY SHARED_LINK WIN_LINK LINUX_LINK DEFINITIONS INCLUDES)


    cmake_parse_arguments(EXE_ARG "${ARGS_FLAGS}" "${ARGS_VARIABLES}" "${ARGS_ARRAYS}" ${ARGN})

    set(TARGET ${EXE_ARG_MODULE})
    string(TOLOWER ${TARGET} TARGET)


    set(TARGET_DIR ${EXE_ARG_PROJECT_DIR})
    string(REPLACE "${OUT_PROJECT_DIR}" "." TARGET_PATH ${TARGET})

    if (NOT DEFINED TARGET_DIR)
        string(REPLACE "${OUT_PROJECT_DIR}" "." TARGET_DIR ${TARGET})
    endif ()

    set(VCPKG_BUILD_TYPE ${CMAKE_BUILD_TYPE_LOWER})

    if (NOT DEFINED EXE_ARG_VCPKG_VERSION)
        set(EXE_ARG_VCPKG_VERSION "4bb07a326d9b9bce3703272a509e5bc25dd9cfd5")
    endif ()

    foreach (file ${EXE_ARG_FIND_LIBRARY})
        find_library(${file} REQUIRED)
    endforeach ()

    project(${TARGET})

    set(SRC_DIR ${EXE_ARG_SOURCE_DIR})
    if (NOT DEFINED SRC_DIR)
        set(SRC_DIR ${PROJECT_SOURCE_DIR}/${TARGET_PATH}/src)
    endif ()

    set(INC_DIR ${EXE_ARG_INCLUDE_DIR})
    if (NOT DEFINED INC_DIR)
        set(INC_DIR ${PROJECT_SOURCE_DIR}/${TARGET_PATH}/inc)
    endif ()

    # Build outputs live in the source tree, so every configured build tree shares
    # this path. Isolate by platform + build type, otherwise the Linux and Windows
    # (mingw) trees clobber each other's librpg-engine.a and the next link pulls in
    # the wrong-architecture archive (R_AMD64_IMAGEBASE / __ImageBase relocations).
    # Also where an imported (source-less) project's prebuilt binaries are found.
    set(TARGET_BIN_DIR "${TARGET_DIR}/bin/${CMAKE_SYSTEM_NAME_LOWER}/${CMAKE_BUILD_TYPE_LOWER}")

    # ---- No sources: import the prebuilt library / executable and its headers ----
    if (NOT IS_DIRECTORY "${SRC_DIR}")
        if (${EXE_ARG_EXECUTABLE})
            add_executable(${TARGET} IMPORTED GLOBAL)
            set(PREBUILT_NAME "${TARGET}${CMAKE_EXECUTABLE_SUFFIX}")
        elseif (${EXE_ARG_SHARED})
            add_library(${TARGET} SHARED IMPORTED GLOBAL)
            set(PREBUILT_NAME "${CMAKE_SHARED_LIBRARY_PREFIX}${TARGET}${CMAKE_SHARED_LIBRARY_SUFFIX}")
        else ()
            add_library(${TARGET} STATIC IMPORTED GLOBAL)
            set(PREBUILT_NAME "${CMAKE_STATIC_LIBRARY_PREFIX}${TARGET}${CMAKE_STATIC_LIBRARY_SUFFIX}")
        endif ()

        # This build type's, else whichever build there is: a shipped game has only its
        # release binaries, but it may be opened with any profile (e.g. an IDE's Debug)
        set(PREBUILT "")
        foreach (build ${CMAKE_BUILD_TYPE_LOWER} release relwithdebinfo minsizerel debug)
            set(candidate_dir "${TARGET_DIR}/bin/${CMAKE_SYSTEM_NAME_LOWER}/${build}")
            if (EXISTS "${candidate_dir}/${PREBUILT_NAME}")
                set(PREBUILT_DIR "${candidate_dir}")
                set(PREBUILT "${candidate_dir}/${PREBUILT_NAME}")
                break()
            endif ()
        endforeach ()

        if (NOT PREBUILT)
            message(FATAL_ERROR
                    "${TARGET}: no sources (${SRC_DIR}) to build, and no prebuilt ${PREBUILT_NAME} "
                    "in ${TARGET_DIR}/bin/${CMAKE_SYSTEM_NAME_LOWER}/<build>/ to import")
        endif ()
        message(STATUS "${TARGET}: no sources, importing ${PREBUILT}")

        set_target_properties(${TARGET} PROPERTIES IMPORTED_LOCATION "${PREBUILT}")

        # A DLL is linked through its import library
        set(PREBUILT_IMPLIB "${PREBUILT_DIR}/${CMAKE_IMPORT_LIBRARY_PREFIX}${TARGET}${CMAKE_IMPORT_LIBRARY_SUFFIX}")
        if (WIN32 AND ${EXE_ARG_SHARED} AND EXISTS "${PREBUILT_IMPLIB}")
            set_target_properties(${TARGET} PROPERTIES IMPORTED_IMPLIB "${PREBUILT_IMPLIB}")
        endif ()

        # Its headers. (An imported target's include directories must exist.)
        foreach (dir ${INC_DIR} ${MOD_DIR} ${EXE_ARG_INCLUDES})
            if (IS_DIRECTORY "${dir}")
                target_include_directories(${TARGET} INTERFACE "${dir}")
            endif ()
        endforeach ()

        _PROJECT_TEMPLATE_USAGE(INTERFACE)
        return()
    endif ()

    # ---- Sources: compile them ----
    if (${EXE_ARG_GLOB_SOURCES})
        file(GLOB_RECURSE SRC ${SRC_DIR}/*.cpp ${SRC_DIR}/*.hpp ${SRC_DIR}/*.c++ ${SRC_DIR}/*.h++ ${SRC_DIR}/*.c ${SRC_DIR}/*.h ${SRC_DIR}/*.cc ${SRC_DIR}/*.hh)
    endif ()

    if (${EXE_ARG_GLOB_INCLUDES})
        file(GLOB_RECURSE INC ${INC_DIR}/*.hpp ${INC_DIR}/*.h++ ${INC_DIR}/*.h ${INC_DIR}/*.hh)
    endif ()

    if (${EXE_ARG_EXECUTABLE})
        add_executable(${TARGET} ${EXE_ARG_SOURCE_FILES} ${SRC} ${INC})


    elseif (${EXE_ARG_SHARED})
        add_library(${TARGET} SHARED ${EXE_ARG_SOURCE_FILES} ${SRC} ${INC})
    else ()
        add_library(${TARGET} ${EXE_ARG_SOURCE_FILES} ${SRC} ${INC})
    endif ()

    target_include_directories(
            ${TARGET}
            PUBLIC ${INC_DIR}
            PRIVATE ${SRC_DIR}
            PUBLIC ${MOD_DIR}
    )
    if (EXE_ARG_INCLUDES)
        target_include_directories(${TARGET} PUBLIC ${EXE_ARG_INCLUDES})
    endif ()

    set_target_properties(
            ${TARGET}
            PROPERTIES
            LINKER_LANGUAGE CXX
            CXX_STANDARD 26
            CXX_STANDARD_REQUIRED ON
    )

    if (RPG_FUSE_LD)
        target_link_options( ${TARGET} PRIVATE ${RPG_FUSE_LD} )
    endif ()

    if (RPG_COMPILER_LAUNCHER)
        set_target_properties( ${TARGET} PROPERTIES
                C_COMPILER_LAUNCHER "${RPG_COMPILER_LAUNCHER}"
                CXX_COMPILER_LAUNCHER "${RPG_COMPILER_LAUNCHER}" )
    endif ()

    _PROJECT_TEMPLATE_USAGE(PUBLIC)

    # Export every symbol from every module (exe included) so Library::function()/
    # global() can index any of them. mingw exports nothing from an exe by default,
    # and stops auto-exporting from a DLL once anything in it is marked dllexport.
    if ("${CMAKE_SYSTEM_NAME}" STREQUAL "Windows" AND CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        target_link_options( ${TARGET} PRIVATE -Wl,--export-all-symbols )

        # ...except the shader compiler's. A module that touches the Engine links its
        # GPU code (the voxel renderer compiles shaders), and with shaderc / glslang /
        # SPIRV-Tools exported too a DLL passes PE's limit of 65535 export ordinals
        # ("export ordinal too large"). Nothing looks those up across modules.
        # Debug and release archive names both listed; ones that aren't linked are ignored.
        if (${EXE_ARG_SHARED})
            target_link_options( ${TARGET} PRIVATE
                    "-Wl,--exclude-libs,libshaderc.a:libshaderc_util.a:libshaderc_combined.a:libglslang.a:libglslangd.a:libSPIRV.a:libSPIRVd.a:libSPIRV-Tools.a:libSPIRV-Tools-opt.a:libSPIRV-Tools-link.a:libSPIRV-Tools-reduce.a:libMachineIndependent.a:libMachineIndependentd.a:libGenericCodeGen.a:libGenericCodeGend.a:libOSDependent.a:libOSDependentd.a:libglslang-default-resource-limits.a:libglslang-default-resource-limitsd.a" )
        endif ()
    endif ()

    # Library(path) calls these in every module it loads, but with the engine linked
    # statically a module only gets Library.cpp.obj if something in it already refers
    # to that object. Template.cpp doesn't (Library::Events is inline in the header),
    # so the hooks were missing and Events::arrive never fired. -u forces them in.
    if (${EXE_ARG_SHARED})
        target_link_options( ${TARGET} PRIVATE
                -Wl,-u,amner_library_arrive
                -Wl,-u,amner_library_depart )
    endif ()

    # Linux: the C++ runtime linked in, not the system's libstdc++.so.6. The release is
    # built with a current GCC (WSL Arch), so its libstdc++ needs GLIBCXX versions older
    # distros and the Steam Runtime don't have ("GLIBCXX_3.4.xx not found"). glibc itself
    # stays dynamic. Each module carries a copy, as it does of the engine.
    if (UNIX AND NOT APPLE AND NOT ANDROID AND NOT EMSCRIPTEN
            AND (${EXE_ARG_EXECUTABLE} OR ${EXE_ARG_SHARED}))
        target_link_options( ${TARGET} PRIVATE -static-libstdc++ -static-libgcc )
    endif ()

    # Linux: a module binds its references to its own definitions, as a DLL always does.
    # The engine is linked into every module and each relies on its own copy (its
    # Library::self(), its registries' statics, its typeinfo). But the executable is
    # linked -rdynamic, exporting everything, and by default ELF binds a module's
    # references to those exports first -- so a mod ran the executable's engine, whose
    # Library::self() is the executable: exoa's registries looked for SkillQuest in the
    # wrong module and crashed in Mod::library() on launch. Lookups by name
    # (Library::function / global, dlsym) still reach the executable's exports.
    if (UNIX AND NOT APPLE AND NOT ANDROID AND NOT EMSCRIPTEN AND ${EXE_ARG_SHARED})
        target_link_options( ${TARGET} PRIVATE -Wl,-Bsymbolic )
    endif ()

    set_target_properties(${TARGET} PROPERTIES
            ARCHIVE_OUTPUT_DIRECTORY "${TARGET_BIN_DIR}"
            LIBRARY_OUTPUT_DIRECTORY "${TARGET_BIN_DIR}"
            RUNTIME_OUTPUT_DIRECTORY "${TARGET_BIN_DIR}"
    )
endfunction()
