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
declare -gr bl_exception__documentation__='
    >>> _() {
    >>>    bl.exception.try {
    >>>        echo $1
    >>>    } bl.exception.catch
    >>>        true
    >>> }
    >>> _ 2
    2

    >>> local a=2
    >>> bl.exception.try {
    >>>     a=3
    >>> } bl.exception.catch {
    >>>     a=4
    >>> }
    >>> echo "$a"
    3

    >>> bl.exception.activate
    >>> false
    +bl.doctest.contains
    +bl.doctest.multiline_ellipsis
    Traceback (most recent call first):
    ...

    >>> bl.exception.activate
    >>> bl.exception.try {
    >>>     false
    >>> } bl.exception.catch {
    >>>     echo caught
    >>> }
    caught

    Exception in a subshell:

    >>> bl.exception.activate
    >>> ( false )
    +bl.doctest.contains
    +bl.doctest.multiline_ellipsis
    Traceback (most recent call first):
    ...
    +bl.doctest.contains
    Traceback (most recent call first):
    ...
    >>> bl.exception.activate
    >>> bl.exception.try {
    >>>     (false; echo "this should not be printed")
    >>>     echo "this should not be printed"
    >>> } bl.exception.catch {
    >>>     echo caught
    >>> }
    caught

    Nested exception:

    >>> bl_exception_foo() {
    >>>     true
    >>>     bl.exception.try {
    >>>         false
    >>>     } bl.exception.catch {
    >>>         echo caught inside foo
    >>>     }
    >>>     false # this is caught at top level
    >>>     echo this should never be printed
    >>> }
    >>> bl.exception.try {
    >>>     bl_exception_foo
    >>> } bl.exception.catch {
    >>>     echo caught
    >>> }
    caught inside foo
    caught

    >>> bl.exception.activate
    >>> bl_exception_foo() {
    >>>     bl.exception.try {
    >>>         false
    >>>     } bl.exception.catch {
    >>>         echo caught
    >>>     }
    >>>     echo this should be printed
    >>> }
    >>> bl_exception_foo || echo info
    +bl.doctest.contains
    +bl.doctest.multiline_ellipsis
    Error: Context does not allow error traps.
    Traceback (most recent call first):
    ...
    this should be printed

    exception are implicitly active inside try blocks:

    >>> foo() {
    >>>     echo $1
    >>>     true
    >>>     bl.exception.try {
    >>>         false
    >>>     } bl.exception.catch {
    >>>         echo caught inside foo
    >>>     }
    >>>     false # this should raise an error if exceptions are active
    >>>     echo this should be printed if exceptions are not active
    >>> }
    >>> foo "exception NOT ACTIVE:"
    >>> bl.exception.activate
    >>> foo "exception ACTIVE:"
    +bl.doctest.multiline_ellipsis
    exception NOT ACTIVE:
    caught inside foo
    this should be printed if exceptions are not active
    exception ACTIVE:
    caught inside foo
    +bl.doctest.contains
    Traceback (most recent call first):
    ...

    Exception inside conditionals:

    >>> bl.exception.activate
    >>> false && echo "should not be printed"
    >>> (false) && echo "should not be printed"
    >>> bl.exception.try {
    >>>     (
    >>>         false
    >>>         echo "should not be printed"
    >>>     )
    >>> } bl.exception.catch {
    >>>     echo caught
    >>> }
    caught

    Print a caught exception traceback.

    >>> bl.exception.try {
    >>>     false
    >>> } bl.exception.catch {
    >>>     echo caught
    >>>     echo "$bl_exception_last_traceback"
    >>> }
    +bl.doctest.multiline_contains
    caught
    Traceback (most recent call first):

    Different syntax variations are possible.

    >>> bl.exception.try {
    >>>     ! true
    >>> } bl.exception.catch {
    >>>     echo caught
    >>> }

    >>> bl.exception.try
    >>>     false
    >>> bl.exception.catch_single {
    >>>     echo caught
    >>> }
    caught

    >>> bl.exception.try
    >>>     false
    >>> bl.exception.catch_single
    >>>     echo caught
    caught

    >>> bl.exception.try {
    >>>     false
    >>> }
    >>> bl.exception.catch_single {
    >>>     echo caught
    >>> }
    caught

    >>> bl.exception.try {
    >>>     false
    >>> }
    >>> bl.exception.catch_single
    >>> {
    >>>     echo caught
    >>> }
    caught
