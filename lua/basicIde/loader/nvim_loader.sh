#!/bin/bash

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

VENVPATH=$(lua "$SCRIPTPATH/project_venv.lua" "$PWD")

[[ ${VENVPATH:-} != "" && -z "$VIRTUAL_ENV" ]] && source "$VENVPATH/bin/activate"
nvim $@
