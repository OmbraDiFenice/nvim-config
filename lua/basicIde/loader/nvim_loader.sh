#!/bin/bash

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
PROJECT_ROOT="$PWD"
NVIM_ARGS=()

NVIM_BIN="$1"
shift

# must be exported so they're available from within nvim too
export LOADER_SHELL_PID=$$
export SET_TITLE_SCRIPT="${SCRIPTPATH}/shellUtils/set_title_stub.sh"

# support setting the title with oh-my-zsh
if [ -n "$ZSH" ]
then
	DISABLE_AUTO_TITLE="true"
	export SET_TITLE_SCRIPT="${SCRIPTPATH}/shellUtils/set_title.zsh"
fi

# Uses nvim as lua interpreter for the given script file.
# The script can take optional arguments.
# This will solve problems related to the version of lua installed on the system:
# now this script only depends on the version of lua embedded in the nvim executable being used
function nlua() {
	local LUA_SCRIPT_FILE="$1"
	shift
	# nvim -l prints on stderr, see https://github.com/neovim/neovim/issues/27084
	# Also, the output will contain \n\r at the end, even on linux.
	# Depending on how the output is going to be used they might need to be stripped off.
	# See https://stackoverflow.com/questions/12524308/bash-strip-trailing-linebreak-from-output for various alternatives
	cat "$LUA_SCRIPT_FILE" | "$NVIM_BIN" --clean -n -i NONE -l - $@ 2>&1
}

# Convenience function to get data from the project configuration
function get_config() {
	local CONFIG="$1"
	nlua "$SCRIPTPATH/read_project_config.lua" "$PROJECT_ROOT" "$CONFIG"
}

CONFIG_DIRECTORY=$(get_config config_directory | tr --delete '\n\r')
REPORT_FILE=$("$SCRIPTPATH"/version_check.sh "$CONFIG_DIRECTORY" | head -n 1)
if [ -f "$REPORT_FILE" ]
then
	# must use env variable to pass the argument to the script because
	# -c doesn't pass arguments and -l would eat up all the following arguments, including files to open
	export REPORT_FILE
	NVIM_ARGS+=("-c" "source $SCRIPTPATH/show_report.lua")
fi

VENVPATH=$(get_config virtual_environment | tr --delete '\n\r')
ENVIRONMENT_VARIABLES=$(get_config environment | tr --delete '\r')
INIT_SCRIPT=$(get_config init_script | tr --delete '\r')
DATA_DIRECTORY=$(get_config data_directory | tr --delete '\n\r')

# commented out because there seems to be activity around these flags that broke the usecase with --listen only
# see:
#   https://github.com/neovim/neovim/issues/25706
#   https://github.com/neovim/neovim/issues/29634
#if [[ ${DATA_DIRECTORY:-} != "" ]]
#then
#	 PIPE="$DATA_DIRECTORY/nvim_server.pipe"
#fi
# uncomment this when/if nvim will add support for --remote-wait
# export GIT_EDITOR="nvim --server $PIPE --remote-wait"

for env_var in $ENVIRONMENT_VARIABLES
do
	var=$(echo "$env_var" | cut -d'=' -f 1)
	val=$(echo "$env_var" | cut -d'=' -f 2)
	export "$var"="$val"
done

[[ ${VENVPATH:-} != "" && -z "$VIRTUAL_ENV" ]] && source "$VENVPATH/bin/activate"

eval "$INIT_SCRIPT"

if ! echo "$@" | grep -- '--listen' && [[ ! -z "$PIPE" ]]
then
	NVIM_ARGS+=("--listen" "$PIPE")
fi

# arguments must be quoted so that shell expansion doesn't break quoting of arguments
# e.g. `nvim -c 'lua print("hello")'` without quotes around $@ would expand to separate
# arguments instead of 2, so it would be the equivalent of `nvim -c lua print("hello")`
# even if the argument was quoted correctly. Quoting $@ would expand the argument preserving
# the original quoting.
#
# For similar reasons build NVIM_ARGS with a bash array instead of just concatenating strings.
"$NVIM_BIN" "${NVIM_ARGS[@]}" "$@"
