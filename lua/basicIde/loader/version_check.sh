#!/bin/bash

report=$(mktemp --suffix '.nvim_report')

headline=''
print_headline_to_report=0
newline_before_headline=0

function log() {
	echo -e $@
}

function log_to_report() {
	local text="$@"
	
	if [ $print_headline_to_report -eq 1 ]
	then
		if [ $newline_before_headline -eq 1 ]
		then
			echo >> "$report"
		fi
		echo "# $headline" >> "$report"
		echo >> "$report"
		print_headline_to_report=0
		newline_before_headline=1
	fi

	echo " * $text" >> "$report"
}

function success() {
	local text="$@"
	if [ ${#text} == 0 ]
	then
		text="ok"
	fi
	log "\033[32m$text\033[0m"
}

function fail() {
	local text="$@"
	if [ ${#text} == 0 ]
	then
		text="ko"
	fi
	log "\033[31m$text\033[0m"
}

function warn() {
	local text="$@"
	if [ ${#text} == 0 ]
	then
		text="warn"
	fi
	log "\033[33m$text\033[0m"
}

function headline() {
	local title="$1"
	local len=${#title}

	headline="$title"
	print_headline_to_report=1
	
	log ""

	for i in $(seq $len)
	do
		log -n "#"
	done
	log "####"

	log "# $title #"

	for i in $(seq $len)
	do
		log -n "#"
	done
	log "####"
}

function check_requirements() {
	headline "Requirements check"

	local ret=0
	local critical=(
		"jq" "cannot verify plugins"
		"git" "cannot install plugins"
	)
	local noncritical=(
		"rg" "grep search won't work properly"
		"python3" "python not present"
		"xclip" "clipboard won't be shared with system"
		"notify-send" "system-style notification won't work"
	)

	for i in $(seq ${#critical[@]})
	do
		((i--))
		if [[ $((i % 2)) -ne 0 ]]; then continue ; fi

		local req=${critical[$i]}
		log -n "checking for $req... "
		local bin=$(which "$req")
		if [[ ${#bin} != 0 ]]
		then
			success "$bin"
		else
			fail "missing"
			log_to_report "missing $req: ${critical[$((i + 1))]}" >> "$report"
			ret=1
		fi
	done

	if [[ "$ret" -ne 0 ]]
	then
		return $ret
	fi

	for i in $(seq ${#noncritical[@]})
	do
		((i--))
		if [[ $((i % 2)) -ne 0 ]]; then continue ; fi

		local req=${noncritical[$i]}
		local drawback=${noncritical[$((i + 1))]}
		log -n "checking for $req... "
		local bin=$(which "$req")
		if [[ ${#bin} != 0 ]]
		then
			success "$bin"
		else
			fail "missing"
			log_to_report "missing $req: $drawback" >> "$report"
		fi
	done

	return $ret
}

function parse_nvim_version() {
	grep NVIM | cut -f2
}

function parse_luajit_version() {
	grep LuaJIT | cut -f2
}

function check_nvim() {
	headline "Nvim version check"

	local ret=0
	local current=$(nvim --version)
	
	local current_nvim=$(echo "$current" | parse_nvim_version)
	local wanted_nvim=$(cat "$NVIM_VERSION_FILE" | parse_nvim_version)

	log -n "nvim version: "
	if [ "$wanted_nvim" != "" -a "$wanted_nvim" == "$current_nvim" ]
	then
		success $current_nvim
	else
		fail $current_nvim
		log_to_report "nvim version difference: you're running $current_nvim, supported is $wanted_nvim" >> "$report"
		ret=1
	fi

	local current_luajit=$(echo "$current" | parse_luajit_version)
	local wanted_luajit=$(cat "$NVIM_VERSION_FILE" | parse_luajit_version)

	log -n "luajit version: "
	if [ "$wanted_luajit" != "" -a "$wanted_luajit" == "$current_luajit" ]
	then
		success "$current_luajit"
	else
		warn "$current_luajit"
		log_to_report "luajit version difference: you're running $current_luajit, supported is $wanted_luajit" >> "$report"
		ret=1
	fi

	return $ret
}

function beginswith() {
	case $1 in 
		"$2"*) true;;
		*) false;;
	esac;
}

function check_plugins() {
	headline "Nvim plugins check"

	local ret=0

	jq -rc 'to_entries | map(.value=.value.commit)[]' "$PACKER_PLUGIN_SNAPSHOT" |\
	while read plugin
	do
		local name=$(echo $plugin | jq -r '.key')
		local commit=$(echo $plugin | jq -r '.value')
		local plugin_dir=$(find "$PACKER_INSTALL_PATH" -maxdepth 2 -type d -name "$name")

		log -n "$name... "

		if [ "$plugin_dir" == "" ]
		then
			warn "not found"
			continue
		fi

		local current_commit=$(git -C "$plugin_dir" rev-parse HEAD)
		if beginswith "$current_commit" "$commit"
		then
			success
			continue
		fi

		warn "resetting to $commit (was at $current_commit)"
		(git -C "$plugin_dir" fetch --depth 9999 --progress --force && \
		git -C "$plugin_dir" reset --hard HEAD && \
		git -C "$plugin_dir" clean -ffd && \
		git -C "$plugin_dir" checkout "$commit" && \
		success "done" \
		log_to_report "plugin $name reset to $commit (was at $current_commit)" >> "$report") \
		|| \
		(ret=1; \
		fail; \
	  log_to_report "plugin $name reset from $current_commit to desired $commit failed!")
		
	done

	return $ret
}

verbose=0
while getopts "v" opt
do
	case $opt in
		v)
			verbose=1
			;;
		\?)
			echo "usage:"
			echo " -v  verbose output"
			echo
			exit 1
			;;
	esac
done
shift $((OPTIND-1))

NVIM_CONFIG_DIR="$1"
NVIM_VERSION_FILE="$NVIM_CONFIG_DIR/lua/basicIde/nvim.version"
PACKER_INSTALL_PATH="$HOME/.local/share/nvim/site/pack/packer"
PACKER_PLUGIN_SNAPSHOT="$NVIM_CONFIG_DIR/lua/basicIde/packer.snapshot"

if [ $verbose -eq 0 ]
then
	function log() {
		return 0
	}
fi

echo "$report"
check_requirements && check_nvim && check_plugins
ret=$?
if [ $ret -eq 0 ]
then
	rm "$report"
fi
exit $ret
