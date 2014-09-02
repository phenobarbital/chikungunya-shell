#!/bin/bash -e
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
    if [ ! -z "$VERBOSE" ]; then
      echo -e $msg >&2;
    fi
}

#
# send a message to a LOGFILE
#
logMessage() {
  scriptname=$(basename $0)
  if [ -f "$LOGFILE" ]; then
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
	if [ "$VERBOSE" == "true" ]; then
    # if [ ! -z "$VERBOSE" ] || [ "$VERBOSE" == "true" ]; then
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
	printf "%s\n"  "$scriptname $message" >&2;
	tput sgr0 # Reset to normal.
	printf "$NORMAL"
	logMessage "ERROR:  $message"
	return 1
}
