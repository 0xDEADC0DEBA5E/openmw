# MinGW-w64 toolchain selection for Windows targets.
#
# The engine is C++26 with P2996 reflection (-freflection), so the Windows
# compiler has to be GCC 16 or newer -- CLion's bundled MinGW is GCC 15.2 and
# rejects -freflection outright. GCC 16 reports __cpp_impl_reflection and ships
# <meta>, so the same -freflection flag project.cmake already passes works on
# both this and the p2996 clang used for the Web target.
#
# Override the location with -DRPG_MINGW_ROOT=<path> or the RPG_MINGW_ROOT
# environment variable if MSYS2 lives somewhere other than C:/msys64.

include_guard(GLOBAL)

set(RPG_MINGW_MIN_VERSION 16)

function(_rpg_mingw_resolve_root out_var)
    if (DEFINED RPG_MINGW_ROOT AND NOT RPG_MINGW_ROOT STREQUAL "")
        file(TO_CMAKE_PATH "${RPG_MINGW_ROOT}" root)
        set(${out_var} "${root}" PARENT_SCOPE)
        return()
    endif ()

    if (DEFINED ENV{RPG_MINGW_ROOT} AND NOT "$ENV{RPG_MINGW_ROOT}" STREQUAL "")
        file(TO_CMAKE_PATH "$ENV{RPG_MINGW_ROOT}" root)
        set(${out_var} "${root}" PARENT_SCOPE)
        return()
    endif ()

    # Probe the usual MSYS2 layouts. mingw64 is msvcrt-flavoured, ucrt64 is UCRT;
    # either is fine as long as the whole build agrees on one of them.
    foreach (candidate "C:/msys64/mingw64" "C:/msys64/ucrt64" "C:/mingw64")
        if (EXISTS "${candidate}/bin/x86_64-w64-mingw32-g++.exe")
            set(${out_var} "${candidate}" PARENT_SCOPE)
            return()
        endif ()
    endforeach ()

    set(${out_var} "" PARENT_SCOPE)
endfunction()

_rpg_mingw_resolve_root(_rpg_mingw_root)

if (_rpg_mingw_root STREQUAL "")
    message(FATAL_ERROR
        "No MinGW-w64 GCC ${RPG_MINGW_MIN_VERSION}+ found.\n"
        "The Windows target needs GCC ${RPG_MINGW_MIN_VERSION}+ for C++26 reflection "
        "(-freflection); CLion's bundled MinGW is GCC 15.2 and cannot build this project.\n"
        "Install it with:  pacman -S mingw-w64-x86_64-gcc\n"
        "or point the build at an existing install with -DRPG_MINGW_ROOT=<path>.")
endif ()

set(RPG_MINGW_ROOT "${_rpg_mingw_root}" CACHE PATH "MinGW-w64 root used for Windows builds" FORCE)
set(RPG_MINGW_BIN "${RPG_MINGW_ROOT}/bin" CACHE PATH "MinGW-w64 bin directory" FORCE)

set(RPG_MINGW_CC  "${RPG_MINGW_BIN}/x86_64-w64-mingw32-gcc.exe")
set(RPG_MINGW_CXX "${RPG_MINGW_BIN}/x86_64-w64-mingw32-g++.exe")
set(RPG_MINGW_RC  "${RPG_MINGW_BIN}/windres.exe")

foreach (tool RPG_MINGW_CC RPG_MINGW_CXX RPG_MINGW_RC)
    if (NOT EXISTS "${${tool}}")
        message(FATAL_ERROR "MinGW-w64 at '${RPG_MINGW_ROOT}' is incomplete: missing ${${tool}}")
    endif ()
endforeach ()

# cc1plus.exe and ld.exe resolve libisl/libmpc/libzstd/... out of ${RPG_MINGW_BIN},
# and those DLLs do not sit next to the executables that need them. Nothing the
# build system passes (-B included) changes DLL search order, so that directory
# has to be on PATH for the whole build, not just for configure. Compile and link
# a real reflection TU here so a broken PATH fails now with an explanation rather
# than as an empty exit-1 from cc1plus somewhere deep in the ninja log.
set(_rpg_mingw_probe_dir "${CMAKE_BINARY_DIR}/CMakeFiles/rpg-mingw-probe")
file(WRITE "${_rpg_mingw_probe_dir}/probe.cpp"
    "#include <meta>\n"
    "constexpr auto r = ^^int;\n"
    "static_assert(r == ^^int);\n"
    "int main() { return 0; }\n")

