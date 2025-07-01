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
# NOTE: We cannot import the logging module to avoid a dependency cycle.
# shellcheck source=./module.sh
source "$(dirname "${BASH_SOURCE[0]}")/module.sh"
# endregion
# region variables
declare -gr BL_ARRAY__DOCUMENTATION__='
    This module implements utility functions concerning arrays.
'
# endregion
# region functions
alias bl.array.contains=bl_array_contains
bl_array_contains() {
    local -r __documentation__='
        Checks if given item equals to one item in given array.

        >>> local a=(a b c)
        >>> bl.array.contains "${a[*]}" c; echo $?
        0
        >>> bl.array.contains "a b c" b; echo $?
        0
        >>> bl.array.contains "a b c" d; echo $?
        1
    '
    local item
    for item in $1; do
        if [ "$2" = "$item" ]; then
            return 0
        fi
    done

    return 1
}
alias bl.array.filter=bl_array_filter
bl_array_filter() {
    local -r __documentation__='
        Filters values from given array by given regular expression.

        >>> local a=(one two three wolf)
        >>> local b=( $(bl.array.filter ".*wo.*" "${a[@]}") )
        >>> echo ${b[*]}
        two wolf
    '
    local -r pattern="$1"
    shift
    local element
    for element in "$@"; do
        echo "$element"
    done | \
        command grep --extended-regexp "$pattern"
}
alias bl.array.get_index=bl_array_get_index
bl_array_get_index() {
    local -r __documentation__='
        Get index of value in an array

        >>> local a=(one two three)
        >>> bl_array_get_index one "${a[@]}"
        0
        >>> local a=(one two three)
        >>> bl_array_get_index two "${a[@]}"
        1
        >>> bl_array_get_index bar foo bar baz
        1
    '
    local -r search_value="$1"
    shift
    local -ar array=("$@")
    local -i result=-1
    local -i index
    for index in "${!array[@]}"; do
        if [ "${array[$index]}" = "$search_value" ]; then
            result="$index"
        fi
    done

    echo "$result"
    if (( result == -1 )); then
        return 1
    fi
}
alias bl.array.reverse=bl_array_reverse
bl_array_reverse() {
    local -r __documentation__='
        Reverse given array.

        >>> bl.array.reverse

        >>> bl.array.reverse a
        a

        >>> bl.array.reverse "a b c"
        c b a
    '
    local result=''
    local item
    for item in $1; do
        if [ "$result" = '' ]; then
            result="$item"
        else
            result="$item $result"
        fi
    done
    echo "$result"
}
alias bl.array.slice=bl_array_slice
bl_array_slice() {
    local -r __documentation__='
        Returns a slice of an array (similar to Python). One way to remember
        how slices work is to think of the indices as pointing between
        elements, with the left edge of the first character numbered `0`. Then
        the right edge of the last element of an array of length `n` has index
        `n`, for example:

        ```
        +---+---+---+---+---+---+
        | 0 | 1 | 2 | 3 | 4 | 5 |
        +---+---+---+---+---+---+
        0   1   2   3   4   5   6
        -6  -5  -4  -3  -2  -1
        ```

        >>> local a=(0 1 2 3 4 5)
        >>> echo $(bl.array.slice 1:-2 "${a[@]}")
        1 2 3
        >>> local a=(0 1 2 3 4 5)
        >>> echo $(bl.array.slice 0:1 "${a[@]}")
        0
        >>> local a=(0 1 2 3 4 5)
        >>> [ -z "$(bl.array.slice 1:1 "${a[@]}")" ] && echo empty
        empty
        >>> local a=(0 1 2 3 4 5)
        >>> [ -z "$(bl.array.slice 2:1 "${a[@]}")" ] && echo empty
        empty
        >>> local a=(0 1 2 3 4 5)
        >>> [ -z "$(bl.array.slice -2:-3 "${a[@]}")" ] && echo empty
        empty
        >>> local a=(0 1 2 3 4 5)
        >>> [ -z "$(bl.array.slice -2:-2 "${a[@]}")" ] && echo empty
        empty

        Slice indices have useful defaults; an omitted first index defaults to
        zero, an omitted second index defaults to the size of the string being
        sliced.

        >>> local a=(0 1 2 3 4 5)
        >>> # from the beginning to position 2 (excluded)
        >>> echo $(bl.array.slice 0:2 "${a[@]}")
        >>> echo $(bl.array.slice :2 "${a[@]}")
        0 1
        0 1

        >>> local a=(0 1 2 3 4 5)
        >>> # from position 3 (included) to the end
        >>> echo $(bl.array.slice 3:"${#a[@]}" "${a[@]}")
        >>> echo $(bl.array.slice 3: "${a[@]}")
        3 4 5
        3 4 5

        >>> local a=(0 1 2 3 4 5)
        >>> # from the second-last (included) to the end
        >>> echo $(bl.array.slice -2:"${#a[@]}" "${a[@]}")
        >>> echo $(bl.array.slice -2: "${a[@]}")
        4 5
        4 5

        >>> local a=(0 1 2 3 4 5)
        >>> echo $(bl.array.slice -4:-2 "${a[@]}")
        2 3

        If no range is given, it works like normal array indices.
        >>> local a=(0 1 2 3 4 5)
        >>> echo $(bl.array.slice -1 "${a[@]}")
        5
        >>> local a=(0 1 2 3 4 5)
        >>> echo $(bl.array.slice -2 "${a[@]}")
        4
        >>> local a=(0 1 2 3 4 5)
        >>> echo $(bl.array.slice 0 "${a[@]}")
        0
        >>> local a=(0 1 2 3 4 5)
        >>> echo $(bl.array.slice 1 "${a[@]}")
        1
        >>> local a=(0 1 2 3 4 5)
        >>> bl.array.slice 6 "${a[@]}"; echo $?
        1
        >>> local a=(0 1 2 3 4 5)
        >>> bl.array.slice -7 "${a[@]}"; echo $?
        1
    '
    local -i array_length
    local end
    local -i length
    local start
    if [[ "$1" == *:* ]]; then
        IFS=':' read -r start end <<< "$1"
        shift
        array_length="$#"
        # defaults
        [ -z "$end" ] && end=$array_length
        [ -z "$start" ] && start=0
        (( start < 0 )) && \
            (( start = array_length + start ))
        (( end < 0 )) && \
            (( end = array_length + end ))
    else
        start="$1"
        shift
        array_length="$#"
        (( start < 0 )) && \
            (( start = array_length + start ))
        (( end = start + 1 ))
    fi
    (( length = end - start ))
    (( start < 0 )) && \
        return 1
    # check bounds
    (( length < 0 )) && \
        return 1
    (( start < 0 )) && \
        return 1
    (( start >= array_length )) && \
        return 1
    # parameters start with $1, so add 1 to $start
    (( start = start + 1 ))
    echo "${@: $start:$length}"
}
alias bl.array.unique=bl_array_unique
bl_array_unique() {
    local -r __documentation__='
        Removes duplicates in given array.

        >>> bl.array.unique ""

        >>> bl.array.unique 1
        1

        >>> bl.array.unique "1 2 3"
        1 2 3

        >>> bl.array.unique "1 1 2 3"
        1 2 3

        >>> bl.array.unique "1 1 2 1 3"
        1 2 3

        >>> bl.array.unique "1 11 2 3"
        1 11 2 3
    '
    echo "$1" | \
        tr ' ' '\n' | \
            sort --unique | \
                tr '\n' ' '
}
# endregion
# region vim modline
# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
