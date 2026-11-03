# Resolve the engine's dependencies before passing them to PROJECT_TEMPLATE.
include("${OUT_PROJECT_DIR}/cmake/project.cmake")
list(PREPEND CMAKE_MODULE_PATH "${OUT_PROJECT_DIR}/cmake")

find_package(OpenGL REQUIRED)
find_package(Threads REQUIRED)
find_package(SQLite3 REQUIRED)
if(NOT TARGET SQLite3::SQLite3 AND TARGET SQLite::SQLite3)
    add_library(SQLite3::SQLite3 ALIAS SQLite::SQLite3)
endif()
find_package(LZ4 REQUIRED)
find_package(QT REQUIRED COMPONENTS Core NAMES Qt6)
find_package(Qt6 COMPONENTS Core Widgets Network OpenGL OpenGLWidgets LinguistTools Svg REQUIRED)
find_package(ICU REQUIRED COMPONENTS uc i18n data)
find_package(yaml-cpp REQUIRED)
find_package(FFmpeg REQUIRED COMPONENTS AVCODEC AVFORMAT AVUTIL SWSCALE SWRESAMPLE)
find_package(Boost 1.70 CONFIG REQUIRED COMPONENTS iostreams program_options)
find_package(MyGUI 3.4.3 REQUIRED)
find_package(SDL2 2.26 REQUIRED)
find_package(OpenAL REQUIRED)
find_package(ZLIB REQUIRED)
find_package(RecastNavigation CONFIG REQUIRED)

find_package(Bullet CONFIGS BulletConfig-float64.cmake QUIET COMPONENTS BulletCollision LinearMath)
if(BULLET_FOUND)
    if(NOT IS_ABSOLUTE "${BULLET_INCLUDE_DIRS}")
        set(BULLET_INCLUDE_DIRS "${BULLET_ROOT_DIR}/${BULLET_INCLUDE_DIRS}")
    endif()
else()
    find_package(Bullet 287 REQUIRED COMPONENTS BulletCollision LinearMath)
endif()

option(USE_LUAJIT "Use LuaJIT instead of Lua" ON)
if(USE_LUAJIT)
    find_package(LuaJit REQUIRED)
    set(LUA_INCLUDE_DIR ${LuaJit_INCLUDE_DIR})
    set(LUA_LIBRARIES ${LuaJit_LIBRARIES})
else()
    find_package(Lua 5.1 REQUIRED)
    add_compile_definitions(NO_LUAJIT)
endif()

set(USED_OSG_COMPONENTS
    osgAnimation osgDB osgGA osgFX osgParticle osgText osgUtil osgShadow osgSim osgViewer)
find_package(OpenSceneGraph 3.6.5 REQUIRED COMPONENTS ${USED_OSG_COMPONENTS})

if(USE_SYSTEM_TINYXML)
    find_package(TinyXML REQUIRED)
endif()
if(BUILD_COMPONENTS_TESTS OR BUILD_OPENMW_TESTS OR BUILD_OPENCS_TESTS)
    find_package(GTest 1.10 REQUIRED)
    find_package(GMock 1.10 REQUIRED)
endif()
if(MYGUI_STATIC AND (APPLE OR ANDROID))
    find_package(Freetype REQUIRED)
endif()
if(OSG_STATIC AND CMAKE_SYSTEM_NAME STREQUAL "Linux")
    find_package(X11 REQUIRED COMPONENTS Xinerama Xrandr)
    find_package(Fontconfig QUIET)
endif()

# These dependencies are provided by the repository rather than a package manager.
if(NOT TARGET Base64)
    add_subdirectory("${DEV_PROJECT_DIR}/extern/Base64" "${CMAKE_CURRENT_BINARY_DIR}/Base64")
endif()
if(NOT TARGET smhasher)
    add_subdirectory("${DEV_PROJECT_DIR}/extern/smhasher" "${CMAKE_CURRENT_BINARY_DIR}/smhasher")
endif()

if(TARGET yaml-cpp::yaml-cpp)
    set(ENGINE_YAML_LIBRARY yaml-cpp::yaml-cpp)
else()
    set(ENGINE_YAML_LIBRARY yaml-cpp)
endif()

PROJECT_TEMPLATE(
        SHARED
        MODULE ${RPG}-engine
        PROJECT_DIR ${CMAKE_CURRENT_SOURCE_DIR}
        SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/cpp/src
        INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/cpp/api
        GLOB_SOURCES
        GLOB_INCLUDES
        INCLUDES
        ${OPENSCENEGRAPH_INCLUDE_DIRS}
        ${BULLET_INCLUDE_DIRS}
        ${MyGUI_INCLUDE_DIRS}
        ${LUA_INCLUDE_DIR}
        ${ICU_INCLUDE_DIRS}
        ${FFmpeg_INCLUDE_DIRS}
        ${OPENAL_INCLUDE_DIR}
        ${DEV_PROJECT_DIR}/extern/sol3
        ${DEV_PROJECT_DIR}/extern/sol_config
        DEFINITIONS
        BT_USE_DOUBLE_PRECISION
        MYGUI_DONT_USE_OBSOLETE=ON
        SHARED_LINK
        ${OSGPARTICLE_LIBRARIES}
        ${OSGVIEWER_LIBRARIES}
        ${OSGSHADOW_LIBRARIES}
        ${OSGANIMATION_LIBRARIES}
        ${OSGGA_LIBRARIES}
        ${OSGTEXT_LIBRARIES}
        ${OSGDB_LIBRARIES}
        ${OSGUTIL_LIBRARIES}
        ${OSGSIM_LIBRARIES}
        ${OSG_LIBRARIES}
        ${OPENTHREADS_LIBRARIES}
        ${BULLET_LIBRARIES}

        Boost::program_options
        Boost::iostreams

        Qt6::Widgets
        Qt6::Network
        Qt6::OpenGLWidgets
        Qt6::Svg
        SDL2::SDL2
        ${OPENAL_LIBRARY}
        ${OPENGL_gl_LIBRARY}
        ${FFmpeg_LIBRARIES}
        ${MyGUI_LIBRARIES}
        ${LUA_LIBRARIES}
        LZ4::LZ4
        RecastNavigation::DebugUtils
        RecastNavigation::Detour
        RecastNavigation::Recast

        Base64
        SQLite3::SQLite3
        smhasher
        ${ICU_LIBRARIES}
        ZLIB::ZLIB
        Threads::Threads
        ${ENGINE_YAML_LIBRARY}
)
