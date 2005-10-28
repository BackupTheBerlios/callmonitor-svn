# lock $file by creating a directory $file.lock
lock() {
    local file="$1" interval="${2:-1000000}" first=1
    local lock="$file.lock"
    while ! mkdir "$lock" 2> /dev/null; do
	if [ $first -eq 1 ]; then 
	    first=0
	    echo "Waiting for exclusive lock on $file" 2> /dev/null
	fi
	usleep $interval
    done
    # echo $$ > "$lock/owner"
}

unlock() {
    local file="$1"
    local lock="$file.lock"
    # rm "$lock/owner"
    rmdir "$lock"
}
