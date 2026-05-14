# Herramientas de Administración de Data Center

**Proyecto Final Sistemas Operativos**

**Universidad ICESI**

Desarrollado por:

- [Pablo Guzmán](https://github.com/Pableis05)
- [David Dulce](https://github.com/arkantrust) 

Este repositorio contiene dos herramientas de administración para data centers:
- Script para Windows: `powershell/datacenter.ps1`
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