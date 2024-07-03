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
declare -gr BL_GLOBALS__DOCUMENTATION__='
    The globals module provides generic re-usable variables.
'
declare -g BL_GLOBALS_CONFIGURATION_PATH=~/configuration/
declare -g BL_GLOBALS_DATA_PATH=~/
declare -g BL_GLOBALS_USER_E_MAIL_ADDRESS=example@domain.tld
# region vim modline
# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
