@echo off
title JTech Fit App Launcher
<<<<<<< HEAD
set APP_PATH=file:///c:/Users/TI/Desktop/Foco/index.html
=======
set APP_PATH="file:///%~dp0index.html"
>>>>>>> 992c6cf (feat: adicionar configuracoes PWA Vercel, chaves Supabase e estrutura nativa mobile)

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
