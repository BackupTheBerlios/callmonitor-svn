#! /usr/bin/env ash
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
<label for="t1">Zugriff von auﬂen erlauben (Port 1011)</label>
</p>
EOF

sec_end
