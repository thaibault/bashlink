#!/usr/bin/env bash
# -*- coding: utf-8 -*-
# region header
# Copyright Torben Sickert (info["~at~"]torben.website) 16.12.2012

# License
# -------

# This library written by Torben Sickert stand under a creative commons naming
# 3.0 unported license. see http://creativecommons.org/licenses/by/3.0/deed.de
# endregion
# shellcheck source=../module.sh
source "$(dirname "${BASH_SOURCE[0]}")/../module.sh"
bl.module.import bashlink.string
bl.module.import bashlink.tools

declare -gr BL_MAIN__DOCUMENTATION__='
    This module produces a command prompt to be set as output for "$PS0":

    set_prompt() {
        local -i last_exit_code=$?

        # This is needed to avoid shadowing the return code via the variable
        # declaration.
        local prompt
        prompt="$("/PATH/TO/BASHLINK/prompt/main.sh" "$last_exit_code")"

        export PS1="$prompt"
    }
    export PROMPT_COMMAND=set_prompt
'

if bl.tools.is_main; then
    bl.string.make_command_prompt_prefix "$@"
fi
# region vim modline
# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
