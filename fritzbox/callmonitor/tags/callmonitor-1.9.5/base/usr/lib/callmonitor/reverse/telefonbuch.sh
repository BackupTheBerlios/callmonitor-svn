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
_reverse_telefonbuch_request() {
    getmsg -w 5 'http://www.dastelefonbuch.de/?la=de&kw=%s&cmd=search' "$1"
}
_reverse_telefonbuch_extract() {
    sed -n -e '
	/kein Teilnehmer gefunden/q
	/<!-- \*\{2,\} Treffer Eintr.ge \*\{2,\} -->/,/<!-- \*\{2,\} Ende Treffer Eintr.ge \*\{2,\} -->/ {
	    \#^[[:space:]]*$#! H
	}
	/<!-- \*\{2,\} Ende Treffer Eintr.ge \*\{2,\} -->/ {
	    g
	    s#^[^<]*\(<[^a][^<]*\)*<a[^>]*title="\([^"]*\)"[[:space:]]*>.*<td width="180">\([^<]*\)</td>.*<span title="\([^"]*\)".*$#\2, \3, \4#
	    t cleanup
	    q
	}
	b
	: cleanup
	'"$REVERSE_SANITIZE"'
	p
	q
    '
}
