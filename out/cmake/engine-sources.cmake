# Engine source lists and generated files from the upstream components build.

if(APPLE)
    set(BUNDLE_RESOURCES_DIR "${APP_BUNDLE_DIR}/Contents/Resources")
    set(OPENMW_RESOURCES_ROOT ${BUNDLE_RESOURCES_DIR})
endif(APPLE)

# Version file
set (VERSION_RESOURCE_FILE_IN "${OpenMW_SOURCE_DIR}/files/version.in")
set (VERSION_RESOURCE_FILE_RELATIVE "resources/version")
set (VERSION_CPP_FILE "components/version/version.cpp")

if (GIT_CHECKOUT)
    get_generator_is_multi_config(multi_config)
    add_custom_target (get-version
       BYPRODUCTS "${OpenMW_BINARY_DIR}/${VERSION_CPP_FILE}"
       DEPENDS "${ENGINE_SOURCE_DIR}/version/version.cpp.in"
       COMMAND ${CMAKE_COMMAND}
            -DGIT_EXECUTABLE=${GIT_EXECUTABLE}
            -DOpenMW_SOURCE_DIR=${OpenMW_SOURCE_DIR}
            -DOpenMW_BINARY_DIR=${OpenMW_BINARY_DIR}
            -DVERSION_RESOURCE_FILE_IN=${VERSION_RESOURCE_FILE_IN}
            -DVERSION_RESOURCE_FILE_RELATIVE=${VERSION_RESOURCE_FILE_RELATIVE}
            -DVERSION_CPP_FILE_IN=${ENGINE_SOURCE_DIR}/version/version.cpp.in
            -DVERSION_CPP_FILE_OUT=${OpenMW_BINARY_DIR}/${VERSION_CPP_FILE}.out
            -DOPENMW_VERSION_MAJOR=${OPENMW_VERSION_MAJOR}
            -DOPENMW_VERSION_MINOR=${OPENMW_VERSION_MINOR}
            -DOPENMW_VERSION_RELEASE=${OPENMW_VERSION_RELEASE}
            -DOPENMW_LUA_API_REVISION=${OPENMW_LUA_API_REVISION}
            -DOPENMW_POSTPROCESSING_API_REVISION=${OPENMW_POSTPROCESSING_API_REVISION}
            -DOPENMW_VERSION=${OPENMW_VERSION}
            -DOPENMW_DOC_BASEURL=${OPENMW_DOC_BASEURL}
            -DMACROSFILE=${OUT_PROJECT_DIR}/cmake/OpenMWMacros.cmake
            "-DCMAKE_CONFIGURATION_TYPES=${CMAKE_CONFIGURATION_TYPES}"
            -Dgenerator_is_multi_config_var=${multi_config}
            -P ${OUT_PROJECT_DIR}/cmake/GitVersion.cmake
        COMMAND ${CMAKE_COMMAND}
            -E copy_if_different ${OpenMW_BINARY_DIR}/${VERSION_CPP_FILE}.out ${OpenMW_BINARY_DIR}/${VERSION_CPP_FILE}
        VERBATIM)
else (GIT_CHECKOUT)
    configure_resource_file(${VERSION_RESOURCE_FILE_IN} ${OpenMW_BINARY_DIR} ${VERSION_RESOURCE_FILE_RELATIVE})
    configure_file("${ENGINE_SOURCE_DIR}/version/version.cpp.in" "${OpenMW_BINARY_DIR}/${VERSION_CPP_FILE}")
endif (GIT_CHECKOUT)

list (APPEND COMPONENT_FILES "${OpenMW_BINARY_DIR}/${VERSION_CPP_FILE}")

# OSG plugin checker
# Also support dependencies extracted into a local development prefix.
set(OPENMW_OSG_LIBRARY_DIR "")
foreach(library IN LISTS OSGDB_LIBRARY)
    if(EXISTS "${library}")
        get_filename_component(OPENMW_OSG_LIBRARY_DIR "${library}" DIRECTORY)
        break()
    endif()
