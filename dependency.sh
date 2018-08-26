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
bl.module.import bashlink.logging
# endregion
# region variables
declare -gr bl_dependency__documentation__='
    The dependency module implements utility functions to check current
    environment again needed assumptions.
'
# endregion
# region functions
alias bl.dependency.check=bl_dependency_check
bl_dependency_check() {
    local -r __documentation__='
        This function check if all given dependencies are present.

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
    if ! hash &>/dev/null; then
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
    local -r __documentation__='
        This function check if all given libraries can be found.

        >>> bl.dependency.check_shared_library libc.so; echo $?
        0
        >>> bl.dependency.check_shared_library libc.so __not_existing__ 1>/dev/null; echo $?
        2
        >>> bl.dependency.check_shared_library __not_existing__ 1>/dev/null; echo $?
        2
    '
    if ! bl.dependency.check pkg-config &>/dev/null; then
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
    local -r __documentation__='
        This function check if all given shared libraries can be found.

        >>> bl.dependency.check_shared_library libc.so; echo $?
        0
        >>> bl.dependency.check_shared_library libc.so __not_existing__ 1>/dev/null; echo $?
        2
        >>> bl.dependency.check_shared_library __not_existing__ 1>/dev/null; echo $?
        2
    '
    if ! bl.dependency.check ldconfig &>/dev/null; then
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

        >>> bl.dependency.determine_packages glibc 1>/dev/null; echo $?
        0
    '
    local package_name
    for package_name in "$@"; do
        local name
        for name in $(pacman --query --list --info "$package_name" | \
            grep --extended-regexp '^(Depends On)|(Hängt ab von)' | \
                sed --regexp-extended 's/[^:]+: (.+)$/\1/'
        ); do
            if ! [[ "$name" =~ ^(None)|(Nichts)$ ]]; then
                echo "$name"
                bl.dependency.determine_packages "$name"
            fi
        done
    done
}
alias bl.dependency.determine_files=bl_dependency_determine_files
bl_dependency_determine_files() {
    local -r __documentation__='
        Determines all needed files for given packages.

        >>> bl.dependency.determine_files glibc 1>/dev/null; echo $?
        0
    '
    if hash pacman &>/dev/null; then
        local name
        for name in "$@"; do
            local path
            pacman --query --list "$name" | while read path; do
                path="$(echo "$path" | \
                    sed --regexp-extended 's:^[^/]+ (/.+):\1:')"
                if ! [[ "$path" =~ .*/$ ]]; then
                    echo "$path"
                fi
            done
            for name in $(bl.dependency.determine_packages "$name"); do
                bl.dependency.determine_files \
                    "$(echo "$name" | \
                        sed --regexp-extended 's/[>=<]+.+$//')"
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
