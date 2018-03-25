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
declare -gr bl_display__documentation__='
    The display module implements utility functions concerning display
    configuration.
'
# endregion
# region functions
alias bl.display.load_xinit_sources=bl_display_load_xinit_sources
bl_display_load_xinit_sources() {
    local -r __documentation__='
        This functions loads all xinit source scripts.

        ``bash
            bl.display.load_xinit_sources
        ```
    '
    local -r xinit_rc_path=/etc/X11/xinit/xinitrc.d
    if [ -d "$xinit_rc_path" ]; then
        local file_path
        for file_path in "${xinit_rc_path}/"*; do
            [ -f "$file_path" ] && \
                source "$file_path"
        done
    fi
}
# endregion
# region vim modline
# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
