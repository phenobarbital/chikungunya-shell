### Debian-based functions

is_debian() 
{
	if [ -f /etc/debian_version ]; then
		# is a Debian-based distribution
		#deb_based=true
		return 0
	else
		#deb_based=false
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


####################
#
# Packages and applications (distribution-based)
#
###########


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
# Network-related functions
#
###########


get_hostname()
{
    local  __resultvar=$1
    local  hostname=`hostname --short`
    if [ "$__resultvar" ]; then
        eval $__resultvar="'$hostname'"
    else
        echo "$hostname"
    fi
}

get_domain()
{
    local  __resultvar=$1
    local  domainname=`hostname -d`
    if [ "$__resultvar" ]; then
        eval $__resultvar="'$domainname'"
    else
        echo "$domainname"
    fi
}



ifdev() {
IF=`cat /proc/net/dev | grep ':' | cut -d ':' -f 1 | tr '\n' ' '`
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
	LAN_INTERFACE=`echo $IF | awk '{print $2}'`
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
# must be rewriten 'cause is bash dependent
#get_network() {
#	IFS= read -r i1 i2 i3 i4 <<< "$1"
#	IFS= read -r m1 m2 m3 m4 <<< "$2"
#	printf "%d.%d.%d.%d\n" "$((i1 & m1))" "$(($i2 & m2))" "$((i3 & m3))" "$((i4 & m4))"
#}

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

