vcpkg_check_linkage(ONLY_STATIC_LIBRARY)
vcpkg_download_distfile(archive
    URLS "https://github.com/OpenMW/recastnavigation/archive/03259f3287ff8330f0d66fcd98d022edddffaa97.zip"
    FILENAME "OpenMW-recastnavigation-03259f3287ff8330f0d66fcd98d022edddffaa97.zip"
    SHA512 63db2ac90904764d7f1466d3c95994ec51d777cddd870b70f8ef674c09ed166b3d16ffc4ac1d18d0eab865fda4bf51b6ea17049025b66a338d3cadd0f48dc712
)
vcpkg_extract_source_archive(SOURCE_PATH ARCHIVE "${archive}")
vcpkg_cmake_configure(SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DRECASTNAVIGATION_DEMO=OFF
        -DRECASTNAVIGATION_TESTS=OFF
        -DRECASTNAVIGATION_EXAMPLES=OFF
)
vcpkg_cmake_install()
vcpkg_cmake_config_fixup(PACKAGE_NAME recastnavigation CONFIG_PATH lib/cmake/recastnavigation)
vcpkg_fixup_pkgconfig()
vcpkg_copy_pdbs()
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/License.txt")
