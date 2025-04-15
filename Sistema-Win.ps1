<#
.SYNOPSIS
   Coleta informações detalhadas do sistema Windows, incluindo componentes e marcas.
.DESCRIPTION
   Este script PowerShell usa Get-CimInstance para consultar informações de hardware
   e software do sistema local, como Sistema Operacional, CPU, RAM, Placa-mãe,
   Gráficos, Discos e Rede.
.NOTES
   Autor: Gemini (adaptado para Português)
   Data: 15 de Abril de 2025
   Requer: PowerShell (geralmente versão 3 ou superior para Get-CimInstance)
   Nota: Algumas informações (como números de série de RAM/Disco) podem exigir
         que o script seja executado com privilégios de Administrador
         (Clique com botão direito no PowerShell > Executar como Administrador).
#>

# Limpa a tela para melhor visualização (opcional)
Clear-Host

# Cabeçalho do Relatório
Write-Host "==================================================" -ForegroundColor Yellow
Write-Host "       Relatório de Informações do Sistema        " -ForegroundColor Yellow
Write-Host "==================================================" -ForegroundColor Yellow
Write-Host "Data e Hora da Coleta: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host ""

# --- Informações do Sistema e OS ---
Write-Host "--- Sistema e Sistema Operacional ---" -ForegroundColor Cyan
try {
    # Informações do Produto (Modelo, Fabricante)
    $csProduct = Get-CimInstance Win32_ComputerSystemProduct -ErrorAction Stop
    Write-Host "Fabricante do Sistema : $($csProduct.Vendor)"
    Write-Host "Modelo do Sistema     : $($csProduct.Name)"
    Write-Host "UUID do Sistema       : $($csProduct.UUID)"

    # Informações do Sistema Operacional
    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
    Write-Host "Sistema Operacional   : $($os.Caption)"
    Write-Host "Versão do SO          : $($os.Version)"
    Write-Host "Build do SO           : $($os.BuildNumber)"
    Write-Host "Arquitetura do SO     : $($os.OSArchitecture)"
    Write-Host "Idioma do SO          : $($os.OSLanguage)"
    Write-Host "Data de Instalação    : $($os.InstallDate | Get-CimInstance Win32_OperatingSystem | Select-Object -ExpandProperty InstallDate | ForEach-Object { $_.ToDateTime(0).ToString('yyyy-MM-dd HH:mm:ss') })" # Conversão de data

    # Informações Gerais do Sistema (RAM Total, Processadores)
    $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop
    $totalRamGB = [Math]::Round($cs.TotalPhysicalMemory / 1GB, 2) # Converte Bytes para GB
    Write-Host "Memória RAM Total     : $($totalRamGB) GB"
    Write-Host "Processadores Lógicos : $($cs.NumberOfLogicalProcessors)"
    Write-Host "Processadores Físicos : $($cs.NumberOfProcessors)" # Contagem de soquetes/CPUs físicas

} catch {
    Write-Warning "ERRO ao obter informações básicas do Sistema/OS: $($_.Exception.Message)"
}
Write-Host ""

# --- BIOS e Placa-mãe ---
Write-Host "--- BIOS e Placa-mãe ---" -ForegroundColor Cyan
try {
    $bios = Get-CimInstance Win32_BIOS -ErrorAction Stop
    Write-Host "Fabricante BIOS       : $($bios.Manufacturer)"
    Write-Host "Versão BIOS           : $($bios.SMBIOSBIOSVersion)"
    # Tenta converter a data do BIOS
    $biosDate = try { [Management.ManagementDateTimeConverter]::ToDateTime($bios.ReleaseDate).ToString('yyyy-MM-dd') } catch { "Data Inválida" }
    Write-Host "Data BIOS             : $($biosDate)"

} catch {
    Write-Warning "ERRO ao obter informações do BIOS: $($_.Exception.Message)"
}
try {
    $baseBoard = Get-CimInstance Win32_BaseBoard -ErrorAction Stop
    Write-Host "Fabricante Placa-mãe: $($baseBoard.Manufacturer)"
    Write-Host "Produto Placa-mãe   : $($baseBoard.Product)"
    Write-Host "Versão Placa-mãe    : $($baseBoard.Version)"
    Write-Host "Serial Placa-mãe    : $($baseBoard.SerialNumber) (Pode requerer Admin)" # Requer Admin

} catch {
    Write-Warning "ERRO ao obter informações da Placa-mãe: $($_.Exception.Message)"
}
Write-Host ""

