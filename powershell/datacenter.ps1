function Get-UsersLastLogin {
    Write-Host "`n--- Usuarios y ultimo login ---`n" -ForegroundColor Cyan

    $format = "{0,-25} {1}"
    Write-Host ($format -f "Usuario", "Ultimo Login") -ForegroundColor Yellow
    Write-Host ("-" * 55)

    # Usa la propiedad LastLogon de la cuenta local (SAM). No requiere Administrador.
    Get-LocalUser | Sort-Object Name | ForEach-Object {
        $lastLogin = if ($_.LastLogon) {
            $_.LastLogon.ToString("yyyy-MM-dd HH:mm:ss")
        } else {
            "Nunca"
        }
        Write-Host ($format -f $_.Name, $lastLogin)
    }
}

function Get-Filesystems {
    Write-Host "`n--- Filesystems / Discos conectados ---`n" -ForegroundColor Cyan

    $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -ne "" }

    $format = "{0,-10} {1,-22} {2,-22} {3}"
    Write-Host ($format -f "Disco", "Tamano (bytes)", "Libre (bytes)", "% Libre") -ForegroundColor Yellow
    Write-Host ("-" * 70)

    foreach ($drive in $drives) {
        try {
            $total = $drive.Used + $drive.Free
            $free  = $drive.Free
            $pct   = if ($total -gt 0) { [math]::Round(($free / $total) * 100, 2) } else { 0 }

            Write-Host ($format -f `
                $drive.Root, `
                ("{0:N0}" -f $total), `
                ("{0:N0}" -f $free), `
                "$pct%")
        } catch {
            Write-Host ($format -f $drive.Root, "N/A", "N/A", "N/A")
        }
    }
}

function Get-Top10Files {
    Write-Host "`n--- Top 10 archivos mas grandes ---`n" -ForegroundColor Cyan
    $path = Read-Host "Ingrese el disco o directorio (ej: C:\)"

    if (-not (Test-Path $path)) {
        Write-Host "La ruta '$path' no existe." -ForegroundColor Red
        return
    }

    Write-Host "`nBuscando archivos en '$path', por favor espere...`n" -ForegroundColor Gray

    try {
        $files = Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue |
            Sort-Object Length -Descending |
            Select-Object -First 10

        if ($files.Count -eq 0) {
            Write-Host "No se encontraron archivos." -ForegroundColor Red
            return
        }

        $i = 1
        $format = "{0,-4} {1,-20} {2}"
        Write-Host ($format -f "#", "Tamano (bytes)", "Ruta completa") -ForegroundColor Yellow
        Write-Host ("-" * 80)

        foreach ($file in $files) {
            Write-Host ($format -f $i, ("{0:N0}" -f $file.Length), $file.FullName)
            $i++
        }
    } catch {
        Write-Host "Error al leer el directorio: $_" -ForegroundColor Red
    }
}

function Get-MemorySwap {
    Write-Host "`n--- Memoria libre y Swap en uso ---`n" -ForegroundColor Cyan

    $os = Get-CimInstance -ClassName Win32_OperatingSystem

    $totalRAM    = $os.TotalVisibleMemorySize * 1KB
    $freeRAM     = $os.FreePhysicalMemory     * 1KB
    $usedRAM     = $totalRAM - $freeRAM
    $pctFreeRAM  = if ($totalRAM -gt 0) { [math]::Round(($freeRAM / $totalRAM) * 100, 2) } else { 0 }

    $totalSwap   = $os.TotalVirtualMemorySize * 1KB
    $freeSwap    = $os.FreeVirtualMemory      * 1KB
    $usedSwap    = $totalSwap - $freeSwap
    $pctUsedSwap = if ($totalSwap -gt 0) { [math]::Round(($usedSwap / $totalSwap) * 100, 2) } else { 0 }

    Write-Host "MEMORIA RAM" -ForegroundColor Yellow
    Write-Host ("  Total:       {0,20:N0} bytes" -f $totalRAM)
    Write-Host ("  En uso:      {0,20:N0} bytes" -f $usedRAM)
    Write-Host ("  Libre:       {0,20:N0} bytes  ({1}%)" -f $freeRAM, $pctFreeRAM)

    Write-Host "`nSWAP / MEMORIA VIRTUAL" -ForegroundColor Yellow
    Write-Host ("  Total:       {0,20:N0} bytes" -f $totalSwap)
    Write-Host ("  En uso:      {0,20:N0} bytes  ({1}%)" -f $usedSwap, $pctUsedSwap)
    Write-Host ("  Libre:       {0,20:N0} bytes" -f $freeSwap)
}

