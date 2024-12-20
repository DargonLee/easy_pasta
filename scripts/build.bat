@echo off
setlocal enabledelayedexpansion

echo 开始构建 Windows 版本...

:: 清理旧的构建文件
echo 清理旧的构建文件...
if exist "build\windows" rd /s /q "build\windows"

:: 获取Flutter依赖
echo 获取Flutter依赖...
call flutter pub get

:: 构建应用
echo 构建应用...
call flutter build windows --release

:: 创建安装包（使用NSIS）
if exist "C:\Program Files (x86)\NSIS\makensis.exe" (
    echo 创建安装包...
    
    :: 创建NSIS脚本
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
    
    "C:\Program Files (x86)\NSIS\makensis.exe" "build\windows\installer.nsi"
)

echo Windows 版本构建完成！

@REM scripts\build.bat