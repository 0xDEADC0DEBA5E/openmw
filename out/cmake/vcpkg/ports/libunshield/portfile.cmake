vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO twogood/unshield
    REF "${VERSION}"
    SHA512 fd3b604e8aa3347a1dc58396d6b9a74b167718908a7f3419dce0a57caaa5d67c3e816da74f05d6690707d09348f9898ea321a80e85a01717eedbf18e60abb3d4
)
string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "static" BUILD_STATIC)
vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    # The bundled MD5 code uses pre-C23 function declarations.
    OPTIONS -DBUILD_STATIC=${BUILD_STATIC} -DBUILD_TESTING=OFF -DUSE_OUR_OWN_MD5=ON
        -DCMAKE_C_STANDARD=17 -DCMAKE_C_STANDARD_REQUIRED=ON
)
vcpkg_cmake_install()
vcpkg_cmake_config_fixup(PACKAGE_NAME unshield CONFIG_PATH lib/cmake/unshield)
vcpkg_copy_tools(TOOL_NAMES unshield AUTO_CLEAN)
vcpkg_fixup_pkgconfig()
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include" "${CURRENT_PACKAGES_DIR}/debug/share")
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
