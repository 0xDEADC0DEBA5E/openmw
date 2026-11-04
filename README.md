OpenMW
======

OpenMW is an open-source open-world RPG game engine that supports playing Morrowind by Bethesda Softworks. You need to own the game for OpenMW to play Morrowind.

OpenMW also comes with OpenMW-CS, a replacement for Bethesda's Construction Set.

* Version: 0.53.0
* License: GPLv3 (see [LICENSE](https://gitlab.com/OpenMW/openmw/-/raw/master/LICENSE) for more information)
* Website: https://www.openmw.org
* IRC: [#openmw on irc.libera.chat](https://web.libera.chat/#openmw)
* Discord: [official server](https://discord.com/servers/openmw-260439894298460160)
* Matrix #openmw-space:openmw.org
* _Note_: IRC, Discord, and Matrix are bridged to each other.

Font Licenses:
* DejaVuLGCSansMono.ttf: custom (see [files/data/fonts/DejaVuFontLicense.txt](https://gitlab.com/OpenMW/openmw/-/raw/master/files/data/fonts/DejaVuFontLicense.txt) for more information)
* DemonicLetters.ttf: SIL Open Font License (see [files/data/fonts/DemonicLettersFontLicense.txt](https://gitlab.com/OpenMW/openmw/-/raw/master/files/data/fonts/DemonicLettersFontLicense.txt) for more information)
* MysticCards.ttf: SIL Open Font License (see [files/data/fonts/MysticCardsFontLicense.txt](https://gitlab.com/OpenMW/openmw/-/raw/master/files/data/fonts/MysticCardsFontLicense.txt) for more information)

Current Status
--------------

The main quests in Morrowind, Tribunal and Bloodmoon are all completable. Some issues with side quests are to be expected (but rare). Check the [bug tracker](https://gitlab.com/OpenMW/openmw/-/issues/?milestone_title=openmw-1.0) for a list of issues we need to resolve before the "1.0" release. Even before the "1.0" release, however, OpenMW boasts some new [features](https://wiki.openmw.org/index.php?title=Features), such as improved graphics and user interfaces.

Pre-existing modifications created for the original Morrowind engine can be hit-and-miss. The OpenMW script compiler performs more thorough error-checking than Morrowind does, meaning that a mod created for Morrowind may not necessarily run in OpenMW. Some mods also rely on quirky behaviour or engine bugs in order to work. We are considering such compatibility issues on a case-by-case basis - in some cases adding a workaround to OpenMW may be feasible, in other cases fixing the mod will be the only option. If you know of any mods that work or don't work, feel free to add them to the [Mod status](https://wiki.openmw.org/index.php?title=Mod_status) wiki page.

Platform Support
------------------

The officially supported platforms at this time are:

- Windows 10 or later
- macOS 14.8 or later
- Linux

We do not support 32-bit platforms.

We welcome efforts to add more supported platforms!

Getting Started
---------------

* [Installation instructions](https://openmw.readthedocs.io/en/latest/manuals/installation/index.html)
* [Build from source](https://wiki.openmw.org/index.php?title=Development_Environment_Setup)
* [Report a bug](https://gitlab.com/OpenMW/openmw/issues) - read the [guidelines](https://wiki.openmw.org/index.php?title=Bug_Reporting_Guidelines) before submitting your first bug!
* [Known issues](https://gitlab.com/OpenMW/openmw/issues?label_name%5B%5D=Bug)

Building this layout on Linux
-----------------------------

Install GCC 16 with C++26 reflection support, CMake, Ninja, and Git. Configure
Linux and cross-compile Windows in separate build directories:

```sh
cmake -S . -B out/build/linux/gcc16-debug -G Ninja -DCMAKE_SYSTEM_NAME=Linux -DCMAKE_BUILD_TYPE=Debug
cmake -S . -B out/build/windows/gcc16-debug -G Ninja -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_BUILD_TYPE=Debug
```

The equivalent presets are `linux-gcc16-debug` and `windows-gcc16-debug`;
both also have `-release` variants. Windows cross-compilation requires
`x86_64-w64-mingw32-gcc`, `x86_64-w64-mingw32-g++`, and
`x86_64-w64-mingw32-windres` in `/usr/bin`. CMake selects the `x64-linux`
host triplet and either `x64-linux` or `x64-mingw-dynamic` for dependencies.
The first configure downloads and builds missing vcpkg packages, which can take
some time (including Qt and the OpenMW OpenSceneGraph fork). The Linux wizard's
libunshield dependency is supplied by a project overlay. If the checkout
has moved, run with `cmake --fresh` to discard paths cached at the old location.

Building this layout on Windows
-------------------------------

The root CMake project configures the engine in `src/engine`, the game in
`src/tes3`, and the launcher in `src/launcher`. The game and launcher currently
build their existing implementations from `apps`. Engine headers retain their
`components/...` include names through a generated include tree in the build
directory. C++26 with reflection is the default; a newer standard can be selected with
`CMAKE_CXX_STANDARD` when supported by the compiler.

Install MSYS2's MinGW-w64 GCC 16 toolchain, CMake 3.21 or newer, Ninja, and Git.
The presets use `C:/msys64/mingw64/bin`; its `gcc.exe` and `g++.exe` must report
version 16. Both the target and host vcpkg triplets are `x64-mingw-dynamic`.
Clone and bootstrap vcpkg into `deps/vcpkg`, or set
`VCPKG_ROOT` to an existing vcpkg checkout:

```powershell
git clone https://github.com/microsoft/vcpkg.git deps/vcpkg
.\deps\vcpkg\bootstrap-vcpkg.bat -disableMetrics
```

`dependencies.json` is the dependency manifest, pinned to the vcpkg baseline
used by OpenMW's dependency build. CMake generates vcpkg's required `vcpkg.json`
filename in the build directory and restores dependencies before configuring
the project. This includes Qt, SQLite, yaml-cpp, double-precision Bullet, and
the OpenMW OpenSceneGraph and Recast forks. Overlay ports are in
`out/cmake/vcpkg/ports`, with Windows-specific fixes in
`out/cmake/vcpkg/windows-ports`; installed packages are kept in each build directory's
`vcpkg_installed` directory so the target platforms remain separate.
No separate Qt SDK is required. Enable existing test or benchmark targets with
their `BUILD_*` options to restore the corresponding optional packages as well.

From PowerShell at the project root, build and launch with:

```powershell
.\out\build.cmd -Run
```

Use `-Configuration Release` for a release build or `-Install` to install under
`out/install/3377440`. The script verifies GCC 16 and builds all enabled
applications. The equivalent CMake commands are:

```powershell
cmake --preset windows-gcc16-debug
cmake --build --preset windows-gcc16-debug --parallel 8
cmake --build out/build/windows/gcc16-debug --target run
```

In CLion, select the `windows-gcc16-debug` preset with the MinGW toolchain.
The executables, configuration files, resources, and required DLLs are placed
together in `out/build/windows/gcc16-debug`. The runnable targets remain `openmw`
and `openmw-launcher`. Configure the launcher with your Morrowind game files
before playing.

Contributing
---------

Not sure what to do with all your free time? OpenMW is always looking for new contributions. [See here for how to contribute.](./CONTRIBUTING.md)

The data path
-------------

The data path tells OpenMW where to find your Morrowind files. If you run the launcher, OpenMW should be able to pick up the location of these files on its own, if both Morrowind and OpenMW are installed properly (installing Morrowind under WINE is considered a proper install).

Command line options
--------------------

    Syntax: openmw <options>
    Allowed options:
      --config arg                          additional config directories
      --replace arg                         settings where the values from the
                                            current source should replace those
                                            from lower-priority sources instead of
                                            being appended
      --user-data arg                       set user data directory (used for
                                            saves, screenshots, etc)
      --resources arg (=resources)          set resources directory
      --help                                print help message
      --version                             print version information and quit
      --data arg (=data)                    set data directories (later directories
                                            have higher priority)
      --data-local arg                      set local data directory (highest
                                            priority)
      --fallback-archive arg (=fallback-archive)
                                            set fallback BSA archives (later
                                            archives have higher priority)
      --start arg                           set initial cell
      --content arg                         content file(s): esm/esp, or
                                            omwgame/omwaddon/omwscripts
      --groundcover arg                     groundcover content file(s): esm/esp,
                                            or omwgame/omwaddon
      --no-sound [=arg(=1)] (=0)            disable all sounds
      --script-all [=arg(=1)] (=0)          compile all scripts (excluding dialogue
                                            scripts) at startup
      --script-all-dialogue [=arg(=1)] (=0) compile all dialogue scripts at startup
      --script-console [=arg(=1)] (=0)      enable console-only script
                                            functionality
      --script-run arg                      select a file containing a list of
                                            console commands that is executed on
                                            startup
      --script-warn [=arg(=1)] (=1)         handling of warnings when compiling
                                            scripts
                                            0 - ignore warnings
                                            1 - show warnings but consider script as
                                            correctly compiled anyway
                                            2 - treat warnings as errors
      --load-savegame arg                   load a save game file on game startup
                                            (specify an absolute filename or a
                                            filename relative to the current
                                            working directory)
      --skip-menu [=arg(=1)] (=0)           skip main menu on game startup
      --new-game [=arg(=1)] (=0)            run new game sequence (ignored if
                                            skip-menu=0)
      --encoding arg (=win1252)             Character encoding used in OpenMW game
                                            messages:

                                            win1250 - Central and Eastern European
                                            such as Polish, Czech, Slovak,
                                            Hungarian, Slovene, Bosnian, Croatian,
                                            Serbian (Latin script), Romanian and
                                            Albanian languages

                                            win1251 - Cyrillic alphabet such as
                                            Russian, Bulgarian, Serbian Cyrillic
                                            and other languages

                                            win1252 - Western European (Latin)
                                            alphabet, used by default
      --fallback arg                        fallback values
      --no-grab [=arg(=1)] (=0)             Don't grab mouse cursor
      --export-fonts [=arg(=1)] (=0)        Export Morrowind .fnt fonts to PNG
                                            image and XML file in current directory
      --activate-dist arg (=-1)             activation distance override
      --random-seed arg (=<impl defined>)   seed value for random number generator
