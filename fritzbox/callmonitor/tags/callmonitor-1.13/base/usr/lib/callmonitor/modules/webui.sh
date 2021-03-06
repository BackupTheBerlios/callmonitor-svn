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
require url

WEBCM_DIR=/usr/www/html/cgi-bin
WEBCM=$WEBCM_DIR/webcm

webui_post_form_generic() {
    local cgi=$1 post_data=$2
    echo -n "$post_data" |
    REQUEST_METHOD=POST REMOTE_ADDR=${REMOTE_ADDR-127.0.0.1} \
    CONTENT_TYPE=application/x-www-form-urlencoded \
    CONTENT_LENGTH=${#post_data} \
    "$cgi"
}
webui_post_form() (
    cd "$WEBCM_DIR"
    local post_data=$1 REMOTE_ADDR=127.0.0.1
    webui_post_form_generic "$WEBCM" "$post_data"
)
webui_get() (
    cd "$WEBCM_DIR"
    REQUEST_METHOD=GET REMOTE_ADDR=127.0.0.1 QUERY_STRING=$1 "$WEBCM"
)
webui_login() {
    local password=$(webui_password)
    if ! empty "$password"; then
	webui_post_form "login:command/password=$(urlencode "$password")" \
	> /dev/null
    fi
}

webui_config() {
    cfg2sh ar7 webui
}

## cache password
unset WEBUI_PASSWORD
webui_password() {
    local webui_password=
    if ! [ ${WEBUI_PASSWORD+set} ]; then
	eval "$(webui_config | grep '^webui_password=')"
	WEBUI_PASSWORD=$webui_password
    fi
    echo "$WEBUI_PASSWORD"
}

## 2008-08-23: The interface to query.txt has been modified in recent 7270
## (Labor) firmwares. Let's try to use both interfaces simultaneously instead
## of doing some kind of firmware detection.
webui_query() {
    local query="getpage=../html/query.txt&var:cnt=$#" var= n=0
    for var; do
	local value=$(urlencode "$var")
	query="$query&var:n${n}=${value}&var:n%5b${n}%5d=${value}"
	let n++
    done
    webui_get "$query" | sed -e '1,/^$/d;$d'
}

webui_page_url() {
    local menu=${1%/*} pagename=${1#*/}
    echo "http://fritz.box/cgi-bin/webcm?getpage=..%2Fhtml%2F${Language:-de}%2Fmenus%2Fmenu2.html&var%3Alang=${Language:-de}&var%3Apagename=$(urlencode "$pagename")&var%3Amenu=$(urlencode "$menu")"
}
