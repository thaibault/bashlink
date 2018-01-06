#!/usr/bin/env bash
# -*- coding: utf-8 -*-
# region header
# Copyright Torben Sickert (info["~at~"]torben.website) 16.12.2012

# License
# -------

# This library written by Torben Sickert stand under a creative commons naming
# 3.0 unported license. see http://creativecommons.org/licenses/by/3.0/deed.de
# endregion
system_compile_and_install_without_root() {
    local __doc__='
    Compiles and installs a program by its given source code. Your have to
    be inside the source code folder to run this function.

    >>> system.compile_and_install_without_root /home/user/myUser/
    ...
    '
    local install_location="~/system/"
    if [ "$1" ]; then
        install_location="$1"
    fi
    chmod +x ./configure
    ./configure prefix="$install_location"
    # NOTE: Another possibility to install to a specified path is
    # "make install DESTDIR=$1"
    make install
    return $?
}
alias system.compile_and_install_without_root='system_compile_and_install_without_root'
system_mount_root_file_system_writable() {
    local __doc__='
    If root file system is mounted as read only this command makes it
    runnable.

    >>> system.mount_root_file_system_writable
    '
    mount -rw --options remount /
    return $?
}
alias system.mount_root_file_system_writable='system_mount_root_file_system_writable'
system_restore_grub() {
    local __doc__='
    Restores the linux boot-manager grub if it was overwritten (e.g. in
    windows).

    >>> system.restore_grub
    '
    # TODO use arch chroot
    echo 'Mount systems root filesystem'
    mount /dev/disk/by-label/system /mnt
    echo 'Bind Kernel directories to run kernel in "/mnt"'
    mount --bind /dev /mnt/dev
    mount --bind /proc /mnt/proc
    mount --bind /run /mnt/run
    mount --bind /sys /mnt/sys
    mount --bind /tmp /mnt/tmp
    echo "Change root file system from rescue root system to system's root filesystem (/mnt)"
    chroot /mnt grub-install /dev/sda
    return $?
}
alias system.restore_grub='system_restore_grub'
# region handle display
loadXINITSources() {
    # This functions loads all xinit source scripts.
    #
    # Examples:
    #
    # >>> loadXINITSources
    local xinitRCPath='/etc/X11/xinit/xinitrc.d'
    if [ -d "$XINIT_RC_PATH" ]; then
        for filePath in "${XINIT_RC_PATH}/"*; do
            [ -x "$filePath" ] && source "$filePath"
        done
        unset filePath
    fi
}
setWacomToLVDS1() {
    # This function maps wacom input devices to given rotation.
    #
    # Examples:
    #
    # >>> setWacomToLVDS1 half
    case $1 in none|half|cw|ccw)
        local _SET_WACOM_TO_LVDS1_ROTATE="$1"
        ;;
    '');; *)
        echo -en\
            "Usage: setWacomToLVDS1 [rotate]\nwhere [rotate] is one of\n"\
            "\thalf\tinvert mapping\n"\
            "\tccw\tturn mapping by 90° to the left\n"\
            "\tcw\tturn mapping by 90° to the right\n"\
            "\tnone\treset rotation\n"
        ;;
    esac

    IFS=$'\n'
    for i in `xsetwacom --list devices | cut -f1 | sed 's/ *$//g'`; do
        xsetwacom set "$i" MapToOutput LVDS1
        if [ $_SET_WACOM_TO_LVDS1_ROTATE ]; then
            xsetwacom set "$i" Rotate $_SET_WACOM_TO_LVDS1_ROTATE
        fi
    done
    unset IFS
}
rotateWacomDisplay() {
    # Rotates a wacom display orientation 180°
    #
    # Examples:
    #
    # >>> rotateWacomDisplay
    local _USE="Script to rotate mapping and view of an wacom-display (named output)."

    local _XRANDR_ARG=''
    local _WACOM_ARG=''
    local _OUTPUT='LVDS1'
    local _SELF='rotateWacomDisplay'

    while true; do
        case $1 in
            -h|--help)
            cat <<EOF
$_USE
Usage: $_SELF rotation [output]
Possible rotations are:
-half, --inverted: turn display 180°.
-cw, --right: turn display 90° clockwise.
-ccw, --left: turn display 90° counter-clockwise.
-none, --normal: no rotation.
-n, --next: enable the next rotation as sorted in the list above.
Optionally a valid name for an output listet by xrandr can be given.
EOF
            return 0
        ;;
        -half|--inverted)
            _XRANDR_ARG='inverted'
            _WACOM_ARG='half'
            shift;;
        -cw|--right)
            _XRANDR_ARG='right'
            _WACOM_ARG='cw'
            shift;;
        -ccw|--left)
            _XRANDR_ARG='left'
            _WACOM_ARG='ccw'
            shift;;
        -none|--normal)
            _XRANDR_ARG='normal'
            _WACOM_ARG='none'
            shift;;
        -n|--next)
            local _CURRENT_ROTATION=`xsetwacom --get "Wacom ISDv4 E6 Pen stylus" Rotate`
            case $_CURRENT_ROTATION in
                none)
                "$_SELF" -half;;
            half)
                "$_SELF" -cw;;
            cw)
                "$_SELF" -ccw;;
            ccw)
                "$_SELF" -none;;
            esac
            return $?
            ;;
        -*)
            echo "Error: Invalid argument: $1"
            sh  --help
            return 1
            ;;
        '')
            if [ $_WACOM_ARG ] && [ $_XRANDR_ARG ]; then
                break
            else
                "$_SELF" --next
                return 0
            fi
            ;;
        *)
            _OUTPUT=$1
        shift;;
        esac
    done

    xrandr --output $_OUTPUT --rotate $_XRANDR_ARG
    setWacomToLVDS1 $_WACOM_ARG
    return $?
}
switchFingerTouchWacomEnabled() {
    # Toggles between enabled and disabled finger touch on wacom displays.
    #
    # Examples:
    #
    # >>> switchFingerTouchWacomEnabled
    # >>> switchFingerTouchWacomEnabled enable
    # >>> switchFingerTouchWacomEnabled disable
    if (xinput --list-props 'Wacom ISDv4 E6 Finger touch' | grep \
        'Device Enabled' | cut --fields 3 | grep 1 --quiet
        [[ "$1" != enable ]]) || [[ "$1" == disable ]]
    then
        xinput set-prop 'Wacom ISDv4 E6 Finger touch' 'Device Enabled' 0
        return $?
    else
        xinput set-prop 'Wacom ISDv4 E6 Finger touch' 'Device Enabled' 1
        return $?
    fi
}
# endregion
# region terminal color
# Enable color support of ls and also add handy aliases.
if [ -x /usr/bin/dircolors ]; then
    [ -r ~/.dircolors ] && eval "$(dircolors -b ~/.dircolors)" || \
        eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'

    alias grep='grep --color=auto --line-number'
    alias fgrep='fgrep --color=auto --line-number'
    alias egrep='egrep --color=auto --line-number'
fi
# endregion
# region vim modline
# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
