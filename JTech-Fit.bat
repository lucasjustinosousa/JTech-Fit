@echo off
title JTech Fit App Launcher
set APP_PATH="file:///%~dp0index.html"

echo Iniciando JTech Fit...

:: Verificar se o Microsoft Edge esta disponivel para rodar em modo APP nativo
if exist "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" (
    start "" "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" --app="%APP_PATH%" --window-size=480,880
    exit
)

if exist "%ProgramFiles%\Microsoft\Edge\Application\msedge.exe" (
    start "" "%ProgramFiles%\Microsoft\Edge\Application\msedge.exe" --app="%APP_PATH%" --window-size=480,880
    exit
)

:: Verificar se o Google Chrome esta disponivel
if exist "%ProgramFiles%\Google\Chrome\Application\chrome.exe" (
    start "" "%ProgramFiles%\Google\Chrome\Application\chrome.exe" --app="%APP_PATH%" --window-size=480,880
    exit
)

:: Fallback: abrir no navegador padrao
start "" "%APP_PATH%"
exit
