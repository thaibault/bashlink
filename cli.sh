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
# endregion
# region variables
declare -gr bl_cli__documentation__='
    This module provides variables for printing colorful and unicode glyphs.
    The Terminal features are detected automatically but can also be
    enabled/disabled manually.

    [bl.cli.enable_color](#function-bl_cli_enable_color) and
    [bl.cli.enable_unicode_glyphs](#function-bl_cli_enable_unicode_glyphs)
'
declare -g bl_cli_color_enabled=false
## region color
declare -g bl_cli_color_black=''
declare -g bl_cli_color_blink=''
declare -g bl_cli_color_blue=''
declare -g bl_cli_color_bold=''
declare -g bl_cli_color_cyan=''
declare -g bl_cli_color_dark_gray=''
declare -g bl_cli_color_default=''
declare -g bl_cli_color_dim=''
declare -g bl_cli_color_green=''
declare -g bl_cli_color_invert=''
declare -g bl_cli_color_invisible=''
declare -g bl_cli_color_light_blue=''
declare -g bl_cli_color_light_cyan=''
declare -g bl_cli_color_light_gray=''
declare -g bl_cli_color_light_green=''
declare -g bl_cli_color_light_magenta=''
declare -g bl_cli_color_light_red=''
declare -g bl_cli_color_light_yellow=''
declare -g bl_cli_color_magenta=''
declare -g bl_cli_color_nodim=''
declare -g bl_cli_color_noblink=''
declare -g bl_cli_color_nobold=''
declare -g bl_cli_color_noinvert=''
declare -g bl_cli_color_noinvisible=''
declare -g bl_cli_color_nounderline=''
declare -g bl_cli_color_red=''
declare -g bl_cli_color_underline=''
declare -g bl_cli_color_white=''
declare -g bl_cli_color_yellow=''
## endregion
## region unicode glyphs
# NOTE: Each fall-back symbol should only consist of one character. To allow
# interactive shell integration (with fixed number of printed characters to
# replace).
declare -g bl_cli_powerline_arrow_down=_
declare -g bl_cli_powerline_arrow_left='<'
declare -g bl_cli_powerline_arrow_right='>'
declare -g bl_cli_powerline_arrow_right_down='>'
declare -g bl_cli_powerline_branch='}'
declare -g bl_cli_powerline_cog='*'
declare -g bl_cli_powerline_fail=x
declare -g bl_cli_powerline_heart=3
declare -g bl_cli_powerline_lightning=!
declare -g bl_cli_powerline_ok=+
declare -g bl_cli_powerline_pointingarrow=~
declare -g bl_cli_powerline_plusminus=x
declare -g bl_cli_powerline_refersto='*'
declare -g bl_cli_powerline_star='*'
declare -g bl_cli_powerline_saxophone=y
declare -g bl_cli_powerline_thumbsup=+
## endregion
# NOTE: Use 'xfd -fa <font-name>' to watch glyphs.
declare -g bl_cli_unicode_enabled=false
# endregion
# region functions
alias bl.cli.glyph_available_in_font=bl_cli_glyph_available_in_font
bl_cli_glyph_available_in_font() {
    local -r __documentation__='
        Check if unicode glyphicons are available.

        >>> bl.cli.glyph_available_in_font
    '
    local current_font
    if ! current_font="$(
        xrdb -q 2>/dev/null | \
            command grep -i facename | \
                cut -d: -f2
    )"; then
        return 1
    fi
    hash fc-match &>/dev/null || \
        return 1
    local -r font_file_name="$(fc-match "$current_font" | cut -d: -f1)"
    local -r font_file_extension="${font_file_name##*.}"
    if [ "$font_file_extension" = otf ]; then
        hash otfinfo &>/dev/null || \
            return 1
        otfinfo /usr/share/fonts/OTF/Hack-Regular.otf -u | \
            command grep -i uni27a1
    elif [ "$font_file_extension" = ttf ]; then
        hash ttfdump &>/dev/null || \
            return 1
        ttfdump -t cmap /usr/share/fonts/TTF/Hack-Regular.ttf 2>/dev/null | \
            command grep 'Char 0x27a1'
    else
        return 1
    fi
    return 0
}
alias bl.cli.disable_color=bl_cli_disable_color
bl_cli_disable_color() {
    local -r __documentation__='
        Disables color output explicitly.

        >>> bl.cli.enable_color
        >>> bl.cli.disable_color
        >>> echo -E "$bl_cli_color_red" red "$bl_cli_color_default"
        red
    '
    bl_cli_color_enabled=false
    local name
    for name in \
        black \
        blink \
        blue \
        bold \
        cyan \
        dark_gray \
        default \
        dim \
        green \
        invert \
        invisible \
        light_blue \
        light_cyan \
        light_gray \
        light_green \
        light_magenta \
        light_red \
        light_yellow \
        magenta \
        nodim \
        noblink \
        nobold \
        noinvert \
        noinvisible \
        nounderline \
        red \
        underline \
        white \
        yellow
    do
        eval "bl_cli_color_${name}=''"
    done
}
alias bl.cli.enable_color=bl_cli_enable_color
bl_cli_enable_color() {
    local -r __documentation__='
        Enables color output explicitly.

        >>> bl.cli.disable_color
        >>> bl.cli.enable_color
        >>> echo -E $bl_cli_color_red red $bl_cli_color_default
        \033[0;31m red \033[0m
    '
    bl_cli_color_enabled=true
    local suffix
    for suffix in \
        "black='\\033[0;30m'" \
        "blink='\\033[5m'" \
        "blue='\\033[0;34m'" \
        "bold='\\033[1m'" \
        "cyan='\\033[0;36m'" \
        "dark_gray='\\033[0;90m'" \
        "default='\\033[0m'" \
        "dim='\\033[2m'" \
        "green='\\033[0;32m'" \
        "invert='\\033[7m'" \
        "invisible='\\033[8m'" \
        "light_blue='\\033[0;94m'" \
        "light_cyan='\\033[0;96m'" \
        "light_gray='\\033[0;37m'" \
        "light_green='\\033[0;92m'" \
        "light_magenta='\\033[0;95m'" \
        "light_red='\\033[0;91m'" \
        "light_yellow='\\033[0;93m'" \
        "magenta='\\033[0;35m'" \
        "nodim='\\033[22m'" \
        "noblink='\\033[25m'" \
        "nobold='\\033[21m'" \
        "noinvert='\\033[27m'" \
        "noinvisible='\\033[28m'" \
        "nounderline='\\033[24m'" \
        "red='\\033[0;31m'" \
        "underline='\\033[4m'" \
        "white='\\033[0;97m'" \
        "yellow='\\033[0;33m'"
    do
        eval "bl_cli_color_${suffix}"
    done
}
## region glyphs
alias bl.cli.disable_unicode_glyphs=bl_cli_disable_unicode_glyphs
bl_cli_disable_unicode_glyphs() {
    local -r __documentation__='
        Disables unicode glyphs explicitly.

        >>> bl.cli.enable_unicode_glyphs
        >>> bl.cli.disable_unicode_glyphs
        >>> echo -E "$bl_cli_powerline_ok"
        +
    '
    bl_cli_unicode_enabled=false
    local name
    for name in \
        arrow_down \
        arrow_left \
        arrow_right \
        arrow_right_down \
        branch \
        cog \
        fail \
        heart \
        lightning \
        ok \
        pointingarrow \
        plusminus \
        refersto \
        star \
        saxophone \
        thumbsup
    do
        if [[ "$(eval "echo \"\$bl_cli_powerline_${name}_backup\"")" != '' ]]; then
            eval \
                "bl_cli_powerline_${name}=\"\$bl_cli_powerline_${name}_backup\""
        fi
    done
}
alias bl.cli.enable_unicode_glyphs=bl_cli_enable_unicode_glyphs
bl_cli_enable_unicode_glyphs() {
    local -r __documentation__='
        Enables unicode glyphs explicitly.

        >>> bl.cli.disable_unicode_glyphs
        >>> bl.cli.enable_unicode_glyphs
        >>> echo -E "$bl_cli_powerline_ok"
        \u2714
    '
    for name in \
        arrow_down \
        arrow_left \
        arrow_right \
        arrow_right_down \
        branch \
        cog \
        fail \
        heart \
        lightning \
        ok \
        pointingarrow \
        plusminus \
        refersto \
        star \
        saxophone \
        thumbsup
    do
        eval "[[ -z \"\$bl_cli_powerline_${name}_backup\" ]] && bl_cli_powerline_${name}_backup=\"\$bl_cli_powerline_${name}\""
    done
    bl_cli_unicode_enabled=true
    local suffix
    for suffix in \
        "arrow_down='\\u2b07'" \
        "arrow_left='\\ue0b2'" \
        "arrow_right='\\ue0b0'" \
        "arrow_right_down='\\u2198'" \
        "branch='\\ue0a0'" \
        "cog='\\u2699'" \
        "fail='\\u2718'" \
        "heart='\\u2764'" \
        "lightning='\\u26a1'" \
        "ok='\\u2714'" \
        "pointingarrow='\\u27a1'" \
        "plusminus='\\ue00b1'" \
        "refersto='\\u27a6'" \
        "star='\\u2b50'" \
        "saxophone='\\u1f3b7'" \
        "thumbsup='\\u1f44d'"
    do
        eval "bl_cli_powerline_${suffix}"
    done
}
## endregion
# endregion
# region detect terminal capabilities
if [[ "${TERM}" == *"xterm"* ]]; then
    bl_cli_enable_color
else
    bl_cli_disable_color
fi
# TODO this breaks dracut (segfault)
#(echo -e $'\u1F3B7' | command grep -v F3B7) &> /dev/null
# NOTE: "bl.tools.is_defined" results in an dependency cycle.
if bl.module.is_defined NO_UNICODE || ! bl.cli.glyph_available_in_font; then
    bl.cli.disable_unicode_glyphs
else
    bl.cli.enable_unicode_glyphs
fi
# endregion
# region vim modline
# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
