##
## Callmonitor for Fritz!Box (telefon)
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
mod_register() {
	local tmp_voip="/var/tmp/rc.voip" org_voip="/etc/init.d/rc.voip"
	if [ ! -e "$TELEFON_USERCFG" ]; then
	    mkdir -p "${TELEFON_USERCFG%/*}"
	    cp "$TELEFON_USERCFG_DEF" "$TELEFON_USERCFG"
	fi
	umount "$org_voip" 2> /dev/null
	sed -e '/^case/ i\
PATH=/var/mod/usr/lib/telefon/bin:$PATH
' "$org_voip" > "$tmp_voip"
	chmod +x "$tmp_voip"
	mount -o bind "$tmp_voip" "$org_voip"
}
mod_unregister() {
	local tmp_voip="/var/tmp/rc.voip" org_voip="/etc/init.d/rc.voip"
	umount "$org_voip"
}
