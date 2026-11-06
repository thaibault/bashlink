#!/usr/bin/env bash
# -*- coding: utf-8 -*-
# region header
# Copyright Torben Sickert (info["~at~"]tsickert.com) 16.12.2012

# License
# -------

# This library written by Torben Sickert stands under a creative commons naming
# 3.0 unported license. See https://creativecommons.org/licenses/by/3.0/deed.de
# endregion
# region import
# shellcheck source=../module.sh
source "$(dirname "${BASH_SOURCE[0]}")/../module.sh"
# NOTE: Accepts "e_*" and "E_*" names in this module only.
# shellcheck disable=SC2034
BL_MODULE_SCOPE_NAME_PREFIX=e
# NOTE: Nested imports should neither see nor reset this module's prefix.
bl.module.import bashlink.mockup.a
# endregion
# shellcheck disable=SC2034
declare -g E_VARIABLE=value
e_function() {
    true
}
unprefixed_function() {
    true
}
bl.logging.plain imported module e
# region vim modline
# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
