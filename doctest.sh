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
# region executable header
if [ ! -f "$(dirname "${BASH_SOURCE[0]}")/module.sh" ]; then
    for BL_DOCTEST_SUB_PATH in / lib/; do
        if [ -f "$(dirname "$(dirname "$(readlink --canonicalize "${BASH_SOURCE[0]}")")")${BL_DOCTEST_SUB_PATH}bashlink/module.sh" ]
        then
            exec "$(dirname "$(dirname "$(readlink --canonicalize "${BASH_SOURCE[0]}")")")${BL_DOCTEST_SUB_PATH}bashlink/doctest.sh" "$@"
        fi
    done
fi
# endregion
# region import
# shellcheck source=./cli.sh
# shellcheck source=./module.sh
source "$(dirname "${BASH_SOURCE[0]}")/module.sh"
bl.module.import bashlink.arguments
bl.module.import bashlink.cli
bl.module.import bashlink.dependency
bl.module.import bashlink.documentation
bl.module.import bashlink.logging
bl.module.import bashlink.path
bl.module.import bashlink.string
bl.module.import bashlink.time
bl.module.import bashlink.tools
# endregion
# region variables
declare -gr BL_DOCTEST__DOCUMENTATION__='
    This module implements function and module level testing via documentation
    strings. Tests can be run by invoking:

    ```bash
        doctest.sh file1 folder1 file2 ...
    ```

    Options:

    ```
        --help|-h               Print help message.
        --prevent-side-by-side  Prevents printing differences of failing
                                tests side by side.
        --no-check-undocumented Do not warn about undocumented functions.
        --use-nounset           Accessing undefined variables produces error.
        --verbose|-v            Be more verbose
    ```

    Example output for `./doctest.sh --verbose arguments.sh`

    ```bash
        [info:doctest:xxx] bl.arguments:[PASS]
        [info:doctest:xxx] bl.arguments.get_flag:[PASS]
        [info:doctest:xxx] bl.arguments.get_keyword:[PASS]
        [info.doctedt:xxx] bl.arguments.get_parameter:[PASS]
        [info:doctest:xxx] bl.arguments.get_positional:[PASS]
        [info:doctest:xxx] bl.arguments.set:[PASS]
        [info:doctest:xxx] bl.arguments - passed 6/6 tests in 918 ms
        [info:doctest:xxx] Total: passed 1/1 items in 941 ms
    ```

    A docstring can be defined for a function by defining a variable named
    "__documentation__" at the function scope. On the module level, the
    variable name should be "<module_name>__DOCUMENTATION__" (e.g.
    "BL_ARGUMENTS__DOCUMENTATION__" for the example above). NOTE: The
    "docstring" needs to be defined with single quotes. Code contained in a
    module level variable named "<module_name>__BL_DOCTEST_SETUP__" will be run
    once before all the tests of a module are run. This is useful for defining
    mockup functions/data that can be used throughout all tests.

    +bl.documentation.exclude_print
    >>> echo bar
    bar
    >>> echo $(( 1 + 2 ))
    3
    >>> echo foo
    foo
    >>> echo bar
    bar

    Single quotes can be escaped like so:

    >>> echo '"'"'$foos'"'"'
    $foos

    Or so

    >>> echo '\''$foos'\''
    $foos

    Some text in between.

    Multiline output
    >>> local i
    >>> for i in 1 2; do
    >>>     echo $i;
    >>> done
    1
    2

    Check ellipsis support

    >>> local i
    >>> for i in 1 2 3 4 5; do
    >>>     echo $i;
    >>> done
    +bl.doctest.multiline_ellipsis
    1
    2
    ...

    Multi line ellipsis are non greedy.

    >>> local i
    >>> for i in 1 2 3 4 5; do
    >>>     echo $i;
    >>> done
    +bl.doctest.multiline_ellipsis
    1
    ...
    4
    5

    Ellipsis matches one line.

    >>> local i
    >>> for i in 1 2 3 4 5; do
    >>>     echo $i;
    >>> done
    +bl.doctest.ellipsis
    1
    ...
    ...
    4
    5

    Each testcase has its own scope:

    >>> local testing="foo"; echo $testing
    foo
    >>> [ -z "${testing:-}" ] && echo empty
    empty

    Check for syntax error in test code:

    >>> f() {a}
    +bl.doctest.multiline_contains
    {a}

    -bl.documentation.exclude_print
