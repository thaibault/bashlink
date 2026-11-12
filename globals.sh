#!/usr/bin/env bash
# -*- coding: utf-8 -*-
# region header
# Copyright Torben Sickert (info["~at~"]tsickert.com) 16.12.2012

# License
# -------

# This library written by Torben Sickert stands under a creative commons naming
# 4.0 international license.
# See https://creativecommons.org/licenses/by/4.0/deed.de
# endregion
# shellcheck disable=SC2016,SC2034,SC2155
declare -gr BL_GLOBALS__DOCUMENTATION__='
    The globals module provides generic re-usable variables.
'
# NOTE: Globals of "bashlink.globals" are meant to be configured by consumers.
declare -g BL_GLOBALS_CONFIGURATION_PATH=~/configuration/
declare -g BL_GLOBALS_DATA_PATH=~/
declare -g BL_GLOBALS_USER_E_MAIL_ADDRESS=example@domain.tld
# NOTE: Keep an exported value since "prompt/timeout.sh" runs as separate
# process and can only be configured via environment.
declare -gi BL_GLOBALS_COMMAND_PROMPT_TIMEOUT_IN_SECONDS="${BL_GLOBALS_COMMAND_PROMPT_TIMEOUT_IN_SECONDS:-1}"
# region vim modline
# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
