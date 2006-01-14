mod_register() {
	local tmp_voip="/var/tmp/rc.voip" org_voip="/etc/init.d/rc.voip"
	sed -e '/^case/ i\
PATH=/var/mod/usr/lib/telefon/bin:$PATH
' "$org_voip" > "$tmp_voip"
	mount -o bind "$tmp_voip" "$org_voip"
}
mod_unregister() {
	local tmp_voip="/var/tmp/rc.voip" org_voip="/etc/init.d/rc.voip"
	umount "$org_voip"
}
