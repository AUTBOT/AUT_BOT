@echo off 
call;

mkdir cache

TITLE Check for python 3.8
ECHO.%PATH%| FINDSTR /I "anaconda python miniconda">Nul
if %ERRORLEVEL% neq 0 call :PythonNotFound
py -0| FINDSTR /I "3.8 3.9 3.10">Nul
if %ERRORLEVEL% neq 0 call :PythonNotFound

TITLE Installing necessary libraries...

if exist bot_env\ (
    rem python environment exists
) else (
    rem python environment doesn't exist
    py -m venv bot_env
)

call bot_env\Scripts\activate.bat
py -m pip install --upgrade pip

setlocal enabledelayedexpansion
FOR /F %%k in (config\requirements.txt) DO (
    py -m pip install %%k
    if !ERRORLEVEL! neq 0 (

        for /f "tokens=1,2 delims==" %%a in ("%%k") do (
        set BEFORE_UNDERSCORE=%%a
        py -m pip install %%a
        )
    )
)

TITLE Downloading model weights...
py -c "import model_sync;model_sync.sync_model()"

TITLE Checking Microsoft Edge version
reg query "HKCU\Software\Microsoft\Edge\BLBeacon" /v version >nul
if %ERRORLEVEL% neq 0 goto MicrosoftEdgeNotFound

FOR /F "tokens=2* skip=2" %%a in ('reg query "HKCU\Software\Microsoft\Edge\BLBeacon" /v "version"') do set edge_version=%%b

echo edge version is %edge_version%

TITLE Downloading Microsoft Edge webdriver...
mkdir edge_driver
curl https://msedgedriver.azureedge.net/%edge_version%/edgedriver_win64.zip --output ./cache/edge_driver.zip
powershell Expand-Archive cache\edge_driver.zip -DestinationPath edge_driver

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

:MicrosoftEdgeNotFound
echo [91mMicrosoft Edge not found, Install Edge to use this Bot.[0m
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