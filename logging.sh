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
declare -gr bl_logging__documentation__='
    The available log levels are:

    - error
    - critical
    - warn (or warning)
    - info
    - debug

    Supported output types for commands and logging are:

    - std (Outputs to standard output)
    - off (does not output anything)
    - file (outputs to given file)
    - tee (outputs to both: given file and standard output)

    Supported type of configurable logging files

    - Logging output
    - Error logging output
    - Command output
    - Error command output

    NOTE: this module saves and provided given standard und error file
    descriptors to descriptors to "5" and "6". So you can enforce corresponding
    output via `command 1>&5 2>&6`.
    This is needed to restore them later via `bl.logging.set_file_descriptors`.
    Logging outputs are alway piped through file descriptor "3" and "4". So
    your able to write your own logging function by logging to this
    descriptors: `custom_logging_function 1>&3 2&>4`.

    The standard loglevel is critical

    >>> bl.logging.get_level
    >>> bl.logging.get_command_level
    critical
    critical

    >>> bl.logging.is_enabled error; echo $?
    0

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
    >>> bl.logging.set_command_level debug
    >>> echo foo

    >>> bl.logging.set_level info
    >>> bl.logging.set_command_level info
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
declare -g bl_logging_file_path=''
declare -g bl_logging_error_file_path=''
declare -g bl_logging_command_file_path=''
declare -g bl_logging_command_error_file_path=''
# logging levels from low to high
declare -ag bl_logging_levels=(
    error
    critical
    warning
    info
    debug
)
# matches the order of logging levels
declare -ag bl_logging_levels_color=(
    "$bl_cli_color_red"
    "$bl_cli_color_magenta"
    "$bl_cli_color_yellow"
    "$bl_cli_color_green"
    "$bl_cli_color_blue"
)
declare -g bl_logging_command_level=$(
    bl.array.get_index critical "${bl_logging_levels[@]}")
declare -g bl_logging_level=$(
    bl.array.get_index critical "${bl_logging_levels[@]}")
declare -g bl_logging_output_target=std
declare -g bl_logging_command_output_target=std
# endregion
# Save existing standard descriptors (in descriptor 5 and 6) and set default
# redirections for logging output (file descriptor 3 and 4).
exec \
    3>&1 \
    4>&2 \
    5>&1 \
    6>&2
