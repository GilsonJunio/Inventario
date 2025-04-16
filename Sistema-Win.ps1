<#
.SYNOPSIS
   Coleta informações essenciais de hardware do sistema Windows e salva na pasta Downloads.
.DESCRIPTION
   Este script PowerShell foca nos componentes principais (Sistema, OS, CPU, RAM,
   Placa-mãe, GPU, Discos Físicos), ignorando detalhes de partições lógicas e
   configurações de rede. Salva a saída em "RelatorioDoSistema.txt" na pasta Downloads.
   O arquivo será sobrescrito a cada execução. Assume que a pasta Downloads existe.
.NOTES
   Autor: Gemini (adaptado para Português)
   Data: 15 de Abril de 2025 - 21:47 (Parnaíba, Piauí)
   Requer: PowerShell
   Nota: Recomenda-se executar como Administrador para obter detalhes máximos
         (como números de série).
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
try {

    # Cabeçalho do Relatório
    Write-Host "==================================================" -ForegroundColor Yellow
    Write-Host "     Relatório de Componentes Principais do Sistema     " -ForegroundColor Yellow
    Write-Host "==================================================" -ForegroundColor Yellow
    Write-Host "Data e Hora da Coleta: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Host ""

    # --- Informações do Sistema e OS ---
    Write-Host "--- Sistema e Sistema Operacional ---" -ForegroundColor Cyan
    try {
        $csProduct = Get-CimInstance Win32_ComputerSystemProduct -ErrorAction Stop
        Write-Host "Fabricante do Sistema : $($csProduct.Vendor)"
        Write-Host "Modelo do Sistema     : $($csProduct.Name)"
        Write-Host "UUID do Sistema       : $($csProduct.UUID)"

        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        Write-Host "Sistema Operacional   : $($os.Caption)"
        Write-Host "Versão do SO          : $($os.Version)"
        Write-Host "Build do SO           : $($os.BuildNumber)"
        Write-Host "Arquitetura do SO     : $($os.OSArchitecture)"
        # Write-Host "Idioma do SO          : $($os.OSLanguage)" # Removido por ser menos essencial
        $installDate = try { [Management.ManagementDateTimeConverter]::ToDateTime($os.InstallDate).ToString('yyyy-MM-dd HH:mm:ss') } catch { "Data Inválida" }
        # Write-Host "Data de Instalação    : $installDate" # Removido por ser menos essencial

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
        $biosDate = try { [Management.ManagementDateTimeConverter]::ToDateTime($bios.ReleaseDate).ToString('yyyy-MM-dd') } catch { "Data Inválida" }
        Write-Host "Data BIOS             : $($biosDate)"
    } catch {
        Write-Warning "AVISO ao obter informações do BIOS: $($_.Exception.Message)"
    }
    try {
        $baseBoard = Get-CimInstance Win32_BaseBoard -ErrorAction Stop
        Write-Host "Fabricante Placa-mãe: $($baseBoard.Manufacturer)"
        Write-Host "Produto Placa-mãe   : $($baseBoard.Product)"
        Write-Host "Versão Placa-mãe    : $($baseBoard.Version)"
        Write-Host "Serial Placa-mãe    : $($baseBoard.SerialNumber) (Pode requerer Admin)"
    } catch {
        Write-Warning "AVISO ao obter informações da Placa-mãe: $($_.Exception.Message)"
    }
    Write-Host ""

    # --- Processador (CPU) ---
    Write-Host "--- Processador (CPU) ---" -ForegroundColor Cyan
    try {
        $cpus = Get-CimInstance Win32_Processor -ErrorAction Stop
        $cpuIndex = 1
        foreach ($cpu in $cpus) {
            Write-Host " CPU $cpuIndex:"
            Write-Host "   Nome                  : $($cpu.Name)"
            Write-Host "   Fabricante            : $($cpu.Manufacturer)"
            Write-Host "   Velocidade Base       : $($cpu.MaxClockSpeed) MHz"
            Write-Host "   Núcleos Físicos       : $($cpu.NumberOfCores)"
            Write-Host "   Processadores Lógicos : $($cpu.NumberOfLogicalProcessors)"
            Write-Host "   Soquete               : $($cpu.SocketDesignation)"
            # Write-Host "   Cache L2 (KB)         : $($cpu.L2CacheSize)" # Removido por ser detalhe extra
            # Write-Host "   Cache L3 (KB)         : $($cpu.L3CacheSize)" # Removido por ser detalhe extra
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
                Write-Host " Módulo $(<span class="math-inline">i\) no Slot '</span>($module.DeviceLocator)':"
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
    } catch {
        Write-Warning "AVISO ao obter detalhes dos pentes de RAM: $($_.Exception.Message)"
    }
    Write-Host ""

    # --- Placa de Vídeo (GPU) ---
    Write-Host "--- Placa de Vídeo (GPU) ---" -ForegroundColor Cyan
    try {
        $gpus = Get-CimInstance Win32_VideoController -ErrorAction Stop
        if ($gpus) {
