#!/bin/bash

############################################################################
#title           : Permite realizar diferentes operaciones para un Examen
#description     : App con menú que clona, configura y elimina MVs por usuario
#				    a partir de una plantilla asignandola a un pool y dándole permiso 
#					de acceso al usuario
#author          : Óscar Borrás
#date mod        : <!#FT> 2025/01/30 20:04:52.027 </#FT>
#version         : <!#FV> 0.5.2 </#FV>
#license         : GNU GPLv3 
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



############################################################################
# VARIABLES:
############################################################################
VERSION="0.5.2"
# shellcheck disable=SC2034
VERSION_BOUNDARIES="<!#FV> 0.5.2 </#FV>"

#Fichero log. Más adelante se indica la subcarpeta donde estará almacenado, que depende del pool
LOG="$0.log"

#Nombre del fichero de config - se localiza en la subcarpeta del pool a usar
FILE_CONF="0.Operaciones_Exam_Menu.conf"

#var para guardar los POOLS disponibles en el servidor
POOLS_DISPONIBLES=()
MI_POOL=""

#guardamos el PID del spinner para poder eliminarlo
SPINNER_PID=""

############################################################################
# FUNCIONES:
############################################################################

msg_info() {
  if [ -n "$SPINNER_PID" ] && ps -p $SPINNER_PID > /dev/null; then kill $SPINNER_PID > /dev/null; fi  
  local msg="$1"

  echo -ne "${TAB}${YW}${HOLD}${msg}${HOLD}"
  
  echo "${msg}" >> ${LOG}
  
  spinner &
  SPINNER_PID=$!

  #version antigua  
  #  echo -ne " ${HOLD} ${YW}${msg} ...  "
}

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

  echo "${msg}" >> "${LOG}"  	
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
  SEARCH="${TAB}🔍${TAB}${CL}"
  CONTAINERID="${TAB}🆔${TAB}${CL}"
  HOSTNAME="${TAB}🏠${TAB}${CL}"
  DISABLEIPV6="${TAB}🚫${TAB}${CL}"
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
    msg_error "Tu shell predeterminado no está configurado actualmente como Bash. Para usar estos scripts, por favor cambia al shell Bash."
    echo -e "\nSaliendo..."
    sleep 2
    exit
  fi
}

# Run as root only
root_check() {
  if [[ "$(id -u)" -ne 0 || $(ps -o comm= -p $PPID) == "sudo" ]]; then
    clear
    msg_error "Este script debe ejecutarse como root."
    echo -e "\nSaliendo..."
    sleep 2
    exit
  fi
}


clonar(){
	msg_info "..."
	TIPO_MV=$(comprobar_tipo_MV ${ID_MV_CLONAR})
	
	msg_info "--> Clonando ${TIPO_MV} ** ${ID_MV_CLONAR} ** con ID ** ${ID_MV} ** con nombre < ${HOSTNAME} >"

	if [[ ${TIPO_MV} = "CT" ]]; then
		pct clone ${ID_MV_CLONAR} ${ID_MV} --hostname ${HOSTNAME} --pool ${POOL} &>>${LOG}
	elif [[ ${TIPO_MV} = "MV" ]]; then
		qm clone ${ID_MV_CLONAR} ${ID_MV} --name ${HOSTNAME} --pool ${POOL} &>>${LOG}
	else
		msg_error "[ERROR] No se ha detectado el tipo de MV/CT a usar."
		return 2	
	fi

	if [ $? -eq 0 ]
	then
		msg_ok "${TIPO_MV} ** ${ID_MV} ** clonada de ** ${ID_MV_CLONAR} ** y nombre < ${HOSTNAME} >"
		return 0
	else
		msg_error "[ERROR] al clonar ${TIPO_MV} ** ${ID_MV_CLONAR} ** con ID ** ${ID_MV} ** y nombre < ${HOSTNAME} >"
		return 1
	fi
}

configurar(){
	msg_info "..."
	TIPO_MV=$(comprobar_tipo_MV ${ID_MV})
	
	msg_info "--> Configurando ${TIPO_MV} ** ${ID_MV} ** "
	
	if [[ ${TIPO_MV} = "CT" ]]; then
		CMD="pct"
	elif [[ ${TIPO_MV} = "MV" ]]; then
		CMD="qm"
	else
		#no existe la MV/CT
		msg_error "[ERROR] No se ha detectado el tipo de MV/CT a usar."
		return 2	
	fi

	if ${CMD} set ${ID_MV} --tags "${TAG}" --description "${NOTAS_MV}" &>>${LOG}
	then
		msg_ok "${TIPO_MV} ** ${ID_MV} ** configurada."
		return 0
	else
		msg_error "[ERROR] al configurar ${TIPO_MV} ** ${ID_MV} **"
		return 1
	fi
}

