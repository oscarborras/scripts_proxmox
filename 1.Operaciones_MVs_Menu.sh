#!/bin/bash

############################################################################
#title     : Permite realizar diferentes operaciones sobre MV y CTs
#author    : Óscar Borrás
#date mod  : <!#FT> 2025/01/30 01:09:49.597 </#FT>
#version   : <!#FV> 0.5.1 </#FV>
############################################################################

############################################################################
# INSTRUCCIONES:
############################################################################
# - Este script debe estar en un directorio de scripts para proxmox con los
#   permisos controlados
# - Los usuarios y el pool deben estar creados en Proxmox

############################################################################
# POR CORREGIR:
############################################################################
# - falta la creacion eliminacion de la SDN

############################################################################
# VARIABLES:
############################################################################
VERSION="0.5.1"
# shellcheck disable=SC2034
VERSION_BOUNDARIES="<!#FV> 0.5.1 </#FV>"

LOG="$0.log"

IDPROF_INICIAL=""
IDPROF_FINAL=""

############################################################################
# FUNCIONES:
############################################################################

msg_aviso() {
  if [ -n "$SPINNER_PID" ] && ps -p $SPINNER_PID > /dev/null; then kill $SPINNER_PID > /dev/null; fi
  printf "\e[?25h"
  local msg="$1"
  echo -e "${BFR}${INFO}${GN}${msg}${CL}"	
}

msg_icono() {
  if [ -n "$SPINNER_PID" ] && ps -p $SPINNER_PID > /dev/null; then kill $SPINNER_PID > /dev/null; fi
  printf "\e[?25h"
  local msg="$2"
  local icono="$1"
  echo -e "${BFR}${icono}${GN}${msg}${CL}"	
}


msg_info() {
  if [ -n "$SPINNER_PID" ] && ps -p $SPINNER_PID > /dev/null; then kill $SPINNER_PID > /dev/null; fi
  
  local msg="$1"
  
  echo -ne "${TAB}${YW}${HOLD}${msg}${HOLD}"

  echo "${msg}" >> ${LOG}
  spinner &
  SPINNER_PID=$!

#version antigua  
#  echo -ne " ${HOLD} ${YW}${msg} ...  "
#  if [ -n "$SPINNER_PID" ] && ps -p $SPINNER_PID > /dev/null; then kill $SPINNER_PID > /dev/null; fi
#  spinner &
#  SPINNER_PID=$!  
}

msg_ok() {
  if [ -n "$SPINNER_PID" ] && ps -p $SPINNER_PID > /dev/null; then kill $SPINNER_PID > /dev/null; fi
  printf "\e[?25h"
  local msg="$1"
  echo -e "${BFR}${CM}${GN}${msg}${CL}"	
  
  echo "${msg}" >> ${LOG}		
}

msg_error() {
  if [ -n "$SPINNER_PID" ] && ps -p $SPINNER_PID > /dev/null; then kill $SPINNER_PID > /dev/null; fi
  printf "\e[?25h"
  local msg="$1"
  echo -e "${BFR}${CROSS}${RD}${msg}${CL}"	

  echo "${msg}" >> ${LOG}  	
}

function ayuda() {
cat << DESCRIPCION_AYUDA
SYNOPIS
     $0 POOL

	IMPORTANTE: El nombre del POOL debe coincidir con el nombre de una subcarpeta
	
	Ejemplo: $0 DWEC

DESCRIPCIÓN
    Permite realizar unas series de operaciones sobre el servidor Proxmox y
	sus máquinas virtuales y contenedores

CÓDIGOS DE RETORNO
    0 - no hay ningún error.
    1 - script no ejecutado como usuario root o administrador
    2 - parámetro incorrecto
    3 - el proceso ya se está ejecutando
    
DESCRIPCION_AYUDA
}

mostrar_profesor() {
  if [ -n "$SPINNER_PID" ] && ps -p $SPINNER_PID > /dev/null; then kill $SPINNER_PID > /dev/null; fi
  printf "\e[?25h"
  local msg="$1"
  echo -e "${BFR}${GN}${msg}${CL}"	
  
  echo "${msg}" >> ${LOG}		
}

