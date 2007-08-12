##
## Callmonitor for Fritz!Box (callmonitor)
## 
## Copyright (C) 2005--2007  Andreas Bühmann <buehmann@users.berlios.de>
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

## generic option parsing
_getopt() {
    local - temp consumed name=$1 ERROR=0
    shift
    temp=$(_getopt_$name "$@") || return 1
    set -f; eval "set -- $temp"; set +f
    while true; do
	_opt_$name "$@"; consumed=$?
	if ? "ERROR > 0"; then
	    return $ERROR
	fi
	if ? "consumed > 0"; then
	    shift $consumed
	else
	    case $1 in
		--) shift; break ;;
		*) echo "$name: unrecognized option \`$1'"; return 1 ;;
	    esac
	fi
    done
    _body_$name "$@"
}