'
declare -g BL_DOCTEST_DEBUG=false
declare -g BL_DOCTEST_MODULE_REFERENCE_UNDER_TEST=''
declare -gr BL_DOCTEST_NAME_INDICATOR=__documentation__
declare -g BL_DOCTEST_NOUNSET=false
declare -g BL_DOCTEST_SYNCHRONIZED=false
declare -g BL_DOCTEST_IS_SYNCHRONIZED=true
declare -g BL_DOCTEST_SUPRESS_UNDOCUMENTED=false
declare -gr BL_DOCTEST_EXPRESSION="/${BL_DOCTEST_NAME_INDICATOR}='/,/';$/p"
declare -g BL_DOCTEST_REGULAR_EXPRESSION_ONE_LINE="${BL_DOCTEST_NAME_INDICATOR}='.*';$"
declare -g BL_DOCTEST_USE_SIDE_BY_SIDE_OUTPUT=true
# endregion
# region functions
alias bl.doctest.compare_result=bl_doctest_compare_result
bl_doctest_compare_result() {
    local -r __documentation__='
        Compares specified result with given one.

        >>> local buffer="line 1
        >>> line 2"
        >>> local got="line 1
        >>> line 2"
        >>> bl.doctest.compare_result "$buffer" "$got"; echo $?
        0

        >>> local buffer="line 1
        >>> foo"
        >>> local got="line 1
        >>> line 2"
        >>> bl.doctest.compare_result "$buffer" "$got"; echo $?
        +bl.doctest.contains
        "line 2" is not "foo".
        4

        >>> local buffer="+bl.doctest.multiline_contains
        >>> line
        >>> line"
        >>> local got="line 1
        >>> line 2"
        >>> bl.doctest.compare_result "$buffer" "$got"; echo $?
        0

        >>> local buffer="+bl.doctest.contains
        >>> line
        >>> foo"
        >>> local got="line 1
        >>> line 2"
        >>> bl.doctest.compare_result "$buffer" "$got"; echo $?
        +bl.doctest.contains
        "line 2" is not "foo".
        4

        >>> local buffer="+bl.doctest.ellipsis
        >>> line
        >>> ...
        >>> "
        >>> local got="line
        >>> line 2
        >>> "
        >>> bl.doctest.compare_result "$buffer" "$got"; echo $?
        0

        >>> local buffer="+bl.doctest.multiline_ellipsis
        >>> line
        >>> ...
        >>> line 2
        >>> "
        >>> local got="line
        >>> ignore
        >>> ignore
        >>> line 2
        >>> "
        >>> bl.doctest.compare_result "$buffer" "$got"; echo $?
        0

        >>> local buffer="+bl.doctest.ellipsis
        >>> line
        >>> ...
        >>> line 2
        >>> "
        >>> local got="line
        >>> ignore
        >>> ignore
        >>> line 2
        >>> line 3
        >>> "
        >>> bl.doctest.compare_result "$buffer" "$got"; echo $?
        +bl.doctest.contains
        "ignore" is not "line 2".
        4
    '
    local -r buffer="$1"
    local -r got="$2"
    local buffer_line
    local got_line
    local contains=false
    local ellipsis=false
    local ellipsis_on=false
    local ellipsis_waiting=false
    local end_of_buffer=false
    local end_of_got=false
    local multiline_contains=false
    local multiline_ellipsis=false
    bl_doctest_compare_line() {
        if $contains; then
            [[ "$got_line" = *"$buffer_line"* ]] || return 1
        else
            [ "$got_line" = "$buffer_line" ] || return 1
        fi
    }
    while true; do
        # parse buffer line
        if ! read -r -u3 buffer_line; then
            end_of_buffer=true
        fi
        if [[ "$buffer_line" = "+bl.doctest.no_capture_stderr"* ]]; then
            continue
        elif [[ "$buffer_line" = "+bl.doctest.contains"* ]]; then
            contains=true
            continue
        elif [[ "$buffer_line" = "+bl.doctest.multiline_contains"* ]]; then
            contains=true
            multiline_contains=true
            continue
        elif [[ "$buffer_line" = "-bl.doctest.multiline_contains"* ]]; then
            contains=false
            multiline_contains=false
            continue
        elif [[ "$buffer_line" = "-bl.doctest.contains"* ]]; then
            contains=false
            continue
        elif [[ "$buffer_line" = "+bl.doctest.ellipsis"* ]]; then
            ellipsis=true
            ellipsis_waiting=true
            continue
        elif [[ "$buffer_line" = "-bl.doctest.ellipsis"* ]]; then
            ellipsis=false
            continue
        elif [[ "$buffer_line" = "+bl.doctest.multiline_ellipsis"* ]]; then
            ellipsis_waiting=true
            multiline_ellipsis=true
            continue
        elif [[ "$buffer_line" = "-bl.doctest.multiline_ellipsis"* ]]; then
            multiline_ellipsis=false
            continue
        fi
        # parse got line
        if ! read -r -u4 got_line; then
            end_of_got=true
        fi
        if $ellipsis || $multiline_ellipsis; then
            if [ "$buffer_line" = '...' ]; then
                ellipsis_on=true
                ellipsis_waiting=false
            fi
        fi
        if $end_of_buffer; then
            if $ellipsis_waiting; then
                echo No expected ellipsis found. 1>&2
                return 1
            fi
            if $end_of_got || $multiline_ellipsis || $multiline_contains; then
                return
            fi
            echo More output given than expected. 1>&2
            return 2
        fi
        if $end_of_got; then
            echo Missing expected output. 1>&2
            return 3
        fi
        if $BL_DOCTEST_DEBUG; then
            local modifier=''
            if $ellipsis_on; then
                modifier+=ellipsis
                $contains && \
                    modifier+=', contains'
            elif $contains; then
                modifier+=contains
            else
                modifier=none
            fi
            echo \
                "Compare given \"$got_line\" with \"$buffer_line\" (modifier: \"$modifier\"):"
        fi
        if $ellipsis_on; then
            if ! $multiline_ellipsis || bl_doctest_compare_line; then
                ellipsis_on=false
            fi
            if $BL_DOCTEST_DEBUG; then
                echo \
                    "Matched by ellipsis ${BL_CLI_COLOR_LIGHT_GREEN}${BL_CLI_POWERLINE_OK}${BL_CLI_COLOR_DEFAULT}"
            fi
        elif bl_doctest_compare_line; then
            if $BL_DOCTEST_DEBUG; then
                echo \
                    "Matched ${BL_CLI_COLOR_LIGHT_GREEN}${BL_CLI_POWERLINE_OK}${BL_CLI_COLOR_DEFAULT}"
            fi
            if ! $multiline_contains; then
                contains=false
            fi
        else
            if $contains; then
                echo \
                    "Specified \"$buffer_line\" is not in given \"$got_line\". ${BL_CLI_COLOR_LIGHT_RED}${BL_CLI_POWERLINE_FAIL}${BL_CLI_COLOR_DEFAULT}" \
                        1>&2
            else
                echo \
                    "\"$got_line\" is not \"$buffer_line\". ${BL_CLI_COLOR_LIGHT_RED}${BL_CLI_POWERLINE_FAIL}${BL_CLI_COLOR_DEFAULT}" \
                        1>&2
            fi
            if ! $multiline_contains; then
                contains=false
            fi
            return 4
        fi
    done 3<<< "$buffer" 4<<< "$got"
}
alias bl.doctest.eval=bl_doctest_eval
bl_doctest_eval() {
    local -r __documentation__='
        >>> local test_buffer="
        >>> echo foo
        >>> echo bar
        >>> "
        >>> local output_buffer="foo
        >>> bar"
        >>> BL_DOCTEST_USE_SIDE_BY_SIDE_OUTPUT=false
        >>> BL_DOCTEST_MODULE_REFERENCE_UNDER_TEST=bashlink.module
        >>> BL_DOCTEST_NOUNSET=false
        >>> bl.doctest.eval "$test_buffer" "$output_buffer"
    '
    local -r test_buffer="$1"
    [ "$test_buffer" = '' ] && \
        return 0
    local -r output_buffer="$2"
    local -r text_buffer="${3-}"
    local -r module_name="${4-}"
    local -r doctest_module_file_path="$(bl.module.resolve bashlink.doctest)"
    local -r module_module_file_path="$(bl.module.resolve bashlink.module)"
    local -r function_name="${5-}"
    local -i result=0

    local -r function_scope_name_prefix="$(bl.module.rewrite_function_scope_name "$(
        bl.module.remove_known_file_extension "$module_name"
    )")"
    local -r alternate_function_scope_name_prefix="${function_scope_name_prefix//./_}"
    local -r global_scope_name_prefix="$(bl.module.rewrite_global_scope_name "$(
        bl.module.remove_known_file_extension "${module_name^^}"
    )")"
    local -r setup_identifier="${global_scope_name_prefix}"__DOCTEST_SETUP__

    local -r setup_string="${!setup_identifier:-}"
    local function_name_description=''
    if [[ "$function_name" != '' ]]; then
        function_name_description="-${function_name}"
    fi
    local -r declared_names_before_run_file_path="$(
        mktemp \
            --suffix "-bashlink-doctest-declared-names-before-${module_name}${function_name_description}.test"
    )"
    # shellcheck disable=SC2064
    trap "rm --force $declared_names_before_run_file_path; exit" EXIT
    local -r declared_names_after_run_file_path="$(
        mktemp \
            --suffix "-bashlink-doctest-declared-names-before-${module_name}${function_name_description}.test")"
    # shellcheck disable=SC2064
    trap "rm --force $declared_names_after_run_file_path; exit" EXIT
    local function_name_description=''
    if [[ "$function_name" != '' ]]; then
        function_name_description="-${function_name}"
    fi
    local -r test_script="$(
        cat << EOF