mostrar_IDsprofesor() {
  if [ -n "$SPINNER_PID" ] && ps -p $SPINNER_PID > /dev/null; then kill $SPINNER_PID > /dev/null; fi
  printf "\e[?25h"
  local msg="Tus IDs: ${IDPROF_INICIAL}..${IDPROF_FINAL}"
  echo -e "${BFR}${OS}${GN}${msg}${CL}"	
  
  echo "${msg}" >> ${LOG}		
}

mostrar_Pool_profesor() {
  if [ -n "$SPINNER_PID" ] && ps -p $SPINNER_PID > /dev/null; then kill $SPINNER_PID > /dev/null; fi
  printf "\e[?25h"
  local msg=" Tu POOL: ${MI_POOL}"
  echo -e "   ${BFR}${OS}${GN}${msg}${CL}"	
  echo "----------------------------------"
  echo "${msg}" >> ${LOG}		
}


formato_mensajes() {
  # Colors
  YW=$(echo "\033[33m")
  YWB=$(echo "\033[93m")
  BL=$(echo "\033[36m")
  RD=$(echo "\033[01;31m")
  BGN=$(echo "\033[4;92m")
  GN=$(echo "\033[1;92m")
  DGN=$(echo "\033[32m")

  # Formatting
  CL=$(echo "\033[m")
  UL=$(echo "\033[4m")
  BOLD=$(echo "\033[1m")
  BFR="\\r\\033[K"
  HOLD=" "
  TAB="  "

  # Icons
  CM="${TAB}✔️${TAB}${CL}"
  CROSS="${TAB}✖️${TAB}${CL}"
  INFO="${TAB}💡${TAB}${CL}"
  OS="${TAB}🖥️${TAB}${CL}"
  OSVERSION="${TAB}🌟${TAB}${CL}"
  CONTAINERTYPE="${TAB}📦${TAB}${CL}" 
  DISKSIZE="${TAB}💾${TAB}${CL}"
  CPUCORE="${TAB}🧠${TAB}${CL}"
  RAMSIZE="${TAB}🛠️${TAB}${CL}"
  SEARCH="${TAB}🔍${TAB}${CL}"
  VERIFYPW="${TAB}🔐${TAB}${CL}"
  CONTAINERID="${TAB}🆔${TAB}${CL}"
  HOSTNAME="${TAB}🏠${TAB}${CL}"
  BRIDGE="${TAB}🌉${TAB}${CL}"
  NETWORK="${TAB}📡${TAB}${CL}"
  GATEWAY="${TAB}🌐${TAB}${CL}"
  DISABLEIPV6="${TAB}🚫${TAB}${CL}"
  DEFAULT="${TAB}⚙️${TAB}${CL}"
  MACADDRESS="${TAB}🔗${TAB}${CL}"
  VLANTAG="${TAB}🏷️${TAB}${CL}"
  ROOTSSH="${TAB}🔑${TAB}${CL}"
  CREATING="${TAB}🚀${TAB}${CL}"
  ADVANCED="${TAB}🧩${TAB}${CL}"
}


formato_mensajes_antiguo(){
	#Codificación de colores usando códigos de escape ANSI para formatear texto en la terminal
	RD=$(echo "\033[01;31m")
	YW=$(echo "\033[33m")
	GN=$(echo "\033[1;92m")
	CL=$(echo "\033[m")
	HOLD="-"
	CM="${GN}✓${CL}"
	CROSS="${RD}✗${CL}"
	#Mueve el cursor al principio de la línea actual (\\r).
	#Borra todo el contenido desde la posición actual del cursor hasta el final de la línea (\\033[K).
	#Esto es lo que permite escribir en la misma linea que el ultimo mensaje borrando lo anterior
	BFR="\\r\\033[K"
	SPINNER_PID=""
}	

