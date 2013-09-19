#!/bin/bash

function __vgrnt_error()
{
	echo -e " >> \033[31;22m$@\033[0m"
}

function __vgrnt_ok()
{
	echo -e " >> \033[32;22m$@\033[0m"
}

function __vgrnt_create()
{
	local box="$1"
	local url="$2"
	local ip="$3"
	local loc="${VGRNT_DIR}/${box}"
	local loc_data="${VGRNT_DATA_DIR}/${box}"

	if [ -d "${loc}" ]
	then
		__vgrnt_error "Already exists ${box}"
	else
		mkdir -p "${loc}/" "${loc_data}/"
		cat > "${loc}/Vagrantfile" << EOF
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "${box}"
  config.vm.box_url = "${url}"
  config.vm.network :private_network, ip: "${ip}"
  config.vm.synced_folder "${VGRNT_DATA_DIR}", "/vagrant_data"
end

EOF

		vagrant box add "${box}" "${url}"
		__vgrnt_ok "Ready to use"
	fi
}

function __vgrnt_destroy()
{
	local OLD=${PWD}
	local box="$1"
	local loc="${VGRNT_DIR}/${box}"

	# check box!!!!111

	if [ -d "${loc}" ]
	then
		vagrant box remove "${box}" && rm -fr "${loc}"
		__vgrnt_ok "Destroyed"
	else
		__vgrnt_error "Not exists"
	fi
}

function __vgrnt_up()
{
	local OLD=${PWD}
	local box="$1"
	local loc="${VGRNT_DIR}/${box}"

	if [ -d "${loc}" ]
	then
		__vgrnt_ok "Entring to ${loc}"
		cd "${loc}" 
		vagrant up 
		cd "${OLD}"
		__vgrnt_ok "Up"
	else
		__vgrnt_error "Not exists"
	fi
}

function __vgrnt_halt()
{
	local OLD=${PWD}
	local box="$1"
	local loc="${VGRNT_DIR}/${box}"

	if [ -d "${loc}" ]
	then
		__vgrnt_ok "Entring to ${loc}"
		cd "${loc}" 
		vagrant halt 
		cd "${OLD}"
	else
		__vgrnt_error "Not exists"
	fi
}

function __vgrnt_ssh()
{
	local OLD=${PWD}
	local box="$1"
	local loc="${VGRNT_DIR}/${box}"

	if [ -d "${loc}" ]
	then
		__vgrnt_ok "Entring to ${loc}"
		cd "${loc}" 
		vagrant ssh
		cd "${OLD}"
	else
		__vgrnt_error "Not exists"
	fi
}


function vgrnt() 
{
	if [ -z "${VGRNT_DIR}" ]
	then
		export VGRNT_DIR="${HOME}/vagrant"
		export VGRNT_DATA_DIR="${HOME}/vagrant_data"
	fi

	if [ ! -d "${VGRNT_DIR}" ]
	then
		mkdir -p "${VGRNT_DIR}"
	fi

	if [ ! -d "${VGRNT_DATA_DIR}" ]
	then
		mkdir -p "${VGRNT_DATA_DIR}"
	fi

	local command="${1}"
	local name="${2}"

	if [ ! "${command}" = "ls" ] 
	then
		if [ $# -ge 2 ] && [[ "${name}" =~ ^[a-zA-Z0-9._-]+$ ]]
		then
			echo -n
		else
			__vgrnt_error "Invalid arguments ${name}"
			command="help"
		fi
	fi

	case "${command}" in 
		create)
			if [ $# -eq 4 ]
			then
				__vgrnt_create "${name}" "$3" "$4"
			else
				__vgrnt_error "Usage: $0 create <name> <url> <ip>"
			fi
			;;
		destroy)
			if [ $# -eq 2 ]
			then
				__vgrnt_destroy "${name}"
			else
				__vgrnt_error "Usage: $0 destroy <name>"
			fi
			;;
		up)
			if [ $# -eq 2 ] 
			then
				__vgrnt_up "${name}"
			else
				__vgrnt_error "Usage: $0 up <name>"
			fi
			;;
		halt)
			if [ $# -eq 2 ] 
			then
				__vgrnt_halt "${name}"
			else
				__vgrnt_error "Usage: $0 halt <name>"
			fi
			;;
		ssh)
			if [ $# -eq 2 ] 
			then
				__vgrnt_ssh "${name}"
			else
				__vgrnt_error "Usage: $0 ssh <name>"
			fi
			;;
		ls)
			for v in ${VGRNT_DIR}/*/Vagrantfile
			do
				echo -en "$(sed -n 's/^.*config.vm.box = "\([^"]*\)".*$/\1/p' ${v})\t"
				echo -en "$(sed -n 's/^.*config.vm.network :private_network, ip: "\([^"]*\)".*$/\1/p' ${v})\t"
				echo -en "$(sed -n 's/^.*config.vm.box_url = "\([^"]*\)".*$/\1/p' ${v})\t"
				echo 
			done | column -c 3 -s '\t'
			;;
		*)
			echo "vgrnt [create <name> <url> <ip>]"
			echo "      [destroy <name>]"
			echo "      [up <name>]"
			echo "      [halt <name>]"
			echo "      [ssh <name>]"
			echo "      [ls]"
			;;
	esac
}

function __vgrnt_cmpl()
{
	local cur prev opts
	local vs="$(vgrnt ls | cut -f1)"
	COMPREPLY=()
	cur="${COMP_WORDS[COMP_CWORD]}"
	prev="${COMP_WORDS[COMP_CWORD-1]}"
	opts="create destroy up halt ssh ls"

	case "${prev}" in
		create | destroy | up | halt | ssh)
			COMPREPLY=( $(compgen -W "${vs}" -- ${cur}) );;
		*)
			COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) );;
	esac
}

complete -F __vgrnt_cmpl vgrnt
