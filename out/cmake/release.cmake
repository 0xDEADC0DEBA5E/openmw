include_guard(GLOBAL)

# ---------------------------------------------------------------------------
# Multi-platform release + Steam upload.
#
# Builds the Linux and Windows release trees, installs them into the Steam
# depot (out/3377440), then uploads with steamcmd.
#
# Run from a NEUTRAL build directory -- NOT out/build/{linux,windows}/release,
# or the inner ninja invocations deadlock on those trees' build locks:
#
#     cmake -S . -B out/build/release -DCMAKE_BUILD_TYPE=Release
#     cmake --build out/build/release --target release         # build both platforms
#     cmake --build out/build/release --target release_steam   # build both + upload
#
# On Windows, release_linux builds out/build/linux/release inside WSL (wsl.exe);
# the default distro needs cmake, ninja and gcc.
#
# Useful cache overrides:
#     -DSTEAM_USER=<account>     Steam account used to upload (default exoa_online)
#     -DSTEAM_SET_LIVE=<branch>  branch to set live after upload (see note below)
# ---------------------------------------------------------------------------

include(InstallRequiredSystemLibraries)

set(STEAM_USER "exoa_online" CACHE STRING "Steam account used to upload the release build")

# NOTE: the *default* branch cannot be set live from steamcmd (Valve rejects the
# commit). Leave empty to upload only, then flip the default branch live in the
# Steamworks web UI. Set to a non-default beta branch name to auto-set-live there.
set(STEAM_SET_LIVE "" CACHE STRING "Branch to set live after upload; empty = upload only")

set(LINUX_RELEASE_DIR   "${OUT_PROJECT_DIR}/build/linux/release")
set(WINDOWS_RELEASE_DIR "${OUT_PROJECT_DIR}/build/windows/release")

# AppID (file) -> DepotID (AppID + 1, matching skillquest.main.vdf).
file(READ "${OUT_PROJECT_DIR}/steam/steam_appid.txt" STEAM_APPID)
string(STRIP "${STEAM_APPID}" STEAM_APPID)
math(EXPR STEAM_DEPOTID "${STEAM_APPID} + 1")

# Generate an app-build script with an absolute ContentRoot pointing at the
# depot, so we don't depend on the checked-in vdf's relative "./out" layout.
set(STEAM_BUILD_VDF "${CMAKE_BINARY_DIR}/steam/skillquest.release.vdf")
file(GENERATE OUTPUT "${STEAM_BUILD_VDF}" CONTENT
"\"AppBuild\"
{
    \"AppID\" \"${STEAM_APPID}\"
    \"Desc\" \"Release ${RPG_VERSION} (cmake release_steam)\"

    \"ContentRoot\" \"${BUILD_OUT_DIR}\"
    \"BuildOutput\" \"${CMAKE_BINARY_DIR}/steam/output\"

    \"SetLive\" \"${STEAM_SET_LIVE}\"

    \"Depots\"
    {
        \"${STEAM_DEPOTID}\"
        {
            \"FileMapping\"
            {
                \"LocalPath\" \"*\"
                \"DepotPath\" \".\"
                \"recursive\" \"1\"
            }
        }
    }
}
")

# Build + install each platform's release tree into the depot.
if (CMAKE_HOST_WIN32)
    # From Windows, the Linux tree is configured and built inside WSL (its cache
    # holds /mnt/c/... paths and the distro's gcc): run its build there, from this
    # checkout, configuring it first if it never has been. It installs into the
    # same depot, through /mnt/c.
    find_program(WSL_EXECUTABLE NAMES wsl wsl.exe)
    if (WSL_EXECUTABLE)
        add_custom_target(release_linux
                COMMAND "${WSL_EXECUTABLE}" --cd "${DEV_PROJECT_DIR}" -- bash -lc
                        "test -f out/build/linux/release/CMakeCache.txt || cmake -S . -B out/build/linux/release -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++ && cmake --build out/build/linux/release --target install"
                USES_TERMINAL VERBATIM
                COMMENT "Building + installing Linux release (in WSL) into ${BUILD_OUT_DIR}")
    else ()
        add_custom_target(release_linux
                COMMAND "${CMAKE_COMMAND}" -E echo
                        "WSL not found -- the Linux release is built in WSL from Windows (wsl --install)"
                COMMAND "${CMAKE_COMMAND}" -E false
                COMMENT "WSL missing")
    endif ()
else ()
    add_custom_target(release_linux
            COMMAND "${CMAKE_COMMAND}" --build "${LINUX_RELEASE_DIR}" --target install
            USES_TERMINAL VERBATIM
            COMMENT "Building + installing Linux release into ${BUILD_OUT_DIR}")
endif ()

add_custom_target(release_windows
        COMMAND "${CMAKE_COMMAND}" --build "${WINDOWS_RELEASE_DIR}" --target install
        USES_TERMINAL VERBATIM
        COMMENT "Building + installing Windows release into ${BUILD_OUT_DIR}")

add_custom_target(release)
add_dependencies(release release_linux release_windows)

# Upload the depot to Steam, with steamcmd from out/steamcmd/ (build steamcmd_install,
# then log in once). Its own folder, not the Steam client's: one there shares the
# client's config.vdf, which the running client rewrites, dropping steamcmd's saved
# login. What's found here (PATH, or the Steam client's folder, which isn't on PATH)
# is only the fallback; steamcmd.cmake picks when release_steam runs.
set(STEAMCMD_DIR "${OUT_PROJECT_DIR}/steamcmd")

add_custom_target(steamcmd_install
        COMMAND "${CMAKE_COMMAND}" -DMODE=install "-DSTEAMCMD_DIR=${STEAMCMD_DIR}" "-DSTEAM_USER=${STEAM_USER}"
                -P "${CMAKE_CURRENT_LIST_DIR}/steamcmd.cmake"
        USES_TERMINAL VERBATIM
        COMMENT "Installing steamcmd into ${STEAMCMD_DIR}")

set(_steam_dirs "")
if (CMAKE_HOST_WIN32)
    set(_program_files_x86 "$ENV{ProgramFiles\(x86\)}")
    if (NOT _program_files_x86)
        set(_program_files_x86 "C:/Program Files (x86)")
    endif ()
    file(TO_CMAKE_PATH "${_program_files_x86}/Steam" _steam_dir)
    list(APPEND _steam_dirs "${_steam_dir}")
endif ()
find_program(STEAMCMD_EXECUTABLE NAMES steamcmd steamcmd.sh HINTS ${_steam_dirs})

if (NOT STEAMCMD_EXECUTABLE)
    set(STEAMCMD_EXECUTABLE "") # no fallback
endif ()

add_custom_target(release_steam
        COMMAND "${CMAKE_COMMAND}" -DMODE=upload "-DSTEAMCMD_DIR=${STEAMCMD_DIR}"
                "-DFALLBACK=${STEAMCMD_EXECUTABLE}" "-DSTEAM_USER=${STEAM_USER}"
                "-DSTEAM_BUILD_VDF=${STEAM_BUILD_VDF}"
                -P "${CMAKE_CURRENT_LIST_DIR}/steamcmd.cmake"
        USES_TERMINAL VERBATIM
        COMMENT "Uploading depot ${STEAM_DEPOTID} (app ${STEAM_APPID}) to Steam as ${STEAM_USER}")

add_dependencies(release_steam release)
