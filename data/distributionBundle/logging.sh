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
# shellcheck source=./arguments.sh
# shellcheck source=./cli.sh
# shellcheck source=./module.sh
source "$(dirname "${BASH_SOURCE[0]}")/module.sh"
bl.module.import bashlink.arguments
bl.module.import bashlink.array
bl.module.import bashlink.cli
# endregion
# region variables
bl_logging__documentation__='
    The available log levels are:
    error critical warn info debug

    The standard loglevel is critical
    >>> bl.logging.get_level
    >>> bl.logging.get_commands_level
    critical
    critical

    >>> bl.logging.error error-message
    >>> bl.logging.critical critical-message
    >>> bl.logging.warn warn-message
    >>> bl.logging.info info-message
    >>> bl.logging.debug debug-message
    +bl.doctest.multiline_contains
    error-message
    critical-message

    If the output of commands should be printed, the commands_level needs to be
    greater than or equal to the log_level.

    >>> bl.logging.set_level critical
    >>> bl.logging.set_commands_level debug
    >>> echo foo

    >>> bl.logging.set_level info
    >>> bl.logging.set_commands_level info
    >>> echo foo
    foo

    Another logging prefix can be set by overriding "bl_logging_get_prefix".

    >>> bl_logging_get_prefix() {
    >>>     local level=$1
    >>>     echo "[myprefix - ${level}]"
    >>> }
    >>> bl.logging.critical foo
    [myprefix - critical] foo
