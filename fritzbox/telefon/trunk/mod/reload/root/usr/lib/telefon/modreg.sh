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
