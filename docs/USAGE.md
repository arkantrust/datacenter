# Manual de Usuario

## Descripción general

Este proyecto provee dos herramientas de línea de comandos equivalentes para la administración de data centers:

- **`powershell/datacenter.ps1`**: Para sistemas Windows con PowerShell
- **`bash/datacenter.sh`**: Para sistemas Linux/macOS con Bash

Ambas herramientas muestran el mismo menú interactivo con cinco opciones de administración del sistema.

## Requisitos

### PowerShell (`datacenter.ps1`)
- Windows 10/11
- PowerShell 5.1 o superior
- **No requiere Administrador** (el último login se obtiene de `Get-LocalUser`/`LastLogon`)

### BASH (`datacenter.sh`)
- Linux (Ubuntu/Debian/CentOS) o macOS
- Bash 4.0 o superior
- Se puede ejecutar sin privilegios; `sudo` mejora la cobertura de `lastlog`/`last` y los datos de memoria

## Uso

### PowerShell
```powershell
# Abrir PowerShell (no requiere Administrador) y ejecutar:
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\powershell\datacenter.ps1
```

### BASH
```bash
chmod +x ./bash/datacenter.sh
./bash/datacenter.sh          # o: sudo ./bash/datacenter.sh para datos completos
```

### Probar el script BASH desde Windows
`test_bash.bat` ejecuta `datacenter.sh` dentro de un contenedor Ubuntu. **Requiere Docker Desktop** en ejecución. Alternativamente, en WSL/Linux se corre directo con `bash bash/datacenter.sh`.

## Opción 1: Usuarios y último login

### ¿Qué hace?
Lista todos los usuarios del sistema junto con la fecha y hora de su último inicio de sesión.

### PowerShell
- Obtiene los usuarios locales con `Get-LocalUser` y lee su propiedad `LastLogon` (registro SAM)
- **No requiere privilegios de Administrador**
- Nota: en equipos con cuenta de Microsoft/Entra el inicio de sesión interactivo se registra bajo el UPN (correo), no bajo la cuenta local; esos usuarios pueden aparecer como `Nunca`

### BASH
- Lee `/etc/passwd` y filtra usuarios con UID ≥ 1000 y el usuario `root`
- Obtiene la fecha del último acceso probando, en orden: `lastlog` → `lastlog2` → `last`
- `lastlog` y `lastlog2` no requieren privilegios; `last` lee `wtmp`. Usar `sudo` mejora la cobertura en algunos sistemas

### Salida de ejemplo
```
Usuario                   Ultimo Login
-------------------------  --------------------
Administrador             Nunca
Johnny                    2023-09-24 20:18:24
WsiAccount                2025-12-23 16:26:58
```

## Opción 2: Filesystems / Discos

### ¿Qué hace?
Muestra todos los discos o filesystems conectados a la máquina con su tamaño total y espacio libre en bytes.

### PowerShell
- Usa `Get-PSDrive -PSProvider FileSystem`
- Calcula espacio total como `Used + Free`
- Muestra tamaño total, espacio libre y porcentaje libre

### BASH
- Usa `df -B1` para obtener valores en bytes
- Muestra filesystem, tamaño, espacio disponible y porcentaje libre

### Salida de ejemplo
```
Filesystem                  Tamano (bytes)         Libre (bytes)         % Libre
-------------------------  --------------------   --------------------  --------
/dev/sda1                  499,963,174,912        123,456,789,012       24.69%
/dev/sdb1                  1,000,204,886,016      450,000,000,000       44.99%
```

## Opción 3: Top 10 archivos más grandes

### ¿Qué hace?
Busca de forma recursiva los 10 archivos más grandes dentro de un disco o directorio especificado por el usuario. Muestra el tamaño en bytes y la ruta completa.

### PowerShell
- Usa `Get-ChildItem -Recurse -File` con `Sort-Object Length -Descending`
- El usuario ingresa la ruta (ej: `C:\` o `D:\Datos`)

### BASH
- Usa `find $path -type f -printf '%s %p\n' | sort -rn | head -10`
- El usuario ingresa la ruta (ej: `/` o `/home/pablo`)

### Salida de ejemplo
```
#    Tamano (bytes)       Ruta completa
----  --------------------  -----------------------------------------
1    4,294,967,296         C:\pagefile.sys
2    1,610,612,736         C:\hiberfil.sys
3    856,932,352           C:\Windows\Installer\archivo.msi
```

## Opción 4: Memoria libre y Swap en uso

### ¿Qué hace?
Muestra el estado actual de la memoria RAM (total, en uso, libre) y del área de swap/memoria virtual (total, en uso, libre), todo expresado en bytes y porcentaje.

### PowerShell
- Usa `Get-CimInstance Win32_OperatingSystem`
- Campos: `TotalVisibleMemorySize`, `FreePhysicalMemory`, `TotalVirtualMemorySize`, `FreeVirtualMemory`
- Convierte de KB a bytes multiplicando por 1024

### BASH
- Usa `free -b` para obtener valores directamente en bytes
- Parsea las líneas `Mem:` y `Swap:`

### Salida de ejemplo
```
MEMORIA RAM
  Total:               17,179,869,184 bytes
  En uso:              12,884,901,888 bytes
  Libre:                4,294,967,296 bytes  (25.00%)

SWAP
  Total:                8,589,934,592 bytes
  En uso:               1,073,741,824 bytes  (12.50%)
  Libre:                7,516,192,768 bytes
```

## Opción 5: Backup a USB con catálogo

### ¿Qué hace?
Copia recursivamente un directorio de origen a una memoria USB. Además de los archivos, genera un catálogo con el nombre, ruta completa, fecha de última modificación y tamaño de cada archivo respaldado.

### PowerShell
- Usa `Copy-Item -Recurse`
- El catálogo se genera como archivo CSV (`catalogo_FECHA.csv`) usando `Export-Csv`
- Crea una carpeta con timestamp en el destino (`backup_2026-05-18_22-30-00`)

### BASH
- Usa `cp -r`
- El catálogo se genera como archivo de texto delimitado por pipes (`catalogo_FECHA.txt`) con `find` y `stat`
- Crea una carpeta con timestamp en el destino

### Entradas requeridas
1. Directorio de origen (ej: `C:\Documentos` o `/home/pablo/docs`)
2. Ruta de la USB (ej: `E:\` o `/media/usb`)

### Salida de ejemplo
```
Backup completado exitosamente.
Destino:  E:\backup_2026-05-18_22-30-00
Catalogo: E:\backup_2026-05-18_22-30-00\catalogo_2026-05-18_22-30-00.csv
Archivos copiados: 47
```

## Errores comunes

| Error | Causa probable | Solución |
|-------|---------------|---------|
| "La ruta no existe" | Ruta mal escrita o USB no conectada | Verificar la ruta e intentar de nuevo |
| "Nunca" en último login | Usuario nunca ha iniciado sesión, o (Windows) la sesión usa cuenta de Microsoft/Entra y no la cuenta local | Normal para cuentas de servicio, nuevas o de Microsoft |
| Sin fecha de login (BASH) | `lastlog` no disponible en distros nuevas (removido de util-linux) | El script usa `lastlog2`/`last` automáticamente; instalar `util-linux` para tener `last` |
| "Error durante el backup/copia" | Permisos insuficientes o destino sin espacio | Verificar permisos del origen/destino y espacio libre en la USB |
