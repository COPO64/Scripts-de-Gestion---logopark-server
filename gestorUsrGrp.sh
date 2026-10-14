#!/bin/bash

# Sistema de Administración de Usuarios y Grupos
# Permite crear y eliminar usuarios y grupos del sistema, además de visualizar
# la lista de usuarios existentes mediante un menú interactivo en la terminal.


# Colores ANSI utilizados para mejorar la presentación de los mensajes mostrados en la terminal.
# Para que los colores funcionen correctamente es necesario utilizar "echo -e", ya que interpreta las secuencias ANSI.
ROJO="\033[1;31m"
VERDE="\033[1;32m"
AMARILLO="\033[1;33m"
AZUL="\033[1;34m"

# Restablece el color original de la terminal después de imprimir un mensaje coloreado.
RESET="\033[0m"


# Función funcMenu:

# Muestra la interfaz principal del programa en la terminal.
# Presenta todas las opciones disponibles y almacena la opción elegida por el usuario en la variable "opcion".
# Se limpia la pantalla ("clear") al principio de esta función, y no solo una vez al inicio del script, para que el menú se
# redibuje limpio en cada vuelta del bucle y no se vayan acumulando los menús y resultados anteriores en la pantalla.
funcMenu() {
    clear
    echo -e "${AZUL}==============================${RESET}"
    echo -e "${AMARILLO}   GESTIÓN DE USUARIOS Y GRUPOS${RESET}"
    echo -e "${AZUL}==============================${RESET}"
    echo -e "1) Crear Grupo"
    echo -e "2) Crear Usuario"
    echo -e "3) Eliminar Grupo"
    echo -e "4) Eliminar Usuario"
    echo -e "5) Ver Lista de Usuarios"
    echo -e "6) Salir"
    echo -e "${AZUL}==============================${RESET}"
    read -p "Seleccione una opción: " opcion
}


# Función funcCrearGrupo:

# Solicita el nombre de un nuevo grupo y lo crea utilizando el comando "groupadd".
# Los posibles mensajes de error generados por el comando son redirigidos a /dev/null para evitar
# mostrarlos en pantalla, mostrando únicamente los mensajes definidos por el script.
funcCrearGrupo() {
    read -p "Ingrese el nombre del grupo: " nombre_grupo
    if sudo groupadd "$nombre_grupo" 2>/dev/null; then
        echo -e "${VERDE}Grupo '$nombre_grupo' creado correctamente.${RESET}"
    else
        echo -e "${ROJO}Error: No se pudo crear el grupo. Puede que ya exista.${RESET}"
    fi
}


# Función funcCrearUsuario:

# Solicita todos los datos necesarios para crear un usuario:
# - Tipo de usuario (administrador o estándar).
# - Nombre.
# - Directorio home.
# - Grupo principal.
# - Grupo secundario (opcional).
# - Contraseña.

# Dependiendo de la opción elegida, el usuario será agregado al grupo "sudo" o solamente a los grupos indicados.
funcCrearUsuario() {
    read -p "¿Quiere crear un usuario administrador? (s/n): " es_Admin
    read -p "Ingrese el nombre del usuario: " nombre_usuario
    read -p "Ingrese la ruta del home del usuario (ej: /home/$nombre_usuario): " ruta_homeusuario
    read -p "Ingrese el grupo principal: " grupo_principal
    read -p "Ingrese el grupo secundario (si no tiene, dejar vacío): " grupo_secundario
    read -s -p "Ingrese la contraseña para el usuario: " contrasena
    echo
    read -s -p "Confirme la contraseña: " confirmar_contrasena
    echo

    # Verifica que ambas contraseñas ingresadas sean iguales.
    # Si no coinciden, se informa el error y la función termina sin crear el usuario.
    if [[ "$contrasena" != "$confirmar_contrasena" ]]; then
        echo -e "${ROJO}Error: las contraseñas no coinciden.${RESET}"
        return
    fi

    # Comprueba si el usuario será administrador.
    # Se aceptan tanto letras mayúsculas como minúsculas.
    if [[ "$es_Admin" == "s" || "$es_Admin" == "S" ]]; then

        # Crea el usuario, genera automáticamente su directorio home, asigna Bash como shell por defecto, establece el grupo principal indicado y lo agrega al grupo sudo.
        sudo useradd -d "$ruta_homeusuario" -m -s /bin/bash -g "$grupo_principal" -G sudo "$nombre_usuario"

        # Asigna la contraseña al usuario utilizando chpasswd.
        echo "$nombre_usuario:$contrasena" | sudo chpasswd

        echo -e "${VERDE}Usuario administrador '$nombre_usuario' creado y agregado al grupo sudo.${RESET}"

    elif [[ "$es_Admin" == "n" || "$es_Admin" == "N" ]]; then

        # Si el usuario posee un grupo secundario, también se asigna durante la creación.
        if [[ -n "$grupo_secundario" ]]; then
            sudo useradd -d "$ruta_homeusuario" -m -s /bin/bash -g "$grupo_principal" -G "$grupo_secundario" "$nombre_usuario"
        else
            sudo useradd -d "$ruta_homeusuario" -m -s /bin/bash -g "$grupo_principal" "$nombre_usuario"
        fi

        # Establece la contraseña del usuario recién creado.
        echo "$nombre_usuario:$contrasena" | sudo chpasswd

        echo -e "${VERDE}Usuario estándar '$nombre_usuario' creado correctamente.${RESET}"

    else
        echo -e "${ROJO}Opción inválida. Debe ingresar 's' o 'n'.${RESET}"
    fi
}



