include_guard( GLOBAL )

set(steamworks_SOURCE_DIR ${PROJECT_SOURCE_DIR}/cmake/steamworks_sdk)

if (WIN32)
    if (BIT_32)
        add_library(steamworks STATIC IMPORTED)
        set_target_properties(
                steamworks PROPERTIES
                IMPORTED_LOCATION ${steamworks_SOURCE_DIR}/redistributable_bin/steam_api.dll
                IMPORTED_IMPLIB ${steamworks_SOURCE_DIR}/redistributable_bin/steam_api.lib
                INTERFACE_INCLUDE_DIRECTORIES "${steamworks_SOURCE_DIR}/public"
        )
    else ()
        add_library(steamworks STATIC IMPORTED)
        set_target_properties(
                steamworks PROPERTIES
                IMPORTED_LOCATION ${steamworks_SOURCE_DIR}/redistributable_bin/win64/steam_api64.dll
                IMPORTED_IMPLIB ${steamworks_SOURCE_DIR}/redistributable_bin/win64/steam_api64.lib
                INTERFACE_INCLUDE_DIRECTORIES "${steamworks_SOURCE_DIR}/public"
        )
    endif ()
elseif (UNIX AND NOT APPLE)
    if (BIT_32)
        add_library(steamworks STATIC IMPORTED)
        set_target_properties(
                steamworks PROPERTIES
                IMPORTED_LOCATION ${steamworks_SOURCE_DIR}/redistributable_bin/linux32/libsteam_api.so
                INTERFACE_INCLUDE_DIRECTORIES "${steamworks_SOURCE_DIR}/public"
        )
    else ()
        add_library(steamworks STATIC IMPORTED)
        set_target_properties(
                steamworks PROPERTIES
                IMPORTED_LOCATION ${steamworks_SOURCE_DIR}/redistributable_bin/linux64/libsteam_api.so
                INTERFACE_INCLUDE_DIRECTORIES "${steamworks_SOURCE_DIR}/public"
        )
    endif ()
elseif (APPLE)
    add_library(steamworks STATIC IMPORTED)
    set_target_properties(
            steamworks PROPERTIES
            IMPORTED_LOCATION ${steamworks_SOURCE_DIR}/redistributable_bin/osx/libsteam_api.dylib
            INTERFACE_INCLUDE_DIRECTORIES "${steamworks_SOURCE_DIR}/public"
    )
endif ()

install(IMPORTED_RUNTIME_ARTIFACTS steamworks DESTINATION "${CMAKE_INSTALL_PREFIX}")

file( READ "${CMAKE_SOURCE_DIR}/out/steam/steam_appid.txt" STEAM_APPID )

