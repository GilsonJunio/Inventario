<#
.SYNOPSIS
   Coleta informações essenciais de hardware e salva na pasta Downloads, usando um arquivo temporário. (v3 - Workaround)
.DESCRIPTION
   Este script PowerShell coleta informações do sistema. Ele grava o log em um arquivo
   temporário e depois o move para "RelatorioDoSistema.txt" na pasta Downloads.
   O arquivo final será sobrescrito a cada execução. Assume que a pasta Downloads existe.
.NOTES
   Autor: Gemini (adaptado para Português)
   Data: 17 de Abril de 2025 - 15:59 (Parnaíba, Piauí)
   Requer: PowerShell
   Nota: Recomenda-se executar como Administrador para obter detalhes máximos.
#>

# --- Configuração dos Arquivos ---
# Nome final do arquivo
$logFileName = "RelatorioDoSistema.txt"
# Caminho final na pasta Downloads
$finalLogPath = Join-Path -Path $HOME -ChildPath "Downloads\$logFileName"
# Caminho temporário para o log (na pasta TEMP do sistema)
# Usamos Get-Random para tornar o nome temporário único e evitar conflitos
$tempLogPath = Join-Path -Path $env:TEMP -ChildPath "RelatorioSistema_Temp_$(Get-Random).log"

# --- Inicia o Log (Transcript) no local TEMPORÁRIO ---
try {
    Start-Transcript -Path $tempLogPath -Force -ErrorAction Stop
    Write-Host "Iniciando gravação temporária do relatório em: $tempLogPath" -ForegroundColor Cyan

} catch {
    Write-Error "ERRO CRÍTICO: Não foi possível iniciar o log temporário em '$tempLogPath'. Verifique as permissões da pasta TEMP. Detalhes: $($_.Exception.Message)"
    try { Stop-Transcript -ErrorAction SilentlyContinue } catch {}
    exit 1
}

