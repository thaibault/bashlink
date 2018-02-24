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
# region variables
bl_network__documentation__='
    The network module implements utility functions concerning network
    confgurations.
'
# endregion
# region functions
alias bl.network.restart_network='sudo ifdown -a &>/dev/null && sudo ifup -a &>/dev/null'
alias bl.network.wlan_start=bl.network_wlan_start
bl_network_wlan_start() {
    local __documentation__='
        Starts wlan functionality.

        ```bash
            bl.network.wlan_start
        ```
    '
    wpa_supplicant -c /etc/wpa_supplicant.conf -i wlan0 -D wext -B
    dhclient wlan0
    return $?
}
alias bl.network.wlan_stop=bl_network_wlan_stop
bl_network_wlan_stop() {
    local __documentation__='
        Stops wlan functionality.

        ```bash
            bl.network.wlan_stop
        ```
    '
    killall wpa_supplicant
    killall dhclient
    killall dhclient3
    return $?
}
# NOTE: Depends on "bl.network.wlan_start" and "bl.network.wlan_stop"
alias bl.network.wlan_restart=bl_network_wlan_restart
bl_network_wlan_restart() {
    local __documentation__='
        Restart wlan functionality.

        ```bash
            bl.network.wlan_restart
        ```
    '
    bl.network.wlan_stop
    bl.network.wlan_start
    return $?
}
# endregion
# region vim modline
# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
