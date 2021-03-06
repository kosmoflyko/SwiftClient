@echo off
cd %~dp0

SETLOCAL
SET NUGET_VERSION=v3.2.0
SET CACHED_NUGET=%LocalAppData%\NuGet\nuget.%NUGET_VERSION%.exe
SET BUILDCMD_KOREBUILD_VERSION=0.2.1-beta8
SET BUILDCMD_DNX_VERSION=1.0.0-beta8

IF EXIST %CACHED_NUGET% goto copynuget
echo Downloading latest version of NuGet.exe...
IF NOT EXIST %LocalAppData%\NuGet md %LocalAppData%\NuGet
@powershell -NoProfile -ExecutionPolicy unrestricted -Command "$ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest 'https://dist.nuget.org/win-x86-commandline/%NUGET_VERSION%/nuget.exe' -OutFile '%CACHED_NUGET%'"

:copynuget
IF EXIST .nuget\nuget.exe goto restore
md .nuget
copy %CACHED_NUGET% .nuget\nuget.exe > nul

:restore
IF EXIST packages\KoreBuild goto run
IF %BUILDCMD_KOREBUILD_VERSION%=="" (
	.nuget\nuget.exe install KoreBuild -ExcludeVersion -o packages -nocache -pre
) ELSE (
	.nuget\nuget.exe install KoreBuild -version %BUILDCMD_KOREBUILD_VERSION% -ExcludeVersion -o packages -nocache -pre
)
.nuget\nuget.exe install Sake -ExcludeVersion -Out packages

IF "%SKIP_DNX_INSTALL%"=="1" goto run
IF %BUILDCMD_DNX_VERSION%=="" (
	CALL packages\KoreBuild\build\dnvm upgrade -runtime CLR -arch x86
) ELSE (
	CALL packages\KoreBuild\build\dnvm install %BUILDCMD_DNX_VERSION% -runtime CLR -arch x86 -a default
)
CALL packages\KoreBuild\build\dnvm install default -runtime CoreCLR -arch x86
CALL packages\KoreBuild\build\dnvm install default -runtime CLR -arch x64
CALL packages\KoreBuild\build\dnvm install default -runtime CoreCLR -arch x64

:run
CALL packages\KoreBuild\build\dnvm use default -runtime CLR -arch x86
packages\Sake\tools\Sake.exe -I packages\KoreBuild\build -f makefile.shade %*