endforeach()
# Helpfully, OSG doesn't export this to its CMake config as it doesn't have one
list(TRANSFORM USED_OSG_PLUGINS REPLACE "^osgdb_" "" OUTPUT_VARIABLE USED_OSG_PLUGIN_NAMES)
list(TRANSFORM USED_OSG_PLUGIN_NAMES PREPEND "\"" OUTPUT_VARIABLE USED_OSG_PLUGIN_NAMES_FORMATTED)
list(TRANSFORM USED_OSG_PLUGIN_NAMES_FORMATTED APPEND "\"")
list(JOIN USED_OSG_PLUGIN_NAMES_FORMATTED ", " USED_OSG_PLUGIN_NAMES_FORMATTED)

set(OSG_PLUGIN_CHECKER_CPP_FILE "components/misc/osgpluginchecker.cpp")
configure_file("${ENGINE_SOURCE_DIR}/misc/osgpluginchecker.cpp.in" "${OpenMW_BINARY_DIR}/${OSG_PLUGIN_CHECKER_CPP_FILE}")
list(APPEND COMPONENT_FILES "${OpenMW_BINARY_DIR}/${OSG_PLUGIN_CHECKER_CPP_FILE}")

# source files

add_component_dir ("${ENGINE_SOURCE_DIR}/lua"
    luastate scriptscontainer asyncpackage utilpackage serialization configuration l10n storage utf8
    shapes/box inputactions yamlloader scripttracker luastateptr
    )
copy_resource_file("${ENGINE_SOURCE_DIR}/lua/util.lua" "${OPENMW_RESOURCES_ROOT}" "resources/lua_libs/util.lua")

add_component_dir ("${ENGINE_SOURCE_DIR}/l10n"
    messagebundles manager
    )

add_component_dir ("${ENGINE_SOURCE_DIR}/settings"
    categories
    categories/camera
    categories/cells
    categories/fog
    categories/game
    categories/general
    categories/groundcover
    categories/gui
    categories/hud
    categories/input
    categories/lua
    categories/map
    categories/models
    categories/navigator
    categories/physics
    categories/postprocessing
    categories/saves
    categories/shaders
    categories/shadows
    categories/sound
    categories/stereo
    categories/stereoview
    categories/terrain
    categories/video
    categories/water
    categories/windows
    gyroscopeaxis
    hrtfmode
    navmeshrendermode
    parser
    sanitizer
    sanitizerimpl
    settings
    settingvalue
    shadermanager
    values
    windowmode
    )

add_component_dir ("${ENGINE_SOURCE_DIR}/bgsm"
    stream file
    )

add_component_dir ("${ENGINE_SOURCE_DIR}/bsa"
    bsafile compressedbsafile ba2gnrlfile ba2dx10file ba2file memorystream
    )

add_component_dir ("${ENGINE_SOURCE_DIR}/bullethelpers"
    collisionobject
    heightfield
    operators
    processtrianglecallback
    transformboundingbox
    )

add_component_dir ("${ENGINE_SOURCE_DIR}/vfs"
    manager archive bsaarchive filesystemarchive pathutil registerarchives
    )

add_component_dir ("${ENGINE_SOURCE_DIR}/resource"
    scenemanager keyframemanager imagemanager animblendrulesmanager bulletshapemanager bulletshape niffilemanager objectcache resourcesystem
    resourcemanager stats animation foreachbulletobject errormarker cachestats bgsmfilemanager
    )

add_component_dir ("${ENGINE_SOURCE_DIR}/shader"
    shadermanager shadervisitor removedalphafunc
    )

add_component_dir ("${ENGINE_SOURCE_DIR}/sceneutil"
    clone attach visitor util statesetupdater stateupdater controller skeleton riggeometry morphgeometry lightcontroller
    lightmanager lightutil positionattitudetransform workqueue pathgridutil waterutil writescene serialize optimizer
    detourdebugdraw navmesh agentpath animblendrules shadow mwshadowtechnique recastmesh shadowsbin osgacontroller rtt
    screencapture depth color riggeometryosgaextension extradata unrefqueue lightcommon clearcolor
    cullsafeboundsvisitor keyframe nodecallback templateref textkeymap userdata glextensions fog texmat material
    )

add_component_dir ("${ENGINE_SOURCE_DIR}/nif"
    base controller data effect extra niffile nifkey nifstream niftypes node parent particle physics property record recordptr texture
    )

add_component_dir ("${ENGINE_SOURCE_DIR}/nifosg"
    autotransform nifloader controller particle matrixtransform
    )

add_component_dir ("${ENGINE_SOURCE_DIR}/nifbullet"
    bulletnifloader
    )

