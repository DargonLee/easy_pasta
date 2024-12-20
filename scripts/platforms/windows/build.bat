@echo off
setlocal enabledelayedexpansion

call :init
call :check_dependencies || exit /b 1
call :build || exit /b 1
call :create_installer || exit /b 1
exit /b 0

:init
    set "SCRIPT_DIR=%~dp0"
    set "CONFIG_FILE=%SCRIPT_DIR%\..\..\common\config.json"
    exit /b 0

:check_dependencies
    where flutter >nul 2>&1 || (
        echo [ERROR] Flutter not found
        exit /b 1
    )
    exit /b 0

:build
    echo [INFO] Building Windows version...
    call flutter build windows --release
    if errorlevel 1 (
        echo [ERROR] Windows build failed
        exit /b 1
    )
    exit /b 0

:create_installer
    if exist "C:\Program Files (x86)\NSIS\makensis.exe" (
        echo [INFO] Creating installer...
        call :generate_nsis_script
        "C:\Program Files (x86)\NSIS\makensis.exe" "build\windows\installer.nsi"
    ) else (
        echo [WARN] NSIS not found, skipping installer creation
    )
    exit /b 0

:generate_nsis_script
    (
        echo !define PRODUCT_NAME "Easy Paste"
        echo !define PRODUCT_VERSION "1.0.0"
        echo !define PRODUCT_PUBLISHER "Your Company"
        echo Name "${PRODUCT_NAME}"
        echo OutFile "build\windows\EasyPaste-Setup.exe"
        echo InstallDir "$PROGRAMFILES64\Easy Paste"
        echo Section "MainSection" SEC01
        echo     SetOutPath "$INSTDIR"
        echo     File /r "build\windows\runner\Release\*.*"
        echo     CreateDirectory "$SMPROGRAMS\Easy Paste"
        echo     CreateShortCut "$SMPROGRAMS\Easy Paste\Easy Paste.lnk" "$INSTDIR\easy_paste.exe"
        echo SectionEnd
    ) > "build\windows\installer.nsi"
    exit /b 0