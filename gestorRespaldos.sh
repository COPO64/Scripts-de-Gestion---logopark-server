#!/bin/bash

# Script para respaldar archivos y directorios importantes de manera local y remota.

# Menu visual:
# Define la función Menu (todavía NO se ejecuta, solo se declara).
# Muestra las opciones y guarda lo que el usuario escriba en la variable "opcion".
# Como no usa "local", "opcion" es global y se puede leer más abajo en el case final.
Menu() { 
    echo "1) Respaldo Local (Manual)"
    echo "2) Respaldo Remoto (Manual)"
    echo "3) Programar Respaldo (Automatizado/Local)"
    echo "4) Salir"
    read -p "Seleccione una opción: " opcion   # -p muestra el texto como prompt
}

# Iniciar el menu y mostrarle las opciones al usuario.
# Acá recién se ejecuta la función: se muestra el menú y se pide la opción.
Menu

# Verificación de permisos:
# Verifica si el script se está ejecutando con permisos de root. Si no, te dice que necesitas permisos root/sudo.
# $EUID es el ID de usuario efectivo; root siempre es 0.
# Si es distinto de 0 (-ne = "not equal"), avisa y corta con "exit 1" (código de error).
# Nota: este chequeo corre DESPUÉS de Menu, así que el usuario elige una opción antes de enterarse de que le faltan permisos.
if [[ $EUID -ne 0 ]]; then
    echo "Este script debe ejecutarse con permisos root o sudo"
    echo "Ejemplo: sudo ./gestorRespaldos.sh"
    exit 1
fi

# Funcion de respaldo local: Copia un archivo o directorio a otra ubicación de la misma máquina.
funcRespaldoLocal() {
    read -p "Ingrese la ruta del directorio o archivo a respaldar: " ruta   # origen
    read -p "Ingrese la ruta de destino para el respaldo: " destino         # destino

    # cp -r = copia recursiva (necesaria para directorios).
    # Las comillas protegen rutas con espacios.
    cp -r "$ruta" "$destino"

    # $? guarda el código de salida del último comando: 0 = éxito, otro = error.
    if [[ $? -eq 0 ]]; then
        echo "Backup exitoso."
    else
        echo "Backup no realizado."
    fi
}

# Funcion de respaldo remoto: Copia un archivo o directorio a otro equipo usando SSH (scp).
funcRespaldoRemoto() {
    echo "Los dos equipos deben estar en la misma red."
    read -p "Ingrese la ruta del directorio o archivo a respaldar: " ruta   # origen local
    read -p "Ingrese el usuario y host remoto (usuario@host): " remoto      # ej: admin@192.168.1.50
    read -p "Ingrese la ruta de destino en el host remoto: " destino        # carpeta en el remoto

    # scp -r copia de forma recursiva por SSH. El formato del destino es usuario@host:/ruta.
    # Va a pedir la contraseña del usuario remoto (o usa clave SSH si está configurada).
    scp -r "$ruta" "$remoto:$destino"

    # Mismo chequeo del código de salida que en el respaldo local.
    if [[ $? -eq 0 ]]; then
        echo "Backup exitoso."
    else
        echo "Backup no realizado."
    fi
}

# No hace el respaldo en el momento: agrega una tarea a cron para que se repita sola.
funcProgramarRespaldo() {

    read -p "Ingrese la ruta del archivo/directorio a respaldar: " ruta
    read -p "Ingrese la ruta de destino: " destino
    echo ""
    echo "¿Cada cuánto desea realizar el respaldo?"
    echo "1) Cada minuto"
    echo "2) Cada hora"
    echo "3) Todos los días"
    echo "4) Todas las semanas"

    read -p "Seleccione una opción: " frecuencia

    # Según la frecuencia, se arma la línea de cron en la variable "tarea".
    # Formato de cron:  minuto hora día-del-mes mes día-de-la-semana comando
    case $frecuencia in

        1)
            # "* * * * *" = todos los minutos de todas las horas, todos los días.
            tarea="* * * * * cp -r \"$ruta\" \"$destino\""
            ;;

        2)
            # Minuto 0 de cada hora (1:00, 2:00, 3:00...).
            tarea="0 * * * * cp -r \"$ruta\" \"$destino\""
            ;;

        3)
            # Minuto 0 de la hora elegida, todos los días.
            read -p "Ingrese la hora (0-23): " hora
            tarea="0 $hora * * * cp -r \"$ruta\" \"$destino\""
            ;;

        4)
            # Minuto 0 de la hora elegida, en el día de semana elegido (0 = domingo ... 6 = sábado).
            read -p "Ingrese el día de la semana (0-6): " dia
            read -p "Ingrese la hora (0-23): " hora
            tarea="0 $hora * * $dia cp -r \"$ruta\" \"$destino\""
            ;;

        *)
            # Cualquier otra entrada: avisa y sale de la función con código de error.
            echo "Opción inválida."
            return 1
            ;;
    esac

    # Agrega la tarea sin borrar las que ya existían:
    # crontab -l: muestra el crontab actual (2>/dev/null oculta el error si está vacío)
    # echo "$tarea": agrega la nueva línea al final
    # | crontab -: reemplaza el crontab con todo ese contenido leído desde la entrada estándar
    # Los paréntesis ( ) agrupan ambos comandos para que sus salidas se junten en un solo flujo.
    (crontab -l 2>/dev/null; echo "$tarea") | crontab -

    echo "Respaldo programado correctamente."
    echo "Tarea agregada:"
    echo "$tarea"
}

# Según la opción que se eligió al principio en Menu, llama a la función correspondiente.
# Recién acá se ejecutan las funciones definidas arriba.
case $opcion in
    1) funcRespaldoLocal ;;
    2) funcRespaldoRemoto ;;
    3) funcProgramarRespaldo ;;
    4) echo "Saliendo..."; exit 0 ;;   # exit 0 = salida normal, sin errores
    *) echo "Opción inválida. Por favor, selecciona una opción válida." ;;
esac