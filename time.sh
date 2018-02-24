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
bl_time__documentation__='
    The time module implements utility functions concerning time measurments.
'
bl_time_start=0
# endregion
# region functions
alias bl.time.get_elapsed=bl_time_get_elapsed
bl_time_get_elapsed() {
    local __documentation__='
        Prints elapsed time in milliseconds since last `bl.time.start` call.

        >>> local time=$(bl.time.get_elapsed)
        >>> (( time > 0 )) && echo $?
        0

        >>> bl.time.start
        >>> local time=$(bl.time.get_elapsed)
        >>> (( time > 0 )) && echo $?
        0
    '
    local end_time="$(date +%s%N)"
    local elapsed_time_in_ns=$(( end_time  - bl_time_start ))
    bl.logging.plain $(( elapsed_time_in_ns / 1000000 ))
}
alias bl.time.start=bl_time_start
bl_time_start() {
    local __documentation__='
        Prints elapsed time in milliseconds since last `bl.time.start` call.

        >>> bl.time.start
        >>> bl.time.start
        >>> local time=$(bl.time.get_elapsed)
        >>> (( time > 0 )) && echo $?
        0
    '
    bl_time_start=$(date +%s%N)
}
# endregion
# region vim modline
# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
