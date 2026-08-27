@echo off
title JTech Fit - Auto Commit ^& Deploy Vercel
echo ========================================================
echo   JTech Fit - Sincronizacao automatica Git ^& Vercel
echo ========================================================
echo.

set MSG=%~1
if "%MSG%"=="" (
    set /p MSG="Digite a mensagem do commit (ou pressione ENTER para mensagem padrao): "
)
if "%MSG%"=="" set MSG=update: alteracoes no aplicativo JTech Fit

echo 1. Adicionando arquivos modificados...
git add .

echo 2. Criando commit...
git commit -m "%MSG%"

echo 3. Enviando para o GitHub e Vercel (Auto Deploy)...
git push origin main

echo ========================================================
echo   SUCESSO! Alteracoes enviadas para o GitHub e Vercel.
echo ========================================================
