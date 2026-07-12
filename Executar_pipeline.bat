@echo off
setlocal

cd /d "%~dp0"

echo ================================================
echo Hamburgueria BlackBull - Automacao de Dados
echo ================================================
echo.
echo Carregando banco de dados...
echo.

python "src\orquestrador.py"
set "RESULTADO=%ERRORLEVEL%"

echo.
if "%RESULTADO%"=="0" (
    echo Carga do Banco de Dados Concluida com Sucesso.
    echo.
    echo O banco foi carregado, tratado e validado.
) else (
    echo Erro ao Carregar Banco de Dados.
    echo.
    echo Possivel erro encontrado no processo:
    echo -----------------------------------------------

    rem NOTE: pega o log mais recente do orquestrador e mostra as ultimas linhas de erro.
    powershell -NoProfile -Command "$log = Get-ChildItem -Path '.\logs' -Filter 'orquestrador_*.log' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1; if ($log) { Select-String -Path $log.FullName -Pattern 'Pipeline falhou|ERROR|Traceback|falhou|Exception|IntegrityError|OperationalError' | Select-Object -Last 8 | ForEach-Object { $_.Line } } else { Write-Output 'Nenhum log encontrado. Verifique se o Python esta instalado e se o caminho do projeto esta correto.' }"

    echo -----------------------------------------------
    echo.
    echo Consulte a pasta logs para o detalhe completo do erro.
)

echo.
pause
endlocal
