#! /usr/bin/env ash
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
. /usr/lib/libmodcgi.sh

remote_tel_chk=''
if [ "$TELEFON_IP" = "*" ]; then
	remote_tel_chk=' checked'
fi

sec_begin 'Telefon-Daemon'

cat << EOF
<p>
<input type="hidden" name="ip" value="">
<input type="checkbox" name="ip" value="*"$remote_tel_chk id="t1">
<label for="t1">Zugriff von außen erlauben (Port 1011)</label>
</p>
EOF

sec_end
