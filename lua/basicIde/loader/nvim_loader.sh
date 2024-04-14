#!/bin/bash

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
PROJECT_ROOT="$PWD"
NVIM_ARGS=""

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
	cat "$LUA_SCRIPT_FILE" | nvim --clean -n -i NONE -l - $@ 2>&1
}

# Convenience function to get data from the project configuration
function get_config() {
	local CONFIG="$1"
	nlua "$SCRIPTPATH/read_project_config.lua" "$PROJECT_ROOT" "$CONFIG"
}

VENVPATH=$(get_config virtual_environment | tr --delete '\n\r')
ENVIRONMENT_VARIABLES=$(get_config environment)
INIT_SCRIPT=$(get_config init_script | tr --delete '\r')
DATA_DIRECTORY=$(get_config data_directory | tr --delete '\n\r')
if [[ ${DATA_DIRECTORY:-} != "" ]]
then
	PIPE="$DATA_DIRECTORY/nvim_server.pipe"
fi
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
	NVIM_ARGS="$NVIM_ARGS --listen '$PIPE'"
fi
nvim $NVIM_ARGS $@