asignar_SDN_MVs(){  
	local NUM_ZONA=$1
	
	for INDEX in "${!VNET_NAMES[@]}"; do
    #echo "Índice: $INDEX, Valor: ${VNET_NAMES[$INDEX]}"

		msg_info "Comprobando tipo de Máquina Virtual (MV o CT)"

		TIPO_MV=$(comprobar_tipo_MV ${ID_MV})

		msg_info "--> Asignando RED  ** ${VNET_NAMES[${INDEX}]}${NUM_ZONA} ** a ${TIPO_MV} con ID ** ${ID_MV} ** "
		if [[ ${TIPO_MV} = "CT" ]]; then
			pct set ${ID_MV} -net${INDEX} name=eth0,bridge=${VNET_NAMES[${INDEX}]}${NUM_ZONA},ip=dhcp &>>${LOG}
		elif [[ ${TIPO_MV} = "MV" ]]; then
			qm set ${ID_MV} -net${INDEX} model=virtio,bridge=${VNET_NAMES[${INDEX}]}${NUM_ZONA} &>>${LOG}
		else
			msg_error "[ERROR] No se ha detectado el tipo de MV/CT a usar."
		fi

		if [ $? -eq 0 ]
		then
			msg_ok "${TIPO_MV} ** ${ID_MV} ** asignada RED ** ${VNET_NAMES[${INDEX}]}${NUM_ZONA} **"
		else
			msg_error "[ERROR] al asignar RED ** ${VNET_NAMES[${INDEX}]}${NUM_ZONA} **  a ${TIPO_MV} con ID ** ${ID_MV} **"
		fi
	done
}

quitar_SDN_MVs(){
	#local NUM_ZONA=$1
	local RED_DEFAULT="vmbr1"
	
	for INDEX in "${!VNET_NAMES[@]}"; do
    #echo "Índice: $INDEX, Valor: ${VNET_NAMES[$INDEX]}"

		msg_info "Comprobando tipo de Máquina Virtual (MV o CT)"

		TIPO_MV=$(comprobar_tipo_MV ${ID_MV})

		msg_info "--> Asignando RED  ** ${RED_DEFAULT} ** a ${TIPO_MV} con ID ** ${ID_MV} ** "
		if [[ ${TIPO_MV} = "CT" ]]; then
			pct set ${ID_MV} -net${INDEX} name=eth0,bridge=${RED_DEFAULT},ip=dhcp &>>${LOG}
		elif [[ ${TIPO_MV} = "MV" ]]; then
			qm set ${ID_MV} -net${INDEX} model=virtio,bridge=${RED_DEFAULT} &>>${LOG}
		else
			msg_error "[ERROR] No se ha detectado el tipo de MV/CT a usar."
		fi

		if [ $? -eq 0 ]
		then
			msg_ok "${TIPO_MV} ** ${ID_MV} ** asignada RED ** ${RED_DEFAULT} **"
		else
			msg_error "[ERROR] al asignar RED ** ${RED_DEFAULT} **  a ${TIPO_MV} con ID ** ${ID_MV} **"
		fi
	done
}

asignar(){
	msg_info "--> Asignando acceso a MV ** ${ID_MV} ** con rol # ${ROL} # a -> ${USUARIO}"
	if pveum acl modify /vms/${ID_MV} -user ${USUARIO} -role ${ROL} &>>${LOG}
	then
		#msg_ok "Asignado acceso a MV ** ${ID_MV} ** con rol # ${ROL} # a -> ${USUARIO}"
		msg_ok "${TIPO_MV} ** ${ID_MV} ** añadido acceso con rol # ${ROL} # a -> ${USUARIO}"
		return 0
	else
		msg_error "[ERROR] asignando acceso a ${TIPO_MV} ** ${ID_MV} ** con rol # ${ROL} # a -> ${USUARIO}"
		return 1
	fi
}

quitar_acceso(){
	msg_info "Comprobando tipo de Máquina Virtual (MV o CT)"
	
	TIPO_MV=$(comprobar_tipo_MV ${ID_MV})
	
	msg_info "--> Quitando acceso a ${TIPO_MV} ** ${ID_MV} ** con rol # ${ROL} # a -> ${USUARIO}"
	
	if pveum acl delete /vms/${ID_MV} -user ${USUARIO} -role ${ROL} &>>${LOG}
	then
		msg_ok "Quitado acceso a ${TIPO_MV} ** ${ID_MV} ** con rol # ${ROL} # a -> ${USUARIO}"
		return 0
	else
		msg_error "[ERROR] quitando acceso a ${TIPO_MV} ** ${ID_MV} ** con rol # ${ROL} # a -> ${USUARIO}"
		return 1
	fi
}

