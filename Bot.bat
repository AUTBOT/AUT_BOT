@echo off 
set batchPath=%~dp0
call powershell.exe "python" "'%batchPath%bot.pyc'"