vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO LuaJIT/LuaJIT
    REF 659a61693aa3b87661864ad0f12eee14c865cd7f  # 2026-03-04
    SHA512 b222ee14789e0017b613ff3edaccd547b30027609fbd721a1185c7f38b0cde7d83ecb7d222f0f68159a1a39ab293ce5dcfc0c66c5678e02adc31d59721472444
    HEAD_REF master
    PATCHES
        msvcbuild.patch
        003-do-not-set-macosx-deployment-target.patch
)

vcpkg_cmake_get_vars(cmake_vars_file)
include("${cmake_vars_file}")

if(VCPKG_DETECTED_MSVC)
    set(VSCMD_ARG_TGT_ARCH "${VCPKG_TARGET_ARCHITECTURE}")
    if(VCPKG_TARGET_ARCHITECTURE STREQUAL "arm64")
        if(DEFINED ENV{PROCESSOR_ARCHITEW6432})
            set(host_arch $ENV{PROCESSOR_ARCHITEW6432})
        else()
            set(host_arch $ENV{PROCESSOR_ARCHITECTURE})
        endif()
        if(host_arch MATCHES "(amd|AMD)64")
            set(ENV{VSCMD_ARG_HOST_ARCH} "x64")
        endif()
    endif()

    vcpkg_list(SET options)
    if (VCPKG_LIBRARY_LINKAGE STREQUAL "static")
        list(APPEND options "MSVCBUILD_OPTIONS=static")
    endif()

    vcpkg_install_nmake(SOURCE_PATH "${SOURCE_PATH}"
        PROJECT_NAME "${CMAKE_CURRENT_LIST_DIR}/Makefile.nmake"
        OPTIONS
            ${options}
    )

    if (VCPKG_LIBRARY_LINKAGE STREQUAL "dynamic")
        vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/include/luajit/luaconf.h" "defined(LUA_BUILD_AS_DLL)" "1")
    endif()

    file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/luajit.pc" DESTINATION "${CURRENT_PACKAGES_DIR}/lib/pkgconfig")
    if(NOT VCPKG_BUILD_TYPE)
        file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/luajit.pc" DESTINATION "${CURRENT_PACKAGES_DIR}/debug/lib/pkgconfig")
    endif()

    vcpkg_copy_pdbs()

    # jit including the specific vmdef.lua generated during the build
    file(COPY "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/src/jit" DESTINATION "${CURRENT_PACKAGES_DIR}/tools/luajit/lua")

