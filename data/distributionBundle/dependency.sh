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
declare -gr BL_DEPENDENCY__DOCUMENTATION__='
    The dependency module implements utility functions to check current
    environment again needed assumptions.
'
# endregion
# region functions
alias bl.dependency.check=bl_dependency_check
bl_dependency_check() {
    local __documentation__='
        This function check if all given dependencies are present.
    '
    if hash &>/dev/null; then
        __documentation__+='
            >>> bl.dependency.check mkdir ls; echo $?
            0
            >>> bl.dependency.check mkdir __not_existing__ 1>/dev/null; echo $?
            2
            >>> bl.dependency.check __not_existing__ 1>/dev/null; echo $?
            2
            >>> bl.dependency.check ls __not_existing__; echo $?
            __not_existing__
            2
            >>> bl.dependency.check "ls __not_existing__"; echo $?
            ls __not_existing__
            2
        '
    else
        bl.logging.error \
            'Missing dependency "hash" to check for available executables.'

        return 1
    fi

    local -i return_code=0
    local dependency
    for dependency in "$@"; do
        if ! hash "$dependency" &>/dev/null; then
            return_code=2
            echo "$dependency"
        fi
    done

    return $return_code
}
alias bl.dependency.check_pkgconfig=bl_dependency_check_pkgconfig
bl_dependency_check_pkgconfig() {
    local __documentation__='
        This function check if all given libraries can be found.
    '
    if bl.dependency.check pkg-config &>/dev/null; then
        __documentation__+='
            >>> bl.dependency.check_shared_library libc.so; echo $?
            0
            >>> bl.dependency.check_shared_library libc.so __not_existing__ 1>/dev/null; echo $?
            2
            >>> bl.dependency.check_shared_library __not_existing__ 1>/dev/null; echo $?
            2
        '
    else
        bl.logging.error \
            'Missing dependency "pkg-config" to check for packages.'

        return 1
    fi

    local -i return_code=0
    local library
    for library in "$@"; do
        if ! pkg-config "$library" &>/dev/null; then
            return_code=2
            echo "$library"
        fi
    done

    return $return_code
}
alias bl.dependency.check_shared_library=bl_dependency_check_shared_library
bl_dependency_check_shared_library() {
    local __documentation__='
        This function check if all given shared libraries can be found.
    '
    if bl.dependency.check ldconfig &>/dev/null; then
        __documentation__+='
            >>> bl.dependency.check_shared_library libc.so; echo $?
            0
            >>> bl.dependency.check_shared_library libc.so __not_existing__ 1>/dev/null; echo $?
            2
            >>> bl.dependency.check_shared_library __not_existing__ 1>/dev/null; echo $?
            2
        '
    else
        bl.logging.error \
            Missing dependency \"ldconfig\" to check for shared libraries.

        return 1
    fi

    local -i return_code=0
    local pattern
    for pattern in "$@"; do
        if ! ldconfig --print-cache | cut --fields 1 --delimiter ' ' | \
            command grep "$pattern" &>/dev/null
        then
            return_code=2
            echo "$pattern"
        fi
    done

    return $return_code
}
# TODO remove redundant artefacts.
alias bl.dependency.determine_packages=bl_dependency_determine_packages
bl_dependency_determine_packages() {
    local -r __documentation__='
        Determines all needed packages for given packages.

        >>> ! hash pacman &>/dev/null || bl.dependency.determine_packages glibc 1>/dev/null; echo $?
        0
    '
    if [[ "$1" == /* ]]; then
        local -r parsed_file_path="$1"
        shift
    else
        local -r parsed_file_path="$(
            mktemp --suffix -bashlink-dependency-determine-packages-ignore)"
    fi
    local package_name
    for package_name in "$@"; do
        local name
        for name in $(command pacman --query --list --info "$package_name" | \
            command grep --extended-regexp '^(Depends On)|(Hängt ab von)' | \
                command sed --regexp-extended 's/[^:]+: (.+)$/\1/'
        ); do
            if \
                ! [[ "$name" =~ ^(None)|(Nichts)$ ]] && \
                ! command grep "$name" "$parsed_file_path" &>/dev/null
            then
                echo "$name" >>"$parsed_file_path"
                echo "$name"
                bl.dependency.determine_packages "$parsed_file_path" "$name"
            fi
        done
    done
}
alias bl.dependency.determine_files=bl_dependency_determine_files
bl_dependency_determine_files() {
    local -r __documentation__='
        Determines all needed files for given packages.

        >>> ! hash pacman &>/dev/null || bl.dependency.determine_files glibc 1>/dev/null; echo $?
        0
    '
    if [[ "$1" == /* ]]; then
        local -r parsed_file_path="$1"
        shift
    else
        local -r parsed_file_path="$(
            mktemp \
                --suffix \
                -bashlink-dependency-determine-files-packages-ignore)"
    fi
    if hash pacman &>/dev/null; then
        local name
        for name in "$@"; do
            local path
            command pacman --query --list "$name" | while read -r path; do
                path="$(echo "$path" | \
                    command sed --regexp-extended 's:^[^/]+ (/.+):\1:')"
                if ! [[ "$path" =~ .*/$ ]]; then
                    echo "$path"
                fi
            done
            local file_name
            for file_name in $(
                bl.dependency.determine_packages "$parsed_file_path" "$name"
            ); do
                bl.dependency.determine_files \
                    "$parsed_file_path" \
                    "$(echo "$file_name" | \
                        command sed --regexp-extended 's/[>=<]+.+$//')"
            done
        done
    else
        bl.logging.error No supported package manager found to determine files.
    fi
}
# endregion
# region vim modline
# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
