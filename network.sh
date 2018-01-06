#!/usr/bin/env bash
# -*- coding: utf-8 -*-
# region header
# Copyright Torben Sickert (info["~at~"]torben.website) 16.12.2012

# License
# -------

# This library written by Torben Sickert stand under a creative commons naming
# 3.0 unported license. see http://creativecommons.org/licenses/by/3.0/deed.de
# endregion
alias network.restart_network='sudo ifdown -a &>/dev/null && sudo ifup -a &>/dev/null'
network_wlan_start() {
    local __doc__='
    Starts wlan functionality.

    >>> network.wlan_start
    '
    wpa_supplicant -c /etc/wpa_supplicant.conf -i wlan0 -D wext -B
    dhclient wlan0
    return $?
}
alias network.wlan_start='network_wlan_start'
network_wlan_stop() {
    local __doc__='
    Stops wlan functionality.

    >>> network.wlan_stop
    '
    killall wpa_supplicant
    killall dhclient
    killall dhclient3
    return $?
}
alias network.wlan_stop='network_wlan_stop'
network_wlan_restart() {
    local __doc__='
    Restart wlan functionality.

    >>> wlanRestart
    '
    network.wlan_stop
    network.wlan_start
    return $?
}
alias network.wlan_restart='network_wlan_restart'
# region vim modline
# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion