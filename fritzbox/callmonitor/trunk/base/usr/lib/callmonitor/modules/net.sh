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

require message
require url

## Basic networking utilities

## carriage return & line feed
CR=""
LF="
"

## output an HTTP Authorization header (Basic)
## basic_auth <user> <password>
basic_auth() {
    local user="$1" password="$2"
    echo -n "$user:$password" | uuencode -m - |
    sed -e '1d;2s/^/Authorization: Basic /;3,$s/^/ /;s/$/'$CR'/;$d'
}

## convert latin1 to utf8
latin1_utf8() {
    hexdump -v -e '100/1 " %02x" "\n"' |
    sed -e '
	s/ \([89ab]\)/c2\1/g
	s/ c/c38/g
	s/ d/c39/g
	s/ e/c3a/g
	s/ f/c3b/g
	s/ //g
	s/\(..\)/\\x\1/g
    ' |
    while IFS= read -r line; do echo -ne "$line"; done
}

__getmsg_usage() {
#<
    cat <<\EOH
Usage:	getmsg [OPTION]... <HOST> <part-url-template> [<message>]...
	getmsg [OPTION]... -t <part-url-template> <host> [<message>]...
	getmsg [OPTION]... <full-url-template> [<message>]...
Send a message in a simple HTTP GET request.

  -t, --template=FORMAT  use this printf-style template to build the URL,
			 all following messages are URL-encoded and filled
			 into this template
  -d, --default=CODE	 default for first parameter (eval'ed later)
  -p, --port=PORT	 use a special target port (default 80)
  -w, --timeout=SECONDS  set connect timeout (default 3)
  -v, --virtual=VIRT	 use a different virtual host (default HOST)
  -U, --user=USER	 user for basic authorization
  -P, --password=PASS	 password for basic authorization
      --help		 show this help

  <full-url-template>    http://[user[:password]@]host[:port]<partial-url-template>
  <part-url-template>    e.g., /path/to/resource?query=string&message=%s
EOH
#>
}
getmsg() {
    __getmsg __getmsg_simple "$@"
}
__getmsg() {
    local - IP= URL= TEMPLATE= VIRTUAL= USERNAME= PASSWORD= AUTH= TEMP= SEND=
    local DEFAULT=default_message PORT=80 TIMEOUT=3
    SEND="$1"; shift
    TEMP="$(getopt -n getmsg -o U:P:v:t:w:p:d: \
	-l user:,password:,virtual:,port:,template:,timeout:,default:,help -- "$@")"
    if ? "$? != 0"; then return 1; fi
    set -f; eval "set -- $TEMP"; set +f
    while true; do
	case $1 in
	    -U|--user) USERNAME="$2"; shift ;;
	    -P|--password) PASSWORD="$2"; shift ;;
	    -v|--virtual) VIRTUAL="$2"; shift ;;
	    -t|--template) TEMPLATE="$2"; shift ;;
	    -w|--timeout) TIMEOUT="$2"; shift ;;
	    -p|--port) PORT="$2"; shift ;;
	    -d|--default) DEFAULT="$2"; shift ;;
	    --help) __getmsg_usage >&2; return 1 ;;
	    --) shift; break ;;
	    *) ;; # should never happen
	esac
	shift
    done
    if ? $# == 0; then echo "Missing hostname or IP" >&2; return 1; fi
    __getmsg_parse "$1" || return 1; shift
    if empty "$TEMPLATE"; then
	if ? $# == 0; then echo "Missing template" >&2; return 1; fi
	TEMPLATE="$1"; shift
    fi
    if ? $# == 0; then set -- "$(eval "$DEFAULT")"; fi
    VIRTUAL="${VIRTUAL:-$IP}"
    if ! empty "$USERNAME" || ! empty "$PASSWORD"; then
	AUTH="$(basic_auth "$USERNAME" "$PASSWORD")"
    fi
    $SEND "$@"
}
## parse first argument: IP | full URL template
__getmsg_parse() {
    if url_parse "$1"; then
	case $url_scheme in
	    http) ;;
	    *) echo "URL scheme '$url_scheme' is not supported" \
		"(only 'http' is)" >&2; return 1 ;;
	esac
	if ! empty "$url_user"; then
	    USERNAME=$(urldecode "$url_user")
	fi
	if ! empty "$url_auth"; then
	    PASSWORD=$(urldecode "$url_auth")
	fi
	IP=$url_host
	if ! empty "$url_port"; then
	    PORT=$(urldecode "$url_port")
	fi
	TEMPLATE="${url_path:-/}${url_query:+?$url_query}"
	return 0
    else
	IP="$1"
	return 0
    fi
}
__getmsg_simple() {
    ## If $1 is empty, it disappears completely in the output of "$@", which
    ## shifts all messages to the left. This seems to be a bug in the busybox
    ## version of ash (prior to v1.1.0). Other empty arguments work as expected.
    URL="$(set -f; IFS=/; printf "$TEMPLATE" \
    $(for arg in "$@"; do echo -n $(urlencode "$arg")/; done))"
    {
	echo "GET $URL HTTP/1.0$CR"
	echo "Host: $VIRTUAL$CR"
	! empty "$AUTH" && echo "$AUTH"
	echo "$CR"
    } | __nc "$TIMEOUT" "$IP" "$PORT"
}

__rawmsg_usage() {
#<
    cat <<\EOH
Usage: rawmsg [OPTION]... <HOST> <template> [<param>]...
       rawmsg [OPTION]... -t <template> <host> [<param>]...
Send a message over a plain TCP connection.

  -t, --template=FORMAT  use this printf-style template to build the message,
			 all following parameters are filled in
  -d, --default=CODE	 default for first parameter (eval'ed later)
  -p, --port=PORT	 use a special target port (default 80)
  -w, --timeout=SECONDS  set connect timeout (default 3)
      --help		 show this help
EOH
#>
}
rawmsg() {
    local - IP= TEMPLATE= TEMP= PORT=80 TIMEOUT=3 DEFAULT=default_raw
    TEMP="$(getopt -n rawmsg -o t:w:p:d: \
	-l port:,template:,timeout:,default:,help -- "$@")"
    if ? "$? != 0"; then return 1; fi
    set -f; eval "set -- $TEMP"; set +f
    while true; do
	case $1 in
	    -t|--template) TEMPLATE="$2"; shift ;;
	    -w|--timeout) TIMEOUT="$2"; shift ;;
	    -p|--port) PORT="$2"; shift ;;
	    -d|--default) DEFAULT="$2"; shift ;;
	    --help) __rawmsg_usage >&2; return 1 ;;
	    --) shift; break ;;
	    *) ;; # should never happen
	esac
	shift
    done
    if ? $# == 0; then echo "Missing hostname or IP" >&2; return 1; fi
    IP="$1"; shift
    if empty "$TEMPLATE"; then
	if ? $# == 0; then echo "Missing template" >&2; return 1; fi
	TEMPLATE="$1"; shift
    fi
    if ? $# == 0; then set -- "$(eval "$DEFAULT")"; fi
    ## If $1 is empty, it disappears completely in the output of "$@", which
    ## shifts all messages to the left. This seems to be a bug in the busybox
    ## version of ash (prior to v1.1.0). Other empty arguments work as expected.
    printf "$TEMPLATE" "$@" | __nc "$TIMEOUT" "$IP" "$PORT"
}
default_raw() {
    default_message
}