#comprueba si un ID es un CT (lxc) o una MV (qemu)
comprobar_tipo_MV(){
	# formas de comprobar tipo de mv de un ID
	# pvesh get /cluster/resources --type vm --noborder
	# pct list | grep -w ${ID_MV}
	# qm list | grep -w ${ID_MV}
	# las opciones anteriores son lentas. Mejor usar las siguientes que trabajan sobre el sistema de ficheros y es mas rapido
	# cat /etc/pve/.vmlist | grep lxc | grep  ID
	# ls /etc/pve/lxc | grep 10353
	# ls /etc/pve/qemu-server | grep 10353

	local ID_MV=$1
	
	#if pct list | grep -w ${ID_MV} &> /dev/null
	if ls /etc/pve/lxc | grep -w ${ID_MV} &> /dev/null
	then
		echo "CT"
	#elif qm list | grep -w ${ID_MV} &> /dev/null
	elif ls /etc/pve/qemu-server | grep -w ${ID_MV} &> /dev/null
	then
		echo "MV"
	else
		echo "ERROR"
	fi
}

iniciar_MVs(){
	
	msg_info "--> Iniciando la máquina ** ${ID_MV} **"

	TIPO_MV=$(comprobar_tipo_MV ${ID_MV})
	
	if [[ ${TIPO_MV} = "CT" ]]; then
		CMD="pct"
	elif [[ ${TIPO_MV} = "MV" ]]; then
		CMD="qm"
	else
		#no existe la MV/CT
		msg_error "[ERROR] No se ha detectado el tipo de MV/CT a usar."
		#return 2	
	fi

	if ${CMD} start $ID_MV &>>${LOG}
	then
		msg_ok "Iniciado ${TIPO_MV} con ID ** ${ID_MV} **"
		#return 0
	else
		msg_error "[ERROR] iniciando ${TIPO_MV} con ID ** ${ID_MV} **"
		#return 1
	fi
}

parar_MVs(){
	msg_info "--> Apagando la máquina ** ${ID_MV} **"

	TIPO_MV=$(comprobar_tipo_MV ${ID_MV})
	
	if [[ ${TIPO_MV} = "CT" ]]; then
		CMD="pct"
	elif [[ ${TIPO_MV} = "MV" ]]; then
		CMD="qm"
	else
		#no existe la MV/CT
		msg_error "[ERROR] No se ha detectado el tipo de MV/CT a usar."
		return 2	
	fi

	if ${CMD} shutdown ${ID_MV} &>>${LOG}
	then
		msg_ok "Apagado ${TIPO_MV} con ID ** ${ID_MV} **"
		return 0
	else
		msg_error "[ERROR] apagando ${TIPO_MV} con ID ** ${ID_MV} **"
		return 1
	fi
}

#comprueba si la primera MV/CT clonada está en el POOL seleccionado al iniciar el script
comprobar_Pool_MV(){
	#pvesh get /pools/DWECL --output-format json-pretty | grep "vmid" | grep 10011
	if pvesh get /pools/${MI_POOL} --output-format json-pretty | grep "vmid" | grep ${ID_MV_INICIAL} &>> ${LOG}
	then
		return 0
	else 
		return 1
	fi
}

#comprueba si la ZONA a eliminar coincide con el POOL seleccionado al iniciar el script
comprobar_Pool_SDN(){
	if [[ "${MI_POOL}" = "${POOL}" ]]
	then
		return 0
	else 
		return 1
	fi
}

eliminar_MVs(){
	msg_info "--> 1. Apagando la máquina ** ${ID_MV} **"

	TIPO_MV=$(comprobar_tipo_MV ${ID_MV})
	
	if [[ ${TIPO_MV} = "CT" ]]; then
		CMD="pct"
		if  pct status ${ID_MV} | grep stopped &>>${LOG}
		then
			msg_ok "${TIPO_MV} apagada con ID ** ${ID_MV} **"
		else
			if pct stop ${ID_MV} &>>${LOG}
			then
				msg_ok "${TIPO_MV} apagada con ID ** ${ID_MV} **"
			else
				msg_error "${TIPO_MV} NO se ha podido apagar con ID ** ${ID_MV} **"
			fi
		fi
		
	elif [[ ${TIPO_MV} = "MV" ]]; then
		CMD="qm"
		if qm stop ${ID_MV} --timeout 2 &>>${LOG}
		then
			msg_ok "${TIPO_MV} apagada con ID ** ${ID_MV} **"
		else
			msg_error "${TIPO_MV} NO se ha podido apagar con ID ** ${ID_MV} **"
		fi
	else
		#no existe la MV/CT
		msg_error "[ERROR] No se ha detectado el tipo de MV/CT a usar."
		return 2	
	fi

	if [ $? -eq 0 ]
	then
		msg_info "--> 2. Eliminando la máquina ** ${ID_MV} **"
		#if qm destroy ${ID_MV} --purge --destroy-unreferenced-disks=1 --skiplock=1 &>>${LOG}
		if ${CMD} destroy ${ID_MV} --purge --destroy-unreferenced-disks=1 &>>${LOG}
		then
			msg_ok "Eliminado ${TIPO_MV} con ID ** ${ID_MV} **"
			return 0
		else
			msg_error "[ERROR] al eliminar ${TIPO_MV} con ID ** ${ID_MV} **"
			return 1
		fi
	else
		msg_error "[ERROR] al parar ${TIPO_MV} con ID ** ${ID_MV} **"
		return 1
	fi
}

