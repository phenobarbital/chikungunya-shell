#!/bin/bash
#
# Common shell functions and messages
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

# library version
VERSION='0.1'

get_version() 
{
	scriptname=$(basename $0)
	echo "$scriptname version $VERSION";
}

##############
#
# Console Messages
#
##

# export colors
export NORMAL='\033[0m'
export RED='\033[1;31m'
export GREEN='\033[1;32m'
export YELLOW='\033[1;33m'
export WHITE='\033[1;37m'
export BLUE='\033[1;34m'

#  If we're running verbosely show a message, otherwise swallow it.
#
message()
{
    msg="$*"
    if [ "$VERBOSE" == "true" ]; then
      echo -e $msg >&2;
    fi
}

#
# send a message to a LOGFILE
#
logMessage() {
  scriptname=$(basename $0)
  if [ ! -z "$LOGFILE" ]; then
	echo "`date +"%D %T"` $scriptname : $@" >> $LOGFILE
  fi
}

#
# display a green-colored message, only if global variable VERBOSE=True
#
info()
{
	message="$*"
    if [ "$VERBOSE" == "true" ]; then
		printf "$GREEN"
		printf "%s\n"  "$message" >&2;
		tput sgr0 # Reset to normal.
		echo -e `printf "$NORMAL"`
    fi
    logMessage $message
}

#
# display a yellow-colored warning message in console
#
warning()
{
	message="$*"
    if [ "$VERBOSE" == "true" ]; then
		printf "$YELLOW"
		printf "%s\n"  "$message" >&2;
		tput sgr0 # Reset to normal.
		printf "$NORMAL"
    fi
    logMessage "WARN: $message"
}

#
# display a blue-colored message
#
debug()
{
	message="$*"
    if [ -n "$VERBOSE" ] && [ "$VERBOSE" == "true" ]; then
		printf "$BLUE"
		printf "%s\n"  "$message" >&2;
		tput sgr0 # Reset to normal.
		printf "$NORMAL"
    fi
    logMessage "DEBUG: $message"
}

#
# display and error (red-colored) and return non-zero value
#
error()
{
	message="$*"
	scriptname=$(basename $0)
	printf "$RED"
	printf "%s\n"  "$scriptname: $message" >&2;
	tput sgr0 # Reset to normal.
	printf "$NORMAL"
	logMessage "ERROR:  $message"
	return 1
}

#
# Display and error and exit script
#
_die()
{
    [ -z "${1}" ] && return 1
    error "${*}" >&2
    exit 1
}

###############
# 
# Strings, Arguments and parameters
#
####

# convert a string to lower string
str2lower()
{
    [ -z "${1}" ] && return 1
    printf "%s\\n" "${@}" | tr '[:upper:]' '[:lower:]'
}

# convert a string to upper string
str2upper()
{
    [ -z "${1}" ] && return 1
    printf "%s\\n" "${@}" | tr '[:lower:]' '[:upper:]'
}

# display and error.
usage_err()
{
	error "$*"
	return 1
}

# check if a required argument is passed.
#
# Sample usage:
#       optarg_check $1 "$2"
optarg_check()
{
    if [ -z "$2" ]; then
        usage_err "option '$1' requires an argument"
    fi
}