[ -z "\$BASH_REMATCH" ] && BASH_REMATCH=''
source '$module_module_file_path'
# Suppress the warnings here because they have already been printed when
# analyzing the module initially.
BL_MODULE_PREVENT_NAMESPACE_CHECK=true
$(
    if [ "$BL_DOCTEST_MODULE_REFERENCE_UNDER_TEST" = doctest ]; then
        echo bl.module.import "$doctest_module_file_path"
    else
        echo bl.module.import "$BL_DOCTEST_MODULE_REFERENCE_UNDER_TEST" "$doctest_module_file_path"
    fi
)
BL_MODULE_PREVENT_NAMESPACE_CHECK=false
$setup_string
bl.module.determine_declared_names >'$declared_names_before_run_file_path'
$($BL_DOCTEST_NOUNSET && echo 'set -o nounset')
# NOTE: We have to wrap the test context a function to ensure the "local"
# keyword has an effect inside.
${alternate_function_scope_name_prefix}_doctest_environment() {
    ${global_scope_name_prefix}_BL_DOCTEST_TEMPORARY_FILE_PATHS_FILE_PATH="\$(
        mktemp --suffix "-bashlink-doctest-${function_scope_name_prefix}${function_name_description}.paths"
    )"
    ${alternate_function_scope_name_prefix}_bl_doctest_mktemp() {
        local result
        if [ "\$#" = 0 ]; then
            result="\$(mktemp --suffix -bashlink-doctest-${function_scope_name_prefix}${function_name_description})"
        else
            result="\$(mktemp "\$@")"
        fi
        echo "\$result" \
          >"\$${global_scope_name_prefix}_BL_DOCTEST_TEMPORARY_FILE_PATHS_FILE_PATH"
        echo "\$result"
    }
    # We run in a subshell to ensure that out cleanup routine runs even after
    # "exit" calls in tests.
    ( $test_buffer )
    sync
    local BL_DOCTEST_TEMPORARY_FILE_PATH
    while read BL_DOCTEST_TEMPORARY_FILE_PATH; do
        rm --force --recursive "\$BL_DOCTEST_TEMPORARY_FILE_PATH"
    done <"\$${global_scope_name_prefix}_BL_DOCTEST_TEMPORARY_FILE_PATHS_FILE_PATH"
    rm --force --recursive "\$${global_scope_name_prefix}_BL_DOCTEST_TEMPORARY_FILE_PATHS_FILE_PATH"
}
${alternate_function_scope_name_prefix}_doctest_environment
bl.module.determine_declared_names >'$declared_names_after_run_file_path'
EOF
    )"
    # run in clean environment
    local output
    if echo "$output_buffer" | \
        command grep '+bl.doctest.no_capture_stderr' \
            1>/dev/null 2>&1
    then
        output="$(bash --noprofile --norc <(echo "$test_script"))"
    else
        output="$(bash --noprofile --norc 2>&1 <(echo "$test_script"))"
    fi
    BL_DOCTEST_NEW_DECLARED_NAMES="$(diff \
        "$declared_names_before_run_file_path" \
        "$declared_names_after_run_file_path" | \
            command grep -e '^>' | command sed 's/^> //'
    )"
    local test_name="$function_name"
    if [ -z "$test_name" ]; then
        test_name="$module_name"
    fi
    if [[ "$BL_DOCTEST_NEW_DECLARED_NAMES" != '' ]]; then
        local name
        bl.string.get_unique_lines <<< "$BL_DOCTEST_NEW_DECLARED_NAMES" | \
            while read -r name; do
                if \
                    ! bl.module.check_name "$name" "$function_scope_name_prefix" && \
                    ! bl.module.check_name "$name" "$global_scope_name_prefix"
                then
                    bl.logging.warn \
                        "Test for \"$test_name\" in module \"$module_name\"" \
                        "introduces a global unprefixed name: \"$name\"."
                fi
            done
    fi
    rm "$declared_names_before_run_file_path"
    rm "$declared_names_after_run_file_path"
    local reason
    if ! reason="$(
        bl.doctest.compare_result "$output_buffer" "$output" 2>&1
    )"; then
        # NOTE: We have to replace last pending test information line first.
        bl.logging.is_enabled info && \
            bl.logging.plain -n $'\r'
        bl.logging.plain "${BL_CLI_COLOR_LIGHT_RED}error:${BL_CLI_COLOR_DEFAULT} ${reason}"
        bl.logging.plain "${BL_CLI_COLOR_LIGHT_RED}test:${BL_CLI_COLOR_DEFAULT}"
        bl.logging.plain "$test_buffer"
        bl.logging.plain "${BL_CLI_COLOR_LIGHT_RED}expected:${BL_CLI_COLOR_DEFAULT}"
        bl.logging.plain "$output_buffer"
        bl.logging.plain "${BL_CLI_COLOR_LIGHT_RED}got:${BL_CLI_COLOR_DEFAULT}"
        bl.logging.plain "$output"
        if $BL_DOCTEST_USE_SIDE_BY_SIDE_OUTPUT; then
            bl.logging.plain "${BL_CLI_COLOR_LIGHT_RED}difference:${BL_CLI_COLOR_DEFAULT}"
            local diff=diff
            bl.dependency.check colordiff && diff=colordiff
            $diff --side-by-side <(echo -e "$(
                bl.doctest.get_formatted_docstring_output "$output_buffer"
            )") <(echo -e "$output")
        fi
        return 1
    fi
}
alias bl.doctest.get_formatted_docstring_output=bl_doctest_get_formatted_docstring_output
bl_doctest_get_formatted_docstring_output() {
    local -r __documentation__='
        Slices doctest modifier from given doctest output.

        >>> bl.doctest.get_formatted_docstring_output ""

        >>> bl.doctest.get_formatted_docstring_output "+bl.doctest.ellipsis
        >>> +bl.doctest.multiline_ellipsis
        >>> +bl.doctest.contains
        >>> test"
        test

        >>> bl.doctest.get_formatted_docstring_output "+bl.doctest.ellipsis
        >>> +bl.doctest.multiline_ellipsis
        >>> +bl.doctest.contains
        >>> test
        >>> +bl.doctest.contains"
        test
    '
    echo "$1" | \
        command sed --regexp-extended '/\+bl\.doc(umentation|test)\..+/d'
}
alias bl.doctest.get_function_docstring=bl_doctest_get_function_docstring
bl_doctest_get_function_docstring() {
    # NOTE: We have to overwrite this variable here so "-r" is not useful.
    local __documentation__='
        Retrieves the docstring from given function name in current scope.

        >>> bl.doctest.get_function_docstring bl_doctest_get_function_docstring
        +bl.doctest.ellipsis
        ...
        Retrieves the docstring from given function name in current scope.
        +bl.doctest.multiline_ellipsis
        ...
    '
    local -r function_name="$1"
    (
        local docstring
        if ! docstring="$(
            type "$function_name" 2>/dev/null | \
                command grep "$BL_DOCTEST_REGULAR_EXPRESSION_ONE_LINE"
        )"; then
            docstring="$(
                type "$function_name" 2>/dev/null | \
                    command sed --quiet "$BL_DOCTEST_EXPRESSION"
            )"
        fi
        eval "unset $BL_DOCTEST_NAME_INDICATOR"
        eval "$docstring"
        echo "${!BL_DOCTEST_NAME_INDICATOR}"
    )
}
alias bl.doctest.parse_docstring=bl_doctest_parse_docstring
bl_doctest_parse_docstring() {
    local -r __documentation__='
        >>> local docstring="
        >>>     (test)block
        >>>     output block
        >>> "
        >>> _() {
        >>>     local output_buffer="$2"
        >>>     echo block:
        >>>     while read -r line; do
        >>>         if [ -z "$line" ]; then
        >>>             echo "empty_line"
        >>>         else
        >>>             echo "$line"
        >>>         fi
        >>>     done <<< "$output_buffer"
        >>> }
        >>> bl.doctest.parse_docstring "$docstring" _ "(test)"
        block:
        output block
        >>> local docstring="
        >>>     Some text (block 1).
        >>>
        >>>
        >>>     Some more text (block 1).
        >>>     (test)block 2
        >>>     (test)block 2.2
        >>>     output block 2
        >>>     (test)block 3
        >>>     output block 3
        >>>
        >>>     Even more text (block 4).
        >>> "
        >>> local i=0
        >>> _() {
        >>>     local test_buffer="$1"
        >>>     local output_buffer="$2"
        >>>     local text_buffer="$3"
        >>>     local line
        >>>     (( i++ ))
        >>>     echo "text_buffer (block $i):"
        >>>     if [ ! -z "$text_buffer" ]; then
        >>>         while read -r line; do
        >>>             if [ -z "$line" ]; then
        >>>                 echo "empty_line"
        >>>             else
        >>>                 echo "$line"
        >>>             fi
        >>>         done <<< "$text_buffer"
        >>>     fi
        >>>     echo "test_buffer (block $i):"
        >>>     [ ! -z "$test_buffer" ] && echo "$test_buffer"
        >>>     echo "output_buffer (block $i):"
        >>>     [ ! -z "$output_buffer" ] && echo "$output_buffer"
        >>>     return 0
        >>> }
        >>> bl.doctest.parse_docstring "$docstring" _ "(test)"
        text_buffer (block 1):
        Some text (block 1).
        empty_line
        empty_line
        Some more text (block 1).
        test_buffer (block 1):
        output_buffer (block 1):
        text_buffer (block 2):
        test_buffer (block 2):
        block 2
        block 2.2
        output_buffer (block 2):
        output block 2
        text_buffer (block 3):
        test_buffer (block 3):
        block 3
        output_buffer (block 3):
        output block 3
        text_buffer (block 4):
        Even more text (block 4).
        test_buffer (block 4):
        output_buffer (block 4):
    '
    local preserve_prompt
    bl.arguments.set "$@"
    bl.arguments.get_flag --preserve-prompt preserve_prompt
    bl.arguments.apply_new
    local docstring="$1"
    local -r parse_buffers_function="$2"
    local -r module_name="${4:-}"
    local -r function_name="${5:-}"
    local prompt="$3"
    [ "$prompt" = '' ] && \
        prompt='>>>'
    local text_buffer=''
    local test_buffer=''
    local output_buffer=''
    # Remove leading blank line
    [[ "$(head --lines=1 <<< "$docstring")" != *[![:space:]]* ]] &&
        docstring="$(tail --lines=+2 <<< "$docstring")"
    # Remove trailing blank license.
    [[ "$(tail --lines=1 <<< "$docstring")" != *[![:space:]]* ]] &&
        docstring="$(head --lines=-1 <<< "$docstring")"
    bl_doctest_eval_buffers() {
        $parse_buffers_function \
            "$test_buffer" \
            "$output_buffer" \
            "$text_buffer" \
            "$module_name" \
            "$function_name"
        local result=$?
        # clear buffers
        text_buffer=''
        test_buffer=''
        output_buffer=''
        return $result
    }
    local line
    local state=TEXT
    local next_state
    local temp_prompt
    while read -r line; do
        case "$state" in
            TEXT)
                next_state=TEXT
                if [ "$line" = '' ]; then
                    [ -n "$text_buffer" ] && \
                        text_buffer+=$'\n'"$line"
                elif [[ "$line" = "$prompt"* ]]; then
                    next_state=TEST
                    [ -n "$text_buffer" ] && \
                        bl_doctest_eval_buffers
                    $preserve_prompt && temp_prompt="$prompt" && prompt=""
                    test_buffer="${line#"$prompt"}"
                    $preserve_prompt && prompt="$temp_prompt"
                # check if start of text
                elif [ -z "$text_buffer" ]; then
                    text_buffer="$line"
                else
                    text_buffer+=$'\n'"$line"
                fi
                ;;
            TEST)
                if [ "$line" = '' ]; then
                    next_state=TEXT
                    bl_doctest_eval_buffers
                    (( $? == 1 )) && \
                        return 1
                elif [[ "$line" = "$prompt"* ]]; then
                    next_state=TEST
                    $preserve_prompt && temp_prompt="$prompt" && prompt=""
                    # check if start of test
                    if [ -z "$test_buffer" ]; then
                        test_buffer="${line#"$prompt"}"
                    else
                        test_buffer+=$'\n'"${line#"$prompt"}"
                    fi
                    $preserve_prompt && prompt="$temp_prompt"
                else
                    next_state=OUTPUT
                    output_buffer="$line"
                fi
                ;;
            OUTPUT)
                if [ "$line" = '' ]; then
                    next_state=TEXT
                    bl_doctest_eval_buffers
                    (( $? == 1 )) && \
                        return 1
                elif [[ "$line" = "$prompt"* ]]; then
                    next_state=TEST
                    bl_doctest_eval_buffers
                    (( $? == 1 )) && \
                        return 1
                    $preserve_prompt && temp_prompt="$prompt" && prompt=""
                    if [ "$test_buffer" = '' ]; then
                        test_buffer="${line#"$prompt"}"
                    else
                        test_buffer+=$'\n'"${line#"$prompt"}"
                    fi
                    $preserve_prompt && \
                        prompt="$temp_prompt"
                else
                    next_state=OUTPUT
                    # check if start of output
                    if [ "$output_buffer" = '' ]; then
                        output_buffer="$line"
                    else
                        output_buffer+=$'\n'"$line"
                    fi
                fi
                ;;
        esac
        state="$next_state"
    done <<< "$docstring"
    # shellcheck disable=SC2154
    [ "$(tail --lines=1 <<< "$text_buffer")" = '' ] &&
        text_buffer="$(head --lines=-1 <<< "$text_buffer" )"
    bl_doctest_eval_buffers
}
alias bl.doctest.run_test=bl_doctest_run_test
bl_doctest_run_test() {
    local -r __documentation__='
        Parses given docstring, evaluates doctest and represents result.

        >>> bl.doctest.run_test "" bashlink.doctest bl_doctest_get_function_docstring

        >>> bl.doctest.run_test "test" bashlink.doctest bl_doctest_get_function_docstring

        >>> BL_DOCTEST_MODULE_REFERENCE_UNDER_TEST=bashlink.doctest
        >>> bl.doctest.run_test ">>> echo a
        >>> a" bashlink.doctest bl_doctest_get_function_docstring

        >>> BL_DOCTEST_MODULE_REFERENCE_UNDER_TEST=bashlink.doctest
        >>> bl.doctest.run_test ">>> echo a" bashlink.doctest bl_doctest_get_function_docstring &>/dev/null 3>&1 4>&1; echo $?
        1
    '
    local -r docstring="$1"
    local -r module_name="$2"
    local -r function_name="$3"
    local test_name="$module_name"
    [[ -z "$function_name" ]] || \
        test_name="$function_name"
    if $BL_DOCTEST_IS_SYNCHRONIZED; then
        bl.logging.info --no-new-line "$test_name ${BL_CLI_COLOR_LIGHT_YELLOW}${BL_CLI_POWERLINE_COG}${BL_CLI_COLOR_DEFAULT}"
    fi
    if bl.doctest.parse_docstring "$docstring" bl_doctest_eval '>>>' \
        "$module_name" "$function_name"
    then
        $BL_DOCTEST_IS_SYNCHRONIZED && \
            bl.logging.is_enabled info && \
            bl.logging.plain -n $'\r'
        bl.logging.info \
            "$test_name" \
            "${BL_CLI_COLOR_LIGHT_GREEN}${BL_CLI_POWERLINE_OK}${BL_CLI_COLOR_DEFAULT}"
    else
        # NOTE: `bl.doctest.eval` has replaced last line if info logging level
        # is enabled.
        bl.logging.warn \
            "$test_name" \
            "${BL_CLI_COLOR_LIGHT_RED}${BL_CLI_POWERLINE_FAIL}${BL_CLI_COLOR_DEFAULT}"
        return 1
    fi
    return 0
}
alias bl.doctest.test=bl_doctest_test
bl_doctest_test() {
    local -r __documentation__='
        Runs tests from given package, module or module function.

        >>> bl.doctest.test bashlink.doctest bl_doctest_run_test

        >>> bl.doctest.test bashlink.doctest run_test

        >>> bl.doctest.test bashlink.doctest not_existing; echo $?
        +bl.doctest.contains
        Given function "bl_doctest_not_existing" is not documented.
        1
    '
    BL_DOCTEST_MODULE_REFERENCE_UNDER_TEST="$1"
    local -r given_function_names_to_test="$2"
    local result
    if ! result="$(
        bl.module.resolve "$BL_DOCTEST_MODULE_REFERENCE_UNDER_TEST" true
    )"; then
        bl.logging.plain -n "$result" 1>&2 3>&4
        return 1
    fi
    local -r file_path="$(
        echo "$result" | command sed --regexp-extended 's:^(.+)/[^/]+$:\1:'
    )"
    local -r module_name="$(
        echo "$result" | command sed --regexp-extended 's:^.*/([^/]+)$:\1:'
    )"
    local function_scope_name_prefix="$(
        bl.module.rewrite_function_scope_name "$module_name" | \
            command sed --regexp-extended 's:\.:_:g'
    )"
    local -i success=0
    local -i total=0
    if [ -d "$file_path" ]; then
        shopt -s nullglob
        local file_paths=(*)
        if (( ${#file_paths[@]} > 1 )); then
            BL_DOCTEST_IS_SYNCHRONIZED=false
        fi
        local sub_file_path
        for sub_file_path in "${file_path}"/*; do
            local excluded=false
            local excluded_name
            for excluded_name in "${BL_MODULE_DIRECTORY_NAMES_TO_IGNORE[@]}"; do
                if [[ -d "$sub_file_path" ]] && [[
                    "$excluded_name" = "$(basename "$sub_file_path")"
                ]]; then
                    excluded=true
                    break
                fi
            done
            if ! $excluded; then
                for excluded_name in "${BL_MODULE_FILE_NAMES_TO_IGNORE[@]}"; do
                    if [[ -f "$sub_file_path" ]] && [ "$excluded_name" = "$(basename "$sub_file_path")" ]; then
                        excluded=true
                        break
                    fi
                done
            fi
            if ! $excluded; then
                if $BL_DOCTEST_SYNCHRONIZED; then
                    (( total++ ))
                    # shellcheck disable=SC1117
                    bl.doctest.test "$(
                        bl.module.remove_known_file_extension "$(
                            echo "$sub_file_path" | \
                                command sed \
                                    --regexp-extended \
                                    "s:${function_scope_name_prefix}/([^/]+):${function_scope_name_prefix}.\1:"
                        )")" && \
                            (( success++ ))
                else
                    # shellcheck disable=SC1117
                    bl.doctest.test "$(
                        bl.module.remove_known_file_extension "$(
                            echo "$sub_file_path" | \
                                command sed \
                                    --regexp-extended \
                                    "s:${function_scope_name_prefix}/([^/]+):${function_scope_name_prefix}.\1:"
                        )")" &
                fi
            fi
        done
        if ! $BL_DOCTEST_SYNCHRONIZED; then
            local -i subprocess_id
            for subprocess_id in $(jobs -p); do
                (( total++ ))
                wait "$subprocess_id" && \
                    (( success++ ))
            done
        fi
        bl.logging.info "Total: passed $success/$total items in" \
            "$(bl.time.get_elapsed) ms from \"$module_name\"."
        (( success != total )) && \
            return 1
        return 0
    fi
    (
        local module_prevent_namespace_check_backup="$BL_MODULE_PREVENT_NAMESPACE_CHECK"
        local module_complain_about_dirty_scope_before_namespace_check_backup="$BL_MODULE_COMPLAIN_ABOUT_DIRTY_SCOPE_BEFORE_NAMESPACE_CHECK"
        BL_MODULE_PREVENT_NAMESPACE_CHECK=false
        BL_MODULE_COMPLAIN_ABOUT_DIRTY_SCOPE_BEFORE_NAMESPACE_CHECK=false
        bl.module.import \
            "$BL_DOCTEST_MODULE_REFERENCE_UNDER_TEST"
        declare -g BL_MODULE_PREVENT_NAMESPACE_CHECK="$module_prevent_namespace_check_backup"
        declare -g BL_MODULE_COMPLAIN_ABOUT_DIRTY_SCOPE_BEFORE_NAMESPACE_CHECK="$module_complain_about_dirty_scope_before_namespace_check_backup"

        function_scope_name_prefix="$(
            bl.module.rewrite_function_scope_name "${module_name^^}" | \
                command sed --regexp-extended 's:\.:_:g'
        )"
        local name
        local function_names_to_test=''
        for name in $given_function_names_to_test; do
            if [[ "$function_names_to_test" != '' ]]; then
                function_names_to_test+=' '
            fi
            if [ "${name/$function_scope_name_prefix/}" = "$name" ]; then
                function_names_to_test+="${function_scope_name_prefix}_${name}"
            else
                function_names_to_test+="$name"
            fi
        done
        if [ "$function_names_to_test" = '' ]; then
            # Get all external module prefix and un-prefixed function names.
            # shellcheck disable=SC2154
            local function_names_to_test="$BL_MODULE_DECLARED_FUNCTION_NAMES_AFTER_SOURCE"
            # Adds internal already loaded but correctly prefixed functions.
            function_names_to_test+=" $(
                ! declare -F | \
                    cut -d' ' -f3 | \
                    command grep -e "^$function_scope_name_prefix"
            )"
        fi
        function_names_to_test="$(bl.string.get_unique_lines <(
            echo "$function_names_to_test"
        ))"
        bl.time.start
        if [ "$given_function_names_to_test" = '' ]; then
            global_scope_name_prefix="$(
                bl.module.rewrite_global_scope_name "${module_name^^}" | \
                    command sed --regexp-extended 's:\.:_:g'
            )"
            # Module level tests
            local module_documentation_variable_name="${global_scope_name_prefix}${BL_DOCTEST_NAME_INDICATOR^^}"
            local docstring="${!module_documentation_variable_name}"
            if [ "$docstring" = '' ]; then
                bl.logging.warn "Module \"${module_name}\" is not documented."
            else
                (( total++ ))
                bl.doctest.run_test "$docstring" "$module_name" && \
                    (( success++ ))
            fi
        fi
        # Function level tests
        local name
        for name in $function_names_to_test; do
            # shellcheck disable=SC2089
            local docstring="$(bl.doctest.get_function_docstring "$name")"
            if [[ "$docstring" != '' ]]; then
                (( total++ ))
                bl.doctest.run_test "$docstring" "$module_name" "$name" && \
                    (( success++ ))
            elif [ "$given_function_names_to_test" != '' ]; then
                (( total++ ))
                bl.logging.error "Given function \"${name}\" is not documented."
            elif ! $BL_DOCTEST_SUPRESS_UNDOCUMENTED; then
                bl.logging.warn "Function \"${name}\" is not documented."
            fi
        done
        bl.logging.info "$module_name - passed $success/$total tests in" \
            "$(bl.time.get_elapsed) ms from \"${module_name}\"."
        (( success != total )) && \
            exit 1
        exit 0
    )
}
# NOTE: Depends on "bl.doctest.test"
alias bl.doctest.main=bl_doctest_main
bl_doctest_main() {
    local -r __documentation__='
        Main entry point for this module.

        >>> bl.doctest.main --help
        +bl.doctest.multiline_ellipsis
        ...
        This module implements functions module level testing via documentation
        ...

        >>> bl.doctest.main --synchronized non_existing_module; echo $?
        +bl.doctest.contains
        error: Module file path for "non_existing_module" could not be
        1
    '
    declare -g module_resolving_cache_file_path_backup="$BL_MODULE_NAME_RESOLVING_CACHE_FILE_PATH"

    bl.arguments.set "$@"
    local help
    bl.arguments.get_flag --help -h help
    if $help; then
        bl.documentation.get_formatted_docstring "$BL_DOCTEST__DOCUMENTATION__"
        return 0
    fi
    local no_side_by_side
    bl.arguments.get_flag --prevent-side-by-side no_side_by_side
    if $no_side_by_side; then
        BL_DOCTEST_USE_SIDE_BY_SIDE_OUTPUT=false
    fi
    # Indicates if we should ran tests in parallel.
    bl.arguments.get_flag --synchronized bl_doctest_synchronized
    # Configures if is should warn about undocumented functions.
    bl.arguments.get_flag --no-check-undocumented bl_doctest_supress_undocumented
    # Indicated if `set -o nounset` should be set inside test contexts.
    bl.arguments.get_flag --use-nounset bl_doctest_nounset
    local verbose
    bl.arguments.get_flag --verbose -v verbose
    bl.arguments.apply_new
    if $verbose; then
        bl.logging.set_level info
    fi
    BL_DOCTEST_IS_SYNCHRONIZED=true
    bl.time.start
    local item_names=''
    local -i success=0
    local -i total=0
    if [ "$#" = 0 ]; then
        item_names=bashlink
        if $BL_DOCTEST_SYNCHRONIZED; then
            (( total++ ))
            bl.doctest.test bashlink && \
                (( success++ ))
        else
            bl.doctest.test bashlink &
        fi
    else
        # Reset global environment.
        declare -g BL_MODULE_NAME_RESOLVING_CACHE_FILE_PATH="${BL_MODULE_NAME_RESOLVING_CACHE_FILE_PATH}-doctest"
        echo ''>"$BL_MODULE_NAME_RESOLVING_CACHE_FILE_PATH"
        env -i

        if ! $BL_DOCTEST_SYNCHRONIZED && [[ "$#" -gt 1 ]]; then
            BL_DOCTEST_IS_SYNCHRONIZED=false
        fi

        local name
        for name in "$@"; do
            if [[ "$item_names" != '' ]]; then
                item_names+="\", \""
            fi
            local module_name="${name/:*/}"
            local function_name="${name/*:/}"
            if [ "$function_name" = "$name" ]; then
                function_name=''
            fi
            if $BL_DOCTEST_SYNCHRONIZED; then
                (( total++ ))
                bl.doctest.test "$module_name" "$function_name" && \
                    (( success++ ))
            else
                bl.doctest.test "$module_name" "$function_name" &
            fi
            item_names+="$name"
        done
    fi

    if ! $BL_DOCTEST_SYNCHRONIZED; then
        local -i subprocess_id
        for subprocess_id in $(jobs -p); do
            (( total++ ))
            wait "$subprocess_id" && \
                (( success++ ))
        done
    fi

    declare -g BL_MODULE_NAME_RESOLVING_CACHE_FILE_PATH="$module_resolving_cache_file_path_backup"

    bl.logging.info \
        "Total: passed $success/$total items in $(bl.time.get_elapsed) ms" \
        "from \"$item_names\""
    (( success != total )) && \
        return 1

    return 0
}
# endregion
if bl.tools.is_main; then
    bl.doctest.main "$@"
fi
# region vim modline
# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