'
declare -g bl_exception_active=false
declare -g bl_exception_active_before_try=false
declare -g bl_exception_last_traceback=''
declare -g bl_exception_last_traceback_file_path=''
declare -ig bl_exception_try_catch_level=0
# endregion
# region functions
alias bl.exception.check_context=bl_exception_check_context
bl_exception_check_context() {
    local -r __documentation__='
        Tests if context allows error traps.

        `set -e` and `ERR traps` are prevented from working in a subprocess
        if it is disabled by the surrounding context due to a chained
        conditional like `( ...  ) || echo Warning ...`.

        >>> bl.exception.activate
        >>> _() {
        >>>     bl.exception.try {
        >>>         false
        >>>     } bl.exception.catch {
        >>>         # NOTE: This is not caught because of the `||` in the
        >>>         # surrounding context.
        >>>         echo caught
        >>>     }
        >>>     false
        >>>     echo this should not be executed
        >>> }
        >>> _ || echo "error in exceptions_foo"
        +bl.doctest.contains
        +bl.doctest.multiline_ellipsis
        Error: Context does not allow error traps.
        Traceback (most recent call first):
        ...
        this should not be executed
    '
    (
        local test_context_pass=false
        set -o errtrace
        trap 'test_context_pass=true' ERR
        false
        $test_context_pass && \
            exit 0
        exit 1
    )
}
# Depends on "bl.exception.check_context"
alias bl.exception.activate=bl_exception_activate
bl_exception_activate() {
    local -r __documentation__='
        Activates exception handling for following code.

        >>> set -o errtrace
        >>> trap '\''echo foo'\'' ERR
        >>> bl.exception.activate
        >>> trap -p ERR | cut --delimiter "'\''" --fields 2
        >>> bl.exception.deactivate
        >>> trap -p ERR | cut --delimiter "'\''" --fields 2
        bl_exception_error_handler || declare -i bl_exception_return_code=$? && (( ${#FUNCNAME[@]} == 0 )) && exit $bl_exception_return_code; return $bl_exception_return_code
        echo foo
    '
    if [[ "$1" != true ]]; then
        bl.exception.check_context
        if [ $? = 1 ]; then
            # NOTE: We should call exception trap logic by hand in this case.
            bl_exception_error_handler true
            local -r message='Error: Context does not allow error traps.'
            if [ -f "$bl_exception_last_traceback_file_path" ]; then
                bl_exception_last_traceback="$(
                    cat "$bl_exception_last_traceback_file_path")"
                rm "$bl_exception_last_traceback_file_path"
                bl.logging.error_exception \
                    "$message" \
                    $'\n' \
                    "$bl_exception_last_traceback"
            else
                bl.logging.error_exception "$message"
            fi
        fi
    fi
    $bl_exception_active && \
        return 0
    bl_exception_errtrace_saved=$(set -o | awk '/errtrace/ {print $2}')
    bl_exception_pipefail_saved=$(set -o | awk '/pipefail/ {print $2}')
    bl_exception_functrace_saved=$(set -o | awk '/functrace/ {print $2}')
    bl_exception_error_traps=$(trap -p ERR | cut --delimiter "'" --fields 2)
    bl_exception_ps4_saved="$PS4"
    # improve xtrace output (set -x)
    export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
    # If set, any trap on ERR is inherited by shell functions,
    # command substitutions, and commands executed in a subshell environment.
    # The ERR trap is normally not inherited in such cases.
    set -o errtrace
    # If set, any trap on DEBUG and RETURN are inherited by shell functions,
    # command substitutions, and commands executed in a subshell environment.
    # The DEBUG and RETURN traps are normally not inherited in such cases.
    #set -o functrace
    # If set, the return value of a pipeline is the value of the last
    # (rightmost) command to exit with a non-zero status, or zero if all
    # commands in the pipeline exit successfully. This option is disabled by
    # default.
    set -o pipefail
    # Treat unset variables and parameters other than the special parameters
    # "@" or "*" as an error when performing parameter expansion.
    # An error message will be written to the standard error, and a
    # non-interactive shell will exit.
    #set -o nounset

    # traps:
    # EXIT      executed on shell exit
    # DEBUG	executed before every simple command
    # RETURN    executed when a shell function or a sourced code finishes executing
    # ERR       executed each time a command's failure would cause the shell to exit when the '-e' option ('errexit') is enabled

    # ERR is not executed in following cases:
    # >>> err() { return 1; }
    # >>> ! err
    # >>> err || echo foo
    # >>> err && echo foo

    # NOTE: We have to check whether we should jump out of a function context
    # with "return $?" (e.g. in "...try { ... }" blocks) or in global scope
    # where an "exit $?" call is more appreciate.
    # NOTE: We can not check "FUNCNAME" or any other context during trap
    # generation because the following code wouldn't be predictable:
    #
    # _() {
    #     trap 'echo handle trap' ERR
    #     if __random__; then
    #         false
    #     fi
    # }
    # _
    # false
    #
    trap 'bl_exception_error_handler || declare -i bl_exception_return_code=$? && (( ${#FUNCNAME[@]} == 0 )) && exit $bl_exception_return_code; return $bl_exception_return_code' ERR
    # trap bl_exception_debug_handler DEBUG
    # trap bl_exception_exit_handler EXIT
    bl_exception_active=true
}
alias bl.exception.deactivate=bl_exception_deactivate
bl_exception_deactivate() {
    local -r __documentation__='
        Deactivates exception handling for code which where activated
        previously.

        >>> set -o errtrace
        >>> trap '\''echo $foo'\'' ERR
        >>> bl.exception.activate
        >>> trap -p ERR | cut --delimiter "'\''" --fields 2
        >>> bl.exception.deactivate
        >>> trap -p ERR | cut --delimiter "'\''" --fields 2
        bl_exception_error_handler || declare -i bl_exception_return_code=$? && (( ${#FUNCNAME[@]} == 0 )) && exit $bl_exception_return_code; return $bl_exception_return_code
        echo $foo
    '
    $bl_exception_active || \
        return 0
    [ "$bl_exception_errtrace_saved" = off ] && \
        set +o errtrace
    [ "$bl_exception_pipefail_saved" = off ] && \
        set +o pipefail
    [ "$bl_exception_functrace_saved" = off ] && \
        set +o functrace
    export PS4="$bl_exception_ps4_saved"
    # shellcheck disable=SC2064
    trap "$bl_exception_error_traps" ERR
    bl_exception_active=false
}
alias bl.exception.enter_try=bl_exception_enter_try
bl_exception_enter_try() {
    local -r __documentation__='
        Catches exceptions for following code blocks.

        >>> bl.exception.enter_try; alias bl.exception.try_wrapper=bl_exception_try_wrapper; bl_exception_try_wrapper() { bl.exception.activate; {
        >>>     false
        >>> } bl.exception.catch {
        >>>     echo caught
        >>> }
        caught
    '
    if (( bl_exception_try_catch_level == 0 )); then
        bl_exception_last_traceback_file_path="$(
            mktemp --suffix -bashlink-exception-last-traceback)"
        bl_exception_active_before_try=$bl_exception_active
    fi
    # NOTE: We have to deactivate exceptions here to avoid calling the error
    # trap a second time after running the catch wrapper function. The nested
    # error trap would be triggered when the wrapper function returns a number
    # other than 0. The nested error trap converts an error into such a
    # `return !=0`.
    bl.exception.deactivate
    (( bl_exception_try_catch_level++ ))
}
alias bl.exception.error_handler=bl_exception_error_handler
bl_exception_error_handler() {
    local -ir error_code=$?
    local -r __documentation__='
        Error handler for captured exceptions.

        >>> bl.exception.error_handler
        +bl.doctest.contains
        +bl.doctest.multiline_ellipsis
        Traceback (most recent call first):
        ...
    '
    local -r do_not_throw="$1"
    local traceback='Traceback (most recent call first):'
    local -i index=0
    while caller $index > /dev/null; do
        local -a trace=("$(caller $index)")
        local line=${trace[0]}
        local subroutine=${trace[1]}
        local filename=${trace[2]}
        # shellcheck disable=SC1117
        traceback+="\n[$index] ${filename}:${line}: ${subroutine}"
        (( index++ ))
    done
    if (( bl_exception_try_catch_level == 0 )) && [ "$do_not_throw" != true ]
    then
        bl.logging.error "$traceback"
    else
        echo "$traceback" >"$bl_exception_last_traceback_file_path"
    fi
    return $error_code
}
alias bl.exception.exit_try=bl_exception_exit_try
bl_exception_exit_try() {
    local -r __documentation__='
        Introduces an exception handling code block.

        >>> bl.exception.try {
        >>>     false
        >>> }; return 0; }; bl_exception_try_wrapper "$@"; bl.exception.exit_try $? || {
        >>>     echo caught
        >>> }
        caught
    '
    local -ir bl_exception_return_code=$1
    (( bl_exception_try_catch_level-- ))
    if (( bl_exception_try_catch_level == 0 )); then
        if $bl_exception_active_before_try; then
            bl.exception.activate true
        else
            bl.exception.deactivate
        fi
        if [ -f "$bl_exception_last_traceback_file_path" ]; then
            bl_exception_last_traceback="$(
                cat "$bl_exception_last_traceback_file_path")"
            rm "$bl_exception_last_traceback_file_path"
        else
            bl.logging.warn \
                "Traceback file under \"$bl_exception_last_traceback_file_path\" is missing."
        fi
    else
        bl.exception.activate true
    fi
    # shellcheck disable=SC2086
    return $bl_exception_return_code
}
alias bl.exception.try='bl.exception.enter_try; alias bl.exception.try_wrapper=bl_exception_try_wrapper; bl_exception_try_wrapper() { bl.exception.activate; '
# shellcheck disable=SC2142
alias bl.exception.catch='; return 0; }; bl_exception_try_wrapper "$@"; bl.exception.exit_try $? || '
# shellcheck disable=SC2142
alias bl.exception.catch_single='return 0; }; bl_exception_try_wrapper "$@"; bl.exception.exit_try $? || '
# endregion
# region vim modline
# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
