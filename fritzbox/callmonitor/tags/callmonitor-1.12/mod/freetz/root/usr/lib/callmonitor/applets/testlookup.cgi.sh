##
## Callmonitor for Fritz!Box (callmonitor)
## 
## Copyright (C) 2005--2008  Andreas B�hmann <buehmann@users.berlios.de>
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
require cgi
require phonebook
require reverse
require file

SELF=testlookup
TITLE="$(lang de:"Test der R�ckw�rtssuche" en:"Check reverse look-up")"

eval "$(modcgi number test)"

number_val=$(html "$TEST_NUMBER")
SELECTED="<input type='checkbox' checked disabled></span>"
LEGEND="$SELECTED: $(lang
	    de:"Wird im normalen Betrieb verwendet"
	    en:"Used in actual operation"
	)"

new_test_form() {
    echo "
<form action='$SELF' method='post'>
    <table><tr>
	<td><label for='number'>$(lang
	    de:"Rufnummer" en:"Number"):</label> </td>
	<td>
	    <input type='text' name='number' id='number' value='$number_val'>
	</td>
    </tr></table>
    <div class='btn'><input type='submit' 
	value='$(lang de:"Nachschlagen" en:"Look up")'></div>
</form>
"
}

show_test_results() {
    local number=$1 name status lkz disp unsupported= prov area_prov
    normalize_tel "$number"; number=$__
    normalize_tel "$number" display; disp=$__
    lkz=$(tel_lkz "$number")
    _reverse_choose_provider "$lkz"
    echo "<p style='color: gray; float: right;'>$LEGEND</p>"
    echo "<p>$(lang de:"Schlage $disp nach" en:"Looking up $disp") ...</p>"
    local type provider site label countries supported
    while readx type provider countries site label; do
	case ",$countries," in
	    *",$lkz,"*|*",$lkz!,"*|*",*,") supported=true ;;
	    *) supported=false ;;
	esac
	local html_label="<a href='http://$site/'>$(html "$label")</a>"
	if ! $supported; then
	    unsupported="${unsupported:+$unsupported, }$html_label"
	else 
	    local selected=
	    if [ "$provider" = "$prov" -o "$provider" = "$area_prov" ]; then
		if [ "$CALLMONITOR_REVERSE" = "yes" ]; then
		    selected=" $SELECTED"
		fi
	    fi
	    echo -n "<h2>$html_label$selected</h2>"
	    echo -n "<p>"
	    _reverse_load "$provider"
	    name=$(_reverse_lookup "$provider" "$number" 2>/dev/null); status=$?
	    local url link
	    url=$(_reverse_lookup_url "$provider" "$number")
	    link="<a href='$(html "$url")' target='_blank'>($(lang de:"�berpr�fen" en:"Check"))</a>"
	    show_result
	    echo -n "</p>"
	fi
    done < "$CALLMONITOR_REVERSE_CFG"
    if ! empty "$unsupported"; then
	echo "<h2>$(lang de:"Andere Anbieter" en:"Other providers")</h2>"
	echo "<p>$(lang 
	    de:"Unterst�tzen ${lkz:++}${lkz:-$disp} nicht"
	    en:"Do not support ${lkz:++}${lkz:-$disp}"
	): $unsupported</p>"
    fi
    echo "<h2>$(lang de:"Lokale Telefonb�cher" en:"Local phone books") $SELECTED</h2>"
    name=$(_pb_main --local get "$number"); status=$?; link=
    show_result
}

## uses $name, $status, and $link
show_result() {
    case $status in
	0)
	    echo "$(lang de:"Gefunden: " en:"Found: ") $link"
	    echo "$name" | pre
	;;
	1) echo "$(lang de:"Nicht gefunden. " en:"Not found. ") $link" ;;
	*) echo "$(lang de:"Fehler." en:"Error.") $link" ;;
    esac
}

cgi_main() {
    if let "${TEST_NUMBER+1}"; then
	cgi_begin "$TITLE ..."
	show_test_results "$TEST_NUMBER"
    else
	cgi_begin "$TITLE" extras
    fi
    new_test_form
    ## config_button
    cgi_end
}

cgi_main
