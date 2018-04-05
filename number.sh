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
# NOTE: We cannot import the logging module to avoid a dependency cycle.
# shellcheck source=./module.sh
source "$(dirname "${BASH_SOURCE[0]}")/module.sh"
bl.module.import bashlink.array
bl.module.import bashlink.logging
# endregion
# region variables
declare -gr bl_number__documentation__='
    The number module implements utility functions concerning numbers.
'
# endregion
# region functions
alias bl.number.calculate_percent=bl_number_calculate_percent
bl_number_calculate_percent() {
    local -r __documentation__='
        Calculates percent of second argument from the first argument.

        >>> bl_number_calculate_percent 100 50
        50.00
    '
    echo "$(((($2 * 10000) / $1) / 100)).$(
        command sed \
            --regexp-extended \
            's/^(.)$/0\1/g' \
                <<<$(((($2 * 10000) / $1) % 100)))"
}
alias bl.number.normalize_version=bl_number_normalize_version
bl_number_normalize_version() {
    local -r __documentation__='
        Normalizes given version number to a raw number.

        >>> bl.number.normalize_version "database/openssl-1.1.0.g-1"
        1101000000000

        >>> bl.number.normalize_version "database/openssl-1.1.0.g-1" 4
        1101

        >>> bl.number.normalize_version 1.1.0.1 4
        1101

        >>> bl.number.normalize_version 1101 4
        1101000

        >>> bl.number.normalize_version 0 4
        0

        >>> bl.number.normalize_version 0 10
        0

        >>> bl.number.normalize_version abc-0.1.1.0.1 6
        11010

        >>> bl.number.normalize_version 19.1-1-x86_64 10
        27774000000

        >>> bl.number.normalize_version abc-0.1.1.0.1 2; echo $?
        1
        0
    '
    local -a items
    IFS='.' read -ra items <<< "$(
        echo "$1" | \
            command sed --regexp-extended 's/[^0-9.-]+//g' | \
                command sed --regexp-extended 's/(^[^0-9]+)|([^0-9]+$)//g' | \
                    command sed --regexp-extended 's/[^0-9]+/./g'
    )"
    # NOTE: We should initialize this value with `1` and decrement the final
    # result to avoid adding `0` to `0` which results into an error.
    local -i result=1
    local item
    local -ir initial_point="${2:-13}"
    local -i point=$(( initial_point - 1 ))
    for item in "${items[@]}"; do
        if (( point < 0 )); then
            bl.logging.warn \
                "Loosing information due to small number representation in version normalizing of \"$1\" with \"$initial_point\"."
        else
            (( result += (( item * (( 10 ** point )) )) ))
            (( point -= 1 ))
        fi
    done
    (( result -= 1 ))
    echo "$result"
}
# endregion
# region vim modline
# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
