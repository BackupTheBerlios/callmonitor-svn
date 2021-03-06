##
## Callmonitor for Fritz!Box (callmonitor)
## 
## Copyright (C) 2005--2006  Andreas Bühmann <buehmann@users.berlios.de>
## 
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
## 
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
## 
## You should have received a copy of the GNU General Public License
## along with this program; if not, write to the Free Software
## Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
## 
## http://developer.berlios.de/projects/callmonitor/
##
usage() {
#<
    cat <<EOF
Usage:	$APPLET [OPTION]...
Options:
    -f		run in foreground
    -s		stop the callmonitor
    --debug     log rule matching/executed commands to syslog
		(and to stderr with -f)
    --help	show this help
EOF
#>
}

require callmonitor

## parse options
TEMP="$(getopt -o 'fs' -l debug,help -n "$APPLET" -- "$@")" || exit 1
eval "set -- $TEMP"

DEBUG=false
FOREGROUND=false
STOP=false
while true; do
    case $1 in
	-f) FOREGROUND=true ;;
	-s) STOP=true ;;
	--debug) DEBUG=true ;;
	--help) usage >&2; exit ;;
	--) shift; break ;;
	*) ;; # should never happen
    esac
    shift
done

## set up logging
__log_setup() {
    if $FOREGROUND; then
	__logger() { exec logger -t "$APPLET" -s "$@"; }
	incoming_call() { __incoming_call "$@"; }
    else
	__logger() { exec logger -t "$APPLET" "$@"; }
	incoming_call() { __incoming_call "$@" > /dev/null 2>&1; }
    fi
    __info() { echo "$*" >&3; }
    __logger -p daemon.info < "$INFO_FIFO" & exec 3>"$INFO_FIFO"
    if $DEBUG; then
	__debug() { echo "$*" >&4; }
	__logger -p daemon.debug < "$DEBUG_FIFO" 3>&- & exec 4>"$DEBUG_FIFO"
    fi
    __debug "entering DEBUG mode"
}

__work() {
    ## a USR1 signal will cause the callmonitor to re-read its configuration
    trap __configure USR1
    trap '__shutdown' EXIT
    trap 'exit 2' HUP INT QUIT TERM

    ## initial configuration
    __log_setup
    __configure

    ## enter main loop
    while true; do
	__read_from_iface
    done
}
__shutdown() {
    __info "Exiting ..."
    for file in "$PIDFILE" /var/run/callmonitor/pid/*; do
	[ ! -f "$file" ] && continue
	PID=
	read PID < "$file"
	if [ "$$" = "$PID" ]; then
	    rm -f "$file"
	    continue
	fi
	__debug "Killing $PID ($file) ..."
	kill "$PID" 2> /dev/null && rm -f "$file"
    done
}

PIDFILE="/var/run/callmonitor/pid/callmonitor"
FIFO="$CALLMONITOR_FIFO"
DEBUG_FIFO="$CALLMONITOR_FIFO.debug"
INFO_FIFO="$CALLMONITOR_FIFO.info"

if $STOP; then
    if [ ! -e "$PIDFILE" ]; then
	echo "$APPLET: not running" 2>&1 
	exit 1
    else
	__shutdown
	exit $?
    fi
else
    mkdir -p "$(dirname "$FIFO")"
    mkdir -p "$(dirname "$PIDFILE")"

    for fifo in "$FIFO" "$DEBUG_FIFO" "$INFO_FIFO"; do
	mknod "$fifo" p 2>/dev/null
    done

    if $FOREGROUND; then
	echo $$ > "$PIDFILE"
	__work
    else
	__work &
	echo $! > "$PIDFILE"
    fi
fi