execute_process(
        COMMAND "${RPG_MINGW_CXX}" -std=c++26 -freflection
                "${_rpg_mingw_probe_dir}/probe.cpp"
                -o "${_rpg_mingw_probe_dir}/probe.exe"
        RESULT_VARIABLE _rpg_mingw_probe_result
        OUTPUT_VARIABLE _rpg_mingw_probe_output
        ERROR_VARIABLE _rpg_mingw_probe_output
)

if (NOT _rpg_mingw_probe_result EQUAL 0)
    set(_rpg_mingw_detail "${_rpg_mingw_probe_output}")
    if (_rpg_mingw_detail STREQUAL "")
        set(_rpg_mingw_detail
            "(no output -- cc1plus/ld could not load their DLLs, which is what a missing PATH entry looks like)")
    endif ()
    message(FATAL_ERROR
        "MinGW-w64 at '${RPG_MINGW_ROOT}' cannot compile and link a C++26 reflection "
        "translation unit (exit ${_rpg_mingw_probe_result}).\n"
        "Most likely '${RPG_MINGW_BIN}' is not on PATH. Add it, or point CLion's "
        "Windows toolchain at '${RPG_MINGW_ROOT}' so it does that for you.\n"
        "Compiler output:\n${_rpg_mingw_detail}")
endif ()

execute_process(
        COMMAND "${RPG_MINGW_CXX}" -dumpversion
        OUTPUT_VARIABLE RPG_MINGW_VERSION
        OUTPUT_STRIP_TRAILING_WHITESPACE
)

if (RPG_MINGW_VERSION VERSION_LESS RPG_MINGW_MIN_VERSION)
    message(FATAL_ERROR
        "MinGW-w64 at '${RPG_MINGW_ROOT}' is GCC ${RPG_MINGW_VERSION}; "
        "GCC ${RPG_MINGW_MIN_VERSION}+ is required for C++26 reflection.")
endif ()

message(STATUS "MinGW-w64: GCC ${RPG_MINGW_VERSION} at ${RPG_MINGW_ROOT}")

# vcpkg builds its ports with a separate toolchain file that locates the compiler
# with find_program(), i.e. off PATH -- it does not see CMAKE_CXX_COMPILER set
# above. If PATH leads somewhere else (CLion's bundled GCC 15.2 is the likely
# culprit, since its bin directory also holds an x86_64-w64-mingw32-g++.exe), the
# ports get one libstdc++ and the engine another, which shows up much later as
# link or runtime failures rather than as an honest configure error. Resolve it
# the same way vcpkg will and insist the two agree.
find_program(RPG_MINGW_PATH_CXX
        NAMES x86_64-w64-mingw32-g++
        NO_CMAKE_FIND_ROOT_PATH)

if (NOT RPG_MINGW_PATH_CXX)
    message(FATAL_ERROR
        "'x86_64-w64-mingw32-g++' is not on PATH.\n"
        "vcpkg resolves the port compiler off PATH, and '${RPG_MINGW_BIN}' also has to be "
        "there for cc1plus/ld to load their DLLs. Add it to PATH, or point CLion's Windows "
        "toolchain at '${RPG_MINGW_ROOT}'.")
endif ()

get_filename_component(_rpg_path_cxx_real "${RPG_MINGW_PATH_CXX}" REALPATH)
get_filename_component(_rpg_chosen_cxx_real "${RPG_MINGW_CXX}" REALPATH)

if (NOT _rpg_path_cxx_real STREQUAL _rpg_chosen_cxx_real)
    message(FATAL_ERROR
        "PATH and the selected MinGW-w64 disagree, so vcpkg would build the ports with a "
        "different compiler than the engine.\n"
        "  engine (RPG_MINGW_ROOT): ${_rpg_chosen_cxx_real}\n"
        "  vcpkg (first on PATH):   ${_rpg_path_cxx_real}\n"
        "Put '${RPG_MINGW_BIN}' ahead of the other toolchain on PATH, or set "
        "-DRPG_MINGW_ROOT= to the one PATH already points at.")
endif ()