confirmar_eliminarMV(){
	echo
	msg_error "Se va a **DESTRUIR** todas las MVs configuradas"
	echo
	read -p "    ¿Estas seguro de querer BORRARLAS? (si / no) " RESP
	if [[ $RESP = "si" ]]; then
		echo
		acciones_MVs
	else
		echo
		echo "OPERACION ABORTADA"
	fi
}

confirmar_eliminar_SDN_ZonaxPool(){ 
	clear
	echo
	msg_error "Se va ELIMINAR una ZONA completa para cada alumno con nombre ** ${POOL} **"
	echo
	read -p "    ¿Estas seguro de querer BORRARLAS? (si / no) " RESP
	if [[ $RESP = "si" ]]; then
		eliminar_SDN_ZonaxPool
	else
		echo
		echo "OPERACION ABORTADA"
	fi
}

existe_SDN_ZonaxPOOL(){
	msg_info "Comprobando si existe la zona del POOL * ${POOL} *"
	
	if pvesh get cluster/sdn/zones/${POOL} &>>${LOG}
	then
#		msg_ok "Quitado acceso a ${TIPO_MV} ** ${ID_MV} ** con rol # ${ROL} # a -> ${USUARIO}"
		return 0
	else
#		msg_error "[ERROR] quitando acceso a ${TIPO_MV} ** ${ID_MV} ** con rol # ${ROL} # a -> ${USUARIO}"
		return 1
	fi
}


existe_SDN_ZonaxAlumno(){
	msg_info "Comprobando si existe la zona del alumno *${ZONA_NAME}01*"
	
	if pvesh get cluster/sdn/zones/${ZONA_NAME}01 &>>${LOG}
	then
#		msg_ok "Quitado acceso a ${TIPO_MV} ** ${ID_MV} ** con rol # ${ROL} # a -> ${USUARIO}"
		return 0
	else
#		msg_error "[ERROR] quitando acceso a ${TIPO_MV} ** ${ID_MV} ** con rol # ${ROL} # a -> ${USUARIO}"
		return 1
	fi
}


#Funcion que crea redes SDN para cada alumno
#Crea y usa zona del POOL y 1 vnet x alumno
crear_SDN_ZonaxPool(){
	clear
	cabecera_accion "Creando SDN por POOL"
#	echo "*****************************" | tee -a ${LOG}
#	echo "     Creando SDN por POOL    " | tee -a ${LOG}
#	echo "*****************************" | tee -a ${LOG}
#	echo
		
	local CONT_ALUMNOS=1
	#var para asignar una subred distinta a cada usuario
	#local CONT=1
	local NUM=""
	#var para saber si tengo que guardar los cambios o no
	local SAVE_SDN=1

	#creamos 1 zona para cada alumno - max 8 caracteres en nombre de la zona
	msg_info "Creando ZONA ** ${POOL} **"
	if pvesh create cluster/sdn/zones --type simple --zone ${POOL} --ipam pve --dhcp dnsmasq &>>${LOG}
	then
		msg_ok "Creada ZONA ** ${POOL} **"
		SAVE_SDN=0
	else
		msg_error "[ERROR] al crear ZONA ** ${POOL} **"
	fi

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

		# creamos X vnets para cada alumno (Ej: gestion y cluster) - max 8 caracteres en nombre de la vnet
		# creamos subnet para cada alumno en cada vnet
		for INDEX in "${!VNET_NAMES[@]}"; do
		    #echo "Índice: $INDEX, Valor: ${VNET_NAMES[$INDEX]}"

			msg_info "creando VNET ${VNET_NAMES[$INDEX]}${NUM} para alumno ** ${NOMBREMV} ** "
			if pvesh create cluster/sdn/vnets --vnet ${VNET_NAMES[$INDEX]}${NUM} --zone ${POOL} &>>${LOG}
			then
				msg_ok "Creada VNET ** ${VNET_NAMES[$INDEX]}${NUM} ** para alumno ** ${NOMBREMV} ** "
				SAVE_SDN=0
			else
				msg_error "[ERROR] al crear VNET ** ${VNET_NAMES[$INDEX]}${NUM} ** para alumno ** ${NOMBREMV} ** "
			fi
			
			#creando subnet			
			SUBNET_ALU=$(echo "${SUBNETS[$INDEX]}" | sed "s/X/${CONT_ALUMNOS}/")
			GATEWAY_ALU=$(echo "${GATEWAYS[$INDEX]}" | sed "s/X/${CONT_ALUMNOS}/")
			DHCP_RANGE_START_ALU=$(echo "${DHCP_RANGE_START[$INDEX]}" | sed "s/X/${CONT_ALUMNOS}/")
			DHCP_RANGE_END_ALU=$(echo "${DHCP_RANGE_END[$INDEX]}" | sed "s/X/${CONT_ALUMNOS}/")
			
			msg_info "creando SUBNET ${SUBNET_ALU}"
			#pvesh create /cluster/sdn/vnets/vnet01/subnets --subnet 192.168.0.0/24 --type subnet --gateway 192.168.0.1 --snat true --dhcp-range start-address=192.168.0.100,end-address=192.168.0.200
			#pvesh usage cluster/sdn/vnets/ges01/subnets -v
			if pvesh create cluster/sdn/vnets/${VNET_NAMES[$INDEX]}${NUM}/subnets/ --subnet ${SUBNET_ALU} --type subnet --gateway ${GATEWAY_ALU} --snat ${SNAT} --dhcp-range start-address=${DHCP_RANGE_START_ALU},end-address=${DHCP_RANGE_END_ALU} &>>${LOG}
			then
				msg_ok "Creada SUBNET ** ${SUBNET_ALU}** con GATEWAY ** ${GATEWAY_ALU} ** "
				SAVE_SDN=0
			else
				msg_error "[ERROR] al crear SUBNET ** ${SUBNET_ALU} ** con GATEWAY ** ${GATEWAY_ALU} ** "
			fi

		done
		echo "------------------------------------"
		let CONT_ALUMNOS++
		#let CONT++
	done < $USUARIOS

	#Aplicamos los cambios si hay algún cambio sin error
	if [ ${SAVE_SDN} -eq 0 ]; then
		msg_info " Aplicando cambios en SDN..."
		if pvesh set cluster/sdn &>>${LOG}
		then
			msg_ok "SDN actualizado satisfactoriamente."
		else
			msg_error "[ERROR] al actualizar la SDN"
		fi
	fi
}


