#!/usr/bin/env bash
# -*- coding: utf-8 -*-
# region header
# Copyright Torben Sickert (info["~at~"]torben.website) 16.12.2012

# License
# -------

# This library written by Torben Sickert stand under a creative commons naming
# 3.0 unported license. see http://creativecommons.org/licenses/by/3.0/deed.de
# endregion
CURRENT_PATH="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/"

declare -i TIMEOUT_IN_SECONDS=1

timeout \
    --kill-after="$((TIMEOUT_IN_SECONDS * 3))" \
    "$TIMEOUT_IN_SECONDS" \
    "${CURRENT_PATH}main.sh"
# region vim modline
# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
