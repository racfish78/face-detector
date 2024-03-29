:: Usage:
:: - Drag & drop .cpp file on this file from Windows explorer
:: - Run from cmd/powershell:
::   - > _winpack_build_sample.cmd cpp\opencv_version.cpp
:: Requires:
:: - CMake
:: - MSVS 2015/2017
:: (tools are searched on default paths or environment should be pre-configured)
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

set SCRIPTDIR=%~dp0
if NOT exist "%SCRIPTDIR%\..\..\build" (
  set "MSG=OpenCV Winpack installation is required"
  goto die
)

if [%1]==[] (
  set "MSG=Sample path is required"
  goto die
)
if exist %1\* (
  set "MSG=Only .cpp samples are allowed (not a directory): %1"
  goto die
)
if NOT "%~x1" == ".cpp" (
  set "MSG=Only .cpp samples are allowed: %~x1"
  goto die
)
set SRC_FILENAME=%~dpnx1
echo SRC_FILENAME=!SRC_FILENAME!
call :dirname "!SRC_FILENAME!" SRC_DIR
echo SRC_DIR=!SRC_DIR!
set "SRC_NAME=%~n1"
echo SRC_NAME=!SRC_NAME!
echo ================================================================================

:: Path to FFMPEG binary files
set "PATH=!PATH!;!SCRIPTDIR!\..\..\build\bin\"

:: Detect compiler
cl /? >NUL 2>NUL <NUL
if !ERRORLEVEL! NEQ 0 (
  PUSHD !CD!
  if exist "C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\VC\Auxiliary\Build\vcvars64.bat" (
    CALL "C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\VC\Auxiliary\Build\vcvars64.bat"
    goto check_msvc
  )
  if exist "C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\VC\Auxiliary\Build\vcvars64.bat" (
    CALL "C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\VC\Auxiliary\Build\vcvars64.bat"
    goto check_msvc
  )
  if exist "C:\Program Files (x86)\Microsoft Visual Studio\2017\BuildTools\VC\Auxiliary\Build\vcvars64.bat" (
    CALL "C:\Program Files (x86)\Microsoft Visual Studio\2017\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
    goto check_msvc
  )
  if exist "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat" (
    CALL "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat" amd64
    goto check_msvc
  )
:check_msvc
  POPD
  cl /? >NUL 2>NUL <NUL
  if !ERRORLEVEL! NEQ 0 (
    set "MSG=Can't detect Microsoft Visial Studio C++ compiler (cl.exe). MSVS 2015/2017 are supported only from standard locations"
    goto die
  )
)

:: Detect CMake
cmake --version >NUL 2>NUL
if !ERRORLEVEL! EQU 0 (
  set CMAKE_FOUND=1
) else (
  if exist "C:\Program Files\CMake\bin" (
    set "PATH=!PATH!;C:\Program Files\CMake\bin"
    cmake --version >NUL 2>NUL
    if !ERRORLEVEL! EQU 0 (
      set CMAKE_FOUND=1
    )
  )
)
if NOT DEFINED CMAKE_FOUND (
  set "MSG=CMake is required to build OpenCV samples. Download it from here: https://cmake.org/download/ and install into 'C:\Program Files\CMake'"
  goto die
) else (
  call :execute cmake --version
  echo CMake is detected
)

:: Detect available MSVS version
if NOT DEFINED VisualStudioVersion (
  set "MSG=Can't determine MSVS version. 'VisualStudioVersion' is not defined"
  goto die
)
if "!VisualStudioVersion!" == "14.0" (
  set CMAKE_GENERATOR="Visual Studio 14 Win64"
  set "PATH=!PATH!;!SCRIPTDIR!\..\..\build\x64\vc14\bin\"
) else (
  if "!VisualStudioVersion!" == "15.0" (
    set CMAKE_GENERATOR="Visual Studio 15 Win64"
    set "PATH=!PATH!;!SCRIPTDIR!\..\..\build\x64\vc15\bin\"
  ) else (
    set "MSG=Unsupported MSVS version. VisualStudioVersion=!VisualStudioVersion!"
    goto die
  )
)

set "BUILD_DIR=!SRC_DIR!\build_!SRC_NAME!"
call :set_title Create build directory
if NOT exist "!BUILD_DIR!" ( call :execute md "!BUILD_DIR!" )
PUSHD "!BUILD_DIR!"
if NOT exist "!BUILD_DIR!/sample" ( call :execute md "!BUILD_DIR!/sample" )
call :execute copy /Y "!SCRIPTDIR!/CMakeLists.example.in" "!BUILD_DIR!/sample/CMakeLists.txt"

call :set_title Configuring via CMake
call :execute cmake -G!CMAKE_GENERATOR! "!BUILD_DIR!\sample" -DEXAMPLE_NAME=!SRC_NAME! "-DEXAMPLE_FILE=!SRC_FILENAME!" "-DOpenCV_DIR=!SCRIPTDIR!\..\..\build"
if !ERRORLEVEL! NEQ 0 (
  set "MSG=CMake configuration step failed: !BUILD_DIR!"
  goto die
)

call :set_title Build sample project via CMake
call :execute cmake --build . --config Release
if !ERRORLEVEL! NEQ 0 (
  set "MSG=Build step failed: !BUILD_DIR!"
  goto die
)

call :set_title Launch !SRC_NAME!
if NOT exist "!BUILD_DIR!\Release\!SRC_NAME!.exe" (
  echo. "ERROR: Can't find executable file (build seems broken): !SRC_NAME!.exe"
) else (
  cd "!BUILD_DIR!\Release"
  call :execute "!SRC_NAME!.exe" --help
  echo ================================================================================
  echo **  Type '!SRC_NAME!.exe' to run sample application
  echo **  Type '!SRC_NAME!.exe --help' to get list of available options (if available)
  echo **  Type 'start ..\!SRC_NAME!.sln' to launch MSVS IDE
  echo **  Type 'cmake --build .. --config Release' to rebuild sample
  echo **  Type 'exit' to exit from interactive shell and open the build directory
  echo ================================================================================
)

call :set_title Hands-on: !SRC_NAME!
cmd /k echo Current directory: !CD!

call :set_title Done: !SRC_NAME!
echo Opening build directory with project files...
explorer "!BUILD_DIR!"

POPD
echo Done!

pause
exit /B 0


::
:: Helper routines
::

:set_title
  title OpenCV sample: %*
  EXIT /B 0

:execute
  echo =================================================================================
  setlocal enableextensions disabledelayedexpansion
  echo %*
  call %*
  endlocal
  EXIT /B %ERRORLEVEL%

:dirname file resultVar
  setlocal
  set _dir=%~dp1
  set _dir=%_dir:~0,-1%
  endlocal & set %2=%_dir%
  EXIT /B 0

:: 'goto die' instead of 'call'
:die
  TITLE OpenCV sample: ERROR: %MSG%
  echo ERROR: %MSG%
  pause
  EXIT /B 1
