# Inventario
Scripts e aplicações para acelerar o processo de inventariado


WIN:

Invoke-WebRequest -Uri "https://raw.githubusercontent.com/GilsonJunio/Inventario/refs/heads/main/Sistema-Win.ps1" -OutFile "Sistema.ps1"; powershell -ExecutionPolicy Bypass -File .\Sistema.ps1 | Out-File -FilePath "$HOME\Downloads\RelatorioDoSistema.txt" -Encoding UTF8; Write-Host "Relatório salvo em $HOME\Downloads\RelatorioDoSistema.txt" -ForegroundColor Green; Remove-Item -Path .\Sistema.ps1 -ErrorAction SilentlyContinue; Write-Host "Script baixado ('Sistema.ps1') foi removido." -ForegroundColor Gray

LINUX:

curl -L -o Sistema.sh "https://raw.githubusercontent.com/GilsonJunio/Inventario/refs/heads/main/Sistema" && chmod +x Sistema.sh && sudo ./Sistema.sh > ~/Downloads/RelatorioDoSistema.txt && rm ./Sistema.sh
