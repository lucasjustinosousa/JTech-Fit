@echo off
title JTech Fit - Auto Commit & Deploy Vercel
echo ========================================================
echo   JTech Fit - Sincronizacao automatica Git & Vercel
echo ========================================================
echo.

set /p MSG="Digite a mensagem do commit (ou pressione ENTER para mensagem padrao): "
if "%MSG%"=="" set MSG="update: alteracoes do aplicativo JTech Fit"

echo.
echo 1. Adicionando arquivos modificados...
git add .

echo.
echo 2. Criando commit com a mensagem: %MSG%
git commit -m %MSG%

echo.
echo 3. Enviando para o GitHub e Vercel (Auto Deploy)...
git push origin main

echo.
echo ========================================================
echo   SUCESSO! Alteracoes enviadas para o GitHub e Vercel.
echo ========================================================
pause
