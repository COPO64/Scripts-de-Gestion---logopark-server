#!/bin/bash

# Gestor del Firewall (UFW) / Menú interactivo para administrar UFW:
# Permite activar o desactivar el firewall, ver su estado, abrir o cerrar los puertos, eliminar las reglas y listar las reglas activas.

# Colores: Para resaltar mensajes en la terminal y hacer el menú más visual. (El echo debe ser si o si "echo -e").
ROJO="\e[1;31m"
VERDE="\e[1;32m"
AMARILLO="\e[1;33m"
CIAN="\e[1;36m"

RESET="\e[0m" # Al final de cada mensaje, restablece al color predeterminado.

# Verificaciones de privilegios: UFW necesita permisos de administrador para poder modificar las reglas del firewall.
if [[ $EUID -ne 0 ]]; then
    echo -e "${ROJO}Este script debe ejecutarse como root o con sudo.${RESET}"
    echo "Ejemplo: sudo ./gestorFirewall.sh"
    exit 1
fi

# Comprueba si el comando "ufw" existe en el sistema. Si no está instalado, se le pregunta al usuario instalarlo automáticamente mediante apt. 
# Si el usuario rechaza la instalación, el script finaliza porque no tiene sentido continuar sin ufw.
if ! command -v ufw &> /dev/null; then
    echo -e "${ROJO}ufw no está instalado en este sistema.${RESET}"
    read -p "¿Querés instalarlo ahora? (s/n): " instalar
    if [[ "$instalar" =~ ^[sS]$ ]]; then
        apt update && apt install -y ufw
    else
        echo "Saliendo..."
        exit 1
    fi
fi

# Funciones contra errores y de terminación: Detiene la ejecución hasta que el usuario presione ENTER.
pausar() {
    echo ""
    read -p "Presioná ENTER para continuar..."
}

# Valida que el puerto ingresado por el usuario tenga un formato correcto antes de pasárselo a ufw. 
validar_puerto() {
    local entrada="$1"
# La expresión regular verifica que la entrada sea: Entre 1 y 5 dígitos numéricos. 
    if [[ "$entrada" =~ ^[0-9]{1,5}(/(tcp|udp))?$ ]]; then
# Separa el número de puerto del protocolo (si lo hubiera) cortando la cadena en el caracter "/".
        local numero="${entrada%%/*}"
# Verifica que el número esté dentro del rango válido de puertos TCP/UDP (1 a 65535).
        if (( numero >= 1 && numero <= 65535 )); then
            return 0
        fi
    fi
    return 1
}

# Funciones del menú / Activación del Firewall:
# Activa el firewall de UFW. Se usa "--force" para que ufw no pida una confirmación adicional por consola, ya que la confirmación real ya la dio el usuario al elegir esta opción desde el menú.
funcActivarFirewall() {
    echo -e "${AMARILLO}Activando el firewall...${RESET}"
    ufw --force enable
    pausar
}

# Desactiva el firewall de UFW. A diferencia de "enable", "disable" no requiere confirmación adicional, por eso no lleva "--force".
funcDesactivarFirewall() {
    echo -e "${AMARILLO}Desactivando el firewall...${RESET}"
    ufw disable
    pausar
}

# Muestra el estado actual del firewall. Se usa "verbose" para obtener información detallada: si está activo o no, la política por defecto (entrante/saliente) 
# y el listado completo de reglas configuradas.
funcEstadoFirewall() {
    echo -e "${CIAN}--- Estado del Firewall ---${RESET}"
    ufw status verbose
    pausar
}

# Funciones del menú / Gestión de Puertos: Solicita un puerto y lo abre (allow) en el firewall.
funcPermitirPuerto() {
    read -p "Ingresá el puerto a abrir (ej: 22, 80/tcp, 53/udp): " puerto

    if validar_puerto "$puerto"; then
        ufw allow "$puerto"
        echo -e "${VERDE}Puerto $puerto abierto.${RESET}"
    else
        echo -e "${ROJO}Puerto inválido. Formato esperado: numero o numero/tcp|udp${RESET}"
    fi

    pausar
}

# Solicita un puerto y lo cierra (deny) en el firewall.
funcDenegarPuerto() {
    read -p "Ingresá el puerto a denegar (ej: 22, 80/tcp, 53/udp): " puerto

    if validar_puerto "$puerto"; then
        ufw deny "$puerto"
        echo -e "${VERDE}Puerto $puerto cerrado.${RESET}"
    else
        echo -e "${ROJO}Puerto inválido. Formato esperado: numero o numero/tcp|udp${RESET}"
    fi
    pausar
}

# Elimina una regla existente del firewall. Se usa "--force" en el delete para que ufw no pida una segunda confirmación por consola.
funcEliminarReglas() {
    echo -e "${CIAN}--- Reglas actuales (numeradas) ---${RESET}"
    ufw status numbered
    echo ""
    read -p "Ingresá el número de regla a eliminar (o 0 para cancelar): " numero
    if [[ "$numero" == "0" ]]; then
        echo "Cancelado."
    elif [[ "$numero" =~ ^[0-9]+$ ]]; then
        ufw --force delete "$numero"
    else
        echo -e "${ROJO}Entrada inválida.${RESET}"
    fi
    pausar
}

# Lista todas las reglas activas del firewall numeradas.
funcListarReglas() {
    echo -e "${CIAN}--- Reglas activas ---${RESET}"
    ufw status numbered
    pausar
}

# Menú principal: Dibuja el menú en pantalla. Se llama en cada vuelta del loop principal, y usa "clear" para que el menú siempre aparezca limpio.
mostrar_menu() {
    clear
    echo -e "${AMARILLO}GESTOR DEL FIREWALL (UFW)${RESET}"
    echo ""
    echo "Activación de Firewall:"
    echo "  1) Activar Firewall"
    echo "  2) Desactivar Firewall"
    echo "  3) Ver Estado del Firewall"
    echo ""
    echo "Puertos:"
    echo "  4) Abrir un Puerto"
    echo "  5) Cerrar un Puerto"
    echo "  6) Eliminar una Regla"
    echo "  7) Listar las Reglas Activas"
    echo ""
    echo "  0) Salir"
    echo ""
}

# Bucle principal: Este es el bucle infinito que mantiene el menú en pantalla hasta que el usuario elija la opción "0" (Salir).
while [[ $opcion != 0 ]]; do
    mostrar_menu
    read -p "Elegí una opción: " opcion
    case $opcion in
        1) funcActivarFirewall ;;
        2) funcDesactivarFirewall ;;
        3) funcEstadoFirewall ;;
        4) funcPermitirPuerto ;;
        5) funcDenegarPuerto ;;
        6) funcEliminarReglas ;;
        7) funcListarReglas ;;
        0) echo "Saliendo..."; exit 0 ;;
        *) echo -e "${ROJO}Opción inválida.${RESET}"; pausar ;;
    esac
done