optarg_count()
{
	if [ $# -ge 1 ]; then
		debug "at least one parameter was given"
		return 0
	fi
}

#
#  Test the given condition is true, and if not abort.
#
#  Sample usage:
#    assert "$LINENO" "${verbose}"
#
assert()
{
    lineno="?"

    if [ -n "${LINENO}" ]; then
        # our shell defines variable LINENO, great!
        lineno=$1
        shift
    fi

    if [ ! $* ] ; then
        echo "assert failed: $0:$lineno [$*]"
        exit
    fi
}

check_name()
{
	if [ ${#1} -gt 40 ] || [ ${#1} -lt 2 ]; then
		usage_err "'$1' is an invalid name"
	fi
}


function get_password() {
	if [ -n "${1}" ]; then
		local  __resultvar="$(printf "%s\\n" "${1}" | tr '[:upper:]' '[:lower:]')"
	else
		local __resultvar="passwd"
	fi
	while /bin/true; do
        echo -n "New password: "
        stty -echo
        read pass1
        stty echo
        echo
        if [ -z "$pass1" ]; then
            echo "Error, password cannot be empty"
            echo
            continue
        fi
        echo -n "Repeat new password: "
        stty -echo
        read pass2
        stty echo
        echo
        if [ "$pass1" != "$pass2" ]; then
            echo "Error, passwords don't match"
            echo
            continue
        fi
        break
	done
    if [ -n "$pass1" ]; then
		if [[ "$__resultvar" ]]; then
			eval $__resultvar="'$pass1'"
		else
			echo "$pass1"
		fi
		printf "\\n"
        return 0
    fi
    return 1
}

####################
#
# Filesystems
#
###########

file_exists()
{
	if [ -f "$@" ]; then
		return 0
	else
		error "file does not exists $*"
		return 1
	fi
}

# test if an directory exists, return 0 on sucess, 1 otherwise
# example:
#      dir_exists /etc
dir_exists()
{
	if [ -d "$@" ]; then
		return 0
	else
		error "directory does not exists $*"
		return 1
	fi
}

# test if an user exists on the system, return 0 on sucess, 1 otherwise
# example:
#      user_exists jesuslara
user_exists()
{
    [ -z "${1}" ] && return 1
    if id -u "${1}" >/dev/null 2>&1; then
        return 0
    else
		error "user $1 does not exists on this system"
        return 1
    fi
}

#
# Open a config file (The file to be sourced should be formated in key="value" format)
# Example:
#       get_config /etc/bashprime.cfg
get_config()
{
	configfile=$1
	if [ -f $configfile ]; then
		# check if the file contains something we don't want
		if egrep -q -v '^#|^[^ ]*=[^;]*' "$configfile"; then
			error "Config file is unclean or invalid"
		else
			source $configfile
		fi
	else
		error "config file ${configfile} does not exists"
		return 1
	fi
}

# return string containing dirname on success, 1 on fail
_dirname()
{
    [ -z "${1}" ] && return 1

    case "${1}" in
        /*|*/*) #http://www.linuxselfhelp.com/gnu/autoconf/html_chapter/autoconf_10.html
            _dirname_var_dir=$(expr "x${1}" : 'x\(.*\)/[^/]*' \| '.'      : '.')
            printf "%s\\n" "${_dirname_var_dir}"
            ;;
        *) printf "%s\\n" ".";;
    esac
}

####################
#
# Packages and applications (distribution-based)
#
###########

### Debian-based functions

is_debian()
{
	if [ -f "/etc/debian_version" ]; then
		# is a Debian-based distribution
		deb_based=true
		return 0
	else
		deb_based=false
		return 1
	fi
}

# return host distribution based on lsb-release
get_distribution() 
{
	if [ -z $(which lsb_release) ]; then
		error "lsb-release is required"
		return 1
	fi
	lsb_release -s -i
}

# get codename (ex: wheezy)
get_suite() 
{
	if [ -z $(which lsb_release) ]; then
		error "lsb-release is required"
		return  1
	fi
	lsb_release -s -c
}

# install a Debian package with no prompt and default options
install_deb()
{
	message "installing Debian package $@"
    #
    #  Use policy-rc to stop any daemons from starting.
    #
    printf '#!/bin/sh\nexit 101\n' > /usr/sbin/policy-rc.d
    chmod +x /usr/sbin/policy-rc.d
	#
	# Install the packages
	#
	DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get --option Dpkg::Options::="--force-overwrite" --option Dpkg::Options::="--force-confold" --yes --force-yes install "$@"
	
    #
    #  Remove the policy-rc.d script.
    #
    rm -f /usr/sbin/policy-rc.d
	
}

# remove a Debian package
remove_deb()
{
	message "removing Debian package $@"
	lsof /var/lib/dpkg/lock >/dev/null 2>&1
	if [ $? = 0 ]; then
		echo "dpkg lock in use"
		return 1
	fi
    #
    # Purge the packages
    #
    DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get remove --yes --purge "$@"
}

# test if a package exists in repository
test_debian_package()
{
	lsof /var/lib/dpkg/lock >/dev/null 2>&1
	if [ $? = 0 ]; then
		echo "dpkg lock in use"
		return 1
	fi
	debug "Testing if package $@ is available for installation"
	DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get --simulate install "$@" >/dev/null 2>&1
	if [ $? -ne 0 ]; then
		return 1
	else
		return 0
	fi
}

# test if a Debian package is already installed
is_installed()
{
	# test installation package
	debug "Test if $@ is installed"
	dpkg-query -s "$@" >/dev/null 2>&1
	if [ $? -ne 0 ]; then
		return 1
	else
		return 0
	fi
}
	
### CentOS-based functions

is_redhat()
{
	if [ -f "/etc/redhat-release" ]; then
		# its a redhat-based distribution
		rpm_based=true
		return 0
	else
		rpm_based=false
		return 1
	fi
}

is_fedora()
{
	if [ -f "/etc/fedora-release" ]; then
		# its a fedora-based distribution
		fedora_based=true
		return 0
	else
		fedora_based=false
		return 1
	fi
}

install_rpm()
{
	message "installing RPM package $@"
	#
	# Install the packages
	#
	/usr/bin/yum -y install  "$@"
}

#
#  Install a package using whatever package management tool is available
#
install_package()
{
	package=$1
	if [ is_debian ]; then
		debug "Is a Debian-based distribution"
		# install_deb "${package}"
	elif [ is_redhat] || [ is_fedora ] || [ is_centos ]; then
		debug "Is a Redhat-based distribution"
		# install_rpm "${package}"
    else
		logMessage "Unable to install package ${package}; no package manager found"
    fi
}


####################
#
# System functions
#
###########

#check for internet connection (get google.com), returns 0 on success, 1 otherwise
# example:
#     if [ ! has_internet ]; then
has_google()
{   
    wget --tries=3 --timeout=5 http://www.google.com -O /tmp/index.google > /dev/null 2>&1
    if [ -s /tmp/index.google ]; then
        rm -rf /tmp/index.google
        return 0
    else
        rm -rf /tmp/index.google
        return 1
    fi
}

# check for internet connection (public dns and name resolution), returns 0 on success, 1 otherwise
has_internet()
{
	gw=$(ip route | grep default | awk '{ print $5 }')
	if [ -z $gw  ]; then
		# check for ping through gateway
		ping -I $gw -c 3 -n -q 8.8.8.8 > /dev/null 2>&1
		if [ $? -eq 0 ]; then
			debug "Can hit to google DNS"
			host -t A -W 1 google.com > /dev/null 2>&1
			if [ $? -eq 0 ]; then
				return 0
			else
				debug "Has Internet, but no name (DNS) resolution"
				return 1
			fi
		else
			return 1
		fi
	else
		debug "system don't have a gateway interface"
		return 1
	fi
}

####################
#
# Network-related functions
#
###########

get_hostname()
{
    local  __resultvar=$1
    local  hostname=`hostname --short`
    if [[ "$__resultvar" ]]; then
        eval $__resultvar="'$hostname'"
    else
        echo "$hostname"
    fi
}

get_domain()
{
    local  __resultvar=$1
    local  domainname=`hostname -d`
    if [[ "$__resultvar" ]]; then
        eval $__resultvar="'$domainname'"
    else
        echo "$domainname"
    fi
}

ifdev() {
IF=(`cat /proc/net/dev | grep ':' | cut -d ':' -f 1 | tr '\n' ' '`)
}

# return 0 if parameter is a valid network interface, 1 otherwise
validif()
{
    [ -z "${1}" ] && return 1
    ip addr show | grep "${1}": >/dev/null && return 0
    return 1
}

# return 0 if parameter is a valid ip4 address, non-zero otherwise
# https://groups.google.com/forum/#!original/comp.unix.shell/NDu-kAL5cHs/7Zpc6Q2Hu5YJ
valid_ipv4()
{
    [ -z "${1}" ] && return 1

    case "${*}" in
        ""|*[!0-9.]*|*[!0-9]) return 1 ;;
    esac

    OLDIFS="${IFS}"
    IFS="."
    set -- ${*}
    IFS="${OLDIFS}"

    [ "${#}" -eq "4" ] &&
        [ "${1:-666}" -le "255" ] && [ "${2:-666}" -le "255" ] &&
        [ "${3:-666}" -le "255" ] && [ "${4:-666}" -le "254" ]
}

