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
bl.module.import bashlink.tools
# endregion
# region variables
declare -gr BL_DICTIONARY__DOCUMENTATION__='
    The dictionary module implements utility functions concerning dictionary
    operations.
'
# endregion
# region functions
alias bl.dictionary.get=bl_dictionary_get
bl_dictionary_get() {
    local -r __documentation__='

        ```bash
            variable=$(bl.dictionary.get dictionary_name key)
        ```

        >>> bl.dictionary.get unset_map unset_value; echo $?
        1
        >>> BL_DICTIONARY_BASH_VERSION_TEST=true
        >>> bl.dictionary.get unset_map unset_value; echo $?
        1

        >>> bl.dictionary.set map foo 2
        >>> bl.dictionary.set map bar 1
        >>> bl.dictionary.get map foo
        >>> bl.dictionary.get map bar
        2
        1

        >>> bl.dictionary.set map foo "a b c"
        >>> bl.dictionary.get map foo
        a b c

        >>> BL_DICTIONARY_BASH_VERSION_TEST=true
        >>> bl.dictionary.set map foo 2
        >>> bl.dictionary.get map foo
        2

        >>> BL_DICTIONARY_BASH_VERSION_TEST=true
        >>> bl.dictionary.set map foo "a b c"
        >>> bl.dictionary.get map foo
        a b c
    '
    local -r name="$1"
    local -r key="$2"
    local store
    if \
        [[ ${BASH_VERSINFO[0]} -lt 4 ]] || \
        [ -n "${BL_DICTIONARY_BASH_VERSION_TEST:-}" ]
    then
        store="BL_DICTIONARY_STORE_${name}_${key}"
    else
        store="BL_DICTIONARY_STORE_${name}[${key}]"
    fi
    bl.tools.is_defined "$store" || \
        return 1
    echo "${!store}"
}
alias bl.dictionary.get_keys=bl_dictionary_get_keys
bl_dictionary_get_keys() {
    local -r __documentation__='
        Get keys of a dictionary as array.

        ```bash
            bl.dictionary.get_keys dictionary_name
        ```

        >>> bl.dictionary.set map foo "a b c" bar 5
        >>> bl.dictionary.get_keys map | sort --unique
        bar
        foo

        >>> bl.dictionary.set map foo "a b c" bar 5
        >>> local key
        >>> for key in $(bl.dictionary.get_keys map | sort --unique); do
        >>>     echo "$key": "$(bl.dictionary.get map "$key")"
        >>> done
        bar: 5
        foo: a b c

        >>> BL_DICTIONARY_BASH_VERSION_TEST=true
        >>> bl.dictionary.set map foo "a b c" bar 5
        >>> bl.dictionary.get_keys map | sort --unique
        bar
        foo
    '
    local -r name="$1"
    local keys
    local store="BL_DICTIONARY_STORE_${name}"
    if \
        (( BASH_VERSINFO[0] < 4 )) || \
        [ -n "${BL_DICTIONARY_BASH_VERSION_TEST:-}" ]
    then
        for key in $(
            declare -p | \
                cut --delimiter ' ' --fields 3 | \
                    command grep --extended-regexp "^$store" | \
                        cut --delimiter '=' --fields 1
        ); do
            echo "${key#"${store}_"}"
        done
    else
        eval 'keys="${!'"$store"'[@]}"'
    fi

    local key
    for key in ${keys:-}; do
        echo "$key"
    done
}
alias bl.dictionary.set=bl_dictionary_set
bl_dictionary_set() {
    local -r __documentation__='
        ```bash
            bl.dictionary.set dictionary_name key value
        ```

        >>> bl.dictionary.set MAP FOO 2
        >>> echo ${BL_DICTIONARY_STORE_MAP[FOO]}
        2
        >>> bl.dictionary.set MAP FOO "a b c" BAR 5
        >>> echo ${BL_DICTIONARY_STORE_MAP[FOO]}
        >>> echo ${BL_DICTIONARY_STORE_MAP[BAR]}
        a b c
        5
        >>> bl.dictionary.set MAP FOO "a b c" BAR; echo $?
        1

        >>> BL_DICTIONARY_BASH_VERSION_TEST=true
        >>> bl.dictionary.set MAP FOO 2
        >>> echo $BL_DICTIONARY_STORE_MAP_FOO
        2
        >>> BL_DICTIONARY_BASH_VERSION_TEST=true
        >>> bl.dictionary.set MAP FOO "a b c"
        >>> echo $BL_DICTIONARY_STORE_MAP_FOO
        a b c
    '
    local -r name="$1"
    while true; do
        local key="$2"
        local value="\"$3\""
        shift 2
        (( $# % 2 )) || \
            return 1

        if \
            (( BASH_VERSINFO[0] < 4 )) || \
            [ -n "${BL_DICTIONARY_BASH_VERSION_TEST:-}" ]
        then
            eval "BL_DICTIONARY_STORE_${name}_${key}=$value"
        else
            declare -Ag "BL_DICTIONARY_STORE_${name}"
            eval "BL_DICTIONARY_STORE_${name}[${key}]=$value"
        fi

        (( $# == 1 )) && \
            return
    done
}
# endregion
# region vim modline
# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