# region functions
alias bl.logging.cat=bl_logging_cat
bl_logging_cat() {
    local -r __documentation__='
        This function prints files
        (e.g `bl.logging.cat < file.txt`) or heredocs. Like `bl.logging.plain`,
        it also prints at any log level and without the prefix.

        >>> echo foo | bl.logging.cat
        foo
    '
    # NOTE: Hack to free call stack and flush pending tee buffer.
    hash sync &>/dev/null && \
        sync
    cat "$@" 1>&3 2>&4
}
alias bl.logging.get_command_level=bl_logging_get_command_level
bl_logging_get_command_level() {
    local -r __documentation__='
        Retrieves current command output level.

        >>> bl.logging.set_command_level critical
        >>> bl.logging.get_command_level
        critical
    '
    echo "${bl_logging_levels[$bl_logging_command_level]}"
}
alias bl.logging.get_level=bl_logging_get_level
bl_logging_get_level() {
    local -r __documentation__='
        Retrieves current logging level.

        >>> bl.logging.set_level critical
        >>> bl.logging.get_level
        critical
    '
    echo "${bl_logging_levels[$bl_logging_level]}"
}
alias bl.logging.get_prefix=bl_logging_get_prefix
bl_logging_get_prefix() {
    local -r __documentation__='
        Determines logging prefix string.

        >>> bl.logging.get_prefix critical
        +bl.doctest.contains
        critical
    '
    local -r level=$1
    local -r level_index=$(
        bl.array.get_index "$level" "${bl_logging_levels[@]}")
    if (( level_index <= -1 )); then
        bl.logging.critical \
            "Given logging level \"$level\" is not available, use one of:" \
            "${bl_logging_levels[*]} or warn."
        return 1
    fi
    local -r color=${bl_logging_levels_color[$level_index]}
    # shellcheck disable=SC2154
    local -r loglevel=${color}${level}${bl_cli_color_default}
    local path="${BASH_SOURCE[2]##./}"
    path="${path%.sh}"
    # shellcheck disable=SC2154
    echo "${loglevel}:${bl_cli_color_light_gray}$(basename "$path")${bl_cli_color_default}:${bl_cli_color_light_cyan}${BASH_LINENO[1]}${bl_cli_color_default}:"
}
alias bl.logging.is_enabled=bl_logging_is_enabled
bl_logging_is_enabled() {
    local -r __documentation__='
        Checks if given logging level is enabled.

        >>> bl.logging.set_level critical
        >>> bl.logging.is_enabled critical; echo $?
        >>> bl.logging.is_enabled info; echo $?
        0
        1
    '
    local -r level="$1"
    local -r level_index=$(bl.array.get_index "$level" "${bl_logging_levels[@]}")
    if (( level_index <= -1 )); then
        # NOTE: `bl.logging.error` is not defined yet.
        bl_logging_log \
            error \
            "Given logging level \"$level\" is not available, use one of:" \
            "${bl_logging_levels[*]} or warn."
        return 1
    fi
    (( level_index <= bl_logging_level ))
}
alias bl.logging.plain_raw=bl_logging_plain_raw
bl_logging_plain_raw() {
    local -r __documentation__='
        This function prints at any log level and without prefix.

        >>> bl.logging.set_level critical
        >>> bl.logging.set_command_level debug
        >>> bl.logging.plain_raw foo
        foo

        >>> bl.logging.set_level info
        >>> bl.logging.set_command_level debug
        >>> bl.logging.debug "not shown"
        >>> echo "not shown"
        >>> bl.logging.plain_raw "shown"
        shown
    '
    echo "$@" 1>&3 2>&4
}
alias bl.logging.plain=bl_logging_plain
bl_logging_plain() {
    local -r __documentation__='
        This function prints a given string in evaluated representation at any
        log level and without prefix.

        >>> bl.logging.set_level critical
        >>> bl.logging.set_command_level debug
        >>> bl.logging.plain foo
        foo

        >>> bl.logging.set_level info
        >>> bl.logging.set_command_level debug
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
    local -r __documentation__='
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
    local no_exception=true
    local level="$1"
    if [ "$level" = warn ]; then
        level=warning
    elif [ "$level" = error_exception ]; then
        no_exception=false
        level=error
    fi
    shift
    if bl.logging.is_enabled "$level"; then
        bl.arguments.set "$@"
        local no_new_line
        bl.arguments.get_flag -n --no-new-line no_new_line
        if $no_new_line; then
            no_new_line='-n'
        else
            no_new_line=''
        fi
        bl.arguments.apply_new
        if [ "$level" = error ]; then
            bl.logging.plain \
                $no_new_line \
                "$(bl_logging_get_prefix "$level")" \
                "$@" \
                    3>&4
        else
            bl.logging.plain \
                $no_new_line \
                "$(bl_logging_get_prefix "$level")" \
                "$@"
        fi
    fi
    $no_exception
}
alias bl.logging.critical='bl_logging_log critical'
alias bl.logging.debug='bl_logging_log debug'
alias bl.logging.error='bl_logging_log error'
alias bl.logging.error_exception='bl_logging_log error_exception'
alias bl.logging.info='bl_logging_log info'
alias bl.logging.warn='bl_logging_log warn'
alias bl.logging.warning=bl.logging.warn
alias bl.logging.set_file_descriptors=bl_logging_set_file_descriptors
bl_logging_set_file_descriptors() {
    # shellcheck disable=SC1004
    local -r __documentation__='
        Sets file descriptors for all generic commands outputs and logging
        methods defined in this module.

        NOTE: We temporary save "/dev/stdout" and "/dev/stderr" in file
        descriptors "3" and "4".

        >>> local test_file="$(bl_logging_bl_doctest_mktemp)"
        >>> bl.logging.plain test >"$test_file"
        >>> bl.logging.set_file_descriptors
        >>> bl.logging.cat "$test_file"
        test

        >>> local test_file="$(bl_logging_bl_doctest_mktemp)"
        >>> bl.logging.set_file_descriptors "$test_file" --logging-output-target=tee
        >>> bl.logging.plain foo
        >>> bl.logging.set_file_descriptors
        >>> bl.logging.cat "$test_file"
        foo
        foo

        >>> local test_file="$(bl_logging_bl_doctest_mktemp)"
        >>> bl.logging.set_file_descriptors "$test_file" --command-output-target=file --logging-output-target=off
        >>> bl.logging.plain not shown
        >>> echo foo
        >>> bl.logging.info test
        >>> bl.logging.set_file_descriptors
        >>> cat "$test_file"
        foo

        >>> local test_file="$(bl_logging_bl_doctest_mktemp)"
        >>> bl.logging.set_file_descriptors "$test_file" --logging-output-target=off
        >>> bl.logging.plain not shown
        >>> echo foo
        >>> bl.logging.set_file_descriptors
        >>> bl.logging.cat "$test_file"
        foo

        >>> local test_file="$(bl_logging_bl_doctest_mktemp)"
        >>> bl.logging.set_file_descriptors "$test_file" --command-output-target=tee
        >>> echo test
        >>> bl.logging.set_file_descriptors
        >>> bl.logging.plain test
        >>> bl.logging.cat "$test_file"
        test
        test
        test

        >>> local test_file="$(bl_logging_bl_doctest_mktemp)"
        >>> bl.logging.set_file_descriptors "$test_file" --command-output-target=file
        >>> bl.logging.plain test
        >>> echo test
        >>> bl.logging.set_file_descriptors
        >>> bl.logging.cat "$test_file"
        test
        test

        >>> local test_file="$(bl_logging_bl_doctest_mktemp)"
        >>> bl.logging.set_file_descriptors "$test_file" --command-output-target=file --logging-output-target=file
        >>> bl.logging.plain test
        >>> echo test
        >>> bl.logging.set_file_descriptors
        >>> bl.logging.cat "$test_file"
        test
        test

        >>> local test_file="$(bl_logging_bl_doctest_mktemp)"
        >>> bl.logging.set_file_descriptors "$test_file" --command-output-target=file --logging-output-target=file
        >>> bl.logging.plain test
        >>> echo test
        >>> bl.logging.set_file_descriptors
        >>> bl.logging.cat "$test_file"
        test
        test

        >>> local test_file="$(bl_logging_bl_doctest_mktemp)"
        >>> bl.logging.set_file_descriptors "$test_file" --command-output-target=tee --logging-output-target=file
        >>> echo test
        >>> bl.logging.plain test
        >>> bl.logging.set_file_descriptors
        >>> bl.logging.cat "$test_file"
        test
        test
        test

        >>> local test_file="$(bl_logging_bl_doctest_mktemp)"
        >>> bl.logging.set_file_descriptors "$test_file" --command-output-target=off --logging-output-target=file
        >>> bl.logging.plain logging
        >>> echo echo
        >>> bl.logging.set_file_descriptors
        >>> bl.logging.cat "$test_file"
        logging

        >>> local test_file="$(bl_logging_bl_doctest_mktemp)"
        >>> bl.logging.set_file_descriptors "$test_file" --command-output-target=tee --logging-output-target=tee
        >>> bl.logging.plain test
        >>> echo test
        >>> bl.logging.set_file_descriptors
        >>> bl.logging.cat "$test_file"
        test
        test
        test
        test
    '
    bl.arguments.set "$@"
    # An output specification have to be one of "file", "std", "tee" or "off".
    local output command_output
    bl.arguments.get_keyword --command-output-target command_output
    bl.arguments.get_keyword --logging-output-target output
    bl_logging_command_output_target="$command_output"
    bl_logging_output_target="$output"
    [ "$bl_logging_command_output_target" = '' ] && \
        bl_logging_command_output_target=std
    [ "$bl_logging_output_target" = '' ] && \
        bl_logging_output_target=std
    set -- "${bl_arguments_new[@]:-}"
    bl_logging_file_path="$1"
    if [ "$bl_logging_file_path" = '' ]; then
        if [ "$bl_logging_output_target" = file ] || \
            [ "$bl_logging_output_target" = tee ] || \
            [ "$bl_logging_command_output_target" = file ] || \
            [ "$bl_logging_command_output_target" = tee ]
        then
            bl_logging_file_path="$(mktemp --suffix -bash-logging)"
        fi
    fi
    bl_logging_error_file_path="$2"
    if [ "$bl_logging_error_file_path" = '' ]; then
        bl_logging_error_file_path="$bl_logging_file_path"
    fi
    bl_logging_command_file_path="$3"
    if [ "$bl_logging_command_file_path" = '' ]; then
        bl_logging_command_file_path="$bl_logging_file_path"
    fi
    bl_logging_command_error_file_path="$4"
    if [ "$bl_logging_command_error_file_path" = '' ]; then
        bl_logging_command_error_file_path="$bl_logging_command_file_path"
    fi
    # NOTE: This is only needed for "dash" compatibility where process
    # substitution is not available.
    if \
        [ "$bl_logging_output_target" = tee ] || \
        [ "$bl_logging_command_output_target" = tee ]
    then
        local -r output_fifo_directory_path="$(
            mktemp --directory --suffix -bashlink-logging-output-fifo)"
        # shellcheck disable=SC2064
        trap "rm --force --recursive '$output_fifo_directory_path'" EXIT
    fi
    if [ "$bl_logging_command_output_target" = tee ]; then
        local -r command_output_fifo_standard_file_path="$output_fifo_directory_path/command_standard"
        local -r command_output_fifo_error_file_path="$output_fifo_directory_path/command_error"
        mkfifo "$command_output_fifo_standard_file_path"
        mkfifo "$command_output_fifo_error_file_path"
    fi
    if [ "$bl_logging_output_target" = tee ]; then
        local -r output_fifo_standard_file_path="$output_fifo_directory_path/standard"
        local -r output_fifo_error_file_path="$output_fifo_directory_path/error"
        mkfifo "$output_fifo_standard_file_path"
        mkfifo "$output_fifo_error_file_path"
    fi
    ##
    if [ "$bl_logging_output_target" = file ]; then
        if [ "$bl_logging_command_output_target" = file ]; then
            exec \
                1>>"$bl_logging_command_file_path" \
                2>>"$bl_logging_command_error_file_path" \
                3>>"$bl_logging_file_path" \
                4>>"$bl_logging_error_file_path"
        elif [ "$bl_logging_command_output_target" = std ]; then
            exec \
                1>&5 \
                2>&6 \
                3>>"$bl_logging_file_path" \
                4>>"$bl_logging_error_file_path"
        elif [ "$bl_logging_command_output_target" = tee ]; then
            # NOTE: bash4+ version
            #exec \
            #    1> >(tee --append "$bl_logging_command_file_path" 1>&5 2>&6) \
            #    2> >(tee --append "$bl_logging_command_error_file_path" 1>&6 2>&6) \
            #    3>>"$bl_logging_file_path" \
            #    4>>"$bl_logging_error_file_path"
            tee \
                --append "$bl_logging_command_file_path" \
                1>&5 \
                2>&6 \
                <"$command_output_fifo_standard_file_path" &
            tee \
                --append "$bl_logging_command_file_path" \
                1>&6 \
                2>&6 \
                <"$command_output_fifo_error_file_path" &
            exec \
                1>"$command_output_fifo_standard_file_path" \
                2>"$command_output_fifo_error_file_path" \
                3>>"$bl_logging_file_path" \
                4>>"$bl_logging_error_file_path"
        elif [ "$bl_logging_command_output_target" = off ]; then
            exec \
                1>/dev/null \
                2>&1 \
                3>>"$bl_logging_file_path" \
                4>>"$bl_logging_error_file_path"
        fi
    elif [ "$bl_logging_output_target" = std ]; then
        if [ "$bl_logging_command_output_target" = file ]; then
            exec \
                1>>"$bl_logging_command_file_path" \
                2>>"$bl_logging_command_error_file_path" \
                3>&5 \
                4>&6
        elif [ "$bl_logging_command_output_target" = std ]; then
            exec \
                1>&5 \
                2>&6 \
                3>&5 \
                4>&6
        elif [ "$bl_logging_command_output_target" = tee ]; then
            # NOTE: bash4+ version
            #exec \
            #    1> >(tee --append "$bl_logging_command_file_path" 1>&5 2>&6) \
            #    2> >(tee --append "$bl_logging_command_error_file_path" 1>&6 2>&6) \
            #    3>&5 \
            #    4>&6
            tee \
                --append "$bl_logging_command_file_path" \
                1>&5 \
                2>&6 \
                <"$command_output_fifo_standard_file_path" &
            tee \
                --append "$bl_logging_command_file_path" \
                1>&6 \
                2>&6 \
                <"$command_output_fifo_error_file_path" &
            exec \
                1>"$command_output_fifo_standard_file_path" \
                2>"$command_output_fifo_error_file_path" \
                3>&5 \
                4>&6
        elif [ "$bl_logging_command_output_target" = off ]; then
            exec \
                1>/dev/null \
                2>&1 \
                3>&5 \
                4>&6
        fi
    elif [ "$bl_logging_output_target" = tee ]; then
        if [ "$bl_logging_command_output_target" = file ]; then
            # NOTE: bash4+ version
            #exec \
            #    1>>"$bl_logging_command_file_path" \
            #    2>>"$bl_logging_command_error_file_path" \
            #    3> >(tee --append "$bl_logging_file_path" 1>&5 2>&6) \
            #    4> >(tee --append "$bl_logging_error_file_path" 1>&6 2>&6)
            tee \
                --append "$bl_logging_command_file_path" \
                1>&5 \
                2>&6 \
                <"$output_fifo_standard_file_path" &
            tee \
                --append "$bl_logging_command_file_path" \
                1>&6 \
                2>&6 \
                <"$output_fifo_error_file_path" &
            exec \
                1>>"$bl_logging_command_file_path" \
                2>>"$bl_logging_command_error_file_path" \
                3>"$output_fifo_standard_file_path" \
                4>"$output_fifo_error_file_path"
        elif [ "$bl_logging_command_output_target" = std ]; then
            # NOTE: bash4+ version
            #exec \
            #    1>&5 \
            #    2>&6 \
            #    3> >(tee --append "$bl_logging_file_path" 1>&5 2>&6) \
            #    4> >(tee --append "$bl_logging_error_file_path" 1>&6 2>&6)
            tee \
                --append "$bl_logging_command_file_path" \
                1>&5 \
                2>&6 \
                <"$output_fifo_standard_file_path" &
            tee \
                --append "$bl_logging_command_file_path" \
                1>&6 \
                2>&6 \
                <"$output_fifo_error_file_path" &
            exec \
                1>&5 \
                2>&6 \
                3>"$output_fifo_standard_file_path" \
                4>"$output_fifo_error_file_path"
        elif [ "$bl_logging_command_output_target" = tee ]; then
            # NOTE: bash4+ version
            #exec \
            #    1> >(tee --append "$bl_logging_command_file_path" 1>&5 2>&6) \
            #    2> >(tee --append "$bl_logging_command_error_file_path" 1>&6 2>&6) \
            #    3>&1 \
            #    4>&1
            tee \
                --append "$bl_logging_command_file_path" \
                1>&5 \
                2>&6 \
                <"$command_output_fifo_standard_file_path" &
            tee \
                --append "$bl_logging_command_file_path" \
                1>&6 \
                2>&6 \
                <"$command_output_fifo_error_file_path" &
            exec \
                1>"$command_output_fifo_standard_file_path" \
                2>"$command_output_fifo_error_file_path" \
                3>&1 \
                4>&1
        elif [ "$bl_logging_command_output_target" = off ]; then
            # NOTE: bash4+ version
            #exec \
            #    1>/dev/null \
            #    2>&1 \
            #    3> >(tee --append "$bl_logging_file_path" 1>&5 2>&6) \
            #    4> >(tee --append "$bl_logging_error_file_path" 1>&6 2>&6)
            tee \
                --append "$bl_logging_command_file_path" \
                1>&5 \
                2>&6 \
                <"$output_fifo_standard_file_path" &
            tee \
                --append "$bl_logging_command_file_path" \
                1>&6 \
                2>&6 \
                <"$output_fifo_error_file_path" &
            exec \
                1>/dev/null \
                2>&1 \
                3>"$output_fifo_standard_file_path" \
                4>"$output_fifo_error_file_path"
        fi
    elif [ "$bl_logging_output_target" = off ]; then
        if [ "$bl_logging_command_output_target" = file ]; then
            exec \
                1>>"$bl_logging_file_path" \
                2>&1 \
                3>/dev/null \
                4>&3
        elif [ "$bl_logging_command_output_target" = std ]; then
            exec \
                1>&5 \
                2>&6 \
                3>/dev/null \
                4>&3
        elif [ "$bl_logging_command_output_target" = tee ]; then
            # NOTE: bash4+ version
            #exec \
            #    1> >(tee --append "$bl_logging_command_file_path" 1>&5 2>&6) \
            #    2> >(tee --append "$bl_logging_command_error_file_path" 1>&6 2>&6) \
            #    3>/dev/null \
            #    4>&3
            tee \
                --append "$bl_logging_command_file_path" \
                1>&5 \
                2>&6 \
                <"$output_fifo_standard_file_path" &
            tee \
                --append "$bl_logging_command_file_path" \
                1>&6 \
                2>&6 \
                <"$output_fifo_error_file_path" &
            exec \
                1>"$output_fifo_standard_file_path" \
                2>"$output_fifo_error_file_path" \
                3>/dev/null \
                4>&3
        elif [ "$bl_logging_command_output_target" = off ]; then
            exec \
                1>/dev/null \
                2>&1 \
                3>&1 \
                4>&1
        fi
    fi
    # NOTE: Hack to free call stack and flush pending tee buffer.
    hash sync &>/dev/null && \
        sync
    return 0
}
# NOTE: Depends on "bl.logging.set_file_descriptors"
alias bl.logging.set_command_output_off=bl_logging_set_command_output_off
bl_logging_set_command_output_off() {
    local -r __documentation__='
        Disables each command output.

        >>> bl.logging.set_command_output_off
        >>> echo test
    '
    bl.logging.set_file_descriptors \
        "$bl_logging_file_path" \
        "$bl_logging_error_file_path" \
        "$bl_logging_command_file_path" \
        "$bl_logging_command_error_file_path" \
        --logging-output-target="$bl_logging_output_target" \
        --command-output-target=off
}
# NOTE: Depends on "bl.logging.set_file_descriptors"
alias bl.logging.set_command_output_on=bl_logging_set_command_output_on
bl_logging_set_command_output_on() {
    local -r __documentation__='
        Enables each command output.

        >>> bl.logging.set_command_output_on
        >>> echo test
        test
    '
    bl.logging.set_file_descriptors \
        "$bl_logging_file_path" \
        "$bl_logging_error_file_path" \
        "$bl_logging_command_file_path" \
        "$bl_logging_command_error_file_path" \
        --logging-output-target="$bl_logging_output_target" \
        --command-output-target=std
}
# NOTE: Depends on "bl.logging.set_command_output_on", bl.logging.set_command_output_off"
alias bl.logging.set_command_level=bl_logging_set_command_level
bl_logging_set_command_level() {
    local -r __documentation__='
        Enables each command output.

        >>> bl.logging.set_command_level critical
        >>> bl.logging.set_level critical
        >>> echo test
        test
        >>> bl.logging.set_command_level warning
        >>> echo test
    '
    local level="$1"
    if [ "$level" = warn ]; then
        level=warning
    fi
    bl_logging_command_level=$(
        bl.array.get_index "$level" "${bl_logging_levels[@]}")
    if (( bl_logging_level >= bl_logging_command_level )); then
        bl.logging.set_command_output_on
    else
        bl.logging.set_command_output_off
    fi
}
alias bl.logging.set_level=bl_logging_set_level
bl_logging_set_level() {
    local -r __documentation__='
        >>> bl.logging.set_command_level info
        >>> bl.logging.set_level info
        >>> echo $bl_logging_level
        >>> echo $bl_logging_command_level
        3
        3
    '
    local level="$1"
    if [ "$level" = warn ]; then
        level=warning
    fi
    bl_logging_level=$(bl.array.get_index "$level" "${bl_logging_levels[@]}")
    if (( bl_logging_level >= bl_logging_command_level )); then
        bl.logging.set_command_output_on
    else
        bl.logging.set_command_output_off
    fi
}
alias bl.logging.set_file=bl_logging_set_file
bl_logging_set_file() {
    local -r __documentation__='
        >>> local test_file_path="$(bl_logging_bl_doctest_mktemp)"
        >>> bl.logging.set_file "$test_file_path"
        >>> bl.logging.plain test
        >>> echo test
        >>> bl.logging.set_file_descriptors
        >>> bl.logging.cat "$test_file_path"
        test
        test
        test
        test
    '
    bl.logging.set_file_descriptors \
        "$1" "$2" "$3" "$4" \
        --command-output-target=tee \
        --logging-output-target=tee
}
# endregion
# region vim modline
# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
