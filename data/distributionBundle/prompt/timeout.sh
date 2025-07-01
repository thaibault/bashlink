#!/usr/bin/env bash
# -*- coding: utf-8 -*-
# region header
# Copyright Torben Sickert (info["~at~"]torben.website) 16.12.2012

# License
# -------

# This library written by Torben Sickert stand under a creative commons naming
# 3.0 unported license. see http://creativecommons.org/licenses/by/3.0/deed.de
# endregion
CURRENT_PATH="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/"

declare -gr BL_TIMEOUT__DOCUMENTATION__='
    This module produces a command prompt to be set as output for "$PS0".

    set_prompt() {
        local -i last_exit_code=$?

        # This is needed to avoid shadowing the return code via the variable
        # declaration.
        local prompt
        prompt="$("/PATH/TO/BASHLINK/prompt/timeout.sh" "$last_exit_code")"

        local timeout_result=$?
        if (( timeout_result = 124 )); then
            prompt="$(
                "/PATH/TO/BASHLINK/prompt/main.sh" --simple "$last_exit_code"
            )"
        fi

        export PS1="$prompt"
    }
    export PROMPT_COMMAND=set_prompt
'
declare -i TIMEOUT_IN_SECONDS=1

if [ "$BL_DOCTEST_MODULE_REFERENCE_UNDER_TEST" = '' ]; then
    timeout \
        --kill-after="$((TIMEOUT_IN_SECONDS * 3))" \
        "$TIMEOUT_IN_SECONDS" \
        "${CURRENT_PATH}main.sh" \
       "$@"
fi
# region vim modline
# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