# --- Corpo Principal do Script (Tudo aqui será logado E exibido no console) ---
try {

    # Cabeçalho do Relatório
    Write-Host "==================================================" -ForegroundColor Yellow
    Write-Host "     Relatório de Componentes Principais do Sistema     " -ForegroundColor Yellow
    Write-Host "==================================================" -ForegroundColor Yellow
    Write-Host "Data e Hora da Coleta: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Host "(Log sendo gravado temporariamente em $tempLogPath)" -ForegroundColor Gray
    Write-Host ""

    # --- Informações do Sistema e OS ---
    Write-Host "--- Sistema e Sistema Operacional ---" -ForegroundColor Cyan
    try {
        $csProduct = Get-CimInstance Win32_ComputerSystemProduct -ErrorAction Stop
        Write-Host "Fabricante do Sistema : $($csProduct.Vendor)"
        Write-Host "Modelo do Sistema     : $($csProduct.Name)"
        # ... (resto das infos de Sistema/OS como na versão anterior) ...
        $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop
        $totalRamGB = [Math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
        Write-Host "Memória RAM Total     : $($totalRamGB) GB"
        Write-Host "Processadores Lógicos : $($cs.NumberOfLogicalProcessors)"
        Write-Host "Processadores Físicos : $($cs.NumberOfProcessors)"
    } catch {
        Write-Warning "AVISO ao obter informações básicas do Sistema/OS: $($_.Exception.Message)"
    }
    Write-Host ""

    # --- BIOS e Placa-mãe ---
    Write-Host "--- BIOS e Placa-mãe ---" -ForegroundColor Cyan
    try {
        $bios = Get-CimInstance Win32_BIOS -ErrorAction Stop
        Write-Host "Fabricante BIOS       : $($bios.Manufacturer)"
        Write-Host "Versão BIOS           : $($bios.SMBIOSBIOSVersion)"
        # ... (resto das infos de BIOS/Placa-mãe) ...
        $baseBoard = Get-CimInstance Win32_BaseBoard -ErrorAction Stop
        Write-Host "Fabricante Placa-mãe: $($baseBoard.Manufacturer)"
        Write-Host "Produto Placa-mãe   : $($baseBoard.Product)"
        Write-Host "Serial Placa-mãe    : $($baseBoard.SerialNumber) (Pode requerer Admin)"
    } catch {
        Write-Warning "AVISO ao obter informações do BIOS/Placa-mãe: $($_.Exception.Message)"
    }
    Write-Host ""

    # --- Processador (CPU) ---
    Write-Host "--- Processador (CPU) ---" -ForegroundColor Cyan
    try {
        $cpus = Get-CimInstance Win32_Processor -ErrorAction Stop
        $cpuIndex = 1
        foreach ($cpu in $cpus) {
            Write-Host " CPU ${cpuIndex}:" # Usa a sintaxe corrigida
            Write-Host "   Nome                  : $($cpu.Name)"
            # ... (resto das infos de CPU) ...
            $cpuIndex++
        }
    } catch {
        Write-Warning "AVISO ao obter informações da CPU: $($_.Exception.Message)"
    }
    Write-Host ""

    # --- Memória RAM (Pentes) ---
    Write-Host "--- Memória RAM (Detalhes por Pente) ---" -ForegroundColor Cyan
    try {
        $memoryModules = Get-CimInstance Win32_PhysicalMemory -ErrorAction Stop
        if ($memoryModules) {
            $i = 1
            foreach ($module in $memoryModules) {
                Write-Host " Módulo $($i) no Slot '$($module.DeviceLocator)':"
                # ... (resto das infos de RAM) ...
                $i++
            }
        } else { Write-Host "Nenhum módulo de memória física encontrado." }
    } catch { Write-Warning "AVISO ao obter detalhes dos pentes de RAM: $($_.Exception.Message)" }
    Write-Host ""

    # --- Placa de Vídeo (GPU) ---
    Write-Host "--- Placa de Vídeo (GPU) ---" -ForegroundColor Cyan
    try {
        $gpus = Get-CimInstance Win32_VideoController -ErrorAction Stop
        if ($gpus) {
            $i = 1
            foreach ($gpu in $gpus) {
                Write-Host " GPU $($i):"
                Write-Host "   Nome        : $($gpu.Name)"
                # ... (resto das infos de GPU) ...
                $i++
            }
        } else { Write-Host "Nenhuma placa de vídeo encontrada." }
    } catch { Write-Warning "AVISO ao obter informações da GPU: $($_.Exception.Message)" }
    Write-Host ""

    # --- Discos de Armazenamento Físicos ---
    Write-Host "--- Discos Físicos (HD/SSD) ---" -ForegroundColor Cyan
    try {
        $disks = Get-CimInstance Win32_DiskDrive -ErrorAction Stop
        if ($disks) {
            $i = 1
            foreach ($disk in $disks) {
                Write-Host " Disco Físico $($i) ($($disk.DeviceID)): "
                Write-Host "   Modelo      : $($disk.Model)"
                # ... (resto das infos de Disco Físico) ...
                $i++
            }
        } else { Write-Host "Nenhum disco físico encontrado." }
    } catch { Write-Warning "AVISO ao obter informações dos Discos Físicos: $($_.Exception.Message)" }
    Write-Host ""

    # --- Finalização do Corpo do Script ---
    Write-Host "==================================================" -ForegroundColor Yellow
    Write-Host "               Fim do Relatório               " -ForegroundColor Yellow
    Write-Host "==================================================" -ForegroundColor Yellow

} catch {
    Write-Error "ERRO GERAL durante a execução do script: $($_.Exception.Message)"
} finally {
    # --- Finaliza o Log (Transcript) e Move o Arquivo ---
    Write-Host ""
    Write-Host "Finalizando a gravação do log temporário..." -ForegroundColor Gray
    Stop-Transcript

    # Verifica se o arquivo temporário foi criado antes de tentar mover
    if (Test-Path $tempLogPath) {
        try {
            Write-Host "Movendo log de '$tempLogPath' para '$finalLogPath'..." -ForegroundColor Gray
            # Move o arquivo de log temporário para o destino final na pasta Downloads
            # -Force garante que ele sobrescreva o arquivo final se já existir
            Move-Item -Path $tempLogPath -Destination $finalLogPath -Force -ErrorAction Stop
            Write-Host "Relatório final salvo com sucesso em: $finalLogPath" -ForegroundColor Green
        } catch {
            # Se a MOVIMENTAÇÃO falhar (talvez ainda por permissão no Downloads ou outro motivo)
            Write-Error "ERRO CRÍTICO: Falha ao mover o log temporário para '$finalLogPath'. Verifique as permissões na pasta Downloads. O log pode estar em '$tempLogPath'. Detalhes: $($_.Exception.Message)"
            # Opcional: Remover o temporário se a movimentação falhar? Ou deixar para análise?
            # Remove-Item -Path $tempLogPath -ErrorAction SilentlyContinue
        }
    } else {
        Write-Warning "AVISO: O arquivo de log temporário '$tempLogPath' não foi encontrado após a execução."
    }
}

# Fim do Script