# --- Processador (CPU) ---
Write-Host "--- Processador (CPU) ---" -ForegroundColor Cyan
try {
    # Em sistemas com múltiplas CPUs físicas, isso pode retornar mais de uma.
    # Para simplicidade, pegamos a primeira. Para listar todas, use um loop.
    $cpu = Get-CimInstance Win32_Processor -ErrorAction Stop | Select-Object -First 1
    Write-Host "Nome                  : $($cpu.Name)"
    Write-Host "Fabricante            : $($cpu.Manufacturer)"
    Write-Host "Velocidade Base       : $($cpu.MaxClockSpeed) MHz"
    Write-Host "Núcleos Físicos       : $($cpu.NumberOfCores)"
    Write-Host "Processadores Lógicos : $($cpu.NumberOfLogicalProcessors)"
    Write-Host "Soquete               : $($cpu.SocketDesignation)"
    Write-Host "Cache L2 (KB)         : $($cpu.L2CacheSize)"
    Write-Host "Cache L3 (KB)         : $($cpu.L3CacheSize)"

} catch {
    Write-Warning "ERRO ao obter informações da CPU: $($_.Exception.Message)"
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
            $capacityGB = [Math]::Round($module.Capacity / 1GB, 2)
            Write-Host "   Capacidade  : $($capacityGB) GB"
            Write-Host "   Velocidade  : $($module.Speed) MHz"
            Write-Host "   Fabricante  : $($module.Manufacturer)"
            Write-Host "   Part Number : $($module.PartNumber)"
            Write-Host "   Serial      : $($module.SerialNumber) (Requer Admin)" # Requer Admin
            Write-Host "   Tipo        : $($module.MemoryType)" # Código numérico; pesquisa necessária para nome amigável
            $i++
        }
    } else {
        Write-Host "Nenhum módulo de memória física encontrado."
    }
} catch {
    Write-Warning "ERRO ao obter detalhes dos pentes de RAM: $($_.Exception.Message)"
}
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
            Write-Host "   Processador : $($gpu.VideoProcessor)"
            # AdapterRAM pode ser nulo ou 0 para GPUs integradas que usam memória do sistema
            if ($gpu.AdapterRAM) {
                $adapterRamMB = [Math]::Round($gpu.AdapterRAM / 1MB, 0) # Exibir em MB
                Write-Host "   Memória Ded.: $($adapterRamMB) MB"
            } else {
                 Write-Host "   Memória Ded.: N/A (Integrada ou não detectada)"
            }
            Write-Host "   Driver Ver. : $($gpu.DriverVersion)"
            # Tenta converter data do driver
             $driverDate = try { [Management.ManagementDateTimeConverter]::ToDateTime($gpu.DriverDate).ToString('yyyy-MM-dd') } catch { "Data Inválida" }
            Write-Host "   Data Driver : $($driverDate)"
            Write-Host "   Status      : $($gpu.Status)"
            $i++
        }
    } else {
        Write-Host "Nenhuma placa de vídeo encontrada."
    }
} catch {
    Write-Warning "ERRO ao obter informações da GPU: $($_.Exception.Message)"
}
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
            $sizeGB = [Math]::Round($disk.Size / 1GB, 2)
            Write-Host "   Tamanho     : $($sizeGB) GB"
            Write-Host "   Interface   : $($disk.InterfaceType)"
            Write-Host "   Serial      : $($disk.SerialNumber) (Requer Admin)" # Requer Admin
            Write-Host "   Partições   : $($disk.Partitions)"
            Write-Host "   Media Type  : $($disk.MediaType)"
            $i++
        }
    } else {
        Write-Host "Nenhum disco físico encontrado."
    }
} catch {
    Write-Warning "ERRO ao obter informações dos Discos Físicos: $($_.Exception.Message)"
}
Write-Host ""

