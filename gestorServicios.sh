#!/bin/bash

# Parte visual del menu (no interactivo).
funcMenu() {
    echo "Gestor de Servicios"
    echo "1) Activar un servicio"
    echo "2) Desactivar un servicio"
    echo "3) Reiniciar un servicio"
    echo "4) Ver estado de un servicio"
    echo "5) Salir"
    read -p "Seleccione una opción: " opcion
}

# Incia el menu y llama a la función funcMenu para mostrar las opciones al usuario.
funcMenu

# Verifica si el script se está ejecutando con permisos de root. Si no, te dice que necesitas permisos root/sudo.
if [[ $EUID -ne 0 ]]; then
    echo "Este script debe ejecutarse con permisos root o sudo"
    echo "Ejemplo: sudo ./gestorServicios.sh"
    exit 1
fi

# Activa el servicio seleccionado por el usuario con systemctl.
funcActivar() {
    read -p "Seleccione un servicio para iniciar: " servicio
    sudo systemctl start $servicio
}

# Desactiva el servicio seleccionado por el usuario con systemctl.
funcDesactivar() {
    read -p "Seleccione un servicio para detener: " servicio
    sudo systemctl stop $servicio
}

# Reinicia el servicio seleccionado por el usuario con systemctl.
funcReiniciar() {
    read -p "Seleccione un servicio para reiniciar: " servicio
    sudo systemctl restart $servicio
}

# Muestra el estado del servicio seleccionado por el usuario con systemctl.
funcEstado() {
    read -p "Seleccione un servicio para ver su estado: " servicio
    sudo systemctl status $servicio
}

# Bucle principal del menu que se va a ejecutar hasta que el usuario ingrese 5.
while [[ $opcion != 5 ]]; do
    case $opcion in
        1) funcActivar ;;
        2) funcDesactivar ;;
        3) funcReiniciar ;;
        4) funcEstado ;;
        5) echo "Saliendo..."; exit 0 ;;
        *) echo "Opción inválida. Por favor, selecciona una opción válida." ;;
    esac
done