#!/usr/bin/env bash
# -*- coding: utf-8 -*-
# region header
# Copyright Torben Sickert (info["~at~"]torben.website) 16.12.2012

# License
# -------

# This library written by Torben Sickert stand under a creative commons naming
# 3.0 unported license. see http://creativecommons.org/licenses/by/3.0/deed.de
# endregion
# shellcheck disable=SC2016,SC2034,SC2155
# region import
# shellcheck source=./module.sh
source "$(dirname "${BASH_SOURCE[0]}")/module.sh"
bl.module.import bashlink.exception
# NOTE: We need to import logging to active alternate output file descriptors.
bl.module.import bashlink.logging
# endregion
# region variables
declare -gr bl_ui__documentation__='
    This module provides helper methods to use low level graphical interfaces.
'
declare -agr bl_ui__dependencies__=(dialog)
# endregion
# region functions
alias bl.ui.dialog=bl_ui_dialog
bl_ui_dialog() {
    # shellcheck disable=SC1004
    local -r __documentation__='
        Shows a dialog box. Forwards all given parameter to dialog.

        ```
            bl.ui.dialog \
                --clear \
                --insecure \
                --title Password \
                --passwordbox "" 0 0
        ```
    '
    local -i return_code
    local -r output_buffer_file_path="$(mktemp --suffix -bashlink-ui-input)"
    bl.exception.try
    {
        dialog "$@" 1>&5 2>"$output_buffer_file_path"
        return_code=$?
        cat "$output_buffer_file_path"
    }
    bl.exception.catch_single
    {
        rm --force "$output_buffer_file_path"
        # shellcheck disable=SC2086,SC2154
        return $bl_exception_return_code
    }
    rm --force "$output_buffer_file_path"
    return $return_code
}
alias bl.ui.input_password=bl_ui_input_password
bl_ui_input_password() {
    # shellcheck disable=SC1004
    local -r __documentation__='
        Shows a password input dialog box. Forwards all given parameter to
        dialog.

        ```
            bl.ui.input_password >/plain_password.txt
        ```

        ```
            bl.ui.input_password "Give me a password" >/plain_password.txt
        ```
    '
    local title=Password
    if [[ "$1" != '' ]]; then
        title="$1"
    fi
    bl.ui.dialog --clear --insecure --title "$title" --passwordbox '' 0 0
}
alias bl.ui.input_text='bl.ui.dialog --clear --inputbox RZ-Login 0 0'
alias bl.ui.input_text=bl_ui_input_text
bl_ui_input_text() {
    # shellcheck disable=SC1004
    local -r __documentation__='
        Shows a text input dialog box. Forwards all given parameter to dialog.

        ```
            bl.ui.input_text "Give me a your name" >/input.txt
        ```
    '
    local title=Login
    if [[ "$1" != '' ]]; then
        title="$1"
    fi
    bl.ui.dialog --clear --inputbox "$title" 0 0
}
# endregion
# region vim modline
# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