# --- Discos Lógicos (Partições com Letra) ---
Write-Host "--- Discos Lógicos (Partições Montadas) ---" -ForegroundColor Cyan
try {
    # DriveType 3 = Disco Local Fixo
    $logicalDisks = Get-CimInstance Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3} -ErrorAction SilentlyContinue
    if ($logicalDisks) {
        foreach ($ldisk in $logicalDisks) {
            Write-Host " Partição $($ldisk.DeviceID)"
            Write-Host "   Nome Volume : $($ldisk.VolumeName)"
            Write-Host "   Sistema Arq.: $($ldisk.FileSystem)"
            $sizeGB = [Math]::Round($ldisk.Size / 1GB, 2)
            $freeGB = [Math]::Round($ldisk.FreeSpace / 1GB, 2)
            Write-Host "   Tamanho Total: $($sizeGB) GB"
            Write-Host "   Espaço Livre: $($freeGB) GB"
        }
    } else {
        Write-Host "Nenhum disco lógico (local) encontrado."
    }
} catch {
    Write-Warning "ERRO ao obter informações dos Discos Lógicos: $($_.Exception.Message)"
}
Write-Host ""

# --- Rede (Adaptadores Ativos com IP) ---
Write-Host "--- Rede (Adaptadores Ativos com IP) ---" -ForegroundColor Cyan
try {
    # Pega adaptadores que têm configuração IP ativa
    $ipConfigs = Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object {$_.IPEnabled -eq $true} -ErrorAction SilentlyContinue

    if ($ipConfigs) {
        foreach ($ipConfig in $ipConfigs) {
            # Encontra o adaptador correspondente para obter o nome/fabricante
            $adapter = Get-CimInstance Win32_NetworkAdapter | Where-Object {$_.InterfaceIndex -eq $ipConfig.InterfaceIndex} -ErrorAction SilentlyContinue

            Write-Host " Adaptador: $($adapter.Name)" # Nome amigável (ex: Ethernet, Wi-Fi)
            Write-Host "   Fabricante  : $($adapter.Manufacturer)"
            Write-Host "   Descrição   : $($ipConfig.Description)" # Nome mais técnico
            Write-Host "   MAC Address : $($ipConfig.MACAddress)"
            Write-Host "   DHCP Ativo  : $($ipConfig.DHCPEnabled)"
            if ($ipConfig.IPAddress) {
                Write-Host "   Endereço(s) IP: $($ipConfig.IPAddress -join ', ')"
            } else {
                 Write-Host "   Endereço(s) IP: N/A"
            }
            if ($ipConfig.DefaultIPGateway) {
                Write-Host "   Gateway Padrão : $($ipConfig.DefaultIPGateway -join ', ')"
            }
             if ($ipConfig.DNSServerSearchOrder) {
                Write-Host "   Servidores DNS : $($ipConfig.DNSServerSearchOrder -join ', ')"
            }
            Write-Host "" # Linha em branco entre adaptadores
        }
    } else {
        Write-Host "Nenhuma configuração de rede IP ativa encontrada."
    }
} catch {
    Write-Warning "ERRO ao obter informações de Rede: $($_.Exception.Message)"
}

Write-Host "==================================================" -ForegroundColor Yellow
Write-Host "               Fim do Relatório               " -ForegroundColor Yellow
Write-Host "==================================================" -ForegroundColor Yellow

# Fim do Script