#Funcion que crea redes SDN para cada alumno
#Crea 1 zona y 1 vnet x alumno
#no usada de momento
crear_SDN_ZonaxAlumno(){
	clear
	echo "*****************************" | tee -a ${LOG}
	echo "         Creando SDN" | tee -a ${LOG}
	echo "*****************************" | tee -a ${LOG}
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

eliminar_SDN_ZonaxPool(){
	clear
	cabecera_accion "Borrando SDN"
	
	local CONT_ALUMNOS=1
	local NUM=""
	#var para saber si tengo que guardar los cambios o no
	local SAVE_SDN=1

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

		for INDEX in "${!VNET_NAMES[@]}"; do
			# Borramos la subnet para cada alumno en cada vnet
			SUBNET_ALU=$(echo "${SUBNETS[$INDEX]}" | sed "s/X/${CONT_ALUMNOS}/")

			msg_info "Eliminando Subnet ${SUBNET_ALU} de la VNET ${VNET_NAMES[${INDEX}]}${NUM}"
			
			# Tenemos que sustituir la subred 192.168.0.0/24 por 192.168.0.0-24 para poder borrarla
			#pvesh delete cluster/sdn/vnets/clus01/subnets/alu01-192.168.101.0-24
			SUBNET_GUION="${SUBNET_ALU//\//-}"
			if pvesh delete cluster/sdn/vnets/${VNET_NAMES[$INDEX]}${NUM}/subnets/${POOL}-${SUBNET_GUION} &>>${LOG}
			then
				msg_ok "Subnet eliminada ** ${SUBNET_ALU} **"
				SAVE_SDN=0
			else
				msg_error "[ERROR] al eliminar la subnet ** ${SUBNET_ALU} **"
			fi

			msg_info "Eliminando VNET ${VNET_NAMES[${INDEX}]}${NUM}"
			#Borramos las vnets para cada alumno (gestion y cluster) - max 8 caracteres en nombre de la vnet
			#pvesh delete cluster/sdn/vnets/clus01
			if pvesh delete cluster/sdn/vnets/${VNET_NAMES[${INDEX}]}${NUM} &>>${LOG}
			then
				msg_ok "Eliminada VNET ** ${VNET_NAMES[${INDEX}]}${NUM} **"
				SAVE_SDN=0
			else
				msg_error "[ERROR] al eliminar VNET ** ${VNET_NAMES[${INDEX}]}${NUM} **"
			fi
		done

		echo "------------------------------------"
		let CONT_ALUMNOS++		
	done < $USUARIOS
	
	#Borramos la zona para cada alumno - max 8 caracteres en nombre de la zona
	#pvesh delete /cluster/sdn/zones/alu01
	msg_info "Eliminando ZONA ** ${POOL} **"
	if pvesh delete cluster/sdn/zones/${POOL} &>>${LOG}
	then
		msg_ok "Eliminada ZONA ** ${POOL} **"
	else
		msg_error "[ERROR] al eliminar ZONA ** ${POOL} **"
	fi

	#Aplicamos los cambios si hay algún cambio sin error
	if [ ${SAVE_SDN} -eq 0 ]; then
		#Aplicamos los cambios
		msg_info " Aplicando cambios en SDN..."
		if pvesh set cluster/sdn &>>${LOG}
		then
			msg_ok "SDN actualizado satisfactoriamente."
		else
			msg_error "[ERROR] al actualizar la SDN"
		fi
	fi
}

#no usada de momento
eliminar_SDN_ZonaxAlumno(){
	clear
	echo "*****************************" | tee -a ${LOG}
	echo "         Borrando SDN" | tee -a ${LOG}
	echo "*****************************" | tee -a ${LOG}
	echo
		
	local CONT_ALUMNOS=1
	local NUM=""

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

		for INDEX in "${!VNET_NAMES[@]}"; do
			# Borramos la subnet para cada alumno en cada vnet
			
			msg_info "Eliminando Subnet ${SUBNETS[${INDEX}]} de la VNET ${VNET_NAMES[${INDEX}]}${NUM}"
			
			# Tenemos que sustituir la subred 192.168.0.0/24 por 192.168.0.0-24 para poder borrarla
			#pvesh delete cluster/sdn/vnets/clus01/subnets/alu01-192.168.101.0-24
			SUBNET_GUION="${SUBNETS[$INDEX]//\//-}"
			if pvesh delete cluster/sdn/vnets/${VNET_NAMES[$INDEX]}${NUM}/subnets/${ZONA_NAME}${NUM}-${SUBNET_GUION} &>>${LOG}
			then
				msg_ok "Subnet eliminada ** ${SUBNETS[${INDEX}]} **"
			else
				msg_error "[ERROR] al eliminar la subnet ** ${SUBNETS[${INDEX}]} **"
			fi

			msg_info "Eliminando VNET ${VNET_NAMES[${INDEX}]}${NUM}"
			#Borramos las vnets para cada alumno (gestion y cluster) - max 8 caracteres en nombre de la vnet
			#pvesh delete cluster/sdn/vnets/clus01
			if pvesh delete cluster/sdn/vnets/${VNET_NAMES[${INDEX}]}${NUM} &>>${LOG}
			then
				msg_ok "Eliminada VNET ** ${VNET_NAMES[${INDEX}]}${NUM} **"
			else
				msg_error "[ERROR] al eliminar VNET ** ${VNET_NAMES[${INDEX}]}${NUM} **"
			fi
		done

		#Borramos la zona para cada alumno - max 8 caracteres en nombre de la zona
		#pvesh delete /cluster/sdn/zones/alu01
		msg_info "Eliminando ZONA ** ${ZONA_NAME}${NUM} **"
		if pvesh delete cluster/sdn/zones/${ZONA_NAME}${NUM} &>>${LOG}
		then
			msg_ok "Eliminada ZONA ** ${ZONA_NAME}${NUM} **"
		else
			msg_error "[ERROR] al eliminar ZONA ** ${ZONA_NAME}${NUM} **"
		fi
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


config_parametros(){
	clear
	echo "Modifica los parámetros deseados. Si se deja vacío se queda la opción actual que sale entre paréntesis:"
	echo "-------------------------------------------------------------------------------------------------------"
	echo -ne "- Indica Fichero con el listado de alumnos (${GN}${USUARIOS}${CL}) --> "
	read  DATO

	USUARIOS=${DATO:-$USUARIOS}

	echo -ne "- Indica POOL (${GN}${POOL}${CL}) --> " 
	read DATO
	POOL=${DATO:-$POOL}

	echo -ne "- Indica ROL del usuario (${GN}${ROL}${CL}) --> "
	read DATO
	ROL=${DATO:-$ROL}
		
	echo -ne "- Indica ID de la MV a clonar (${GN}${IDs_MVs_CLONAR[*]}${CL}) --> " 
	read -r -a DATO
	if [ ${#DATO[@]} -ge 1 ]; then
		IDs_MVs_CLONAR=("${DATO[@]}")
	fi

	echo -ne "- Indica ID de la 1ª MV clonada (${GN}${ID_MV_INICIAL}${CL}) --> " 
	read DATO
	ID_MV_INICIAL=${DATO:-$ID_MV_INICIAL}

	echo -ne "- Indica TAGs para la MV (${GN}${TAG}${CL}) --> " 
	read DATO
	TAG=${DATO:-$TAG}

	echo -ne "- Indica Nombre de la MV (${GN}${NOMBRES_MVs[*]}${CL}) --> "
	read -r -a DATO
	if [ ${#DATO[@]} -ge 1 ]; then
		NOMBRES_MVs=("${DATO[@]}")
	fi


	clear
	echo "                RESUMEN"
	echo "------------------------------------------"
	mostrar_parametros
}

mostrar_parametros(){
	clear
	echo "----------------------------------------------------"
	echo "               PARAMETROS ACTUALES"
	echo "----------------------------------------------------"
	echo -e "- Fichero de usuarios -> ${GN} ${USUARIOS} ${CL}"
	echo -e "- POOL -> ${GN} ${POOL} ${CL}"
	echo -e "- ROL -> ${GN} ${ROL} ${CL}"
	echo -e "- IDs MVs a clonar -> ${GN} ${IDs_MVs_CLONAR[*]} ${CL}"
	echo -e "- ID 1ª MV clonada -> ${GN} ${ID_MV_INICIAL} ${CL}"
	echo -e "- TAGs -> ${GN} ${TAG} ${CL}"
	echo -e "- Nombres MV -> ${GN} ${NOMBRES_MVs[*]} ${CL}"
}

pulsa_enter(){
	echo; echo "Pulsa enter para volver al menú"
	read
}

mostrar_menu(){

	while true; do
		clear
		echo
		echo "       M E N U   P R I N C I P A L  (v.${VERSION})"
		echo "-------------------------------------------------"
		echo -e "         ${GN}${POOL}: ${TAG}${CL}"
		echo "-------------------------------------------------"
		echo
		echo "  1.- Clonar MVs y asignar alumnos a las máquinas"
		echo "  2.- Clonar MVs SIN asignar alumnos a las máquinas"
		echo "  3.- Asignar alumnos a MVs creadas previamente"
		echo "  4.- Quitar acceso a alumnos"
		echo "  5.- Iniciar MVs"
		echo "  6.- Parar MVs"
		echo "  7.- Crear Red SDN con zona POOL y 1 VNET por alumno y asignarla a las MVs"
		echo "  8.- Eliminar Red SDN con zona POOL y 1 VNET por alumno"		
		echo "  9.- Eliminar MVs"
		echo
		echo "  a.- Consultar parametros y variables a usar."
		echo "  b.- Modificar parámetros y variables"
		echo "  x.- Solo para pruebas de opciones y comandos"
		echo 
		echo "  S.- Salir."
		echo
		read -r -p "  Elija una opcion --> " MODO
		echo
		clear
		
		case ${MODO} in
			[Ss])
				exit
				;;
			"a")
				mostrar_parametros
				pulsa_enter
				;;
			"x")
				cabecera_accion "Pruebas"
				acciones_MVs
				pulsa_enter
				;;
			[1,2])
				cabecera_accion "Clonación de MVs"
				acciones_MVs
				pulsa_enter
				;;

			3)
				cabecera_accion "Asignar usuarios a MVs"				
				acciones_MVs
				pulsa_enter
				;;
			4)
				cabecera_accion "Quitar acceso a MVs"
				acciones_MVs
				pulsa_enter
				;;

			5)
				cabecera_accion " Iniciar MVs"
				acciones_MVs
				pulsa_enter
				;;
			6)
				cabecera_accion " Parar MVs"
				acciones_MVs
				pulsa_enter
				;;

			7)
				crear_SDN_ZonaxPool
				acciones_MVs
				pulsa_enter
				;;
			8)
				if ! comprobar_Pool_SDN
				then
					echo
					msg_error "La ZONA a eliminar no coincide con el POOL seleccionado al iniciar el script."
					msg_icono "${SEARCH}" "Verifica que ha seleccionado el POOL correcto al iniciar el script."
				else
					acciones_MVs
					confirmar_eliminar_SDN_ZonaxPool
				fi
				pulsa_enter
				;;

			9)
				cabecera_accion "Eliminar MVs"
				if ! comprobar_Pool_MV
				then
					echo
					msg_error "Las MVs/CTs a eliminar no pertenecen al POOL seleccionado al iniciar el script."
					msg_icono "${SEARCH}" "Verifica que ha seleccionado el POOL correcto al iniciar el script."
				else
					confirmar_eliminarMV
				fi
				pulsa_enter
				;;
			"b")
				config_parametros
				pulsa_enter
				;;
			*)
				echo
				msg_error "Opción no válida. Espere por favor..."
				sleep 2s			
				;;
		esac
	done
}