else()
    vcpkg_list(SET options)
    if(VCPKG_CROSSCOMPILING)
        list(APPEND options
            "LJARCH=${VCPKG_TARGET_ARCHITECTURE}"
            "BUILDVM_X=${CURRENT_HOST_INSTALLED_DIR}/manual-tools/${PORT}/buildvm-${VCPKG_TARGET_ARCHITECTURE}${VCPKG_HOST_EXECUTABLE_SUFFIX}"
            "HOST_LUA=${CURRENT_HOST_INSTALLED_DIR}/manual-tools/${PORT}/minilua${VCPKG_HOST_EXECUTABLE_SUFFIX}"
        )
    endif()

    set(linux_to_mingw_dynamic OFF)
    if(VCPKG_CROSSCOMPILING AND VCPKG_TARGET_IS_MINGW AND VCPKG_HOST_IS_LINUX
       AND VCPKG_TARGET_ARCHITECTURE STREQUAL "x64" AND VCPKG_LIBRARY_LINKAGE STREQUAL "dynamic")
        set(linux_to_mingw_dynamic ON)
    endif()

    # Linux buildvm binaries from the host port target Linux and cannot emit
    # Windows PE objects. Build the generator locally with TARGET_SYS=Windows.
    if(linux_to_mingw_dynamic)
        find_program(LUAJIT_HOST_CC NAMES cc gcc REQUIRED)
        list(APPEND options "HOST_CC=${LUAJIT_HOST_CC}")
    endif()

    vcpkg_list(SET make_options "EXECUTABLE_SUFFIX=${VCPKG_TARGET_EXECUTABLE_SUFFIX}")
    set(strip_options "") # cf. src/Makefile
    if(VCPKG_TARGET_IS_OSX)
        vcpkg_list(APPEND make_options "TARGET_SYS=Darwin")
        set(strip_options " -x")
    elseif(VCPKG_TARGET_IS_IOS)
        vcpkg_list(APPEND make_options "TARGET_SYS=iOS")
        set(strip_options " -x")
    elseif(VCPKG_TARGET_IS_LINUX)
        vcpkg_list(APPEND make_options "TARGET_SYS=Linux")
    elseif(VCPKG_TARGET_IS_WINDOWS)
        vcpkg_list(APPEND make_options "TARGET_SYS=Windows")
        set(strip_options " --strip-unneeded")
    endif()

    set(dasm_archs "")
    if("buildvm-32" IN_LIST FEATURES)
        string(APPEND dasm_archs " arm x86")
    endif()
    if("buildvm-64" IN_LIST FEATURES)
        string(APPEND dasm_archs " arm64 x64")
    endif()

    file(COPY "${CMAKE_CURRENT_LIST_DIR}/configure" DESTINATION "${SOURCE_PATH}")
    vcpkg_configure_make(SOURCE_PATH "${SOURCE_PATH}"
        COPY_SOURCE
        OPTIONS
            "BUILDMODE=${VCPKG_LIBRARY_LINKAGE}"
            ${options}
        OPTIONS_RELEASE
            "DASM_ARCHS=${dasm_archs}"
    )
    if(linux_to_mingw_dynamic)
        # Upstream explicitly does not support Windows in its install Makefile.
        vcpkg_build_make(
            MAKEFILE "Makefile.vcpkg"
            OPTIONS ${make_options}
                "TARGET_AR=${VCPKG_DETECTED_CMAKE_AR} rcus"
                "TARGET_STRIP=${VCPKG_DETECTED_CMAKE_STRIP}${strip_options}"
        )
        foreach(config IN ITEMS dbg rel)
            if(config STREQUAL "dbg")
                if(VCPKG_BUILD_TYPE)
                    continue()
                endif()
                set(dest "${CURRENT_PACKAGES_DIR}/debug")
            else()
                set(dest "${CURRENT_PACKAGES_DIR}")
            endif()
            set(build_src "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-${config}/src")
            file(INSTALL "${build_src}/lua51.dll" DESTINATION "${dest}/bin")
            file(INSTALL "${build_src}/libluajit-5.1.dll.a" DESTINATION "${dest}/lib")
            file(INSTALL "${build_src}/luajit.exe" DESTINATION "${dest}/bin")
            # Reuse the port's metadata, matching the MinGW import library name.
            file(READ "${CMAKE_CURRENT_LIST_DIR}/luajit.pc" pkgconfig)
            string(REPLACE "libname=lua\${abiver}" "libname=luajit-5.1" pkgconfig "${pkgconfig}")
            file(WRITE "${dest}/lib/pkgconfig/luajit.pc" "${pkgconfig}")
        endforeach()
        foreach(header IN ITEMS lua.h lualib.h lauxlib.h luaconf.h lua.hpp luajit.h)
            file(INSTALL "${build_src}/${header}" DESTINATION "${CURRENT_PACKAGES_DIR}/include/luajit")
        endforeach()
        vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/include/luajit/luaconf.h" "defined(LUA_BUILD_AS_DLL)" "1")
        file(COPY "${build_src}/jit" DESTINATION "${CURRENT_PACKAGES_DIR}/tools/luajit/lua")
    else()
        vcpkg_install_make(
            MAKEFILE "Makefile.vcpkg"
            OPTIONS
                ${make_options}
                "TARGET_AR=${VCPKG_DETECTED_CMAKE_AR} rcus"
                "TARGET_STRIP=${VCPKG_DETECTED_CMAKE_STRIP}${strip_options}"
        )
    endif()
endif()

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
    "${CURRENT_PACKAGES_DIR}/debug/lib/lua"
    "${CURRENT_PACKAGES_DIR}/debug/share"
    "${CURRENT_PACKAGES_DIR}/lib/lua"
    "${CURRENT_PACKAGES_DIR}/share/lua"
    "${CURRENT_PACKAGES_DIR}/share/man"
)

file(REMOVE "${CURRENT_PACKAGES_DIR}/bin/luajit-symlink" "${CURRENT_PACKAGES_DIR}/debug/bin/luajit-symlink")
vcpkg_copy_tools(TOOL_NAMES luajit AUTO_CLEAN)

vcpkg_fixup_pkgconfig()

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYRIGHT")
