<#
.SYNOPSIS
   Coleta informações essenciais de hardware do sistema Windows e salva na pasta Downloads. (v4 - Usa Copiar/Remover)
.DESCRIPTION
   Este script PowerShell foca nos componentes principais (Sistema, OS, CPU, RAM,
   Placa-mãe, GPU, Discos Físicos). Ele grava o log em um arquivo temporário,
   copia para "RelatorioDoSistema.txt" na pasta Downloads e tenta remover o temporário.
   O arquivo final será sobrescrito a cada execução. Assume que a pasta Downloads existe.
.NOTES
   Autor: Gemini (adaptado para Português)
   Data: 17 de Abril de 2025 - 16:41 (Parnaíba, Piauí)
   Requer: PowerShell
   Nota: Recomenda-se executar como Administrador para obter detalhes máximos.
#>

# --- Configuração dos Arquivos ---
# Nome final do arquivo
$logFileName = "RelatorioDoSistema.txt"
# Caminho final na pasta Downloads
$finalLogPath = Join-Path -Path $HOME -ChildPath "Downloads\$logFileName"
# Caminho temporário para o log (na pasta TEMP do sistema)
$tempLogPath = Join-Path -Path $env:TEMP -ChildPath "RelatorioSistema_Temp_$(Get-Random).log"

# --- Inicia o Log (Transcript) no local TEMPORÁRIO ---
try {
    Start-Transcript -Path $tempLogPath -Force -ErrorAction Stop
    Write-Host "Iniciando gravação temporária do relatório em: $tempLogPath" -ForegroundColor Cyan
    Write-Host "*** ATENÇÃO: O arquivo final '$logFileName' na pasta Downloads será sobrescrito se já existir! ***" -ForegroundColor Yellow
    Write-Host ""

} catch {
    Write-Error "ERRO CRÍTICO: Não foi possível iniciar o log temporário em '$tempLogPath'. Verifique as permissões da pasta TEMP. Detalhes: $($_.Exception.Message)"
    try { Stop-Transcript -ErrorAction SilentlyContinue } catch {}
    exit 1
}

