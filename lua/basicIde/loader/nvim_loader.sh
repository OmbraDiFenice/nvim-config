#!/bin/bash

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

VENVPATH=$(lua "$SCRIPTPATH/project_venv.lua" "$PWD")
PIPE="$(nvim --headless -c 'GetDataDirectory' -c 'qa!' 2>&1)/nvim_server.pipe"
# uncomment this when/if nvim will add support for --remote-wait
# export GIT_EDITOR="nvim --server $PIPE --remote-wait"

[[ ${VENVPATH:-} != "" && -z "$VIRTUAL_ENV" ]] && source "$VENVPATH/bin/activate"
nvim --listen "$PIPE" $@
