#!/usr/bin/env bash
# -*- coding: utf-8 -*-
# region header
# Copyright Torben Sickert (info["~at~"]torben.website) 16.12.2012

# License
# -------

# This library written by Torben Sickert stand under a creative commons naming
# 3.0 unported license. see http://creativecommons.org/licenses/by/3.0/deed.de
# endregion
# shellcheck disable=SC2016,SC2155
# region import
# shellcheck source=./cli.sh
# shellcheck source=./module.sh
source "$(dirname "${BASH_SOURCE[0]}")/module.sh"
bl.module.import bashlink.arguments
bl.module.import bashlink.cli
bl.module.import bashlink.documentation
bl.module.import bashlink.logging
bl.module.import bashlink.path
bl.module.import bashlink.string
bl.module.import bashlink.time
bl.module.import bashlink.tools
# endregion
# region variables
# shellcheck disable=SC2034,SC2016
bl_doctest__documentation__='
    The doctest module implements function and module level testing via
    documentation strings. Tests can be run by invoking:

    ```bash
        doctest.sh file1 folder1 file2 ...
    ```

    #### Options:

    ```
        --help|-h                   Print help message.
        --side-by-side              Print diff of failing tests side by side.
        --no-check-undocumented     Do not warn about undocumented functions.
        --use-nounset               Accessing undefined variables produces error.
        --verbose|-v                Be more verbose
    ```

    #### Example output for `./doctest.sh -v arguments.sh`

    ```bash
        [verbose:doctest.sh:330] bl.arguments:[PASS]
        [verbose:doctest.sh:330] bl.arguments.get_flag:[PASS]
        [verbose:doctest.sh:330] bl.arguments.get_keyword:[PASS]
        [verbose:doctest.sh:330] bl.arguments.get_parameter:[PASS]
        [verbose:doctest.sh:330] bl.arguments.get_positional:[PASS]
        [verbose:doctest.sh:330] bl.arguments.set:[PASS]
        [info:doctest.sh:590] bl.arguments - passed 6/6 tests in 918 ms
        [info:doctest.sh:643] Total: passed 1/1 modules in 941 ms
    ```

    A docstring can be defined for a function by defining a variable named
    `__documentation__` at the function scope. On the module level, the
    variable name should be `<module_name>__documentation__` (e.g.
    `bl_arguments__documentation__` for the example above). NOTE: The
    "docstring" needs to be defined with single quotes. Code contained in a
    module level variable named `<module_name>__bl_doctest_setup__` will be run
    once before all the tests of a module are run. This is usefull for defining
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

    ##### Single quotes can be escaped like so:
    >>> echo '"'"'$foos'"'"'
    $foos

    ##### Or so
    >>> echo '\''$foos'\''
    $foos

    ##### Some text in between.
    Multiline output
    >>> local i
    >>> for i in 1 2; do
    >>>     echo $i;
    >>> done
    1
    2

    ##### Check ellipsis support
    >>> local i
    >>> for i in 1 2 3 4 5; do
    >>>     echo $i;
    >>> done
    +bl.doctest.multiline_ellipsis
    1
    2
    ...

    ##### Multi line ellipsis are non greedy.
    >>> local i
    >>> for i in 1 2 3 4 5; do
    >>>     echo $i;
    >>> done
    +bl.doctest.multiline_ellipsis
    1
    ...
    4
    5

    ##### Ellipsis matches one line.
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

    ##### Each testcase has its own scope:
    >>> local testing="foo"; echo $testing
    foo
    >>> [ -z "${testing:-}" ] && echo empty
    empty

    ##### Check for syntax error in test code:
    >>> f() {a}
    +bl.doctest.multiline_contains
    {a}

    -bl.documentation.exclude_print