# --- Corpo Principal do Script (Tudo aqui será logado E exibido no console) ---
try { # Início do TRY principal

    # Cabeçalho do Relatório
    Write-Host "==================================================" -ForegroundColor Yellow
    Write-Host "     Relatório de Componentes Principais do Sistema     " -ForegroundColor Yellow
    Write-Host "==================================================" -ForegroundColor Yellow
    Write-Host "Data e Hora da Coleta: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Host "(Log sendo gravado temporariamente em $tempLogPath)" -ForegroundColor Gray
    Write-Host ""

    # --- Informações do Sistema e OS ---
    Write-Host "--- Sistema e Sistema Operacional ---" -ForegroundColor Cyan
    try { # Início do try Sistema/OS
        $csProduct = Get-CimInstance Win32_ComputerSystemProduct -ErrorAction Stop
        Write-Host "Fabricante do Sistema : $($csProduct.Vendor)"
        Write-Host "Modelo do Sistema     : $($csProduct.Name)"
        Write-Host "UUID do Sistema       : $($csProduct.UUID)"

        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        Write-Host "Sistema Operacional   : $($os.Caption)"
        Write-Host "Versão do SO          : $($os.Version)"
        Write-Host "Build do SO           : $($os.BuildNumber)"
        Write-Host "Arquitetura do SO     : $($os.OSArchitecture)"
        $installDate = try { [Management.ManagementDateTimeConverter]::ToDateTime($os.InstallDate).ToString('yyyy-MM-dd HH:mm:ss') } catch { "Data Inválida" }
        # Write-Host "Data de Instalação    : $installDate" # Removido

        $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop
        $totalRamGB = [Math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
        Write-Host "Memória RAM Total     : $($totalRamGB) GB"
        Write-Host "Processadores Lógicos : $($cs.NumberOfLogicalProcessors)"
        Write-Host "Processadores Físicos : $($cs.NumberOfProcessors)"
    } catch { # Fechamento do catch Sistema/OS
        Write-Warning "AVISO ao obter informações básicas do Sistema/OS: $($_.Exception.Message)"
    } # Fechamento do try Sistema/OS
    Write-Host ""

    # --- BIOS e Placa-mãe ---
    Write-Host "--- BIOS e Placa-mãe ---" -ForegroundColor Cyan
    try { # Início do try BIOS
        $bios = Get-CimInstance Win32_BIOS -ErrorAction Stop
        Write-Host "Fabricante BIOS       : $($bios.Manufacturer)"
        Write-Host "Versão BIOS           : $($bios.SMBIOSBIOSVersion)"
        $biosDate = try { [Management.ManagementDateTimeConverter]::ToDateTime($bios.ReleaseDate).ToString('yyyy-MM-dd') } catch { "Data Inválida" }
        Write-Host "Data BIOS             : $($biosDate)"
    } catch { # Fechamento do catch BIOS
        Write-Warning "AVISO ao obter informações do BIOS: $($_.Exception.Message)"
    } # Fechamento do try BIOS
    try { # Início do try Placa-mãe
        $baseBoard = Get-CimInstance Win32_BaseBoard -ErrorAction Stop
        Write-Host "Fabricante Placa-mãe: $($baseBoard.Manufacturer)"
        Write-Host "Produto Placa-mãe   : $($baseBoard.Product)"
        Write-Host "Versão Placa-mãe    : $($baseBoard.Version)"
        Write-Host "Serial Placa-mãe    : $($baseBoard.SerialNumber) (Pode requerer Admin)"
    } catch { # Fechamento do catch Placa-mãe
        Write-Warning "AVISO ao obter informações da Placa-mãe: $($_.Exception.Message)"
    } # Fechamento do try Placa-mãe
    Write-Host ""

    # --- Processador (CPU) ---
    Write-Host "--- Processador (CPU) ---" -ForegroundColor Cyan
    try { # Início do try CPU
        $cpus = Get-CimInstance Win32_Processor -ErrorAction Stop
        $cpuIndex = 1
        foreach ($cpu in $cpus) {
            Write-Host " CPU ${cpuIndex}:" # Usa a sintaxe corrigida
            Write-Host "   Nome                  : $($cpu.Name)"
            Write-Host "   Fabricante            : $($cpu.Manufacturer)"
            Write-Host "   Velocidade Base       : $($cpu.MaxClockSpeed) MHz"
            Write-Host "   Núcleos Físicos       : $($cpu.NumberOfCores)"
            Write-Host "   Processadores Lógicos : $($cpu.NumberOfLogicalProcessors)"
            Write-Host "   Soquete               : $($cpu.SocketDesignation)"
            $cpuIndex++
        }
    } catch { # Fechamento do catch CPU
        Write-Warning "AVISO ao obter informações da CPU: $($_.Exception.Message)"
    } # Fechamento do try CPU
    Write-Host ""

    # --- Memória RAM (Pentes) ---
    Write-Host "--- Memória RAM (Detalhes por Pente) ---" -ForegroundColor Cyan
    try { # Início do try RAM
        $memoryModules = Get-CimInstance Win32_PhysicalMemory -ErrorAction Stop
        if ($memoryModules) {
            $i = 1
            foreach ($module in $memoryModules) {
                Write-Host " Módulo $($i) no Slot '$($module.DeviceLocator)':"
                $capacityGB = [Math]::Round($module.Capacity / 1GB, 2)
                Write-Host "   Capacidade  : $($capacityGB) GB"
                Write-Host "   Velocidade  : $($module.Speed) MHz"
                Write-Host "   Fabricante  : $($module.Manufacturer)"
                Write-Host "   Part Number : $($module.PartNumber)"
                Write-Host "   Serial      : $($module.SerialNumber) (Requer Admin)"
                Write-Host "   Tipo        : $($module.MemoryType)"
                $i++
            }
        } else {
            Write-Host "Nenhum módulo de memória física encontrado."
        }
    } catch { # Fechamento do catch RAM
        Write-Warning "AVISO ao obter detalhes dos pentes de RAM: $($_.Exception.Message)"
    } # Fechamento do try RAM
    Write-Host ""

    # --- Placa de Vídeo (GPU) ---
    Write-Host "--- Placa de Vídeo (GPU) ---" -ForegroundColor Cyan
    try { # Início do try GPU
        $gpus = Get-CimInstance Win32_VideoController -ErrorAction Stop
        if ($gpus) {
            $i = 1
            foreach ($gpu in $gpus) {
                Write-Host " GPU $($i):"
                Write-Host "   Nome        : $($gpu.Name)"
                if ($gpu.AdapterRAM) {
                    $adapterRamMB = [Math]::Round($gpu.AdapterRAM / 1MB, 0)
                    Write-Host "   Memória Ded.: $($adapterRamMB) MB"
                } else {
                     Write-Host "   Memória Ded.: N/A (Integrada ou não detectada)"
                }
                Write-Host "   Driver Ver. : $($gpu.DriverVersion)"
                $i++
            }
        } else {
            Write-Host "Nenhuma placa de vídeo encontrada."
        }
    } catch { # Fechamento do catch GPU
        Write-Warning "AVISO ao obter informações da GPU: $($_.Exception.Message)"
    } # Fechamento do try GPU
    Write-Host ""

    # --- Discos de Armazenamento Físicos ---
    Write-Host "--- Discos Físicos (HD/SSD) ---" -ForegroundColor Cyan
    try { # Início do try Discos Físicos
        $disks = Get-CimInstance Win32_DiskDrive -ErrorAction Stop
        if ($disks) {
            $i = 1
            foreach ($disk in $disks) {
                Write-Host " Disco Físico $($i) ($($disk.DeviceID)): "
                Write-Host "   Modelo      : $($disk.Model)"
                $sizeGB = [Math]::Round($disk.Size / 1GB, 2)
                Write-Host "   Tamanho     : $($sizeGB) GB"
                Write-Host "   Interface   : $($disk.InterfaceType)"
                Write-Host "   Serial      : $($disk.SerialNumber) (Requer Admin)"
                Write-Host "   Media Type  : $($disk.MediaType)"
                $i++
            }
        } else {
            Write-Host "Nenhum disco físico encontrado."
        }
    } catch { # Fechamento do catch Discos Físicos
        Write-Warning "AVISO ao obter informações dos Discos Físicos: $($_.Exception.Message)"
    } # Fechamento do try Discos Físicos
    Write-Host ""

    # --- SEÇÃO DE DISCOS LÓGICOS REMOVIDA ---
    # --- SEÇÃO DE REDE REMOVIDA ---

    # --- Finalização do Corpo do Script ---
    Write-Host "==================================================" -ForegroundColor Yellow
    Write-Host "               Fim do Relatório               " -ForegroundColor Yellow
    Write-Host "==================================================" -ForegroundColor Yellow

} catch { # Fechamento do TRY principal
    Write-Error "ERRO GERAL durante a execução do script: $($_.Exception.Message)"
} finally {
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
} # Fechamento do FINALLY principal

# Fim do Script
