<#
.SYNOPSIS
   Coleta informações essenciais de hardware do sistema Windows e salva na pasta Downloads. (v2 - Corrigido)
.DESCRIPTION
   Este script PowerShell foca nos componentes principais (Sistema, OS, CPU, RAM,
   Placa-mãe, GPU, Discos Físicos), ignorando detalhes de partições lógicas e
   configurações de rede. Salva a saída em "RelatorioDoSistema.txt" na pasta Downloads.
   O arquivo será sobrescrito a cada execução. Assume que a pasta Downloads existe.
.NOTES
   Autor: Gemini (adaptado para Português)
   Data: 17 de Abril de 2025 - 15:53 (Parnaíba, Piauí)
   Requer: PowerShell
   Nota: Recomenda-se executar como Administrador para obter detalhes máximos.
#>

# --- Configuração do Arquivo de Saída ---
$logFileName = "RelatorioDoSistema.txt"
$logPath = Join-Path -Path $HOME -ChildPath "Downloads\$logFileName"

# --- Inicia o Log (Transcript) ---
try {
    Start-Transcript -Path $logPath -Force -ErrorAction Stop
    Write-Host "Iniciando gravação do relatório em: $logPath" -ForegroundColor Green
    Write-Host "*** ATENÇÃO: Este arquivo será sobrescrito se já existir! ***" -ForegroundColor Yellow
    Write-Host ""

} catch {
    Write-Error "ERRO CRÍTICO: Não foi possível iniciar o log em '$logPath'. Verifique as permissões e se a pasta Downloads (`$($HOME)\Downloads`) existe. Detalhes: $($_.Exception.Message)"
    try { Stop-Transcript -ErrorAction SilentlyContinue } catch {}
    exit 1
}

# --- Corpo Principal do Script ---
try { # Início do TRY principal

    # Cabeçalho do Relatório
    Write-Host "==================================================" -ForegroundColor Yellow
    Write-Host "     Relatório de Componentes Principais do Sistema     " -ForegroundColor Yellow
    Write-Host "==================================================" -ForegroundColor Yellow
    Write-Host "Data e Hora da Coleta: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
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
            # CORREÇÃO APLICADA AQUI: Use ${cpuIndex} para delimitar a variável
            Write-Host " CPU ${cpuIndex}:"
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
    try { # Início do try GPU - Verifique se este bloco está correto
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
    } catch { # Fechamento do catch GPU - Verifique se este bloco está correto
        Write-Warning "AVISO ao obter informações da GPU: $($_.Exception.Message)"
    } # Fechamento do try GPU - Verifique se este bloco está correto
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

    # --- Finalização do Corpo do Script ---
    Write-Host "==================================================" -ForegroundColor Yellow
    Write-Host "               Fim do Relatório               " -ForegroundColor Yellow
    Write-Host "==================================================" -ForegroundColor Yellow

# Fechamento do TRY principal - CORREÇÃO ADICIONADA AQUI
} catch {
    Write-Error "ERRO GERAL durante a execução do script: $($_.Exception.Message)"
} finally {
    # --- Finaliza o Log (Transcript) ---
    Write-Host ""
    Write-Host "Finalizando a gravação do log..." -ForegroundColor Gray
    Stop-Transcript
    Write-Host "Relatório completo salvo em: $logPath" -ForegroundColor Green
}

# Fim do Script
