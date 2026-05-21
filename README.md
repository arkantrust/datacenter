# Herramientas de Administración de Data Center

**Proyecto Final Sistemas Operativos**

**Universidad ICESI**

Desarrollado por:

- [Pablo Guzmán](https://github.com/Pableis05)
- [David Dulce](https://github.com/arkantrust) 

Este repositorio contiene dos herramientas de administración para data centers:
- Script para Windows (PowerShell 5.1+): `powershell/datacenter.ps1`
- Script para Linux/macOS: `bash/datacenter.sh`

## Funcionalidades

Ambas herramientas despliegan un menú interactivo con las siguientes opciones:

| # | Opción | Descripción |
|---|--------|-------------|
| 1 | Usuarios y último login | Muestra todos los usuarios del sistema y la fecha/hora de su último ingreso |
| 2 | Filesystems / Discos | Muestra los discos conectados con tamaño total y espacio libre en bytes |
| 3 | Top 10 archivos más grandes | Lista los 10 archivos más grandes de un disco o directorio especificado |
| 4 | Memoria libre y Swap | Muestra memoria libre y swap en uso en bytes y porcentaje |
| 5 | Backup a USB con catálogo | Copia un directorio a una USB y genera un catálogo con nombres y fechas |

## Requisitos

### PowerShell (`datacenter.ps1`)
- Windows 10/11
- PowerShell 5.1 o superior

## Uso

### PowerShell
```powershell
# Abrir PowerShell (no requiere Administrador) y ejecutar:
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\powershell\datacenter.ps1
```

## Ejemplos de salida

### Usuarios y último login
```
Usuario                   Ultimo Login
-------------------------------------------------------
Administrador             Nunca
DefaultAccount            Nunca
Invitado                  Nunca
Johnny                    2023-09-24 20:18:24
nbdyn                     Nunca
WDAGUtilityAccount        Nunca
WsiAccount                2025-12-23 16:26:58
yrami                     Nunca
```

### Filesystems / Discos
```
Disco      Tamano (bytes)         Libre (bytes)          % Libre
----------------------------------------------------------------------
C:\        499,963,174,912        123,456,789,012        24.69%
D:\        1,000,204,886,016      450,000,000,000        44.99%
```

### Top 10 archivos más grandes
```
Ingrese el disco o directorio: C:\
#   Tamaño (bytes)    Ruta completa
--  ----------------  -----------------------------------------
1   4,294,967,296     C:\pagefile.sys
2   1,610,612,736     C:\hiberfil.sys
...
```

### Memoria libre y Swap
```
MEMORIA RAM
  Total:             17,179,869,184 bytes
  En uso:            12,884,901,888 bytes
  Libre:              4,294,967,296 bytes  (25.00%)

SWAP / MEMORIA VIRTUAL
  Total:              8,589,934,592 bytes
  En uso:             1,073,741,824 bytes  (12.50%)
  Libre:              7,516,192,768 bytes
```

### Backup a USB
```
Directorio origen:  C:\MisCarpetas\Documentos
Destino USB:        E:\
Copiando archivos...
Generando catálogo...
Backup completado. Catálogo guardado en: E:\catalogo_2026-05-20.csv
```
