#!/usr/bin/env bash
# -*- coding: utf-8 -*-
# region header
# Copyright Torben Sickert (info["~at~"]torben.website) 16.12.2012

# License
# -------

# This library written by Torben Sickert stand under a creative commons naming
# 3.0 unported license. See https://creativecommons.org/licenses/by/3.0/deed.de
# endregion
# shellcheck disable=SC2016,SC2034,SC2155
# region import
# shellcheck source=./globals.sh
# shellcheck source=./module.sh
source "$(dirname "${BASH_SOURCE[0]}")/module.sh"
bl.module.import bashlink.globals
bl.module.import bashlink.logging
# endregion
# region variables
declare -gr bl_ssh__documentation__='
    This module implements utility functions concerning ssh connections.
'
# endregion
# region functions
alias bl.ssh.make_key=bl_ssh_make_key
bl_ssh_make_key() {
    local -r __documentation__='
    Generates a new ssh key.

    ```
        bl.ssh.make_key
        bl.ssh.make_key hans
    ```
    '
    local user="$bl_globals_user_e_mail_address"
    if [ "$1" ]; then
        user="$1"
    fi
    ssh-keygen -t rsa -C "$user"
}
alias bl.ssh.print=bl_ssh_print
bl_ssh_print() {
    local -r __documentation__='
        Prints a file via ssh. A given printable file will be sent to a given
        location via scp. The file be stored in remotes home directory with
        given name. After this procedure a remote print order will be sent.

        ```bash
            bl.ssh.print /home/hans/document.txt
        ```

        ```bash
            bl.ssh.print /home/hans/document.txt hans
        ```

        ```bash
            bl.ssh.print /home/hans/document.txt hans hp15
        ```
    '
    local user=sickertt
    local host=login.informatik.uni-freiburg.de
    local default_printer=hp15
    local usage_message="Usage: $0 <file> [login] [printer] [withFileContentPipe]"
    if (( $# = 0 )); then
        bl.logging.plain "$usage_message"
    # 1. argument: File, which we want to print.
    elif [ -f "$1" ]; then
        # 2. argument: Check for given user name.
        if [[ $# -ge 2 ]]; then
            local login="${2}${host}"
        elif [ "$user" ]; then
            local login="${user}@${host}"
        else
            # Grab user from "~/.ssh/config".
            local user_row="$(
                command grep "$host" -A1 ~/.ssh/config | \
                command grep -i user)"
            if [[ "$user_row" != '' ]]; then
                # shellcheck disable=SC2001
                local user="$(
                    echo "$user_row" | \
                        command sed s/user\\s//ig)"
                local login="${user}@${host}"
            else
                bl.logging.plain No login given.
                bl.logging.plain "$usage_message"
            fi
        fi
        # 3. argument: Select printer.
        local printer="$default_printer"
        if [ "$3" ]; then
            local printer="$3"
        fi
        # 4. argument: Determines which way to use for transport file content.
        if [ "$4" ]; then
            bl.logging.info Pipe file content through ssh.
            ssh "$login" lpr -P"$printer" < "$1"
            return $?
        else
            bl.logging.info "Copy file to server via scp ($login)."
            scp "$1" "${login}:/tmp/.sshPrint"
            ssh "$login" lpr -P"$printer" ~/.sshPrint
            return $?
        fi
    else
        bl.logging.error "Given file \"$1\" doesn't exist."
        return 1
    fi
}
alias bl.ssh.screen=bl_ssh_screen
bl_ssh_screen() {
    local -r __documentation__='
        Wraps the ssh client for automatically starting a screen session on
        server.

        ```bash
            bl.ssh.screen user@host [SSH_OPTIONS]
        ```
    '
    # shellcheck disable=SC2029
    ssh "$1" -t 'screen -r || screen -S main' "${@:2}"
}
# endregion
# region vim modline
# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
