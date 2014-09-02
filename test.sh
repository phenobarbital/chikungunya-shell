#!/bin/bash
#
# Test all functions in shell framework
#
# Author:
# Jesus Lara <jesuslarag@gmail.com>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA


#
#  all common functions
#
if [ -e /usr/lib/chikungunya/basic.sh ]; then
    . /usr/lib/chikungunya/basic.sh
else
    . ./lib/basic.sh
fi

VERBOSE="true"
LOGFILE="log/test.log"

message "Este es un mensaje de prueba"
echo "-"
info "Este mensaje es de información"
echo "-"
warning "Esta es una advertencia"
echo "-"
debug "Esta es una información de depuración"
echo "-"
error "Este es un mensaje de error"
echo "-"

install_package "apache-22"
echo "--------"
debug "My Hostname: $(get_hostname).$(get_domain)"

testing() {
	read -d '' msg << EOF
	$*
EOF
echo "$msg"
}
echo "--------"

testing <<< "sits proudly on his throne in localhost."

# _die "error message"

_dirname "/home/jesuslara/Proyectos/chikungunya/LICENSE"

if [ ! has_internet ]; then
	warning "No hay internet"
else
	info "Si hay Internet"
fi

if [ -z $(dir_exists "/etc/xen") ]; then
	warning "Directorio no existe"
else
	info "Si existe el directorio /etc/xen"	
fi

if [ $(get_domain) = 'devel.local' ]; then
	info "Si, es un dominio"
fi


_xmessage "Notice ..."
