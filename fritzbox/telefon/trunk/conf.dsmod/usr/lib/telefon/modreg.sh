mod_register() {
	local DAEMON=telefon
	modreg cgi $DAEMON 'Telefon'
}
mod_unregister() {
	local DAEMON=telefon
	modunreg cgi $DAEMON
}
