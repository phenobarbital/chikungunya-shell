#!/bin/sh
#
# Common shell functions and messages
#

# Copyright 2014 Alberto Mijares & Jesus Lara. All rights reserved.

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:

# Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.  Redistributions
# in binary form must reproduce the above copyright notice, this list of
# conditions and the following disclaimer in the documentation and/or
# other materials provided with the distribution.

# THIS SOFTWARE IS PROVIDED BY Alberto Mijares and Jesus Lara ``AS
# IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL Alberto
# Mijares, Jesus Lara OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
# OF THE POSSIBILITY OF SUCH DAMAGE.

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

# define colors
NORMAL='\033[0m'
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
BLUE='\033[1;34m'

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


get_password() {
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
		if [ "$__resultvar" ]; then
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
			. $configfile
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
		line=`sed 's/\"/\\\"/g' ${file}`
		line=`echo ${line} | sed 's/\`/\\\`/g'`
		line=`echo ${line} | sed 's/\$/\\\$/g'`
		line=`echo ${line} | sed 's/\\\${/\${/g'`
		eval "echo \"$line\"";
		return 0
	else
		return 1
	fi
}

case `uname` in

    Linux)

	. ./lib/linux_functions.sh
	;;

    {Free|Open}BSD)

	. ./lib/bsd_functions.sh
	;;

    Windows)

	echo "Are you kidding me???"
	exit 1
	;;

esac