# Muestra el spinner animado
spinner() {
  local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
  local spin_i=0
  local interval=0.1
  printf "\e[?25l"

  local color="${YWB}"

  while true; do
    printf "\r ${color}%s${CL}" "${frames[spin_i]}"
    spin_i=$(( (spin_i + 1) % ${#frames[@]} ))
    sleep "$interval"
  done
}

spinner_antiguo() {
    local chars="/-\|"
    local spin_i=0
    printf "\e[?25l"
    while true; do
        printf "\r \e[36m%s\e[0m" "${chars:spin_i++%${#chars}:1}"
        sleep 0.1
    done
}

# This function enables error handling in the script by setting options and defining a trap for the ERR signal.
catch_errors() {
  set -Eeuo pipefail
  trap 'error_handler $LINENO "$BASH_COMMAND"' ERR
}

# This function is called when an error occurs. It receives the exit code, line number, and command that caused the error, and displays an error message.
error_handler() {
  if [ -n "$SPINNER_PID" ] && ps -p $SPINNER_PID > /dev/null; then kill $SPINNER_PID > /dev/null; fi
  printf "\e[?25h"
  local exit_code="$?"
  local line_number="$1"
  local command="$2"
  local error_message="${RD}[ERROR]${CL} in line ${RD}$line_number${CL}: exit code ${RD}$exit_code${CL}: while executing command ${YW}$command${CL}"
  echo -e "\n$error_message\n"
}

# Check if the shell is using bash
shell_check() {
  if [[ "$(basename "$SHELL")" != "bash" ]]; then
    clear
    msg_error "Your default shell is currently not set to Bash. To use these scripts, please switch to the Bash shell."
    echo -e "\nExiting..."
    sleep 2
    exit
  fi
}

# Run as root only
root_check() {
  if [[ "$(id -u)" -ne 0 || $(ps -o comm= -p $PPID) == "sudo" ]]; then
    clear
    msg_error "Please run this script as root."
    echo -e "\nExiting..."
    sleep 2
    exit
  fi
}

configurar(){
	msg_info "--> Configurando MV ** ${ID_MV} ** "
	if qm set ${ID_MV} --tags "${TAG}" --description "${NOTAS_MV}" &>>${LOG}
	then
		msg_ok "MV ** ${ID_MV} ** configurada."
		return 0
	else
		msg_error "[ERROR] al configurar la MV ** ${ID_MV} **"
		return 1
	fi
}

asignar(){
	msg_info "--> Asignando acceso a MV ** ${ID_MV} ** con rol # ${ROL} # a -> ${USUARIO}"
	if pveum acl modify /vms/${ID_MV} -user ${USUARIO} -role ${ROL} &>>${LOG}
	then
		#msg_ok "Asignado acceso a MV ** ${ID_MV} ** con rol # ${ROL} # a -> ${USUARIO}"
		msg_ok "MV ** ${ID_MV} ** añadido acceso con rol # ${ROL} # a -> ${USUARIO}"
		return 0
	else
		msg_error "[ERROR] asignando acceso a MV ** ${ID_MV} ** con rol # ${ROL} # a -> ${USUARIO}"
		return 1
	fi
}

quitar_acceso(){
	msg_info "--> Quitando acceso a MV ** ${ID_MV} ** con rol # ${ROL} # a -> ${USUARIO}"
	if pveum acl delete /vms/${ID_MV} -user ${USUARIO} -role ${ROL} &>>${LOG}
	then
		msg_ok "Quitado acceso a MV ** ${ID_MV} ** con rol # ${ROL} # a -> ${USUARIO}"
		return 0
	else
		msg_error "[ERROR] quitando acceso a MV ** ${ID_MV} ** con rol # ${ROL} # a -> ${USUARIO}"
		return 1
	fi
}

#comprueba si un ID es un CT (lxc) o una MV (qemu)
comprobar_tipo_MV(){
	
	# pvesh get /cluster/resources --type vm --noborder
	# cat /etc/pve/.vmlist | grep lxc

	local ID_MV=$1

	if pct list | grep -w ${ID_MV} &> /dev/null
	then
		echo "CT"
	elif qm list | grep -w ${ID_MV} &> /dev/null
	then
		echo "MV"
	else
		echo "ERROR"
	fi
}

#verifica si lso IDs introducidos están en el rango de ID del profesor actual
verificar_IDs(){
	if [ ${IDPROF_INICIAL} -eq 0 ]; then
		return 0
	fi
	
	if [ $1 -ge ${IDPROF_INICIAL} ] && [ $1 -le ${IDPROF_FINAL} ] && [ $2 -ge ${IDPROF_INICIAL} ] && [ $2 -le ${IDPROF_FINAL} ]; then
		return 0
	else
		return 1
	fi
}

#comprueba si la primera MV/CT clonada está en el POOL seleccionado al iniciar el script
comprobar_Pool_MV(){
	local MV_INICIAL=$1
	local MV_FINAL=$2

	#pvesh get /pools/DWECL --output-format json-pretty | grep "vmid" | grep 10011
	if pvesh get /pools/${MI_POOL} --output-format json-pretty | grep "vmid" | grep ${MV_INICIAL} &>> ${LOG}
	then
		return 0
	else 
		return 1
	fi
}

iniciar_MV(){
	local ID_MV=$1
	
	if comprobar_Pool_MV ${ID_MV}
	then
		TIPO_MV=$(comprobar_tipo_MV ${ID_MV})

		if [[ ${TIPO_MV} = "CT" ]]; then
			CMD="pct"
		elif [[ ${TIPO_MV} = "MV" ]]; then
			CMD="qm"
		else
			#no existe la MV/CT
			msg_error "[ERROR] No existe la máquina ** ${ID_MV} **"
			return 2	
		fi
		
		if ${CMD} start ${ID_MV} &>>${LOG}
		then
			msg_ok "Iniciado la máquina ** ${ID_MV} **"
			return 0
		else
			msg_error "[ERROR] iniciando la máquina ** ${ID_MV} **"
			return 1
		fi
	else
		msg_error "El POOL de la MV/CT ** ${ID_MV} ** no coincide con tu usuario."
		return 2
	fi
}

apagar_MV(){
	local ID_MV=$1

	if comprobar_Pool_MV ${ID_MV}
	then
		TIPO_MV=$(comprobar_tipo_MV ${ID_MV})

		if [[ ${TIPO_MV} = "CT" ]]; then
			CMD="pct"
		elif [[ ${TIPO_MV} = "MV" ]]; then
			CMD="qm"
		else
			#no existe la MV/CT
			msg_error "[ERROR] No existe la máquina ** ${ID_MV} **"
			return 2	
		fi

		if ${CMD} shutdown ${ID_MV} &>>${LOG}
		then
			msg_ok "Apagado la máquina ** ${ID_MV} **"
			return 0
		else
			msg_error "[ERROR] apagando la máquina ** ${ID_MV} **"
			return 1
		fi
	else
		msg_error "El POOL de la MV/CT ** ${ID_MV} ** no coincide con tu usuario o no existe la MV/CT."
		return 2
	fi	
}

asignar_TAGS(){
	local ID_MV=$1

	if comprobar_Pool_MV ${ID_MV}
	then
		TIPO_MV=$(comprobar_tipo_MV ${ID_MV})

		if [[ ${TIPO_MV} = "CT" ]]; then
			CMD="pct"
		elif [[ ${TIPO_MV} = "MV" ]]; then
			CMD="qm"
		else
			#no existe la MV/CT
			msg_error "[ERROR] No existe la máquina ** ${ID_MV} **"
			return 2	
		fi

		#qm set ID --tags myfirsttag;mysecondtag
		if ${CMD} set ${ID_MV} --tags "${TAGS}" &>>${LOG}
		then
			msg_ok "Asignado TAGS a la máquina ** ${ID_MV} **"
			return 0
		else
			msg_error "[ERROR] asignando TAGS a la máquina ** ${ID_MV} **"
			return 1
		fi
	else
		msg_error "El POOL de la MV/CT ** ${ID_MV} ** no coincide con tu usuario o no existe la MV/CT."
		return 2
	fi	
}


backup_MV(){
	local ID_MV=$1
	local STORAGE=$2
	local MODO=$3

	msg_info "--> Realizando Backup de la máquina ** ${ID_MV} **"

	#/usr/bin/vzdump $ID_MV --node $NODO --remove 0 --storage $STORAGE --mode stop --notes-template '{{guestname}}' --compress zstd
	if vzdump ${ID_MV} --remove 0 --storage $STORAGE --mode ${MODO} --notes-template '{{guestname}}' --compress zstd &>>${LOG}
	then
		msg_ok "Backup realizado de la máquina ** ${ID_MV} **"
		return 0
	else
		msg_error "[ERROR] realizando backup de la máquina ** ${ID_MV} **"
		return 1
	fi
}


eliminar_MV(){
	local ID_MV=$1

	#comprobamos si la MV pertecene al POOL del usuario	
	if comprobar_Pool_MV ${ID_MV}
	then
		TIPO_MV=$(comprobar_tipo_MV ${ID_MV})

		if [[ ${TIPO_MV} = "CT" ]]; then
			CMD="pct"
		elif [[ ${TIPO_MV} = "MV" ]]; then
			CMD="qm"
		else
			#no existe la MV/CT
			msg_error "[ERROR] No existe la máquina ** ${ID_MV} **"
			return 2	
		fi
			
		msg_info "--> 1. Apagando la máquina ** ${ID_MV} **"
		if ${CMD} stop ${ID_MV} --timeout 2 &>>${LOG}
		then
			msg_info "--> 2. Eliminando la máquina ** ${ID_MV} **"
			if ${CMD} destroy ${ID_MV} --purge --destroy-unreferenced-disks=1 --skiplock=1 &>>${LOG}
			then
				msg_ok "Eliminado la máquina ** ${ID_MV} **"
				return 0
			else
				msg_error "[ERROR] al eliminar la máquina ** ${ID_MV} **"
				return 1
			fi
		else
			msg_error "[ERROR] al parar la MV ** ${ID_MV} **"
			return 1
		fi
	else
		msg_error "El POOL de la MV/CT ** ${ID_MV} ** no coincide con tu usuario."
		return 2
	fi
}

iniciarMVs(){
	mostrar_Pool_profesor
	echo ""
	echo -n "Indicar ID de la primera MV a iniciar: "
	read ID_INICIAL
	echo -n "Indicar ID de la ultima MV a iniciar: "
	read ID_FINAL
	echo ""
	
	for (( ID_MV=$ID_INICIAL; ID_MV<=$ID_FINAL; ID_MV++ ))
	do
		msg_info "--> Iniciando la máquina ** ${ID_MV} **"
		iniciar_MV $ID_MV
	done
	echo	
}

apagarMVs(){
	mostrar_Pool_profesor
	echo ""
	echo -n "Indicar ID de la primera MV a apagar: "
	read ID_INICIAL
	echo -n "Indicar ID de la ultima MV a apagar: "
	read ID_FINAL
	echo ""

	for (( ID_MV=$ID_INICIAL; ID_MV<=$ID_FINAL; ID_MV++ ))
	do
		msg_info "--> Apagando la máquina ** ${ID_MV} **"
		apagar_MV ${ID_MV}
	done
	echo
}

asignarTAGs(){
	mostrar_Pool_profesor
	echo ""
	read -p "Indica las etiquetas (TAG) a asignar separados por espacios: " TAGS
	read -p "Indicar ID de la primera MV a asignar etiqueta: " ID_INICIAL
	read -p "Indicar ID de la ultima MV a asignar etiqueta: " ID_FINAL
	echo ""

	for (( ID_MV=$ID_INICIAL; ID_MV<=$ID_FINAL; ID_MV++ ))
	do
		msg_info "--> Asignando TAGS a máquina ** ${ID_MV} **"
		asignar_TAGS $ID_MV
	done
	echo
}

backupsMVs(){
	mostrar_Pool_profesor
	echo ""
	echo -n "Indicar ID de la primera MV a la que realizar backup: "
	read ID_INICIAL
	echo -n "Indicar ID de la ultima MV a la que realizar backup: "
	read ID_FINAL

	#STORAGE="local-backup1"
	read -p "Indica el almacenamiento a utilizar (debe permitir backups): " STORAGE
	read -p "Indica el tipo de backup (<snapshot | stop | suspend>): " TIPO
	echo ""

	for (( ID_MV=$ID_INICIAL; ID_MV<=$ID_FINAL; ID_MV++ ))
	do
		backup_MV $ID_MV $STORAGE $TIPO
	done
	echo
}


eliminarMVs(){
	mostrar_Pool_profesor
	echo ""
	echo -n "Indicar ID de la primera máquina o contenedor a borrar : "
	read ID_INICIAL
	echo -n "Indicar ID de la ultima máquina o contenedor a borrar  : "
	read ID_FINAL

	echo
	msg_error "Se va a **DESTRUIR** todas las MVs desde la ${ID_INICIAL} hasta la ${ID_FINAL}"
	echo
	read -p "    ¿Estas seguro de querer BORRARLAS? (si / no): " RESP
	echo 
	
	if [[ $RESP = "si" ]]; then
		for (( ID_MV=$ID_INICIAL; ID_MV<=$ID_FINAL; ID_MV++ ))
		do
			msg_info "--> Comprobando POOL ..."
			eliminar_MV $ID_MV
		done
		echo
	else
		echo "OPERACION ABORTADA"
	fi
}

crear_SDN_estatica(){
	clear
	echo "*****************************" | tee -a ${LOG}
	echo "         Creando SDN" | tee -a ${LOG}
	echo "*****************************" | tee -a ${LOG}
	echo


#Por defecto se crea zona según el Pool
	echo "Indicar ID para la ZONA a crear (zn_${POOL}):"
	read ID_INICIAL
	echo "Indicar ID de la ultima MV a iniciar:"
	read ID_FINAL
	echo ""
	
	if verificar_IDs ${ID_INICIAL} ${ID_FINAL}
	then
		for (( ID_MV=$ID_INICIAL; ID_MV<=$ID_FINAL; ID_MV++ ))
		do
			iniciar_MV $ID_MV
		done
	else
		msg_error "Los IDs indicados no se corresponden con tu usuario."
	fi
	echo	



	local CONT_ALUMNOS=1

	while IFS=: read USUARIO NOMBREMV
	do
		#nos saltamos lineas comentadas
		if [[ "${USUARIO:0:1}" = "#" ]]; then
			continue
		fi

		if [ ${CONT_ALUMNOS} -lt 10 ]; then
			NUM="0${CONT_ALUMNOS}"
		else
			NUM="${CONT_ALUMNOS}"
		fi			

		#creamos 1 zona para cada alumno - max 8 caracteres en nombre de la zona
		msg_info "Creando ZONA ** ${ZONA_NAME}${NUM} **"
		if pvesh create cluster/sdn/zones --type simple --zone ${ZONA_NAME}${NUM} --ipam pve --dhcp dnsmasq &>>${LOG}
		then
			msg_ok "Creada ZONA ** ${ZONA_NAME}${NUM} **"
		else
			msg_error "[ERROR] al crear ZONA ** ${ZONA_NAME}${NUM} **"
		fi

		# creamos X vnets para cada alumno (Ej: gestion y cluster) - max 8 caracteres en nombre de la vnet
		# creamos subnet para cada alumno en cada vnet
		for INDEX in "${!VNET_NAMES[@]}"; do
		    #echo "Índice: $INDEX, Valor: ${VNET_NAMES[$INDEX]}"

			msg_info "creando VNET ${VNET_NAMES[$INDEX]}${NUM} "
			if pvesh create cluster/sdn/vnets --vnet ${VNET_NAMES[$INDEX]}${NUM} --zone ${ZONA_NAME}${NUM} &>>${LOG}
			then
				msg_ok "Creada VNET ** ${VNET_NAMES[$INDEX]}${NUM} **"
			else
				msg_error "[ERROR] al crear VNET ** ${VNET_NAMES[$INDEX]}${NUM} **"
			fi
			
			msg_info "creando SUBNET ${SUBNETS[$INDEX]}"
			#pvesh create /cluster/sdn/vnets/vnet01/subnets --subnet 192.168.0.0/24 --type subnet --gateway 192.168.0.1 --snat true --dhcp-range start-address=192.168.0.100,end-address=192.168.0.200
			#pvesh usage cluster/sdn/vnets/ges01/subnets -v
			if pvesh create cluster/sdn/vnets/${VNET_NAMES[$INDEX]}${NUM}/subnets/ --subnet ${SUBNETS[$INDEX]} --type subnet --gateway ${GATEWAYS[$INDEX]} --snat ${SNAT} --dhcp-range start-address=${DHCP_RANGE_START[$INDEX]},end-address=${DHCP_RANGE_END[$INDEX]}
			then
				msg_ok "Creada SUBNET ** ${SUBNETS[$INDEX]}**"
			else
				msg_error "[ERROR] al crear SUBNET ** ${SUBNETS[$INDEX]} **"
			fi

		done
		echo "------------------------------------"
		let CONT_ALUMNOS++
		
	done < $USUARIOS

	#Aplicamos los cambios
	msg_info " Aplicando cambios en SDN..."
	if pvesh set cluster/sdn &>>${LOG}
	then
		msg_ok "SDN actualizado satisfactoriamente."
	else
		msg_error "[ERROR] al actualizar la SDN"
	fi

}

pulsa_enter(){
	echo; echo "Pulsa enter para volver al menú"
	read enter
}

cabecera_accion(){
	local msg="$1"
	clear
	echo "**********************************" | tee -a ${LOG}
	echo "${msg}" | tee -a ${LOG}
	echo "**********************************" | tee -a ${LOG}
	echo	
}

mostrar_menu(){

	while true; do
		clear
		echo
		echo "       M E N U   P R I N C I P A L"
		echo "--------------------------------------------"
		echo "   Operaciones sobre MVs y CTs (${VERSION})"
		echo "--------------------------------------------"
		mostrar_profesor "  POOL de trabajo: ${MI_POOL}"
		echo "--------------------------------------------"
		echo
		echo "  1.- Iniciar MVs"
		echo "  2.- Apagar MVs"
		echo "  3.- Asignar etiquetas a MVs"
		echo "  4.- Realizar backups de MVs"
		echo "  5.- Crear Red SDN (Zona - Vnet - Subred)***************"
		echo "  6.- Eliminar Red SDN (Zona - Vnet - Subred)************"
		echo "  9.- Eliminar MVs"
		echo
		echo "  S.- Salir."
		echo
		read -p "  Elija una opcion --> " MODO
		echo

		case ${MODO} in
			[Ss])
				exit
				;;
			1)
				cabecera_accion "        Iniciar MVs/CTs"
				iniciarMVs
				pulsa_enter
				;;
			2)
				cabecera_accion "        Apagar MVs/CTs"
				apagarMVs
				pulsa_enter
				;;
			3)
				cabecera_accion "     Asignar Tags a MVs/CTs"
				asignarTAGs
				pulsa_enter
				;;
			4)
				cabecera_accion "   Realizar Backups de MVs/CTs"
				backupsMVs
				pulsa_enter
				;;
			5)
				cabecera_accion "           Crear SDNs"
				crearSDN
				pulsa_enter
				;;

			9)
				cabecera_accion "        Borrar MVs/CTs"
				eliminarMVs
				pulsa_enter
				;;
			*)
				echo "Opción no válida. Espere por favor..."
				sleep 2s			
				;;
		esac
	done
}

