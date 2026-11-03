# ---------------------------------------------------------------------------
# steamcmd for release_steam, run in script mode (cmake -P) by release.cmake.
#
# steamcmd keeps its login in config/config.vdf in its own folder. A copy inside the
# Steam client's install shares that file with the client, which rewrites it while it
# runs and drops steamcmd's saved login ("Cached credentials not found" every time).
# So it gets a folder of its own, out/steamcmd/, as Valve recommends.
#
#   MODE=install  download Valve's steamcmd into STEAMCMD_DIR
#   MODE=upload   run STEAM_BUILD_VDF as STEAM_USER with STEAMCMD_DIR's steamcmd, or
#                 FALLBACK (what configure found) if there is none
# ---------------------------------------------------------------------------

if (CMAKE_HOST_WIN32)
    set(_archive "steamcmd.zip")
    set(_executable "${STEAMCMD_DIR}/steamcmd.exe")
else ()
    set(_archive "steamcmd_linux.tar.gz")
    set(_executable "${STEAMCMD_DIR}/steamcmd.sh")
endif ()

if ("${MODE}" STREQUAL "install")
    if (EXISTS "${_executable}")
        message(STATUS "steamcmd already in ${STEAMCMD_DIR}")
        return()
    endif ()

    set(_url "https://steamcdn-a.akamaihd.net/client/installer/${_archive}")
    set(_download "${STEAMCMD_DIR}/${_archive}")
    message(STATUS "Downloading ${_url}")
    file(DOWNLOAD "${_url}" "${_download}" STATUS _status TLS_VERIFY ON)
    list(GET _status 0 _code)
    if (NOT _code EQUAL 0)
        list(GET _status 1 _error)
        message(FATAL_ERROR "Couldn't download steamcmd: ${_error}")
    endif ()

    file(ARCHIVE_EXTRACT INPUT "${_download}" DESTINATION "${STEAMCMD_DIR}")
    file(REMOVE "${_download}")

    message(STATUS "steamcmd installed in ${STEAMCMD_DIR}. Log in once, interactively, so it keeps the login:")
    message(STATUS "    \"${_executable}\" +login ${STEAM_USER} +quit")

elseif ("${MODE}" STREQUAL "upload")
    if (EXISTS "${_executable}")
        set(_steamcmd "${_executable}")
    elseif (FALLBACK)
        set(_steamcmd "${FALLBACK}")
        message(WARNING
                "Using ${FALLBACK}: in the Steam client's folder it shares its login file with the "
                "client, which drops the saved login. Build steamcmd_install for a copy of its own.")
    else ()
        message(FATAL_ERROR "No steamcmd: build the steamcmd_install target (or pass -DSTEAMCMD_EXECUTABLE=<path>)")
    endif ()

    message(STATUS "Uploading with ${_steamcmd} as ${STEAM_USER}")
    execute_process(
            COMMAND "${_steamcmd}" +login "${STEAM_USER}" +run_app_build "${STEAM_BUILD_VDF}" +quit
            RESULT_VARIABLE _result)
    if (NOT _result EQUAL 0)
        message(FATAL_ERROR
                "steamcmd failed (${_result}). If it asked for a password, it has no saved login: "
                "log in once, interactively, then build release_steam again:\n"
                "    \"${_steamcmd}\" +login ${STEAM_USER} +quit")
    endif ()

else ()
    message(FATAL_ERROR "steamcmd.cmake: MODE must be install or upload")
endif ()
