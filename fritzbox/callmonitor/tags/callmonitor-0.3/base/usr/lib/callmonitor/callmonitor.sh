# Syntax of rules in file /mod/etc/callmonitor.listeners (not compatible
# with versions in mod-0.57 and earlier):
#
# [NT:|*:][!]<caller-regexp> [!]<called-regexp> <command line (rest)>
#
# A command line is executed whenever an incoming call is detected that
# matches both (egrep) regexps (caller and called). The prefix "NT:" to
# the caller-regexp can be used to restrict matches to calls coming from
# the S0 bus ("Incoming from NT"); no prefix ignores these calls (the
# default); "*:" matches both. !-prefixed regexps must NOT match for the
# rule to succeed.
#
# Lines starting with "#" are ignored, as are empty lines.

# these stubs/defaults can be overridden (the configuration from system.cfg
# is needed, too; it must be included separately)
__debug() :
__info() :
incoming_call() { __incoming_call "$@"; }
PHONEBOOK_OPTIONS=""

__configure() {
	# import action functions
	local ACTIONSDIR ACTIONS
	for ACTIONSDIR in "$CALLMONITOR_LIBDIR/actions.d" \
		"$CALLMONITOR_LIBDIR/actions.local.d"; do
		for ACTIONS in "$ACTIONSDIR"/*.sh; do
			if [ -r "$ACTIONS" ]; then
				__debug "including $(realpath "$ACTIONS")"
				. "$ACTIONS"
			fi
		done
	done
}

# process an "IncomingCall" line
__incoming_call() {
	local line="$1"
	local SOURCE="${line##*caller: \"}"; SOURCE="${SOURCE%%\"*}"
	local DEST="${line##*called: \"}"; DEST="${DEST%%\"*}"
	local SOURCE_NAME="" DEST_NAME="" NT=false
	local SOURCE_OPTIONS= DEST_OPTIONS=
	__debug "detected '$line'"
	case "$line" in
		"IncomingCall from NT:"*) NT=true ;; 
	esac

	# only one reverse lookup; it is expensive
	if $NT; then
		SOURCE_OPTIONS="--local"
	else
		DEST_OPTIONS="--local"
	fi
	if [ ! -z "$SOURCE" ]; then
		SOURCE_NAME="$(phonebook $PHONEBOOK_OPTIONS $SOURCE_OPTIONS \
			get "$SOURCE")"
	fi
	if [ ! -z "$DEST" ]; then
		DEST_NAME="$(phonebook $PHONEBOOK_OPTIONS $DEST_OPTIONS \
			get "$DEST")"
	fi
	__info "SOURCE='$SOURCE' DEST='$DEST' SOURCE_NAME='$SOURCE_NAME'" \
		"DEST_NAME='$DEST_NAME' NT=$NT" 

	if [ ! -r /mod/etc/callmonitor.listeners ]; then
		__debug "/mod/etc/callmonitor.listeners is missing"
		return
	else
		__debug "processing rules from /mod/etc/callmonitor.listeners"
	fi

	# make call information available to listeners
	export SOURCE DEST SOURCE_NAME DEST_NAME NT

	# deprecated interface
	export MSISDN="$SOURCE" CALLER="$SOURCE_NAME" CALLED="$DEST"

	local msisdn_pattern called_pattern listener rule=0
	cat /mod/etc/callmonitor.listeners | {
		while read -r msisdn_pattern called_pattern listener
		do
			# comment or empty line
			case $msisdn_pattern in \#*|"") continue ;; esac

			# process rule asynchronously
			RULE=$rule \
			__process_rule "$msisdn_pattern" "$called_pattern" "$listener" &
			let rule="$rule + 1"
		done
		wait
	}
}

# process a single rule
__process_rule() {
	local msisdn_pattern="$1" called_pattern="$2" listener="$3"
	__debug_rule "processing rule '$msisdn_pattern' '$called_pattern' '$listener'"

	# match and strip NT/* prefix
	case $msisdn_pattern in
		NT:*)
			if ! $NT; then 
				__debug_rule "call is NOT from NT"
				__debug_rule "FAILED"
				return 1
			fi
			msisdn_pattern=${msisdn_pattern#NT:}
			;;
		\*:*)  
			msisdn_pattern=${msisdn_pattern#\*:}
			;;
		*)
			if $NT; then 
				__debug_rule "call IS from NT"
				__debug_rule "FAILED"
				return 1
			fi
			;;
	esac

	# match
	__match SOURCE "$SOURCE" "$msisdn_pattern" || return 1
	__match DEST "$DEST" "$called_pattern" || return 1

	# execute listener
	__debug_rule "SUCCEEDED: executing '$listener'"
	set --
	eval "$listener"
	local status=$?
	if [ $status -ne 0 ]; then
		__debug_rule "listener failed with an exit status of $status"
	fi

	return 0
}
__debug_rule() {
	__debug "[$RULE]" "$@"
}

# match a single pattern from a rule
__match() {
	local PARAM="$1" VALUE="$2" PATTERN="$3" RESULT=1
	local REGEXP="${PATTERN#!}"
	local SHPAT="${REGEXP#^}"
	SHPAT="${SHPAT%\$}"
	case "$SHPAT" in
		*[!A-Za-z_0-9-]*)
			if echo "$VALUE" | egrep -q "$REGEXP"; then
				RESULT=0
			fi
			;;
		*) # match simple patterns on our own
			case "$REGEXP" in
				^*) ;;
				*) SHPAT="*$SHPAT" ;;
			esac
			case "$REGEXP" in
				*\$) ;;
				*) SHPAT="$SHPAT*" ;;
			esac
			case "$VALUE" in
				$SHPAT) RESULT=0 ;;
			esac
			;;
	esac
	case $PATTERN in
		!*) let RESULT="!$RESULT" ;;
	esac
	if [ $RESULT -eq 0 ]; then
		__debug_rule "parameter $PARAM='$VALUE' matches pattern '$PATTERN'"
	else
		__debug_rule "parameter $PARAM='$VALUE' does NOT match" \
			"pattern '$PATTERN'"
		__debug_rule "FAILED"
	fi
	return $RESULT
}

# copy stdin to stdout while looking for incoming calls
__read() {
	local line
	while IFS= read -r line
	do
		echo "$line"
		case $line in
			"IncomingCall"*"caller: "*"called: "*)
				incoming_call "$line" & ;;
		esac
	done
}