selecciona_usuario(){

	if ! [ -r "${FICH_PROFESORES}" ]; then
		msg_error "No existe el fichero de configuración '${FICH_PROFESORES}'."
		msg_error "Contacta con el administrador para avisarlo."
		msg_error "Se va a cerrar la aplicación."
		echo
		exit 1
	fi
	
	while true; do
		clear
		echo "       SELECCION DE USUARIO"
		echo "--------------------------------------"
		
		#Mostramos lista de profesores configurados
		oldIFS=${IFS}
		IFS=$'\n' 
		for PROFESOR in $(cat ${FICH_PROFESORES})
		do
			if [ "${PROFESOR:0:1}" != "#" ]; then
				echo "- ${PROFESOR}" | cut -d ":" -f1
			fi
		done
		IFS=${oldIFS}
		echo ""

		read -p "  Indica quien eres (si no apareces contacta con el administrador) --> " PROFESOR
		if grep -i ${PROFESOR} ${FICH_PROFESORES} &> /dev/null
		then
			#Leemos el rango de ID de MVs del profesor seleccionado
			IDPROF_INICIAL=$(grep -i ${PROFESOR} ${FICH_PROFESORES} | cut -d ":" -f2)
			IDPROF_FINAL=$(grep -i ${PROFESOR} ${FICH_PROFESORES} | cut -d ":" -f3)
			break
		else
			case $PROFESOR in
				"salir")
					exit
					;;
				"root")
					IDPROF_INICIAL=0
					IDPROF_FINAL=0
					break
					;;
				*)
					echo ""
					msg_error "[ERROR] Nombre de usuario incorrecto. Prueba otra vez y escribe 'salir' si desea cancelar"
					#echo "  [ERROR]  Nombre de usuario no existente. Prueba otra vez y escribe 'salir' si desea cancelar"
					read -p "  Pulsa ENTER para continuar "
					;;
			esac
			
		fi
	done
}

