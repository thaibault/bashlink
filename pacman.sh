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
bl.module.import bashlink.number
# endregion
# region variables
declare -gr bl_pacman__documentation__='
    This module implements utility functions concerning the package manager
    `pacman`.
'
# endregion
# region functions
alias bl.pacman.show_config_backups=bl_pacman_show_config_backups
bl_pacman_show_config_backups() {
    local -r __documentation__='
        Shows all config backups created by pacman.

        ```bash
            bl.pacman.show_config_backups
        ```
    '
    pushd / 1>/dev/null && \
    local pattern
    for pattern in '*.pacnew' '*.orig' '*_backup*' '*.pacorig'; do
        sudo command find -name "$pattern" -and \( -type f -or -type l -or -type d \)
    done
    # shellcheck disable=SC2164
    popd 1>/dev/null
}
alias bl.pacman.show_not_maintained_by_pacman_system_files=bl_tools_show_not_maintained_by_pacman_system_files
bl_pacman_show_not_maintained_by_pacman_system_files() {
    local -r __documentation__='
        Shows all files which are not maintained by pacman on currently running
        system.

        ```bash
            bl.pacman.show_not_maintained_by_pacman_system_file
        ```
    '
    local -r paths_file_path="$(mktemp --suffix -bashlink-pacman-file-paths)"
    local -r maintained_paths_file_path="$(
        mktemp --suffix -bashlink-pacman-maintained-file-paths)"
    sudo command find / | \
        sort | \
            command sed 's:/$::g' | \
                sort | \
                    uniq 1>"$paths_file_path"
    pacman --query --list --quiet | \
        command sed 's:/$::g' | \
            sort | \
                uniq 1>"$maintained_paths_file_path"
    bl.logging.cat "$paths_file_path" "$maintained_paths_file_path" | \
        command sed 's:^/home/.*$::g' | \
        command sed 's:^/root/.*$::g' | \
        command sed 's:^/dev/.*$::g' | \
        command sed 's:^/sys/.*$::g' | \
        command sed 's:^/tmp/.*$::g' | \
        command sed 's:^/run/.*$::g' | \
        command sed 's:^/var/tmp/.*$::g' | \
        command sed 's:^/var/cache/.*$::g' | \
        command sed 's:^/var/log/.*$::g' | \
        command sed 's:^/proc/.*$::g' | \
        sort | \
        uniq --unique
    local -ir number_of_files=$(
        wc --lines "$paths_file_path" | \
            cut --delimiter ' ' --field 1)
    local -ir number_of_maintained_files=$(
        wc --lines "$maintained_paths_file_path" | \
            cut --delimiter ' ' --field 1)
    rm "$paths_file_path"
    rm "$maintained_paths_file_path"
    local -i number_of_not_maintained_files
    (( number_of_not_maintained_files=(( number_of_files - number_of_maintained_files )) ))
    # shellcheck disable=SC2086
    bl.logging.cat << EOF

Number of files: $number_of_files 100%
Number of maintained files: $number_of_maintained_files $(bl.number.calculate_percent $number_of_files $number_of_maintained_files)%
Number of not maintained files: $number_of_not_maintained_files $(bl.number.calculate_percent $number_of_files $number_of_not_maintained_files)%
EOF
}
# endregion
# region vim modline
# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