'
bl_doctest_debug=false
bl_doctest_module_reference_under_test=''
bl_doctest_name_indicator=__documentation__
bl_doctest_nounset=false
bl_doctest_supress_undocumented=false
bl_doctest_regular_expression="/${bl_doctest_name_indicator}='/,/';$/p"
bl_doctest_regular_expression_one_line="${bl_doctest_name_indicator}='.*';$"
bl_doctest_use_side_by_side_output=false
# endregion
# region functions
alias bl.doctest.compare_result=bl_doctest_compare_result
bl_doctest_compare_result() {
    # shellcheck disable=SC2016,SC2034
    local __documentation__='
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
        "ignore" is not "line 2".
        4
    '
    local buffer="$1"
    local got="$2"
    local buffer_line
    local got_line
    local result=0
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
        # set result
        if $ellipsis || $multiline_ellipsis; then
            if [ "$buffer_line" = '...' ]; then
                ellipsis_on=true
                ellipsis_waiting=false
            fi
        fi
        if $end_of_buffer; then
            if $ellipsis_waiting; then
                echo No expected ellipsis found.
                return 1
            fi
            if $end_of_got || $multiline_ellipsis || $multiline_contains; then
                return
            fi
            echo More output given than expected.
            return 2
        fi
        if $end_of_got; then
            echo Missing expected output.
            return 3
        fi
        if $bl_doctest_debug; then
            echo "Compare given \"$got_line\" with \"$buffer_line\":"
        fi
        if $ellipsis_on; then
            if ! $multiline_ellipsis || bl_doctest_compare_line; then
                ellipsis_on=false
            fi
            if $bl_doctest_debug; then
                echo Matched by ellipsis.
            fi
        elif bl_doctest_compare_line; then
            if $bl_doctest_debug; then
                echo Matched.
            fi
            if ! $multiline_contains; then
                contains=false
            fi
        else
            if $contains; then
                echo "\"$buffer_line\" is not in \"$got_line\"."
            else
                echo "\"$got_line\" is not \"$buffer_line\"."
            fi
            if ! $multiline_contains; then
                contains=false
            fi
            return 4
        fi
    done 3<<< "$buffer" 4<<< "$got"
    return $result
}
alias bl.doctest.get_function_docstring=bl_doctest_get_function_docstring
bl_doctest_get_function_docstring() {
    local __documentation__='
        Retrieves the docstring from given function name in current scope.

        >>> bl.doctest.get_function_docstring bl_doctest_get_function_docstring
        +bl.doctest.ellipsis
        ...
        Retrieves the docstring from given function name in current scope.
        +bl.doctest.multiline_ellipsis
        ...
    '
    local function_name="$1"
    (
        if ! docstring="$(type "$function_name" 2>/dev/null | \
            command grep "$bl_doctest_regular_expression_one_line")"
        then
            docstring="$(
                type "$function_name" 2>/dev/null | \
                    command sed --quiet "$bl_doctest_regular_expression")"
        fi
        eval "unset $bl_doctest_name_indicator"
        eval "$docstring"
        echo "${!bl_doctest_name_indicator}"
    )
}
alias bl.doctest.main=bl_doctest_main
bl_doctest_main() {
    # shellcheck disable=SC2016,SC2034
    local __documentation__='
        +bl.documentation.exclude
        >>> bl.doctest.main non_existing_module
        >>> echo $?
        +bl.doctest.contains
        +bl.doctest.ellipsis
        critical: Module file path for "non_existing_module" could not be
        ...
        1

        -bl.documentation.exclude
    '
    bl.arguments.set "$@"
    local help
    bl.arguments.get_flag --help -h help
    $help && \
        bl.documentation.print_docstring "$bl_doctest__documentation__" && \
        return 0
    bl.arguments.get_flag --side-by-side bl_doctest_use_side_by_side_output
    # do not warn about undocumented functions
    bl.arguments.get_flag --no-check-undocumented bl_doctest_supress_undocumented
    # use set -o nounset inside tests
    bl.arguments.get_flag --use-nounset bl_doctest_nounset
    local verbose
    bl.arguments.get_flag --verbose -v verbose
    bl.arguments.apply_new
    if $verbose; then
        bl.logging.set_level verbose
    else
        bl.logging.set_level info
    fi
    bl.time.start
    if [[ $# == 0 ]]; then
        bl.doctest.test bashlink
    else
        local name
        for name in "$@"; do
            local module_name="${name/:*/}"
            local function_name="${name/*:/}"
            if [ "$function_name" = "$name" ]; then
                function_name=''
            fi
            bl.doctest.test "$module_name" "$function_name" &
        done
    fi
    local success=0
    local total=0
    local job
    for job in $(jobs -p); do
        (( total++ ))
        wait "$job" && (( success++ ))
    done
    bl.logging.info "Total: passed $success/$total modules in" \
        "$(bl.time.get_elapsed) ms"
    (( success != total )) && return 1
    return 0
}
alias bl.doctest.parse_docstring=bl_doctest_parse_docstring
bl_doctest_parse_docstring() {
    # shellcheck disable=SC2016,SC2034
    local __documentation__='
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
    local parse_buffers_function="$2"
    local prompt="$3"
    local module_name="${4:-}"
    local function_name="${5:-}"
    [ -z "$prompt" ] && prompt='>>>'
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
        $parse_buffers_function "$test_buffer" "$output_buffer" \
            "$text_buffer" "$module_name" "$function_name"
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
                    [ ! -z "$text_buffer" ] && text_buffer+=$'\n'"$line"
                elif [[ "$line" = "$prompt"* ]]; then
                    next_state=TEST
                    [ ! -z "$text_buffer" ] && bl_doctest_eval_buffers
                    $preserve_prompt && temp_prompt="$prompt" && prompt=""
                    test_buffer="${line#$prompt}"
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
                    [ $? == 1 ] && return 1
                elif [[ "$line" = "$prompt"* ]]; then
                    next_state=TEST
                    $preserve_prompt && temp_prompt="$prompt" && prompt=""
                    # check if start of test
                    if [ -z "$test_buffer" ]; then
                        test_buffer="${line#$prompt}"
                    else
                        test_buffer+=$'\n'"${line#$prompt}"
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
                    [ $? == 1 ] && return 1
                elif [[ "$line" = "$prompt"* ]]; then
                    next_state=TEST
                    bl_doctest_eval_buffers
                    [ $? == 1 ] && return 1
                    $preserve_prompt && temp_prompt="$prompt" && prompt=""
                    if [ -z "$test_buffer" ]; then
                        test_buffer="${line#$prompt}"
                    else
                        test_buffer+=$'\n'"${line#$prompt}"
                    fi
                    $preserve_prompt && prompt="$temp_prompt"
                else
                    next_state=OUTPUT
                    # check if start of output
                    if [ -z "$output_buffer" ]; then
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
    [[ "$(tail --lines=1 <<< "$text_buffer")" = "" ]] &&
        text_buffer="$(head --lines=-1 <<< "$text_buffer" )"
    bl_doctest_eval_buffers
}
# NOTE: Depends on "pring_declarations_warning".
alias bl.doctest.eval=bl_doctest_eval
bl_doctest_eval() {
    # shellcheck disable=SC2016,SC2034
    local __documentation__='
        >>> local test_buffer="
        >>> echo foo
        >>> echo bar
        >>> "
        >>> local output_buffer="foo
        >>> bar"
        >>> bl_doctest_use_side_by_side_output=false
        >>> bl_doctest_module_reference_under_test=bashlink.module
        >>> bl_doctest_nounset=false
        >>> bl.doctest.eval "$test_buffer" "$output_buffer"
    '
    local test_buffer="$1"
    [[ -z "$test_buffer" ]] && return 0
    local output_buffer="$2"
    local text_buffer="${3-}"
    local module_name="${4-}"
    local module_module_file_path="$(bl.module.resolve bashlink.module)"
    local function_name="${5-}"
    local result=0
    local scope_name="$(bl.module.rewrite_scope_name "$(
        bl.module.remove_known_file_extension "$module_name")")"
    local setup_identifier="${scope_name//[^[:alnum:]_]/_}"__doctest_setup__
    local setup_string="${!setup_identifier:-}"
    local declared_names_before_run_file_path="$(
        mktemp --suffix=bashlink-doctest)"
    # shellcheck disable=SC2064
    trap "rm --force $declared_names_before_run_file_path; exit" EXIT
    local declared_names_after_run_file_path="$(
        mktemp --suffix=bashlink-doctest)"
    # shellcheck disable=SC2064
    trap "rm --force $declared_names_after_run_file_path; exit" EXIT
    local test_script="$(
        echo '[ -z "$BASH_REMATCH" ] && BASH_REMATCH=""'
        echo source "$module_module_file_path"
        # Suppress the warnings here because they have already been printed
        # when analyzing the module initially.
        echo "bl_module_prevent_namespace_check=true"
        echo "bl.module.import '$bl_doctest_module_reference_under_test' '${BASH_SOURCE[1]}'"
        echo "bl_module_prevent_namespace_check=false"
        echo "$setup_string"
        # _ can be used as anonymous variable (without warning)
        echo "_=''"
        echo "bl.module.determine_declared_names > $declared_names_before_run_file_path"
        $bl_doctest_nounset && echo 'set -o nounset'
        # NOTE: We havt to wrap the test context a function to ensure the
        # "local" keyword has an effect inside.
        echo "
            _() {
                $test_buffer
            }
            _
        "
        echo "bl.module.determine_declared_names > $declared_names_after_run_file_path"
    )"
    # run in clean environment
    local output
    if echo "$output_buffer" | command grep '+bl.doctest.no_capture_stderr' \
        &>/dev/null
    then
        output="$(bash --noprofile --norc <(echo "$test_script"))"
    else
        output="$(bash --noprofile --norc 2>&1 <(echo "$test_script"))"
    fi
    bl_doctest_new_declared_names="$(diff \
        "$declared_names_before_run_file_path" \
        "$declared_names_after_run_file_path" | \
            command grep -e '^>' | command sed 's/^> //')"
    local test_name="$function_name"
    if [ -z "$test_name" ]; then
        test_name="$module_name"
    fi
    if [[ "$bl_doctest_new_declared_names" != '' ]]; then
        local name
        bl.string.get_unique_lines <<< "$bl_doctest_new_declared_names" | \
        while read -r name; do
            if ! bl.module.check_name "$name" "$scope_name"; then
                bl.logging.warn \
                    "Test for \"$test_name\" in module \"$module_name\"" \
                    "introduces a global unprefixed name: \"$name\"."
            fi
        done
    fi
    rm "$declared_names_before_run_file_path"
    rm "$declared_names_after_run_file_path"
    local reason
    if ! reason="$(bl.doctest.compare_result "$output_buffer" "$output")"
    then
        echo -e "Error: ${reason}\n"
        echo -e "${bl_cli_color_light_red}test:${bl_cli_color_default}"
        echo "$test_buffer"
        if $bl_doctest_use_side_by_side_output; then
            output_buffer=$'expected:\n'"${output_buffer}"
            # TODO exclude doctest_options
            local diff=diff
            bl.tools.dependency_check colordiff && diff=colordiff
            $diff --side-by-side <(echo "$output_buffer") <(echo "$output")
        else
            echo -e "${bl_cli_color_light_red}expected:${bl_cli_color_default}"
            echo "$output_buffer"
            echo -e "${bl_cli_color_light_red}got:${bl_cli_color_default}"
            echo "\"$output\""
        fi
        return 1
    fi
}
alias bl.doctest.run_test=bl_doctest_run_test
bl_doctest_run_test() {
    local docstring="$1"
    local module_name="$2"
    local function_name="$3"
    local test_name="$module_name"
    [[ -z "$function_name" ]] || test_name="$function_name"
    if bl.doctest.parse_docstring "$docstring" bl_doctest_eval '>>>' \
        "$module_name" "$function_name"
    then
        bl.logging.verbose "$test_name ${bl_cli_color_light_green}${bl_cli_powerline_ok}${bl_cli_color_default}"
    else
        bl.logging.warn "$test_name ${bl_cli_color_light_red}${bl_cli_powerline_fail}${bl_cli_color_default}"
        return 1
    fi
}
alias bl_doctest_test=bl.doctest.test
bl_doctest_test() {
    bl_doctest_module_reference_under_test="$1"
    local given_function_names_to_test="$2"
    local result
    if ! result="$(
        bl.module.resolve "$bl_doctest_module_reference_under_test" true
    )"; then
        echo "$result" 1>&2
        return 1
    fi
    local file_path="$(
        echo "$result" | command sed --regexp-extended 's:^(.+)/[^/]+$:\1:')"
    local module_name="$(
        echo "$result" | command sed --regexp-extended 's:^.*/([^/]+)$:\1:')"
    local scope_name="$(
        bl.module.rewrite_scope_name "$module_name" | \
            command sed --regexp-extended 's:\.:_:g')"
    local name
    local function_names_to_test=''
    for name in $given_function_names_to_test; do
        if [[ "$function_names_to_test" != '' ]]; then
            function_names_to_test+=' '
        fi
        if [ "${name/$scope_name/}" = "$name" ]; then
            function_names_to_test+="${scope_name}_${name}"
        else
            function_names_to_test+="$name"
        fi
    done
    if [[ -d "$file_path" ]]; then
        local sub_file_path
        for sub_file_path in "${file_path}"/*; do
            local excluded=false
            local excluded_name
            for excluded_name in "${bl_module_directory_names_to_ignore[@]}"; do
                if [[ -d "$sub_file_path" ]] && [
                    "$excluded_name" = "$(basename "$sub_file_path")"
                ]; then
                    excluded=true
                    break
                fi
            done
            if ! $excluded; then
                for excluded_name in "${bl_module_file_names_to_ignore[@]}"; do
                    if [[ -f "$sub_file_path" ]] && [ "$excluded_name" = "$(basename "$sub_file_path")" ]; then
                        excluded=true
                        break
                    fi
                done
            fi
            if ! $excluded; then
                # shellcheck disable=SC1117
                bl.doctest.test "$(bl.module.remove_known_file_extension "$(
                    echo "$sub_file_path" | \
                        command sed \
                            --regexp-extended \
                            "s:${scope_name}/([^/]+):${scope_name}.\1:"
                )")"
            fi
        done
        return 0
    fi
    (
        bl.module.import_without_namespace_check \
            "$bl_doctest_module_reference_under_test"
        if [ "$function_names_to_test" = '' ]; then
            # NOTE: Get all external module prefix and unprefixed function
            # names.
            # shellcheck disable=SC2154
            local function_names_to_test="$module_declared_function_names_after_source"
            # NOTE: Adds internal already loaded but correctly prefixed
            # functions.
            function_names_to_test+=" $(
                ! declare -F | cut -d' ' -f3 | command grep -e "^$scope_name")"
        fi
        # NOTE: Removes duplicates.
        function_names_to_test="$(bl.string.get_unique_lines <(
            echo "$function_names_to_test"))"
        local total=0
        local success=0
        bl.time.start
        if [ "$given_function_names_to_test" = '' ]; then
            # Module level tests
            local module_documentation_variable_name="${scope_name}${bl_doctest_name_indicator}"
            local docstring="${!module_documentation_variable_name}"
            if ! [ -z "$docstring" ]; then
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
            elif ! $bl_doctest_supress_undocumented; then
                bl.logging.warn "Function \"$name\" is not documented."
            fi
        done
        bl.logging.info "$module_name - passed $success/$total tests in" \
            "$(bl.time.get_elapsed) ms"
        (( success != total )) && exit 1
        exit 0
    )
}
# endregion
if bl.tools.is_main; then
    bl.doctest.main "$@"
fi
# region vim modline
# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
