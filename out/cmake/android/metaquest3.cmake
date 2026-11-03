include_guard(GLOBAL)

if ( DEFINED ANDROID )
    set( ANDROID_ABI arm64-v8a )
    set( ANDROID_PLATFORM 34 )
    set( VCPKG_TARGET_TRIPLET arm64-android )
    set( VCPKG_TARGET_TRIPLET_ARCH arm64 )
endif()