#!/bin/bash

# Obtiene el ultimo login de un usuario probando varias fuentes en orden de
# completitud: lastlog (historico completo) -> lastlog2 (reemplazo moderno) ->
# last (wtmp, solo historial reciente). Extrae la fecha con una expresion regular
# para tolerar la columna "From" vacia, que desplaza las columnas con awk.
get_last_login_for_user() {
    local user="$1" line=""

    # 1) lastlog (historico, todas las distros tradicionales)
    if command -v lastlog >/dev/null 2>&1; then
        line=$(lastlog -u "$user" 2>/dev/null | sed -n '2p')
        printf '%s' "$line" | grep -qi 'never' && { echo "Nunca"; return; }
    fi
    # 2) lastlog2 (distros nuevas donde lastlog fue removido)
    if [ -z "$line" ] && command -v lastlog2 >/dev/null 2>&1; then
        line=$(lastlog2 -u "$user" 2>/dev/null | sed -n '2p')
        printf '%s' "$line" | grep -qi 'never' && { echo "Nunca"; return; }
    fi
    # 3) last (wtmp) como ultima opcion
    if [ -z "$line" ] && command -v last >/dev/null 2>&1; then
        line=$(last -F -w "$user" 2>/dev/null | awk 'NF{print; exit}')
    fi

    [ -z "$line" ] && { echo "Nunca"; return; }

    # Extrae "Dia Mes DD HH:MM:SS [TZ] [AAAA]" sin importar las columnas previas
    local fecha
    fecha=$(printf '%s\n' "$line" \
        | grep -oE '[A-Z][a-z]{2} [A-Z][a-z]{2} +[0-9]+ [0-9:]+( [-+][0-9]{4})?( [0-9]{4})?' \
        | head -1)
    [ -z "$fecha" ] && fecha="Nunca"
    echo "$fecha"
}

get_users_last_login() {
    echo ""
    echo "--- Usuarios y ultimo login ---"
    echo ""
    printf "%-25s %s\n" "Usuario" "Ultimo Login"
    printf "%-25s %s\n" "-------------------------" "--------------------"

    while IFS=: read -r username _ uid _; do
        if [ "$uid" -ge 1000 ] || [ "$username" = "root" ]; then
            last_login=$(get_last_login_for_user "$username")
            [ -z "$last_login" ] && last_login="Nunca"
            printf "%-25s %s\n" "$username" "$last_login"
        fi
    done < /etc/passwd
}

get_filesystems() {
    echo ""
    echo "--- Filesystems / Discos conectados ---"
    echo ""
    printf "%-25s %20s %20s %8s\n" "Filesystem" "Tamano (bytes)" "Libre (bytes)" "% Libre"
    printf "%-25s %20s %20s %8s\n" "-------------------------" "--------------------" "--------------------" "-------"

    df -B1 --output=source,size,avail,pcent 2>/dev/null | tail -n +2 | while read -r fs size avail pcent; do
        free_pct=$(echo "$pcent" | tr -d '%')
        used_pct=$free_pct
        avail_pct=$((100 - used_pct))
        printf "%-25s %20s %20s %7s%%\n" "$fs" "$size" "$avail" "$avail_pct"
    done
}

get_top10_files() {
    echo ""
    echo "--- Top 10 archivos mas grandes ---"
    echo ""
    read -rp "Ingrese el disco o directorio (ej: /): " path

    if [ ! -d "$path" ]; then
        echo "El directorio '$path' no existe."
        return
    fi

    echo ""
    echo "Buscando archivos en '$path', por favor espere..."
    echo ""

    printf "%-4s %-20s %s\n" "#" "Tamano (bytes)" "Ruta completa"
    printf "%-4s %-20s %s\n" "----" "--------------------" "----------------------------------------"

    i=1
    find "$path" -type f -printf '%s %p\n' 2>/dev/null | \
        sort -rn | head -10 | \
        while read -r size filepath; do
            printf "%-4s %-20s %s\n" "$i" "$size" "$filepath"
            ((i++))
        done
}