function Invoke-Backup {
    Write-Host "`n--- Backup a USB con catalogo ---`n" -ForegroundColor Cyan

    $origen = Read-Host "Ingrese el directorio de origen"
    $destino = Read-Host "Ingrese la ruta de la memoria USB (ej: E:\)"

    if (-not (Test-Path $origen)) {
        Write-Host "El directorio de origen '$origen' no existe." -ForegroundColor Red
        return
    }
    if (-not (Test-Path $destino)) {
        Write-Host "La ruta de destino '$destino' no existe o la USB no esta conectada." -ForegroundColor Red
        return
    }

    $timestamp   = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $backupFolder = Join-Path $destino "backup_$timestamp"
    $catalogPath  = Join-Path $backupFolder "catalogo_$timestamp.csv"

    try {
        Write-Host "`nCopiando archivos a '$backupFolder'..." -ForegroundColor Gray
        Copy-Item -Path $origen -Destination $backupFolder -Recurse -Force

        Write-Host "Generando catalogo de archivos..." -ForegroundColor Gray

        $archivos = Get-ChildItem -Path $backupFolder -Recurse -File |
            Select-Object `
                @{Name="Nombre"; Expression={$_.Name}}, `
                @{Name="RutaCompleta"; Expression={$_.FullName}}, `
                @{Name="UltimaModificacion"; Expression={$_.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")}}, `
                @{Name="Tamano_bytes"; Expression={$_.Length}}

        $archivos | Export-Csv -Path $catalogPath -NoTypeInformation -Encoding UTF8

        Write-Host "`nBackup completado exitosamente." -ForegroundColor Green
        Write-Host "Destino:  $backupFolder" -ForegroundColor Green
        Write-Host "Catalogo: $catalogPath"  -ForegroundColor Green
        Write-Host "Archivos copiados: $($archivos.Count)" -ForegroundColor Green
    } catch {
        Write-Host "Error durante el backup: $_" -ForegroundColor Red
    }
}

function Show-Menu {
    Clear-Host
    Write-Host "=======================================" -ForegroundColor Cyan
    Write-Host "   HERRAMIENTA DE ADMINISTRACION DC   " -ForegroundColor Cyan
    Write-Host "=======================================" -ForegroundColor Cyan
    Write-Host "  1. Usuarios y ultimo login"
    Write-Host "  2. Filesystems / Discos"
    Write-Host "  3. Top 10 archivos mas grandes"
    Write-Host "  4. Memoria libre y Swap en uso"
    Write-Host "  5. Backup a USB con catalogo"
    Write-Host "  0. Salir"
    Write-Host "=======================================" -ForegroundColor Cyan
}

do {
    Show-Menu
    $opcion = Read-Host "Seleccione una opcion"

    switch ($opcion) {
        "0" { Write-Host "Saliendo..." -ForegroundColor Yellow; break }
        "1" { Get-UsersLastLogin }
        "2" { Get-Filesystems }
        "3" { Get-Top10Files }
        "4" { Get-MemorySwap }
        "5" { Invoke-Backup }
        default { Write-Host "Opcion invalida. Intente de nuevo." -ForegroundColor Red }
    }

    if ($opcion -ne "0") {
        Write-Host "`nPresione Enter para continuar..." -ForegroundColor Gray
        Read-Host | Out-Null
    }

} while ($opcion -ne "0")
