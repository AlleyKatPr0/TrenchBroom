vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

# SourceForge is unavailable in some network environments (including our CI sandbox),
# so mirror the `clipper_ver6.4.2.zip` contents from GitHub.
vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO jaseg/gerbolyze
    REF b07f461be3d29581c42ec9507f77e562126de9d6
    SHA512 dc905b551add75986fd284c9ab9fc757ef8fbd66aeee0ace4170d362209257f8b38ce47f8a37d6473cd8a17191c148396e5cdee04c3b1644c7bebc22f3647996
)

set(CLIPPER_SOURCE_PATH "${SOURCE_PATH}/upstream/clipper-6.4.2")

vcpkg_apply_patches(
    SOURCE_PATH "${CLIPPER_SOURCE_PATH}"
    PATCHES
        fix_targets.patch
)

vcpkg_cmake_configure(
    SOURCE_PATH "${CLIPPER_SOURCE_PATH}/cpp"
)

vcpkg_cmake_install()
vcpkg_cmake_config_fixup()

if(NOT DEFINED VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "debug")
    file(RENAME "${CURRENT_PACKAGES_DIR}/debug/share/pkgconfig" "${CURRENT_PACKAGES_DIR}/debug/lib/pkgconfig")
endif()
if(NOT DEFINED VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "release")
    file(RENAME "${CURRENT_PACKAGES_DIR}/share/pkgconfig" "${CURRENT_PACKAGES_DIR}/lib/pkgconfig")
endif()
vcpkg_fixup_pkgconfig()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")
file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/FindCLIPPER.cmake" DESTINATION "${CURRENT_PACKAGES_DIR}/share/clipper")
file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/vcpkg-cmake-wrapper.cmake" DESTINATION "${CURRENT_PACKAGES_DIR}/share/clipper")

file(INSTALL "${CLIPPER_SOURCE_PATH}/License.txt" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)

vcpkg_fixup_pkgconfig()
