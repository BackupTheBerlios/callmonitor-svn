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
require if_jfritz_status
require if_jfritz_cgi
require version
require webui
require tel

check "$CALLMONITOR_ENABLED" yes:auto *:man
check "$CALLMONITOR_DEBUG" yes:debug
check "$CALLMONITOR_REVERSE" yes:reverse
select "$CALLMONITOR_REVERSE_CACHE" no transient:trans persistent:pers
check "$CALLMONITOR_READ_FONBUCH" yes:fon
check "$CALLMONITOR_PHONEBOOKS" "callers cache avm":after "avm callers cache":before

SYSLOG='$(lang de:"System-Log" en:"system log")'
if has_package syslogd; then
    SYSLOG="<a href='pkgconf.cgi?pkg=syslogd'>$SYSLOG</a>"
fi
echo '
<script type="text/javascript">
    function dep(father, child) {
	document.getElementById(child).disabled = ! father.checked;
    }
    dep.init = function() {
	for (var i = 0; i < document.forms.length; i++) {
	    var f = document.forms[i];
	    for (var j = 0; j < f.elements.length; j++) {
		var e = f.elements[j];
		if (e.onchange) e.onchange();
	    }
	}
    }

    var oldonload = window.onload;
    window.onload = function() {
	if (oldonload) oldonload();
	dep.init();
    }
</script>
'

if ! have monitor; then
    echo "<p>$(lang de:"Monitor nicht installiert" en:"Monitor not installed")</p>"
else

sec_begin '$(lang de:"Starttyp" en:"Startup type")'

echo "
<div style='float: right;'><a target='_blank' href='$CALLMONITOR_FORUM_URL'>Version
    $CALLMONITOR_VERSION</a></div>
<p>
    <input type='radio' name='enabled' value='yes'$auto_chk id='e1'>
    <label for='e1'>$(lang de:"Automatisch" en:"Automatic")</label>
    <input type='radio' name='enabled' value='no'$man_chk id='e2'>
    <label for='e2'>$(lang de:"Manuell" en:"Manual")</label>
</p>
<p>
    <input type='hidden' name='debug' value='no'>
    <input type='checkbox' name='debug' value='yes'$debug_chk id='d1'>
    <label for='d1'>$(lang 
	de:"mit Debug-Ausgaben" 
	en:"with debugging output"
    )</label> ($(lang de:"ins" en:"into the") $SYSLOG)
</p>
"
sec_end

if ! _j_is_up; then
    sec_begin '$(lang de:"Status" en:"Status")'
    echo '<ul>'
    _j_cgi_is_down
    echo '</ul>'
    sec_end
fi

sec_begin '$(lang de:"Aktionen bei Anruf" en:"Actions upon calls")'

echo "
<ul>
    <li><a href='/cgi-bin/file.cgi?id=listeners'>$(lang
	de:"Listeners bearbeiten" en:"Edit Listeners")</a></li>
    <li><a href='/cgi-bin/extras.cgi/callmonitor/testcall'>$(lang
	de:"Testanruf durchf�hren" en:"Perform test call")</a></li>
</ul>
"

sec_end
fi

if ! have phonebook; then
    echo "<p>$(lang de:"Telefonbuch nicht installiert" en:"Phone book not installed")</p>"
else

sec_begin '$(lang de:"Standortangaben" en:"Location data")'

echo "
<table width='100%'>
    <colgroup>
	<col width='25%' span='2'>
	<col width='50%'>
    </colgroup>
<tr>
    <td>$(lang de:"Landesvorwahl" en:"Country code")</td>
    <td><input disabled size="3" value='$(html "$LKZ_PREFIX")'>
	<input disabled size="4" value='$(html "$LKZ")'></td>
</tr>
<tr>
    <td>$(lang de:"Ortsvorwahl" en:"Area code")</td>
    <td><input disabled size="3" value='$(html "$OKZ_PREFIX")'>
	<input disabled size="4" value='$(html "$OKZ")'></td>
    <td>
	<a target='_blank' href='$(html "$(webui_page_url fon/sipoptionen)")'>$(lang de:"�ndern" en:"Change")</a>
    </td>
</tr>
</table>
"

sec_end

sec_begin '$(lang de:"R�ckw�rtssuche" en:"Reverse lookup")'

H_CALLERS="<a href='/cgi-bin/file.cgi?id=callers' title='$(lang 
	de:"Telefonbuch des Callmonitors"
	en:"Callmonitor's phone book"
    )'>Callers</a>"

echo "
<table>
<tr>
    <td><input type='checkbox' name='dummy' checked disabled></td>
    <td>$(lang de:"In" en:"Lookup in") $H_CALLERS
	$(lang de:"nachschlagen" en:"")</td>
</tr>
<tr>
    <td><input type='hidden' name='read_fonbuch' value='no'><!--
    --><input type='checkbox' name='read_fonbuch' value='yes'$fon_chk id='r5'
	onchange='dep(this,\"prio\")'></td>
    <td><label for='r5'>$(lang
	de:"Im FRITZ!Box-Telefonbuch nachschlagen"
	en:"Lookup in the FRITZ!Box's phone book"
    )</label></td>
    <td><input type='hidden' name='phonebooks' value='callers cache avm'><!--
    --><input type='checkbox' name='phonebooks' value='avm callers cache'$before_chk id='prio'></td>
    <td><label for='prio'>$(lang
	de:"vor Callers"
	en:"before Callers"
    )</label></td>
</tr>
"
H_PROVIDERS="<a href='/cgi-bin/extras.cgi/callmonitor/reverse' title='$(lang
	de:"R�ckw�rtssucheseiten im Web"
	en:"Reverse-lookup Web sites"
    )'>$(lang de:"externen Anbietern" en:"external providers")</a>"
echo "
<tr>
    <td><input type='hidden' name='reverse' value='no'><!--
    --><input type='checkbox' name='reverse' value='yes'$reverse_chk id='r4'
	onchange='dep(this,\"cache\")'></td>
    <td><label title='$(lang
	de:"Rufnummern wenn m�glich in Namen aufl�sen"
	en:"Resolve numbers to names if possible"
    )' for='r4'>$(lang
	de:"R�ckw�rtssuche"
	en:"Perform reverse lookup"
    )</label> $(lang
	de:"bei $H_PROVIDERS durchf�hren"
	en:"at $H_PROVIDERS"
    )</td>
</tr>
<tr><td></td>
    <td><label for='cache'>$(lang
	de:"Suchergebnisse zwischenspeichern?"
	en:"Cache query results?"
    )</label></td>
    <td colspan="0"><select name='reverse_cache' id='cache'>
	<option title='$(lang
	    de:"Keine Speicherung der Namen"
	    en:"Names are not stored"
	)' value='no'$no_sel>$(lang de:"Nein" en:"No")</option>
	<option title='$(lang
	    de:"Namen gehen bei n�chstem Neustart verloren"
	    en:"Names will be lost at the next reboot"
	)' value='transient'$trans_sel>$(lang
	    de:"Fl�chtig" en:"Transiently")</option>
	<option title='$(lang 
	    de:"Namen werden in den Callers gespeichert"
	    en:"Names are stored in the Callers"
	)' value='persistent'$pers_sel>$(lang
	    de:"Dauerhaft" en:"Persistently")</option>
    </select></td>
</tr>
</table>
"

sec_end
fi