cabecera_accion(){
	local msg="$1"
	clear
	echo "**********************************" | tee -a ${LOG}
	echo "         ${msg}" | tee -a ${LOG}
	echo "**********************************" | tee -a ${LOG}
	echo	
}


acciones_MVs(){

#	echo "*****************************" | tee -a ${LOG}
#	echo "         MODO: ${MODO}" | tee -a ${LOG}
#	echo "*****************************" | tee -a ${LOG}
#	echo
	
	ID_MV=${ID_MV_INICIAL}
	CONT=0
	#NUM_MVs_CLONAR=${#IDs_MVs_CLONAR[@]}
	
	#bucle para ejecutar acciones sobre cada máquina clonada
	for ID_MV_CLONAR in "${IDs_MVs_CLONAR[@]}"; do
		NOMBREPC=${NOMBRES_MVs[$CONT]}
		NOTAS_MV=${NOTAS_MVs[$CONT]}
		CONT_ALUMNOS=1
		#este bucle hace las acciones necesarias para cada usuario del fichero indicado
		#Formato fichero usuarios: <usuario proxmox incluyendo ambito>:<nombre para MV>
		while IFS=: read -r USUARIO NOMBREMV
		do
			#nos saltamos lineas comentadas
			if [[ "${USUARIO:0:1}" = "#" ]]; then
				#let ID_MV++
				continue
			fi
			#Para Modo 7 
			if [ ${CONT_ALUMNOS} -lt 10 ]; then
				NUM_ZONA="0${CONT_ALUMNOS}"
			else
				NUM_ZONA="${CONT_ALUMNOS}"
			fi			
			
			HOSTNAME="${NOMBREPC}-${NOMBREMV}"
			case ${MODO} in
				"x")
					echo "Modo Prueba..."
					qm set ${ID_MV} --description "${NOTAS_MV}" 
					;;
				1)
					if clonar
					then
						if configurar
						then
							asignar
						fi
					fi
					echo ""
					;;
				2)
					if clonar
					then
						configurar
					fi
					echo ""
					;;
				3)
					asignar
					;;
				4)
					quitar_acceso
					;;
				5)
					iniciar_MVs
					;;
				6)
					parar_MVs
					;;
				7)
					asignar_SDN_MVs ${NUM_ZONA}
					;;
				8)
					quitar_SDN_MVs
					;;
				9)
					eliminar_MVs
					;;
			esac
			
			let ID_MV++
			let CONT_ALUMNOS++
		done < ${USUARIOS}

		let CONT+=1
	done
}