add_component_dir ("${ENGINE_SOURCE_DIR}/toutf8"
    tablesgen
    toutf8
    )

add_component_dir("${ENGINE_SOURCE_DIR}/esm" attr common defs esmcommon records util luascripts format refid esmbridge esmterrain
    formid
    fourcc
    stringrefid
    generatedrefid
    indexrefid
    serializerefid
    esm3exteriorcellrefid
    quaternion
    vector3
    exteriorcelllocation
    )

add_component_dir("${ENGINE_SOURCE_DIR}/fx" pass technique lexer lexertypes parseconstants widgets stateupdater)

add_component_dir("${ENGINE_SOURCE_DIR}/std140" ubo)

add_component_dir ("${ENGINE_SOURCE_DIR}/esm3"
    esmreader esmwriter loadacti loadalch loadappa loadarmo loadbody loadbook loadbsgn loadcell
    loadclas loadclot loadcont loadcrea loaddial loaddoor loadench loadfact loadglob loadgmst
    loadinfo loadingr loadland loadlevlist loadligh loadlock loadprob loadrepa loadltex loadmgef loadmisc
    loadnpc loadpgrd loadrace loadregn loadscpt loadskil loadsndg loadsoun loadspel loadsscr loadstat
    loadweap aipackage effectlist spelllist variant variantimp loadtes3 cellref filter
    savedgame journalentry queststate locals globalscript player objectstate cellid cellstate globalmap
    inventorystate containerstate npcstate creaturestate dialoguestate statstate npcstats creaturestats
    weatherstate quickkeys fogstate spellstate activespells creaturelevliststate doorstate projectilestate debugprofile
    aisequence magiceffects custommarkerstate stolenitems transport animationstate controlsstate mappings readerscache
    infoorder timestamp formatversion landrecorddata selectiongroup dialoguecondition
    refnum actoridconverter
    )

add_component_dir ("${ENGINE_SOURCE_DIR}/esmterrain"
    gridsampling
    storage
    )

add_component_dir ("${ENGINE_SOURCE_DIR}/esm4"
    actor
    cellgrid
    common
    dialogue
    effect
    grid
    grouptype
    inventory
    lighting
    loadachr
    loadacti
    loadalch
    loadaloc
    loadammo
    loadanio
    loadappa
    loadarma
    loadarmo
    loadaspc
    loadbook
    loadbptd
    loadcell
    loadclas
    loadclfm
    loadclot
    loadcont
    loadcrea
    loaddial
    loaddobj
    loaddoor
    loadeyes
    loadflor
    loadflst
    loadfurn
    loadglob
    loadgmst
    loadgras
    loadgrup
    loadhair
    loadhdpt
    loadidle
    loadidlm
    loadimod
    loadinfo
    loadingr
    loadkeym
    loadland
    loadlgtm
    loadligh
    loadltex
    loadlvlc
    loadlvli
    loadlvln
    loadmato
    loadmisc
    loadmset
    loadmstt
    loadmusc
    loadnavi
    loadnavm
    loadnote
    loadnpc
    loadotft
    loadpack
    loadpgrd
    loadpgre
    loadpwat
    loadqust
    loadrace
    loadrefr
    loadregn
    loadroad
    loadsbsp
    loadscol
    loadscpt
    loadscrl
    loadsgst
    loadslgm
    loadsndr
    loadsoun
    loadstat
    loadtact
    loadterm
    loadtes4
    loadtree
    loadtxst
    loadweap
    loadwrld
    magiceffectid
    reader
    readerutils
    reference
    script
    typetraits
    vertex
)

add_component_dir ("${ENGINE_SOURCE_DIR}/misc"
    barrier budgetmeasurement color compression constants convert coordinateconverter display endianness float16 frameratelimiter framestats
    guarded math mathutil messageformatparser notnullptr objectpool osgpluginchecker osguservalues progressreporter resourcehelpers
    rng strongtypedef thread timeconvert timer tuplehelpers tuplemeta utf8stream weakcache windows
    )

add_component_dir ("${ENGINE_SOURCE_DIR}/misc/strings"
    algorithm conversion format lower
    )

add_component_dir ("${ENGINE_SOURCE_DIR}/stereo"
    frustum multiview stereomanager types
    )

add_component_dir ("${ENGINE_SOURCE_DIR}/debug"
    debugging debuglog gldebug debugdraw writeflags
    )
