finally {
    # --- Finaliza o Log (Transcript), Copia e TENTA Remover o Arquivo Temporário ---
    Write-Host ""
    Write-Host "Finalizando a gravação do log temporário..." -ForegroundColor Gray
    Stop-Transcript # Para a gravação no arquivo temporário

    # Verifica se o arquivo temporário existe
    if (Test-Path $tempLogPath) {
        $copyError = $null
        $removeError = $null
        try {
            Write-Host "Copiando log de '$tempLogPath' para '$finalLogPath'..." -ForegroundColor Gray
            # 1. COPIA o arquivo temporário para o destino final, sobrescrevendo se necessário
            Copy-Item -Path $tempLogPath -Destination $finalLogPath -Force -ErrorAction Stop
            Write-Host "Relatório final salvo com sucesso em: $finalLogPath" -ForegroundColor Green

            # 2. Se a cópia foi bem-sucedida, TENTA REMOVER o temporário
            try {
                 Write-Host "Removendo arquivo temporário '$tempLogPath'..." -ForegroundColor Gray
                 Remove-Item -Path $tempLogPath -Force -ErrorAction Stop
                 Write-Host "Arquivo temporário removido com sucesso." -ForegroundColor Gray
            } catch {
                # Captura erro APENAS na remoção do arquivo temporário
                $removeError = $_.Exception.Message
                Write-Warning "AVISO: O log foi copiado para Downloads, mas FALHA ao REMOVER o arquivo temporário '$tempLogPath'. Pode ser necessário removê-lo manualmente. Detalhes: $removeError"
            }

        } catch {
            # Captura erro na CÓPIA para o destino final
            $copyError = $_.Exception.Message
            Write-Error "ERRO CRÍTICO: Falha ao COPIAR o log temporário para '$finalLogPath'. Verifique as permissões na pasta Downloads. O log original pode estar em '$tempLogPath'. Detalhes: $copyError"
            # Tenta remover o temporário mesmo se a cópia falhar, para limpar
            Remove-Item -Path $tempLogPath -Force -ErrorAction SilentlyContinue
        }
    } else {
        # Se o arquivo temporário não foi encontrado após Stop-Transcript
        Write-Warning "AVISO: O arquivo de log temporário '$tempLogPath' não foi encontrado após a execução do script principal."
    }
}