# Función funcEliminarGrupo:

# Solicita el nombre de un grupo existente y lo elimina del sistema utilizando "groupdel".
# Los mensajes de error del comando son redirigidos a /dev/null para mostrar únicamente los mensajes definidos por el programa.
funcEliminarGrupo() {
    read -p "Ingrese el nombre del grupo a eliminar: " nombre_grupo
    if sudo groupdel "$nombre_grupo" 2>/dev/null; then
        echo -e "${VERDE}Grupo '$nombre_grupo' eliminado correctamente.${RESET}"
    else
        echo -e "${ROJO}Error: No se pudo eliminar el grupo. Verifique que exista o que no esté en uso.${RESET}"
    fi
}

# Función funcEliminarUsuario:

# Elimina un usuario del sistema.
# Antes de eliminarlo se consulta si también debe eliminarse su directorio home.
# Si se responde "s", se utiliza la opción "-r" de userdel, eliminando también el directorio personal del usuario.
funcEliminarUsuario() {
    read -p "Ingrese el nombre del usuario a eliminar: " nombre_usuario
    read -p "¿Desea eliminar también su carpeta home? (s/n): " eliminar_home

    if [[ "$eliminar_home" == "s" || "$eliminar_home" == "S" ]]; then
        sudo userdel -r "$nombre_usuario" 2>/dev/null
        echo -e "${AMARILLO}Usuario '$nombre_usuario' y su carpeta home fueron eliminados.${RESET}"
    else
        sudo userdel "$nombre_usuario" 2>/dev/null
        echo -e "${AMARILLO}Usuario '$nombre_usuario' eliminado, carpeta home conservada.${RESET}"
    fi
}

# Función funcVerUsuarios:

# Recorre el archivo /etc/passwd mostrando únicamente los usuarios normales del sistema (UID igual o superior a 1000).
# Durante la lectura se utiliza IFS=":" para indicar que los campos del archivo passwd están separados por dos puntos.
funcVerUsuarios() {
    echo -e "${AZUL}==============================${RESET}"
    echo -e "${AMARILLO}      LISTA DE USUARIOS${RESET}"
    echo -e "${AZUL}==============================${RESET}"

    # Extrae de /etc/passwd solo los campos que necesitamos:
    # campo 1 (usuario), campo 3 (uid) y campo 6 (home).
    # Así evitamos leer variables que no vamos a usar.
    while IFS=: read -r usuario uid home; do

        # Filtra los usuarios del sistema mostrando solamente aquellos creados para uso normal (UID 1000 o más).
        if [ "$uid" -ge 1000 ]; then
            printf "${VERDE}Usuario:${RESET} %-20s | ${AMARILLO}UID:${RESET} %-5s | ${AZUL}Home:${RESET} %s\n" "$usuario" "$uid" "$home"
        fi

    done < <(cut -d: -f1,3,6 /etc/passwd)

    echo -e "${AZUL}==============================${RESET}"
}

# Bucle principal del programa:

# Mantiene el menú en ejecución de forma indefinida hasta que el usuario seleccione la opción "Salir".
# Según la opción elegida, se invoca la función correspondiente.
# Si el valor ingresado no coincide con ninguna opción válida, se muestra un mensaje de error y el menú vuelve a aparecer.
# Se agrega "read -p ... Presione ENTER" al final de cada vuelta para que el usuario tenga tiempo de leer el resultado de la
# acción antes de que "funcMenu" limpie la pantalla de nuevo.
while [[ $opcion != 0 ]]; do
    funcMenu
    case $opcion in
        1) funcCrearGrupo ;;
        2) funcCrearUsuario ;;
        3) funcEliminarGrupo ;;
        4) funcEliminarUsuario ;;
        5) funcVerUsuarios ;;
        0) echo -e "${AMARILLO}Saliendo...${RESET}"; exit 0 ;;
        *) echo -e "${ROJO}Opción inválida. Intente de nuevo.${RESET}" ;;
    esac
    echo
    read -p "Presione ENTER para continuar..."
done