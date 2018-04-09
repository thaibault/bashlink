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
# NOTE: This module is the only dependency of `bashlink.module` and so can not
# import any other modules to avoid a cyclic dependency graph.
# region variables
declare -gr bl_path__documentation__='
    The path module implements utility functions concerning path.
'
# endregion
# region functions
alias bl.path.convert_to_absolute=bl_path_convert_to_absolute
bl_path_convert_to_absolute() {
    local -r __documentation__='
        Converts given path into an absolute one.

        >>> bl.path.convert_to_absolute ./
        +bl.doctest.contains
        /
    '
    local -r path="$1"
    if [ -d "$path" ]; then
        pushd "$path" &>/dev/null || \
            return 1
        pwd
        popd &>/dev/null || \
            return 1
    else
        local -r file_name="$(basename "$path")"
        pushd "$(dirname "$path")" &>/dev/null || \
            return 1
        local absolute_path="$(pwd)"
        popd &>/dev/null || \
            return 1
        echo "${absolute_path}/${file_name}"
    fi
}
alias bl.path.convert_to_relative=bl_path_convert_to_relative
bl_path_convert_to_relative() {
    local -r __documentation__='
        Computes relative path from first given argument to second one.

        >>> bl.path.convert_to_relative /A/B/C /A
        ../..
        >>> bl.path.convert_to_relative /A/B/C /A/B
        ..
        >>> bl.path.convert_to_relative /A/B/C /A/B/C/D
        D
        >>> bl.path.convert_to_relative /A/B/C /A/B/C/D/E
        D/E
        >>> bl.path.convert_to_relative /A/B/C /A/B/D
        ../D
        >>> bl.path.convert_to_relative /A/B/C /A/B/D/E
        ../D/E
        >>> bl.path.convert_to_relative /A/B/C /A/D
        ../../D
        >>> bl.path.convert_to_relative /A/B/C /A/D/E
        ../../D/E
        >>> bl.path.convert_to_relative /A/B/C /D/E/F
        ../../../D/E/F
        >>> bl.path.convert_to_relative / /
        .
        >>> bl.path.convert_to_relative /A/B/C /A/B/C
        .
        >>> bl.path.convert_to_relative /A/B/C /
        ../../../
    '
    # both $1 and $2 are absolute paths beginning with /
    # returns relative path to $2/$target from $1/$source
    local -r source="$1"
    local -r target="$2"
    if [ "$source" = "$target" ]; then
        echo .
        return
    fi
    local common_part="$source"
    local result=''
    while [ "${target#$common_part}" = "${target}" ]; do
        # no match, means that candidate common part is not correct
        # go up one level (reduce common part)
        common_part="$(dirname "$common_part")"
        # and record that we went back, with correct / handling
        if [ "$result" = '' ]; then
            result=..
        else
            result="../$result"
        fi
    done
    if [ "$common_part" = / ]; then
        # special case for root (no common path)
        result="$result/"
    fi
    # since we now have identified the common part,
    # compute the non-common part
    local -r forward_part="${target#$common_part}"
    # and now stick all parts together
    if [[ "$result" != '' ]] && [[ "$forward_part" != '' ]]; then
        result="${result}${forward_part}"
    elif [[ "$forward_part" != '' ]]; then
        # extra slash removal
        result="${forward_part:1}"
    fi
    echo "$result"
}
alias bl.path.open=bl_path_open
bl_path_open() {
    local -r __documentation__='
        Opens a given path with a useful program.

        ```bash
            bl.path.open http://www.google.de
        ```

        ```bash
            bl.path.open file.text
        ```
    '
    local program
    for program in \
        gnome-open \
        kde-open \
        gvfs-open \
        exo-open \
        xdg-open \
        gedit \
        mousepad \
        gvim \
        vim \
        emacs \
        nano \
        vi \
        less \
        cat
    do
        if hash "$program" 2>/dev/null; then
            "$program" "$1"
            break
        fi
    done
}
alias bl.path.pack=bl_path_pack
bl_path_pack() {
    local -r __documentation__='
        Packs files in an archive.

        ```bash
            bl.path.pack archiv.zip /path/to/file.ext
        ```

        ```bash
            bl.path.pack archiv.zip /path/to/directory
        ```
    '
    if [ -d "$2" ] || [ -f "$2" ]; then
        local command
        case "$1" in
            *.tar.bz2|*.tbz2)
                command="tar --dereference --create --verbose --bzip2 --file \"$1\" \"$2\""
                ;;
            *.tar.gz|.*tgz)
                command="tar --dereference --create --verbose --gzip --file \"$1\" \"$2\""
                ;;
            *.bz2)
                command="bzip2 --stdout \"$2\" 1>\"$1\""
                ;;
            *.gz)
                if [ -d "$2" ]; then
                    command="gzip --recursive --stdout \"$2\" 1>\"$1\""
                else
                    command="gzip --stdout \"$2\" 1>\"$1\""
                fi
                ;;
            *.tar)
                command="tar --dereference --create --verbose --file \"$1\" \"$2\""
                ;;
            *.zip)
                if [ -d "$2" ]; then
                    command="zip --recurse-paths \"$1\" \"$2\""
                else
                    command="zip \"$1\" \"$2\""
                fi
                ;;
            *.Z)
                command="compress --stdout \"$2\" 1>\"$1\""
                ;;
            *.7z)
                command="7z a \"$1\" \"$2\""
                ;;
            *)
                echo "Cannot pack \"$1\"."
                return $?
        esac
        if [ "$command" ]; then
            echo "Running: [$command]."
            eval "$command"
            return $?
        fi
    else
        echo "\"$2\" is not a valid file or directory."
        return $?
    fi
}
alias bl.path.run_in_programs_location=bl_path_run_in_programs_location
bl_path_run_in_programs_location() {
    local -r __documentation__='
        Changes current working directory to given program path and runs the
        program.

        ```bash
            bl.path.run_in_programs_location /usr/bin/python3.2
        `
    '
    if [ "$1" ] && [ -f "$1" ]; then
        cd "$(dirname "$1")" && \
        "./$(basename "$1")" "$@"
        return $?
    fi
    echo Please insert a path to an executable file.
}
alias bl.path.unpack=bl_path_unpack
bl_path_unpack() {
    local -r __documentation__='
        Unpack archives in various formats.

        ```bash
            unpack path/to/archiv.zip`
        ```
    '
    if [ -f "$1" ]; then
        local command
        case "$1" in # switch
            *.tar.bz2|*.tbz2)
                command="tar --extract --verbose --bzip2 --file \"$1\""
                ;;
            *.tar.gz|*.tgz)
                command="tar --extract --verbose --gzip --file \"$1\""
                ;;
            *.bz2)
                command="bzip2 --decompress \"$1\""
                ;;
            *.rar)
                command="unrar x \"$1\""
                ;;
            *.gz)
                command="gzip --decompress \"$1\""
                ;;
            *.tar)
                command="tar --extract --verbose --file \"$1\""
                ;;
            *.zip)
                command="unzip -o \"$1\""
                ;;
            *.Z)
                command="compress -d \"$1\""
                ;;
            *.7z)
                7z x "$1"
                ;;
            *)
                echo  "Cannot extract \"$1\"."
                ;;
        esac
        if [ "$command" ]; then
            echo "Running: [$command]."
            eval "$command"
            return $?
        fi
    else
        echo "\"$1\" is not a valid file."
        return $?
    fi
}
# endregion
# region vim modline
# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
