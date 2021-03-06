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

## run callmonitor in test mode: do not run as a daemon, do not write
## pid file, show trace of rule processing for simplified call on stdout

require callmonitor

__debug() { echo "$*"; }
__info() { echo "$*"; }

__configure

event=$1 source=$2 dest=$3

## dummy values
id=1 ext=4 duration=16 timestamp=$(date +"%d.%m.%y %H:%M")

_j_output "$event"

wait
exit 0
