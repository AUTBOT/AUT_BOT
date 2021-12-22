@echo off 
call;

netsh interface ipv4 set dns "Wi-Fi" static 178.22.122.100
netsh interface ipv4 add dns "Wi-Fi" 185.51.200.2 index=2

mkdir cache

TITLE Check for python 3.8
ECHO.%PATH%| FINDSTR /I "anaconda python miniconda">Nul
if %ERRORLEVEL% neq 0 call :PythonNotFound
py -0| FINDSTR /I "3.8 3.9 3.10">Nul
if %ERRORLEVEL% neq 0 call :PythonNotFound

TITLE Installing necessary libraries...
py -m venv bot_env
call bot_env\Scripts\activate.bat

setlocal enabledelayedexpansion
FOR /F %%k in (config\requirements.txt) DO (
    py -m pip install %%k
    echo errorlevel is !ERRORLEVEL!
    if !ERRORLEVEL! neq 0 (

        for /f "tokens=1,2 delims==" %%a in ("%%k") do (
        set BEFORE_UNDERSCORE=%%a
        py -m pip install %%a
        )
    )
)

TITLE Downloading model weights...
py -c "import model_sync;model_sync.sync_model()"

TITLE Checking Google Chrome version
reg query "HKEY_CURRENT_USER\Software\Google\Chrome\BLBeacon" /v version >nul
if %ERRORLEVEL% neq 0 goto GoogleChromeNotFound

FOR /F "tokens=2* skip=2" %%a in ('reg query "HKEY_CURRENT_USER\Software\Google\Chrome\BLBeacon" /v "version"') do set chrome_version=%%b

echo chrome version is %chrome_version%

TITLE Downloading Google Chrome webdriver...
mkdir chrome_driver
curl https://chromedriver.storage.googleapis.com/%chrome_version%/chromedriver_win32.zip --output ./chrome_driver/chromedriver.exe

TITLE Creating Desktop shortcut...
set batchPath=%~dp0
echo Set oWS = WScript.CreateObject("WScript.Shell") > CreateShortcut.vbs
echo sLinkFile = "%HOMEDRIVE%%HOMEPATH%\Desktop\AUT-Bot.lnk" >> CreateShortcut.vbs
echo Set oLink = oWS.CreateShortcut(sLinkFile) >> CreateShortcut.vbs
echo oLink.TargetPath = "%batchPath%Bot.vbs" >> CreateShortcut.vbs
echo oLink.IconLocation = "%batchPath%weights\icon.ico" >> CreateShortcut.vbs
echo oLink.WorkingDirectory = "%batchPath%" >> CreateShortcut.vbs
echo oLink.Save >> CreateShortcut.vbs
cscript CreateShortcut.vbs
del CreateShortcut.vbs

rmdir /s/q "cache"
exit /b 0

:GoogleChromeNotFound
echo [91mNo Google Chrome found, Install Chrome to use the Bot.[0m
exit /b 1

:PythonNotFound
TITLE Downloading python 3.8 ...
if exist cache\python-3.8.3-amd64.exe (
    rem file exists
) else (
    rem file doesn't exist
    curl https://www.python.org/ftp/python/3.8.3/python-3.8.3-amd64.exe --output ./cache/python-3.8.3-amd64.exe.part
    ren cache\python-3.8.3-amd64.exe.part cache\python-3.8.3-amd64.exe
)
TITLE Installing python 3.8 ...
cache\python-3.8.3-amd64.exe /passive
SETX /M PATH %PATH%;"%LocalAppData%\Programs\Python\Python38"
call;