'
bl_logging_commands_output_saved=std
bl_logging_commands_tee_fifo_active=false
bl_logging_file_descriptors_saved=false
# logging levels from low to high
bl_logging_levels=(
    error
    critical
    warning
    info
    verbose
    debug
)
# matches the order of logging levels
bl_logging_levels_color=(
    "$bl_cli_color_red"
    "$bl_cli_color_magenta"
    "$bl_cli_color_yellow"
    "$bl_cli_color_cyan"
    "$bl_cli_color_green"
    "$bl_cli_color_blue"
)
bl_logging_commands_level=$(bl.array.get_index critical "${bl_logging_levels[@]}")
bl_logging_level=$(bl.array.get_index critical "${bl_logging_levels[@]}")
bl_logging_log_file_path=''
bl_logging_off=false
bl_logging_options_log=std
bl_logging_options_command=std
bl_logging_output_to_saved_file_descriptors=false
bl_logging_tee_fifo=''
bl_logging_tee_fifo_path=''
bl_logging_tee_fifo_active=false
# endregion
# region functions
alias bl.logging.cat=bl_logging_cat
bl_logging_cat() {
    local __documentation__='
        "bl.logging.cat" can be used to print files
        (e.g "bl.logging.cat < file.txt") or heredocs. Like "bl.logging.plain",
        it also prints at any log level and without the prefix.

        >>> echo foo | bl.logging.cat
        foo
    '
    $bl_logging_off && return 0
    if [[ "$bl_logging_log_file_path" != '' ]]; then
        cat "$@" >> "$bl_logging_log_file_path"
        if $bl_logging_tee_fifo_active; then
            cat "$@"
        fi
    elif $bl_logging_output_to_saved_file_descriptors; then
        cat "$@" 1>&3 2>&4
    else
        cat "$@"
    fi
}
alias bl.logging.get_commands_level=bl_logging_get_commands_level
bl_logging_get_commands_level() {
    local __documentation__='
        Retrieves current command output level.

        >>> bl.logging.set_commands_level critical
        >>> bl.logging.get_commands_level
        critical
    '
    echo "${bl_logging_levels[$bl_logging_commands_level]}"
}
alias bl.logging.get_level=bl_logging_get_level
bl_logging_get_level() {
    local __documentation__='
        Retrieves current logging level.

        >>> bl.logging.set_level critical
        >>> bl.logging.get_level
        critical
    '
    echo "${bl_logging_levels[$bl_logging_level]}"
}
alias bl.logging.get_prefix=bl_logging_get_prefix
bl_logging_get_prefix() {
    local __documentation__='
        Determines logging prefix string.

        >>> bl.cli.disable_color
        >>> bl.logging.get_prefix critical 1
        \033[0;35mcritical:63:14:
    '
    local level=$1
    local level_index=$2
    local color=${bl_logging_levels_color[$level_index]}
    # shellcheck disable=SC2154
    local loglevel=${color}${level}${bl_cli_color_default}
    local path="${BASH_SOURCE[2]##./}"
    path="${path%.sh}"
    # shellcheck disable=SC2154
    echo "${loglevel}:${bl_cli_color_light_gray}$(basename "$path")${bl_cli_color_default}:${bl_cli_color_light_cyan}${BASH_LINENO[1]}${bl_cli_color_default}:"
}
alias bl.logging.plain_raw=bl_logging_plain_raw
bl_logging_plain_raw() {
    local __documentation__='
        "bl.logging.plain" can be used to print at any log level and without
        prefix.

        >>> bl.logging.set_level critical
        >>> bl.logging.set_commands_level debug
        >>> bl.logging.plain_raw foo
        foo

        >>> bl.logging.set_level info
        >>> bl.logging.set_commands_level debug
        >>> bl.logging.debug "not shown"
        >>> echo "not shown"
        >>> bl.logging.plain_raw "shown"
        shown
    '
    $bl_logging_off && return 0
    if [[ "$bl_logging_log_file_path" != '' ]]; then
        echo "$@" >> "$bl_logging_log_file_path"
        if $bl_logging_tee_fifo_active; then
            echo "$@"
        fi
    elif $bl_logging_output_to_saved_file_descriptors; then
        echo "$@" 1>&3 2>&4
    else
        echo "$@"
    fi
}
alias bl.logging.plain=bl_logging_plain
bl_logging_plain() {
    local __documentation__='
        "bl.logging.plain" can be used to print string in evaluated
        representation at any log level and without prefix.

        >>> bl.logging.set_level critical
        >>> bl.logging.set_commands_level debug
        >>> bl.logging.plain foo
        foo

        >>> bl.logging.set_level info
        >>> bl.logging.set_commands_level debug
        >>> bl.logging.debug "not shown"
        >>> echo "not shown"
        >>> bl.logging.plain "shown"
        shown
    '
    bl_logging_plain_raw -e "$@"
}
# NOTE: Depends on "bl.logging.plain"
alias bl.logging.log=bl_logging_log
bl_logging_log() {
    local __documentation__='
        Main logging function which will be wrapped from each level specific
        logging function.

        >>> bl.logging.log critical test
        +bl.doctest.contains
        critical

        >>> bl.logging.log critical test
        +bl.doctest.contains
        test

        >>> bl.logging.log not_existing_level test
        +bl.doctest.contains
        Given logging level "not_existing_level" is not available
    '
    local level="$1"
    if [ "$level" = warn ]; then
        level=warning
    fi
    shift
    local level_index=$(bl.array.get_index "$level" "${bl_logging_levels[@]}")
    if [ "$level_index" -eq -1 ]; then
        bl.logging.log \
            critical \
            "Given logging level \"$level\" is not available, use one of:" \
            "${bl_logging_levels[*]} or warn"
        return 1
    fi
    if [ "$bl_logging_level" -ge "$level_index" ]; then
        bl.logging.plain "$(bl_logging_get_prefix "$level" "$level_index")" "$@"
    fi
}
alias bl.logging.critical='bl_logging_log critical'
alias bl.logging.debug='bl_logging_log debug'
alias bl.logging.error='bl_logging_log error'
alias bl.logging.info='bl_logging_log info'
alias bl.logging.verbose='bl_logging_log verbose'
alias bl.logging.warn='bl_logging_log warn'
alias bl.logging.warning=bl.logging.warn
alias bl.logging.set_file_descriptors=bl_logging_set_file_descriptors
bl_logging_set_file_descriptors() {
    # shellcheck disable=SC1004
    local __documentation__='
        >>> local test_file="$(mktemp)"
        >>> bl.logging.plain "test_file:" >"$test_file"
        >>> bl.logging.set_file_descriptors ""
        >>> bl.logging.cat "$test_file"
        >>> rm "$test_file"
        test_file:

        >>> local test_file="$(mktemp)"
        >>> bl.logging.set_file_descriptors "$test_file"
        >>> bl.logging.set_file_descriptors ""
        >>> echo "test_file:" >"$test_file"
        >>> bl.logging.cat "$test_file"
        >>> rm "$test_file"
        test_file:

        >>> local test_file="$(mktemp)"
        >>> bl.logging.set_file_descriptors "$test_file" --logging=tee
        >>> bl.logging.plain foo
        >>> bl.logging.set_file_descriptors ""
        >>> bl.logging.cat "$test_file"
        >>> rm "$test_file"
        foo
        foo

        >>> echo "$test_file"

        >>> local test_file="$(mktemp)"
        >>> bl.logging.set_file_descriptors "$test_file" --logging=off --commands=file
        >>> bl.logging.plain not shown
        >>> echo foo
        >>> bl.logging.set_file_descriptors ""
        >>> bl.logging.cat "$test_file"
        >>> rm "$test_file"
        foo

        >>> local test_file="$(mktemp)"
        >>> bl.logging.set_file_descriptors "$test_file" --logging=off
        >>> bl.logging.plain not shown
        >>> echo foo
        >>> bl.logging.set_file_descriptors ""
        >>> bl.logging.cat "$test_file"
        >>> rm "$test_file"
        foo

        >>> local test_file="$(mktemp)"
        >>> bl.logging.set_file_descriptors "$test_file" --commands=tee
        >>> bl.logging.plain logging
        >>> echo echo
        >>> bl.logging.set_file_descriptors ""
        >>> bl.logging.cat "$test_file"
        >>> rm "$test_file"
        logging
        echo
        echo

        >>> local test_file="$(mktemp)"
        >>> bl.logging.set_file_descriptors "$test_file" --commands=file
        >>> bl.logging.plain logging
        >>> echo echo
        >>> bl.logging.set_file_descriptors ""
        >>> bl.logging.cat "$test_file"
        >>> rm "$test_file"
        logging
        echo

        >>> local test_file="$(mktemp)"
        >>> bl.logging.set_file_descriptors "$test_file" --logging=file --commands=file
        >>> bl.logging.plain logging
        >>> echo echo
        >>> bl.logging.set_file_descriptors ""
        >>> bl.logging.cat "$test_file"
        >>> rm "$test_file"
        logging
        echo

        >>> local test_file="$(mktemp)"
        >>> bl.logging.set_file_descriptors "$test_file" --logging=file --commands=file
        >>> bl.logging.plain logging
        >>> echo echo
        >>> bl.logging.set_file_descriptors ""
        >>> bl.logging.cat "$test_file"
        >>> rm "$test_file"
        logging
        echo

        >>> local test_file="$(mktemp)"
        >>> bl.logging.set_file_descriptors "$test_file" --logging=file --commands=tee
        >>> bl.logging.plain logging
        >>> echo echo
        >>> bl.logging.set_file_descriptors ""
        >>> bl.logging.cat "$test_file"
        >>> rm "$test_file"
        echo
        logging
        echo

        >>> local test_file="$(mktemp)"
        >>> bl.logging.set_file_descriptors "$test_file" --logging=file --commands=off
        >>> bl.logging.plain logging
        >>> echo echo
        >>> bl.logging.set_file_descriptors ""
        >>> bl.logging.cat "$test_file"
        >>> rm "$test_file"
        logging

        >>> local test_file="$(mktemp)"
        >>> bl.logging.set_file_descriptors "$test_file" --logging=tee --commands=tee
        >>> bl.logging.plain logging
        >>> echo echo
        >>> bl.logging.set_file_descriptors ""
        >>> bl.logging.cat "$test_file"
        >>> rm "$test_file"
        logging
        echo
        logging
        echo

        Test exit handler

        >>> local test_file fifo
        >>> test_file="$(mktemp)"
        >>> fifo=$(bl.logging.set_file_descriptors "$test_file" --commands=tee; \
        >>>    echo $bl.logging.tee_fifo)
        >>> [ -p "$fifo" ] || echo fifo deleted
        >>> rm "$test_file"
        fifo deleted
    '
    bl.arguments.set "$@"
    # Must be one off "std", "off", "tee" or "file".
    local options_log options_command
    bl.arguments.get_keyword --commands options_command
    bl.arguments.get_keyword --logging options_log
    [[ "${options_command-}" == '' ]] && options_command=std
    [[ "${options_log-}" == '' ]] && options_log=std
    bl_logging_options_command="$options_command"
    bl_logging_options_log="$options_log"
    set -- "${bl_arguments_new[@]:-}"
    local log_file_path="$1"
    bl_logging_off=false
    # restore
    if $bl_logging_file_descriptors_saved; then
        exec 1>&3 2>&4 3>&- 4>&-
        bl_logging_file_descriptors_saved=false
    fi
    [ -p "$bl_logging_tee_fifo" ] && rm -rf "$bl_logging_tee_fifo_path"
    bl_logging_commands_tee_fifo_active=false
    bl_logging_tee_fifo_active=false
    bl_logging_output_to_saved_file_descriptors=false
    if [ "$log_file_path" = '' ]; then
        bl_logging_log_file_path=''
        [ "$bl_logging_options_log" = tee ] && return 1
        [ "$bl_logging_options_command" = tee ] && return 1
        if [ "$bl_logging_options_log" = off ]; then
            bl_logging_off=true
        fi
        if [ "$bl_logging_options_command" = off ]; then
            exec 3>&1 4>&2
            bl_logging_file_descriptors_saved=true
            exec &>/dev/null
            bl_logging_output_to_saved_file_descriptors=true
        fi
        return 0
    fi
    # It's guaranteed that we have a log file from here on.
    if ! $bl_logging_file_descriptors_saved; then
        # save /dev/stdout and /dev/stderr to &3, &4
        exec 3>&1 4>&2
        bl_logging_file_descriptors_saved=true
    fi
    if [ "$bl_logging_options_log" = tee ]; then
        if [ "$bl_logging_options_command" != tee ]; then
            bl_logging_log_file_path="$log_file_path"
            bl_logging_tee_fifo_active=true
        fi
    elif [ "$bl_logging_options_log" = stdout ]; then
        true
    elif [ "$bl_logging_options_log" = file ]; then
        bl_logging_log_file_path="$log_file_path"
    elif [ "$bl_logging_options_log" = off ]; then
        bl_logging_off=true
    fi
    if [ "$bl_logging_options_command" = tee ]; then
        bl_logging_tee_fifo_path="$(
            mktemp --directory bashlink-logging-fifo-XXX)"
        bl_logging_tee_fifo="$bl_logging_tee_fifo_path/fifo"
        mkfifo "$bl_logging_tee_fifo"
        trap '[ -p "$bl_logging_tee_fifo" ] && rm -rf "$bl_logging_tee_fifo_path"; exit' EXIT
        tee --append "$log_file_path" <"$bl_logging_tee_fifo" &
        exec 1>>"$bl_logging_tee_fifo" 2>>"$bl_logging_tee_fifo"
        bl_logging_commands_tee_fifo_active=true
        if [[ "$bl_logging_options_log" != tee ]]; then
            bl_logging_output_to_saved_file_descriptors=true
        fi
    elif [ "$bl_logging_options_command" = stdout ]; then
        true
    elif [ "$bl_logging_options_command" = file ]; then
        exec 1>>"$log_file_path" 2>>"$log_file_path"
        bl_logging_output_to_saved_file_descriptors=true
    elif [ "$bl_logging_options_command" = off ]; then
        exec 1>>/dev/null 2>>/dev/null
    fi
}
# NOTE: Depends on "bl.logging.set_file_descriptors"
alias bl.logging.set_command_output_off=bl_logging_set_command_output_off
bl_logging_set_command_output_off() {
    local __documentation__='
        Disables each command output.

        >>> bl.logging.set_command_output_off
        >>> echo test
    '
    bl_logging_commands_output_saved="$bl_logging_options_command"
    bl.logging.set_file_descriptors \
        "$bl_logging_log_file_path" \
        --logging="$bl_logging_options_log" \
        --commands=off
}
# NOTE: Depends on "bl.logging.set_file_descriptors"
alias bl.logging.set_command_output_on=bl_logging_set_command_output_on
bl_logging_set_command_output_on() {
    local __documentation__='
        Enables each command output.

        >>> bl.logging.set_command_output_on
        >>> echo test
        test
    '
    bl.logging.set_file_descriptors \
        "$bl_logging_log_file_path" \
        --logging="$bl_logging_options_log" \
        --commands=std
}
# NOTE: Depends on "bl.logging.set_command_output_on", bl.logging.set_command_output_off"
alias bl.logging.set_commands_level=bl_logging_set_commands_level
bl_logging_set_commands_level() {
    local __documentation__='
        Enables each command output.

        >>> bl.logging.set_commands_level critical
        >>> bl.logging.set_level critical
        >>> echo test
        test
        >>> bl.logging.set_commands_level warning
        >>> echo test
    '
    local level="$1"
    if [ "$level" = warn ]; then
        level=warning
    fi
    bl_logging_commands_level=$(
        bl.array.get_index "$level" "${bl_logging_levels[@]}")
    if [ "$bl_logging_level" -ge "$bl_logging_commands_level" ]; then
        bl.logging.set_command_output_on
    else
        bl.logging.set_command_output_off
    fi
}
alias bl.logging.set_level=bl_logging_set_level
bl_logging_set_level() {
    local __documentation__='
        >>> bl.logging.set_commands_level info
        >>> bl.logging.set_level info
        >>> echo $bl_logging_level
        >>> echo $bl_logging_commands_level
        3
        3
    '
    local level="$1"
    if [ "$level" = warn ]; then
        level=warning
    fi
    bl_logging_level=$(bl.array.get_index "$level" "${bl_logging_levels[@]}")
    if (( bl_logging_level >= bl_logging_commands_level )); then
        bl.logging.set_command_output_on
    else
        bl.logging.set_command_output_off
    fi
}
alias bl.logging.set_log_file=bl_logging_set_log_file
bl_logging_set_log_file() {
    local __documentation__='
        >>> local test_file_path="$(mktemp)"
        >>> bl.logging.set_log_file "$test_file_path"
        >>> bl.logging.plain logging
        >>> echo echo
        >>> bl.logging.set_log_file ""
        >>> bl.logging.cat "$test_file_path"
        >>> rm "$test_file_path"
        logging
        echo
        logging
        echo

        >>> bl.logging.set_commands_level debug
        >>> bl.logging.set_level debug
        >>> local test_file_path="$(mktemp)"
        >>> bl.logging.set_log_file "$test_file_path"
        >>> bl.logging.plain 1
        >>> bl.logging.set_log_file ""
        >>> bl.logging.set_log_file "$test_file_path"
        >>> bl.logging.plain 2
        >>> bl.logging.set_log_file ""
        >>> bl.logging.cat "$test_file_path"
        >>> rm "$test_file_path"
        1
        2
        1
        2
    '
    [ "$bl_logging_log_file_path" = "$1" ] && return 0
    bl.logging.set_file_descriptors ''
    [ "$1" = '' ] && return 0
    bl.logging.set_file_descriptors "$1" --commands=tee --logging=tee
}
# endregion
# region vim modline
# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