add_component_dir ("${ENGINE_SOURCE_DIR}/files"
    linuxpath androidpath windowspath macospath fixedpath multidircollection collections configurationmanager
    constrainedfilestream memorystream hash configfileparser openfile constrainedfilestreambuf conversion
    istreamptr streamwithbuffer utils
    )

if(NOT CMAKE_CXX_COMPILER_ID STREQUAL "MSVC" AND NOT CMAKE_CXX_COMPILER_FRONTEND_VARIANT STREQUAL "MSVC")
    set_source_files_properties("${ENGINE_SOURCE_DIR}/files/configfileparser.cpp" PROPERTIES COMPILE_FLAGS -Wno-shadow)
endif()

if (NOT WIN32 AND NOT APPLE)
    set_source_files_properties("${ENGINE_SOURCE_DIR}/files/linuxpath.cpp" PROPERTIES COMPILE_DEFINITIONS "GLOBAL_DATA_PATH=\"${GLOBAL_DATA_PATH}\";GLOBAL_CONFIG_PATH=\"${GLOBAL_CONFIG_PATH}\"")
endif ()

add_component_dir ("${ENGINE_SOURCE_DIR}/compiler"
    context controlparser errorhandler exception exprparser extensions fileparser generator
    lineparser literals locals output parser scanner scriptparser skipparser streamerrorhandler
    stringparser tokenloc nullerrorhandler opcodes extensions0 declarationparser
    quickfileparser discardparser junkparser
    )

add_component_dir ("${ENGINE_SOURCE_DIR}/interpreter"
    context controlopcodes genericopcodes installopcodes interpreter localopcodes mathopcodes
    miscopcodes opcodes program runtime types defines
    )

add_component_dir ("${ENGINE_SOURCE_DIR}/translation"
    translation
    )

add_component_dir ("${ENGINE_SOURCE_DIR}/terrain"
    storage world buffercache defs terraingrid material terraindrawable texturemanager chunkmanager compositemaprenderer
    quadtreeworld quadtreenode viewdata cellborder view heightcull
    )

add_component_dir ("${ENGINE_SOURCE_DIR}/loadinglistener"
    loadinglistener asynclistener
    )

add_component_dir ("${ENGINE_SOURCE_DIR}/myguiplatform"
    myguirendermanager myguidatamanager myguiplatform myguitexture myguiloglistener additivelayer scalinglayer
    )

add_component_dir ("${ENGINE_SOURCE_DIR}/widgets"
    box fontwrapper imagebutton tags list numericeditbox sharedstatebutton windowcaption widgets
    )

add_component_dir ("${ENGINE_SOURCE_DIR}/fontloader"
    fontloader
    )

add_component_dir ("${ENGINE_SOURCE_DIR}/sdlutil"
    events
    gl4esinit
    imagetosurface
    sdlcursormanager
    sdlgraphicswindow
    sdlinputwrapper
    sdlmappings
    sdlvideowrapper
    vsyncmode
    )

add_component_dir ("${ENGINE_SOURCE_DIR}/version"
    version
    )

add_component_dir ("${ENGINE_SOURCE_DIR}/fallback"
    fallback validate
    )

add_component_dir ("${ENGINE_SOURCE_DIR}/lua_ui"
    registerscriptsettings scriptsettings
    properties widget input element util layers content alignment resources
    adapter text textedit window image container flex padding
    )
copy_resource_file("${ENGINE_SOURCE_DIR}/lua_ui/content.lua" "${OPENMW_RESOURCES_ROOT}" "resources/lua_libs/content.lua")


if(WIN32)
    add_component_dir ("${ENGINE_SOURCE_DIR}/crashcatcher"
        windowscrashcatcher
        windowscrashdumppathhelpers
        windowscrashmonitor
        windowscrashshm
    )
elseif(NOT ANDROID)
    add_component_dir ("${ENGINE_SOURCE_DIR}/crashcatcher"
        crashcatcher
    )
    if (EXTRA_DEBUGINFOD_URLS)
        set_source_files_properties("${ENGINE_SOURCE_DIR}/crashcatcher/crashcatcher.cpp" PROPERTIES COMPILE_DEFINITIONS "EXTRA_DEBUGINFOD_URLS=\"${EXTRA_DEBUGINFOD_URLS}\"")
    endif ()