get_memory_swap() {
    echo ""
    echo "--- Memoria libre y Swap en uso ---"
    echo ""

    read -r _ total_kb used_kb free_kb _ <<< "$(free -b | grep '^Mem:')"
    read -r _ swap_total_kb swap_used_kb swap_free_kb <<< "$(free -b | grep '^Swap:')"

    if [ "$total_kb" -gt 0 ]; then
        pct_free_ram=$(awk "BEGIN {printf \"%.2f\", ($free_kb / $total_kb) * 100}")
    else
        pct_free_ram="0.00"
    fi

    if [ "$swap_total_kb" -gt 0 ]; then
        pct_used_swap=$(awk "BEGIN {printf \"%.2f\", ($swap_used_kb / $swap_total_kb) * 100}")
    else
        pct_used_swap="0.00"
    fi

    echo "MEMORIA RAM"
    printf "  Total:       %20s bytes\n" "$total_kb"
    printf "  En uso:      %20s bytes\n" "$used_kb"
    printf "  Libre:       %20s bytes  (%s%%)\n" "$free_kb" "$pct_free_ram"

    echo ""
    echo "SWAP"
    printf "  Total:       %20s bytes\n" "$swap_total_kb"
    printf "  En uso:      %20s bytes  (%s%%)\n" "$swap_used_kb" "$pct_used_swap"
    printf "  Libre:       %20s bytes\n" "$swap_free_kb"
}

invoke_backup() {
    echo ""
    echo "--- Backup a USB con catalogo ---"
    echo ""
    read -rp "Ingrese el directorio de origen: " origen
    read -rp "Ingrese la ruta de la memoria USB (ej: /media/usb): " destino

    if [ ! -d "$origen" ]; then
        echo "El directorio de origen '$origen' no existe."
        return
    fi
    if [ ! -d "$destino" ]; then
        echo "La ruta de destino '$destino' no existe o la USB no esta montada."
        return
    fi

    timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
    backup_folder="$destino/backup_$timestamp"
    catalog_path="$backup_folder/catalogo_$timestamp.txt"

    echo ""
    echo "Copiando archivos a '$backup_folder'..."
    cp -r "$origen" "$backup_folder" 2>&1

    if [ $? -ne 0 ]; then
        echo "Error durante la copia."
        return
    fi

    echo "Generando catalogo de archivos..."
    echo "Nombre|Ruta completa|Ultima modificacion|Tamano (bytes)" > "$catalog_path"

    find "$backup_folder" -type f | while read -r file; do
        name=$(basename "$file")
        mod_date=$(stat -c "%y" "$file" 2>/dev/null | cut -d'.' -f1)
        size=$(stat -c "%s" "$file" 2>/dev/null)
        echo "$name|$file|$mod_date|$size" >> "$catalog_path"
    done

    count=$(find "$backup_folder" -type f | wc -l)

    echo ""
    echo "Backup completado exitosamente."
    echo "Destino:  $backup_folder"
    echo "Catalogo: $catalog_path"
    echo "Archivos copiados: $count"
}

show_menu() {
    clear
    echo "======================================="
    echo "   HERRAMIENTA DE ADMINISTRACION DC   "
    echo "======================================="
    echo "  1. Usuarios y ultimo login"
    echo "  2. Filesystems / Discos"
    echo "  3. Top 10 archivos mas grandes"
    echo "  4. Memoria libre y Swap en uso"
    echo "  5. Backup a USB con catalogo"
    echo "  0. Salir"
    echo "======================================="
}

while true; do
    show_menu
    read -rp "Seleccione una opcion: " opcion

    case $opcion in
        0) echo "Saliendo..."; exit 0 ;;
        1) get_users_last_login ;;
        2) get_filesystems ;;
        3) get_top10_files ;;
        4) get_memory_swap ;;
        5) invoke_backup ;;
        *) echo "Opcion invalida. Intente de nuevo." ;;
    esac

    echo ""
    read -rp "Presione Enter para continuar..."
done
