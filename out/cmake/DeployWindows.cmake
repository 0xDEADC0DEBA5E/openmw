# Stage runtime files beside the executables for launches from an IDE or Explorer.
# Libraries outside vcpkg can provide additional DLL directories through the cache.
set(OPENMW_RUNTIME_LIBRARY_DIRS "" CACHE STRING "Additional runtime DLL directories")

function(openmw_copy_runtime_dlls source destination)
    file(GLOB runtime_dlls "${source}/*.dll")
    foreach(dll IN LISTS runtime_dlls)
        get_filename_component(name "${dll}" NAME)
        configure_file("${dll}" "${destination}/${name}" COPYONLY)
    endforeach()
endfunction()

get_generator_is_multi_config(multi_config)
if(multi_config)
    set(runtime_configs ${CMAKE_CONFIGURATION_TYPES})
else()
    set(runtime_configs "${CMAKE_BUILD_TYPE}")
endif()

if(USE_QT)
    get_target_property(qmake Qt::qmake IMPORTED_LOCATION)
    execute_process(COMMAND "${qmake}" -query QT_INSTALL_PLUGINS
        OUTPUT_VARIABLE qt_plugins_dir OUTPUT_STRIP_TRAILING_WHITESPACE
        COMMAND_ERROR_IS_FATAL ANY)
endif()

foreach(config IN LISTS runtime_configs)
    if(multi_config)
        set(destination "${OpenMW_BINARY_DIR}/${config}")
    else()
        set(destination "${OpenMW_BINARY_DIR}")
    endif()

    string(TOUPPER "${config}" config_upper)
    if(MINGW)
        get_filename_component(compiler_bin "${CMAKE_CXX_COMPILER}" DIRECTORY)
        file(GLOB compiler_runtime_dlls
            "${compiler_bin}/libgcc_s_*.dll"
            "${compiler_bin}/libstdc++-6.dll"
            "${compiler_bin}/libwinpthread-1.dll")
        foreach(dll IN LISTS compiler_runtime_dlls)
            get_filename_component(name "${dll}" NAME)
            configure_file("${dll}" "${destination}/${name}" COPYONLY)
        endforeach()
    endif()

    if(config_upper STREQUAL "DEBUG")
        set(qt_suffix d)
        set(vcpkg_bin "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/debug/bin")
        set(mygui_config Debug)
    else()
        set(qt_suffix "")
        set(vcpkg_bin "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/bin")
        set(mygui_config Release)
    endif()

    if(VCPKG_INSTALLED_DIR AND VCPKG_TARGET_TRIPLET)
        openmw_copy_runtime_dlls("${vcpkg_bin}" "${destination}")
        openmw_copy_runtime_dlls("${vcpkg_bin}/${mygui_config}" "${destination}")
        openmw_copy_runtime_dlls("${vcpkg_bin}/osgPlugins-${OPENSCENEGRAPH_VERSION}"
            "${destination}/osgPlugins-${OPENSCENEGRAPH_VERSION}")
    endif()
    foreach(directory IN LISTS OPENMW_RUNTIME_LIBRARY_DIRS)
        openmw_copy_runtime_dlls("${directory}" "${destination}")
    endforeach()

    if(USE_QT)
        foreach(module Core Gui Network OpenGL OpenGLWidgets Widgets Svg)
            get_target_property(dll Qt6::${module} IMPORTED_LOCATION_${config_upper})
            if(NOT dll)
                get_target_property(dll Qt6::${module} IMPORTED_LOCATION_RELEASE)
            endif()
            get_filename_component(name "${dll}" NAME)
            configure_file("${dll}" "${destination}/${name}" COPYONLY)
        endforeach()
        foreach(plugin platforms/qwindows imageformats/qsvg iconengines/qsvgicon
                styles/qwindowsvistastyle styles/qmodernwindowsstyle)
            if(EXISTS "${qt_plugins_dir}/${plugin}${qt_suffix}.dll")
                configure_file("${qt_plugins_dir}/${plugin}${qt_suffix}.dll"
                    "${destination}/${plugin}${qt_suffix}.dll" COPYONLY)
            endif()
        endforeach()
    endif()
endforeach()