endif()

add_component_dir("${ENGINE_SOURCE_DIR}/detournavigator"
    agentbounds
    areatype
    asyncnavmeshupdater
    bounds
    cellgridbounds
    changetype
    collisionshapetype
    commulativeaabb
    dbrefgeometryobject
    debug
    exceptions
    findrandompointaroundcircle
    findsmoothpath
    flags
    generatenavmeshtile
    gettilespositions
    guardednavmeshcacheitem
    heightfieldshape
    makenavmesh
    navigator
    navigatorimpl
    navigatorstub
    navigatorutils
    navmeshcacheitem
    navmeshdata
    navmeshdb
    navmeshdbutils
    navmeshmanager
    navmeshtilescache
    navmeshtileview
    objectid
    objecttransform
    offmeshconnection
    offmeshconnectionsmanager
    preparednavmeshdata
    preparednavmeshdatatuple
    raycast
    recast
    recastallocutils
    recastcontext
    recastglobalallocator
    recastmesh
    recastmeshbuilder
    recastmeshobject
    recastmeshprovider
    recastmeshtiles
    recastparams
    recasttempallocator
    ref
    serialization
    settings
    settingsutils
    sharednavmeshcacheitem
    stats
    status
    tilebounds
    tilecachedrecastmeshmanager
    tileposition
    tilespositionsrange
    updateguard
    version
    waitconditiontype
    )

add_component_dir("${ENGINE_SOURCE_DIR}/loadinglistener"
    reporter
    )

add_component_dir("${ENGINE_SOURCE_DIR}/serialization"
    binaryreader
    binarywriter
    osgyaml
    sizeaccumulator
    )

add_component_dir("${ENGINE_SOURCE_DIR}/sqlite3"
    db
    request
    statement
    transaction
)

add_component_dir("${ENGINE_SOURCE_DIR}/esmloader"
    lessbyid
    load
    esmdata
)

add_component_dir("${ENGINE_SOURCE_DIR}/navmeshtool"
    protocol
    )

add_component_dir("${ENGINE_SOURCE_DIR}/platform"
    platform
    file
    )

if (WIN32)
    add_component_dir("${ENGINE_SOURCE_DIR}/platform"
        filewin32
        )
elseif (UNIX)
    add_component_dir("${ENGINE_SOURCE_DIR}/platform"
        fileposix
        )
else ()
    add_component_dir("${ENGINE_SOURCE_DIR}/platform"
        filestdio
        )
endif()

add_component_dir("${ENGINE_SOURCE_DIR}/testing"
    expecterror
    util
)

if (USE_QT)
    add_component_qt_dir ("${ENGINE_SOURCE_DIR}/contentselector"
        model/modelitem model/esmfile
        model/contentmodel
        model/loadordererror
        view/combobox view/contentselector
        )

    add_component_qt_dir ("${ENGINE_SOURCE_DIR}/config"
        gamesettings
        launchersettings
        )

    add_component_qt_dir ("${ENGINE_SOURCE_DIR}/l10n"
        qttranslations
        )

    add_component_qt_dir ("${ENGINE_SOURCE_DIR}/process"
        processinvoker
        )

    add_component_qt_dir ("${ENGINE_SOURCE_DIR}/misc"
        helpviewer utf8qtextstream hash scalableicon
        )

    add_component_qt_dir ("${ENGINE_SOURCE_DIR}/files"
        qtconversion
        qtconfigpath
        )

    add_component_qt_dir ("${ENGINE_SOURCE_DIR}/platform"
        application
        )

    add_component_qt_dir ("${ENGINE_SOURCE_DIR}/vfs"
        qtconversion
        )

endif()

if (MSVC)
    # these TUs take a lot of memory for codegen
    # in CI, they often go over the 8GB memory limit if another cl.exe is running at the same time
    # this option (make sure you're not looking at the docs for the identically-named linker option) stops four codegen threads being spun off
    # it hurts build time ~33% to enable this unnecessarily, though, so target it to the hungriest boys
    set_source_files_properties(
        "${ENGINE_SOURCE_DIR}/detournavigator/tilecachedrecastmeshmanager.cpp"
        "${ENGINE_SOURCE_DIR}/lua/utilpackage.cpp"
        PROPERTIES
        COMPILE_OPTIONS /cgthreads1
    )
endif()

