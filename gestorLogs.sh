#!/bin/bash

# Verifica si el script se está ejecutando con permisos de root. Si no, te dice que necesitas permisos root/sudo.
if [[ $EUID -ne 0 ]]; then
    echo "Este script debe ejecutarse con permisos root o sudo"
    echo "Ejemplo: sudo ./gestorLogs.sh"
    exit 1
fi

# Menu: solo muestra las opciones en pantalla (no lee nada).
Menu(){
    echo "1) Buscar intentos de Login"
    echo "2) Buscar comandos ejecutados (con Regex)"
    echo "3) Salir"
}

# funcIntentosLogin: pregunta si se quieren ver los logins exitosos o los fallidos y los busca en el registro de SSH.
funcIntentosLogin(){
    echo "Seleccione qué tipo de intento de login desea buscar:"
    echo "1) Intentos de login exitosos"
    echo "2) Intentos de login fallidos"
    read -p "Ingrese su opción: " tipo_intento

    if [[ "$tipo_intento" == "1" ]]; then
        echo "Buscando intentos de login exitosos..."

        # sudo: los registros del sistema (logs) solo los puede leer root o un usuario del grupo "adm". Con sudo corremos
        # journalctl con permisos de administrador, sino no mostraría todo o daría error de permisos.

        # journalctl -u ssh: lee los logs del servicio SSH. En Ubuntu 24.04 el servicio se llama "ssh" (no "sshd") y los logs
        # viven en el journal, ya que /var/log/auth.log puede no existir.

        # --no-pager: imprime todo directo, sin abrir el visor "less".

        # grep "Accepted": SSH escribe "Accepted" cuando un login sale bien.

        # || echo: si grep no encuentra nada, avisa en vez de quedar en blanco.
        sudo journalctl -u ssh --no-pager | grep "Accepted" || echo "No se encontraron resultados."

    elif [[ "$tipo_intento" == "2" ]]; then
        echo "Buscando intentos de login fallidos..."

        # Igual que arriba, pero SSH escribe "Failed" cuando un login falla (por ejemplo, contraseña incorrecta).
        sudo journalctl -u ssh --no-pager | grep "Failed" || echo "No se encontraron resultados."

    else
        echo "Opción no válida"
    fi
}

# funcComandosEjecutados: busca una palabra o expresión regular en el historial de comandos de los usuarios.
funcComandosEjecutados(){
    read -p "Ingrese la palabra o comando a buscar: " comando_buscar
    echo "Buscando coincidencias en el historial..."

    # Por qué NO usamos el comando "history": dentro de un script arranca con el historial vacío. Por eso leemos directamente los
    # archivos ".bash_history", que es donde bash guarda los comandos.

    # sudo cat: el historial de cada usuario es privado. Sin sudo solo podríamos leer el nuestro; con sudo leemos el de todos
    # (/root y cada carpeta dentro de /home).

    # 2>/dev/null: oculta los errores, por ejemplo si algún usuario todavía no tiene archivo .bash_history.

    # grep -E: permite usar Regex (expresiones regulares).

    # grep -i: ignora mayúsculas/minúsculas para evitar errores comunes.
    
    # || echo: si no hay coincidencias, avisa.
    sudo cat /root/.bash_history /home/*/.bash_history 2>/dev/null | grep -a -E -i "$comando_buscar" || echo "No se encontraron coincidencias."
}

# Bucle del menú principal: se repite hasta que el usuario elige 3.
opcion=0

# Se compara como texto ("!=") para que no falle si escriben una letra.
while [ "$opcion" != "3" ]; do
    Menu
    read -p "Ingrese su opción: " opcion

    case $opcion in
        1) funcIntentosLogin;;
        2) funcComandosEjecutados;;
        3) echo "Saliendo del programa...";;
        *) echo "Opción no válida, intente de nuevo.";;
    esac
    echo "" # Espacio en blanco para separar las repeticiones del menú
done