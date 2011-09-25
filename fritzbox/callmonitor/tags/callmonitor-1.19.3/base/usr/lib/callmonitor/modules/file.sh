##
## Callmonitor for Fritz!Box (callmonitor)
## 
## Copyright (C) 2005--2008  Andreas Bühmann <buehmann@users.berlios.de>
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
ensure_file() {
    local file dir
    for file; do
	if ! touch "$file" 2> /dev/null; then
	    dir=$(dirname "$file")
	    ensure_dir "$dir" && touch "$file"
	fi
    done
}
ensure_dir() {
    local dir
    for dir; do
	[ -e "$dir" ] || mkdir -p "$dir"
    done
}

## 'read -r' that skips comments and empty lines
readx() {
    local __
    while true; do
	read -r "$@" || return $?
	eval "__=\$$1"
	case $__ in
	    \#*|"") continue ;;
	    *) return 0 ;;
	esac
    done
}