mostrar_ayuda() {
cat << DESCRIPCION_AYUDA
SINTAXIS
    $0 POOL

	Ejemplo: $0 DWEC
	
DESCRIPCIÓN
    Permite realizar unas series de operaciones sobre el servidor Proxmox
    en las que el script nos irá solcitando los datos que necesite.

CÓDIGOS DE RETORNO
    0 - no hay ningún error.
    1 - script no ejecutado como usuario root o administrador
    2 - no se usa la shell Bash
    
DESCRIPCION_AYUDA
}

#selección del pool a usar en las operaciones
seleccion_pool(){
	function mensaje_pools_disponibles(){
		msg_icono "${SEARCH}" "Listado de POOLS disponibles:"
		echo
		echo -n "         "
		# shellcheck disable=SC2128
		echo ${POOLS_DISPONIBLES}
		echo
		read -r -p "   Indica el POOL de trabajo: " MI_POOL
	}

	if [ $# -ne 1 ]; then
		
		POOLS_DISPONIBLES=$(cat /etc/pve/user.cfg | grep pool: | cut -d ":" -f2)

		echo
		msg_aviso "Debes indicar con que POOL quieres trabajar. Solo podrás operar con las MVs del POOL que indiques."
		echo 
		mensaje_pools_disponibles
		
		while ! echo ${POOLS_DISPONIBLES} | grep ${MI_POOL}
		do
			clear
			echo
			msg_error "El POOL indicado no existe en el servidor"
			echo 
			sleep 1
			mensaje_pools_disponibles
		done
		
	else
		MI_POOL=$1
		case "$1" in
			"-h") 
				mostrar_ayuda
				exit
				;;
			"-v") 
				echo
				msg_ok " Versión: ${VERSION}"
				echo
				exit
				;;
		esac
	fi
}


############################################################################
# APP MAIN:
############################################################################
clear
echo "" > ${LOG}

formato_mensajes
#selecciona_usuario
seleccion_pool $1
mostrar_menu

