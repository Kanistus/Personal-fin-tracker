@echo off
setlocal

set "JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-17.0.19.10-hotspot"
set "APKSIGNER=%LOCALAPPDATA%\Android\Sdk\build-tools\34.0.0\apksigner.bat"
set "FLUTTER=C:\Users\kanis\flutter\flutter\bin\flutter.bat"
set "OUT_APK=build\app\outputs\flutter-apk\app-release.apk"

echo Building signed release APK via Gradle (V1 + V2 + V3)...
call "%FLUTTER%" build apk --release
if %ERRORLEVEL% neq 0 (
    echo BUILD FAILED.
    exit /b %ERRORLEVEL%
)

copy /Y "%OUT_APK%" "personal_fin.apk"

echo.
echo Verifying signature schemes...
call "%APKSIGNER%" verify --verbose "personal_fin.apk"

echo.
echo ===================================================
echo Build complete: personal_fin.apk
echo ===================================================
endlocal
