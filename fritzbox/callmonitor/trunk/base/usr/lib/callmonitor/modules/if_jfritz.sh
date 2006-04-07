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

## analyze call information
__read() {
    local timestamp event id ext source dest remote duration
    while _j_parse; do

	## complete information
	case $event in
	    CONNECT)	_j_load source dest ;;
	    DISCONNECT)	_j_load source dest ext ;;
	esac

	local state output
	_j_load state
	_j_transition
	
	case $state in
	    disconnected)
		_j_remove state source dest ext
		;;
	    *)
		case $event in
		    CALL|RING) _j_store source dest ;;
		    CONNECT)   _j_store source dest ext ;;
		esac
		_j_store state
		;;
	esac
    done
}

## separate state maschine for each connection id
_j_transition() {
    case $state in
	""|disconnected)
	    case $event in
		CALL)	    state=calling	output=out:request ;;
		RING)	    state=ringing	output=in:request ;;
		*)	    state=disconnected  output=error ;;
	    esac
	;;
	calling)
	    case $event in
		CONNECT)    state=connected:out	output=out:connect
			    dest=$remote ;;
		DISCONNECT) state=disconnected	output=out:cancel ;;
		*)	    state=disconnected  output=error ;;
	    esac
	;;
	ringing)
	    case $event in
		CALL)	    state=accepted:in	output=in:accept ;;
		CONNECT)    state=connected:in	output=in:connect
			    source=$remote ;;
		DISCONNECT) state=disconnected	output=in:cancel ;;
		*)	    state=disconnected  output=error ;;
	    esac
	;;
	accepted:in)
	    case $event in
		CONNECT)    state=connected:in	output=in:connect
			    source=$remote ;;
		DISCONNECT) state=disconnected	output=in:cancel ;;
		*)	    state=disconnected  output=error ;;
	    esac
	;;
	connected:in)
	    case $event in
		DISCONNECT) state=disconnected	output=in:disconnect ;;
		*)	    state=disconnected  output=error ;;
	    esac
	;;
	connected:out)
	    case $event in
		DISCONNECT) state=disconnected	output=out:disconnect ;;
		*)	    state=disconnected  output=error ;;
	    esac
	;;
    esac
    let INSTANCE++
    export INSTANCE
    case $output in
	""|in:accept)
	    ## not used yet
	;;
	*)
	    { _j_output "$output" & } & wait $!
	;;
    esac
}

_j_parse() {
    local _1 _2 _3 _4 empty DEBUG
    IFS=';' read -r timestamp event _1 _2 _3 _4 empty || return 1
    id=$_1
    DEBUG="timestamp=$timestamp event=$event id=$id"
    unset ext source dest remote duration
    case $event in
	CALL)
	    ext=$_2 source=$_3 dest=$_4
	    DEBUG="$DEBUG ext=$ext source=$source dest=$dest"
	;;
	RING)
	    source=$_2 dest=$_3
	    DEBUG="$DEBUG source=$source dest=$dest"
	;;
	CONNECT)
	    ext=$_2 remote=$_3
	    DEBUG="$DEBUG ext=$ext remote=$remote"
	;;
	DISCONNECT)
	    duration=$_2
	    DEBUG="$DEBUG duration=$duration"
	;;
	*)
	    return 1
	;;
    esac
    __debug '<<<' $DEBUG
    return 0
}

__read_from_iface() {
    let "_j_SLEEP = (_j_SLEEP < 1) ? 1 : _j_SLEEP"
    if ! nc 127.0.0.1 1012 < /dev/null > /dev/null 2>&1; then
	__info "Please use #96*5* to enable telefon's interface."
        __info "Trying again in $_j_SLEEP seconds ..."

	sleep "$_j_SLEEP"
	let "_j_SLEEP *= 2"
	let "_j_SLEEP = (_j_SLEEP > 600) ? 600 : _j_SLEEP"
    else
	_j_SLEEP=
	## hack to provide "never"-ending but empty stdin: FIXME
	mkdir -p /var/run/callmonitor/pid
	{
	    sleep 20000d &
	    echo $! > /var/run/callmonitor/pid/sleep
	    wait
	    rm /var/run/callmonitor/pid/sleep
	} | nc 127.0.0.1 1012 | __read
    fi
}

__init_iface() {
    :
}

_j_output() {
    local output="$1"
    __debug '>>>' "$* ID=$id TIMESTAMP=$timestamp SOURCE=$source DEST=$dest" \
	"EXT=$ext DURATION=$duration"

    local ID=$id SOURCE=$source DEST=$dest EXT=$ext DURATION=$duration
    local TIMESTAMP=$timestamp EVENT= SOURCE_OPTIONS= DEST_OPTIONS=
    case $output in
	in:accept)
	    ## not used yet
	;;
	in:*)
	    EVENT=$output
	    DEST_OPTIONS="--local"
	;;
	out:*)
	    EVENT=$output
	    SOURCE_OPTIONS="--local"
	;;
    esac
    if ! empty "$EVENT"; then
	incoming_call
    fi
}

## store attributes per connection id
_j_store() {
    for var; do eval "_j__${var}_${id}=\"\$${var}\""; done
}
_j_load() {
    for var; do eval "${var}=\"\$_j__${var}_${id}\""; done
}
_j_remove() {
    for var; do eval "unset ${var} _j__${var}_${id}"; done
}