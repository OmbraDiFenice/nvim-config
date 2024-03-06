#!/bin/bash

# Uses nvim as lua interpreter for the given script file.
# The script can take optional arguments.
# This will solve problems related to the version of lua installed on the system:
# now this script only depends on the version of lua embedded in the nvim executable being used
function nlua() {
	local LUA_SCRIPT_FILE="$1"
	shift
	# nvim -l prints on stderr, see https://github.com/neovim/neovim/issues/27084
	# Also, the output needs to be stripped of newline and carriage return characters.
	# This works fine here, but might be not what we want if the output is expected to contain newlines.
	# See https://stackoverflow.com/questions/12524308/bash-strip-trailing-linebreak-from-output for alternatives
	cat "$LUA_SCRIPT_FILE" | nvim --clean -n -i NONE -l - $@ 2>&1 | tr -d '\n\r'
}

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

VENVPATH=$(nlua "$SCRIPTPATH/project_venv.lua" "$PWD")
PIPE="$(nvim --headless -c 'GetDataDirectory' -c 'qa!' 2>&1)/nvim_server.pipe"
# uncomment this when/if nvim will add support for --remote-wait
# export GIT_EDITOR="nvim --server $PIPE --remote-wait"

[[ ${VENVPATH:-} != "" && -z "$VIRTUAL_ENV" ]] && source "$VENVPATH/bin/activate"
nvim --listen "$PIPE" $@
