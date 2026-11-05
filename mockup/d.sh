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
# endregion
# NOTE: Defined before a nested import to check that it is still attributed to
# this module.
bl_mockup_d_before() {
    true
}
# region import
# NOTE: Functions of nested imports should not be attributed to this module
# even if they are imported without namespace check.
BL_MODULE_PREVENT_NAMESPACE_CHECK=true
bl.module.import bashlink.number
BL_MODULE_PREVENT_NAMESPACE_CHECK=false
# endregion
bl_mockup_d_after() {
    true
}
# region vim modline
# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