obtener_pools(){
	#pvesh get /pools --noborder  --> listado de pools
	#obtener listado de pools: cat /etc/pve/user.cfg | grep pool: | cut -d ":" -f2
	#pvesh get /pools/DWECL --output-format json-pretty | grep "vmid" | grep 10011   saber un in ID pertenece a un POOL en concreto
	#comprobar si existe un pool: cat /etc/pve/user.cfg | grep pool:DWECs

	#obtenemos listado de pools
	cat /etc/pve/user.cfg | grep pool: | cut -d ":" -f2

}

comprobar_ficheros_conf() {
	#Definimos fichero ubicación LOG
	LOG="${MI_POOL}/${LOG}"
	echo "" > ${LOG}

	#Comprobamos fichero .conf
	if [ -r "${MI_POOL}/0.Operaciones_Exam_Menu.conf" ]; then
		# shellcheck source=/dev/null
		source "./${MI_POOL}/${FILE_CONF}"
	else
		clear
		echo
		msg_error " El fichero de configuración no existe en '.${MI_POOL}/${FILE_CONF}'"
		echo
		msg_ok "Sintasis comando: $0 POOL" 
		echo
		exit 10
	fi

	#Comprobamos fichero con alumnos
	if ! [ -r "${USUARIOS}" ]; then
		clear
		echo
		msg_error " El fichero de USUARIOS no existe en '${USUARIOS}'"
		msg_error " Debes tener un fichero con el listado de usuarios a usar con el formato correcto."
		echo
		exit 10
	fi

}

mostrar_ayuda() {
cat << DESCRIPCION_AYUDA
SINTAXIS
    $0 POOL

	IMPORTANTE: El nombre del POOL debe coincidir con el nombre de una subcarpeta
	
	Ejemplo: $0 DWEC
	
DESCRIPCIÓN
    Permite realizar unas series de operaciones sobre el servidor Proxmox
    necesarias para preparar un entorno de MVs/CTs para exámenes o prácticas

CÓDIGOS DE RETORNO
    0 - no hay ningún error.
    1 - script no ejecutado como usuario root o administrador
    2 - no se usa la shell Bash
    10 - El fichero de configuración no se ha encontrado en la ruta esperada
    
DESCRIPCION_AYUDA
}

parametros_script(){
	#seleccion_fich_config
	#Fichero que contiene las variables a modificar para cada examen
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
		msg_aviso "Debes indicar con que POOL quieres trabajar. Solo podrás modificar y eliminar MVs del POOL que indiques."
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
formato_mensajes
parametros_script $1
comprobar_ficheros_conf
mostrar_menu
