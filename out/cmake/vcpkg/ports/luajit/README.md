# LuaJIT Linux-to-MinGW overlay

Based on vcpkg LuaJIT 2026-03-04 (port tree 9b886d100b2c1f11346a201f6350cc225d7853bb).
Keep the upstream support files in sync when updating the vcpkg baseline.

For Linux-to-x64-MinGW dynamic builds, compile buildvm locally using the native
C compiler and LuaJIT's Windows target flags. The Linux host port's buildvm
cannot emit Windows PE objects. Clear target link options for this host tool.
Install Windows artifacts directly because the upstream Unix install target
uses Unix filenames and does not preserve the cross-build settings.

Other configurations retain the baseline port behavior.