firstdev() {
	ifdev
	LAN_INTERFACE=${IF[1]}
}

# get ip from interface
get_ip() {
	# get ip info
	IP=`ip addr show $1 | grep "[\t]*inet " | head -n1 | awk '{print $2}' | cut -d'/' -f1`
	if [ -z "$IP" ]; then
		echo ''
	else
		echo $IP
	fi
}

# get default gateway from LAN
get_gateway() {
	ip route | grep "default via" | awk '{print $3}'
}

# get netmask from IP
get_netmask() {
	ifconfig $1 | sed -rn '2s/ .*:(.*)$/\1/p'
}

# get network from ip and netmask
get_network() {
	IFS=. read -r i1 i2 i3 i4 <<< "$1"
	IFS=. read -r m1 m2 m3 m4 <<< "$2"
	printf "%d.%d.%d.%d\n" "$((i1 & m1))" "$(($i2 & m2))" "$((i3 & m3))" "$((i4 & m4))"
}

# get broadcast from interface
get_broadcast() {
	# get ip info
	ip addr show $1 | grep "[\t]*inet " | head -n1 | egrep -o 'brd (.*) scope' | awk '{print $2}'
}

# get subnet octect
mask2cidr() {
    nbits=0
    IFS=.
    for dec in $1 ; do
        case $dec in
            255) let nbits+=8;;
            254) let nbits+=7;;
            252) let nbits+=6;;
            248) let nbits+=5;;
            240) let nbits+=4;;
            224) let nbits+=3;;
            192) let nbits+=2;;
            128) let nbits+=1;;
            0);;
            *) echo "Error: $dec is not recognised"; exit 1
        esac
    done
    echo "$nbits"
}

get_subnet() {
	MASK=`get_netmask`
	echo $(mask2cidr $MASK)
}

####################
#
# Basic Template system
#
###########

# expand all shell backsticks, subshell and variable environment substitution
shelltemplate()
{
	# loading a template
	file=$@
	if [ -f "$file" ]; then
	eval "cat <<EOF
$(<${file})
EOF
" 2> /dev/null
	fi
}

# replace all bash placeholders (${}) with your value without replace shell and sub-shell strings
# usage: var=$(template $filename)
# or
#var=$(cat << _MSG
#$(template $filename)
#_MSG
#)
template()
{
	file=$@
	if [ -f "$file" ]; then
	while read -r line ; do
		line=${line//\"/\\\"}
		line=${line//\`/\\\`}
		line=${line//\$/\\\$}
		line=${line//\\\${/\${}
		eval "echo \"$line\"";
	done < "${file}"
		return 0
	else
		return 1
	fi
}
