@echo off 
set batchPath=%~dp0
call bot_env\Scripts\activate.bat
call powershell.exe "python" "'%batchPath%bot.pyc'"