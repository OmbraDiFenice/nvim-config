#!/usr/bin/zsh

local TITLE="\e]2;$*\a"
echo -n -e ${TITLE} > /proc/${LOADER_SHELL_PID}/fd/1
