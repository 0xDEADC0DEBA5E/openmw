# Once found, defines:
#  LuaJit_FOUND
#  LuaJit_INCLUDE_DIR
#  LuaJit_LIBRARIES

include(LibFindMacros)

libfind_pkg_detect(LuaJit luajit
        FIND_PATH luajit.h PATH_SUFFIXES luajit luajit-2.1
        FIND_LIBRARY luajit-5.1 luajit lua51
        )

libfind_process(LuaJit)

# Static LuaJIT needs the platform math and dynamic-loader libraries as well.
# Keep the library selected by find_library (including its Debug variant).
if(LuaJit_FOUND AND UNIX AND NOT APPLE)
    list(APPEND LuaJit_LIBRARIES m ${CMAKE_DL_LIBS})
    list(REMOVE_DUPLICATES LuaJit_LIBRARIES)
endif()

