#!/usr/bin/env bash
# -*- coding: utf-8 -*-
# region header
# Copyright Torben Sickert (info["~at~"]torben.website) 16.12.2012

# License
# -------

# This library written by Torben Sickert stand under a creative commons naming
# 3.0 unported license. see http://creativecommons.org/licenses/by/3.0/deed.de
# endregion
# region import
# shellcheck source=../module.sh
source "$(dirname "${BASH_SOURCE[0]}")/../module.sh"
bl.module.import bashlink.logging
bl.module.import bashlink.tools
# endregion
bl_mockup_a_foo() {
    bl.logging.plain a
}
if bl.tools.is_main; then
    bl.logging.plain running a
    exit 0
fi
bl.logging.plain imported module a
# region vim modline
# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
